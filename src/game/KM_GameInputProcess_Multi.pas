unit KM_GameInputProcess_Multi;
{$I KaM_Remake.inc}
interface
uses
  KM_GameInputProcess,
  KM_Hand, KM_Networking,
  KM_CommonClasses, KM_CommonTypes, KM_Defaults;

const
  MAX_SCHEDULE = 100; //Size of ring buffers (10 sec) Make them large so overruns do not occur
  DELAY_ADJUST = 40; //How often to adjust fDelay (every 4 seconds) This must be higher than MAX_DELAY
  MIN_DELAY = 2; //A delay of 1 is not possible because that means the command shall be processed on the next tick after it was issued, but that could be 0.0001ms after the player clicks, meaning there is no way the command would have been sent. Therefore the delay must be 2 at minimum.
  MAX_DELAY = 32; //Maximum number of ticks (3.2 sec) to plan ahead (highest value fDelay can take)

type
  TKMDataType = (kdpCommands, kdpRandomCheck);

  TKMCommandsPack = class
  private
    fCount: Byte;
    fItems: array of TKMGameInputCommand; //1..n
    function GetItem(aIndex: Integer): TKMGameInputCommand;
  public
    property  Count: Byte read fCount;
    procedure Clear;
    procedure Add(aCommand: TKMGameInputCommand);
    function CRC: Cardinal;
    property Items[aIndex: Integer]: TKMGameInputCommand read GetItem;
    procedure Save(aStream: TKMemoryStream);
    procedure Load(aStream: TKMemoryStream);
  end;

  TKMRandomCheck = record
    OurCheck: Cardinal;
    PlayerCheck: array [1..MAX_LOBBY_SLOTS] of Cardinal;
    PlayerCheckPending: array [1..MAX_LOBBY_SLOTS] of Boolean;
  end;

  TKMGameInputProcess_Multi = class (TKMGameInputProcess)
  private
    fNetworking: TKMNetworking;
    fDelay: Word; //How many ticks ahead the commands are scheduled
    fLastSentTick: Cardinal; //Needed for resync

    fNumberConsecutiveWaits: Word; //Number of consecutive times we have been waiting for network

    //Each player can have any number of commands scheduled for execution in one tick
    fSchedule: array[0..MAX_SCHEDULE-1, 1..MAX_LOBBY_SLOTS] of TKMCommandsPack; //Ring buffer

    //All players must send us data every tick
    fRecievedData: array[0..MAX_SCHEDULE-1, 1..MAX_LOBBY_SLOTS] of Boolean; //Ring buffer

    //Mark commands we've already sent to other players
    fSent: array[0..MAX_SCHEDULE-1] of Boolean; //Ring buffer

    //Did the player issue a command for this tick? If not it must be cleared from last time (we can't clear it earlier as it might be needed for resync)
    fCommandIssued: array[0..MAX_SCHEDULE-1] of Boolean;

    //Store random seeds at each tick then confirm with other players
    fRandomCheck: array[0..MAX_SCHEDULE-1] of TKMRandomCheck; //Ring buffer

    procedure SendCommands(aTick: Cardinal; aPlayerIndex: ShortInt=-1);
    procedure SendRandomCheck(aTick: Cardinal);
    procedure DoRandomCheck(aTick: Cardinal; aPlayerIndex: ShortInt);

    procedure SetDelay(aNewDelay:integer);
  protected
    procedure TakeCommand(const aCommand: TKMGameInputCommand); override;
  public
    constructor Create(aReplayState: TKMGIPReplayState; aNetworking: TKMNetworking);
    destructor Destroy; override;
    procedure WaitingForConfirmation(aTick: Cardinal); override;
    procedure AdjustDelay(aGameSpeed: Single);
    procedure PlayerTypeChange(aPlayer: TKMHandID; aType: TKMHandType);
    function GetNetworkDelay: Word;
    property GetNumberConsecutiveWaits: Word read fNumberConsecutiveWaits;
    function GetWaitingPlayers(aTick: Cardinal): TKMByteArray;
    procedure RecieveCommands(aStream: TKMemoryStream; aSenderIndex: ShortInt); //Called by TKMNetwork when it has data for us
    procedure ResyncFromTick(aSender: ShortInt; aTick: Cardinal);
    function CommandsConfirmed(aTick: Cardinal):boolean; override;
    procedure RunningTimer(aTick: Cardinal); override;
    procedure UpdateState(aTick: Cardinal); override;
  end;


implementation
uses
  SysUtils, Math, KromUtils,
  KM_GameApp, KM_Game, KM_HandsCollection,
  KM_ResTexts, KM_ResSound, KM_Sound, KM_CommonUtils,
  KM_GameTypes;


{ TCommandsPack }
procedure TKMCommandsPack.Clear;
begin
  fCount := 0;
end;


procedure TKMCommandsPack.Add(aCommand: TKMGameInputCommand);
begin
  inc(fCount);
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 8);

  fItems[fCount] := aCommand;
end;


function TKMCommandsPack.GetItem(aIndex:integer): TKMGameInputCommand;
begin
  Result := fItems[aIndex];
end;


//Return CRC of the pack
function TKMCommandsPack.CRC: Cardinal;
var I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    Result := Result xor Adler32CRC(@fItems[I], SizeOf(fItems[I]))
end;


procedure TKMCommandsPack.Save(aStream: TKMemoryStream);
var I: Integer;
begin
  aStream.Write(fCount);
  for I := 1 to fCount do
  begin
    //gLog.AddTime(Format('%s', [GetEnumName(TypeInfo(TGameInputCommandType), Integer(fItems[I].CommandType))]));
    SaveCommandToMemoryStream(fItems[I], aStream);
  end;
end;


procedure TKMCommandsPack.Load(aStream: TKMemoryStream);
var I: Integer;
begin
  aStream.Read(fCount);
  SetLength(fItems, fCount + 1);

  for I := 1 to fCount do
    LoadCommandFromMemoryStream(fItems[I], aStream);
end;


{ TGameInputProcess_Multi }
constructor TKMGameInputProcess_Multi.Create(aReplayState: TKMGIPReplayState; aNetworking: TKMNetworking);
var i:integer; k: ShortInt;
begin
  inherited Create(aReplayState);
  fNetworking := aNetworking;
  fNetworking.OnCommands := RecieveCommands;
  fNetworking.OnResyncFromTick := ResyncFromTick;
  AdjustDelay(1); //Initialise the delay

  //Allocate memory for all commands packs
  for i:=0 to MAX_SCHEDULE-1 do for k:=1 to MAX_LOBBY_SLOTS do
  begin
    fSchedule[i,k] := TKMCommandsPack.Create;
    fRandomCheck[i].PlayerCheckPending[k] := false; //We don't have anything to be checked yet
  end;
end;


destructor TKMGameInputProcess_Multi.Destroy;
var
  I: integer;
  K: ShortInt;
begin
  for I := 0 to MAX_SCHEDULE - 1 do
    for K := 1 to MAX_LOBBY_SLOTS do
      fSchedule[I, K].Free;
  inherited;
end;


//Stack the command into schedule
procedure TKMGameInputProcess_Multi.TakeCommand(const aCommand: TKMGameInputCommand);
var I,Tick: Cardinal;
begin
  Assert(fDelay < MAX_SCHEDULE, 'Error, fDelay >= MAX_SCHEDULE');
  if ((gGame.GameMode = gmMultiSpectate) and not (aCommand.CommandType in AllowedBySpectators)) // Do not allow spectators to command smth
    or ((gGame.GameMode = gmMulti)                      // in multiplayer game
      and IsSelectedObjectCommand(aCommand.CommandType) // block only commands for selected object
      and (gMySpectator.Selected <> nil)                // if there is selected object
      and not gMySpectator.IsSelectedMyObj) then        // and we try to make command to ally's object
    Exit;

  if gGame.IsPeaceTime and (aCommand.CommandType in BlockedByPeaceTime) then
  begin
    gGameApp.Networking.PostLocalMessage(gResTexts[TX_MP_BLOCKED_BY_PEACETIME], csNone);
    gSoundPlayer.Play(sfxCantPlace);
    Exit;
  end;

  if (gGame.GameMode <> gmMultiSpectate) and gMySpectator.Hand.AI.HasLost
    and not (aCommand.CommandType in AllowedAfterDefeat) then
  begin
    gSoundPlayer.Play(sfxCantPlace);
    Exit;
  end;

  //Find first unsent pack
  Tick := MAX_SCHEDULE; //Out of range value
  for I := gGame.GameTick + fDelay to gGame.GameTick + MAX_SCHEDULE - 1 do
    if not fSent[I mod MAX_SCHEDULE] then
    begin
      Tick := I mod MAX_SCHEDULE; //Place in a ring buffer
      Break;
    end;
  Assert(Tick < MAX_SCHEDULE, 'Could not find place for new commands');

  if not fCommandIssued[Tick] then
  begin
    fSchedule[Tick, gGame.Networking.MyIndex].Clear; //Clear old data (it was kept in case it was required for resync)
    fCommandIssued[Tick] := true;
  end;
  fSchedule[Tick, gGame.Networking.MyIndex].Add(aCommand);
end;


procedure TKMGameInputProcess_Multi.WaitingForConfirmation(aTick: Cardinal);
begin
  //This is a notification that the game is waiting for a tick to be ready
  if fNumberConsecutiveWaits < High(fNumberConsecutiveWaits) then
    inc(fNumberConsecutiveWaits);
  //Mostly unused at the moment, could be used later for e.g. better fDelay calculation.
end;


function TKMGameInputProcess_Multi.GetNetworkDelay: Word;
begin
  Result := fDelay;
end;


procedure TKMGameInputProcess_Multi.SetDelay(aNewDelay: Integer);
begin
  fDelay := EnsureRange(aNewDelay, MIN_DELAY, MAX_DELAY);
end;


procedure TKMGameInputProcess_Multi.AdjustDelay(aGameSpeed: Single);
begin
  //Half of the maximum round trip is a good guess for delay. +1.2 is our safety net to account
  //for processing the packet and random variations in ping. It's always better for commands to
  //be slightly delayed than for the game to freeze/lag regularly.
  SetDelay(Ceil(aGameSpeed * (fNetworking.NetPlayers.GetMaxHighestRoundTripLatency / 200 + 1.2)));
end;


procedure TKMGameInputProcess_Multi.PlayerTypeChange(aPlayer: TKMHandID; aType: TKMHandType);
begin
  Assert(ReplayState = gipRecording);
  StoreCommand(MakeCommand(gicGamePlayerTypeChange, aPlayer, Byte(aType)));
end;


procedure TKMGameInputProcess_Multi.SendCommands(aTick: Cardinal; aPlayerIndex: ShortInt=-1);
var
  Msg: TKMemoryStream;
begin
  Msg := TKMemoryStream.Create;
  try
    Msg.Write(Byte(kdpCommands));
    Msg.Write(aTick); //Target Tick in 1..n range
    fSchedule[aTick mod MAX_SCHEDULE, gGame.Networking.MyIndex].Save(Msg); //Write all commands to the stream

    fNetworking.SendCommands(Msg, aPlayerIndex); //Send to all players by default
  finally
    Msg.Free;
  end;
end;


procedure TKMGameInputProcess_Multi.SendRandomCheck(aTick: Cardinal);
var
  Msg: TKMemoryStream;
begin
  Msg := TKMemoryStream.Create;
  try
    Msg.Write(Byte(kdpRandomCheck));
    Msg.Write(aTick); //Target Tick in 1..n range
    Msg.Write(fRandomCheck[aTick mod MAX_SCHEDULE].OurCheck); //Write our random check to the stream
    fNetworking.SendCommands(Msg); //Send to all opponents
  finally
    Msg.Free;
  end;
end;


procedure TKMGameInputProcess_Multi.DoRandomCheck(aTick: Cardinal; aPlayerIndex: ShortInt);
begin
  with fRandomCheck[aTick mod MAX_SCHEDULE] do
  begin
    Assert(OurCheck = PlayerCheck[aPlayerIndex],Format('Random check mismatch for tick %d from net player %d [%s] [Hand %d] processed at tick %d',
                                                       [aTick,
                                                        aPlayerIndex,
                                                        fNetworking.NetPlayers[aPlayerIndex].Nikname,
                                                        fNetworking.NetPlayers[aPlayerIndex].HandIndex,
                                                        gGame.GameTick]));
    PlayerCheckPending[aPlayerIndex] := False;
  end;
end;


//Decode recieved messages (Commands from other players, Confirmations, Errors)
procedure TKMGameInputProcess_Multi.RecieveCommands(aStream: TKMemoryStream; aSenderIndex: ShortInt);
var
  dataType: TKMDataType;
  Tick: Cardinal;
  CRC: Cardinal;
begin
  aStream.Read(dataType, 1); //Decode header
  aStream.Read(Tick); //Target tick

  case dataType of
    kdpCommands:
        begin
          //Recieving commands too late will happen during reconnections, so just ignore it
          if Tick > gGame.GameTick then
          begin
            fSchedule[Tick mod MAX_SCHEDULE, aSenderIndex].Load(aStream);
            fRecievedData[Tick mod MAX_SCHEDULE, aSenderIndex] := True;
          end;
        end;
    kdpRandomCheck: //Other player is confirming that random seeds matched at a tick in the past
        begin
          aStream.Read(CRC); //Read the random check from the message
          fRandomCheck[Tick mod MAX_SCHEDULE].PlayerCheck[aSenderIndex] := CRC; //Store it for this player
          fRandomCheck[Tick mod MAX_SCHEDULE].PlayerCheckPending[aSenderIndex] := True;
          //If we have processed this tick already, check now
          if Tick <= gGame.GameTick then
            DoRandomCheck(Tick, aSenderIndex);
        end;
  end;
end;


//We must resend the commands from aTick to the last sent tick to the specified player
procedure TKMGameInputProcess_Multi.ResyncFromTick(aSender: ShortInt; aTick: Cardinal);
var
  I: Cardinal;
begin
  for I := aTick to fLastSentTick do
    SendCommands(I, aSender);
end;


//Are all the commands are confirmed?
function TKMGameInputProcess_Multi.CommandsConfirmed(aTick: Cardinal): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to fNetworking.NetPlayers.Count do
    Result := Result and (fRecievedData[aTick mod MAX_SCHEDULE, I]
              or not fNetworking.NetPlayers[I].IsHuman or fNetworking.NetPlayers[I].Dropped);
end;


//Indexes of players we are waiting for
function TKMGameInputProcess_Multi.GetWaitingPlayers(aTick: Cardinal): TKMByteArray;
var
  I, K: Integer;
begin
  SetLength(Result, MAX_LOBBY_SLOTS);

  K := 0;
  for I := 1 to fNetworking.NetPlayers.Count do
    if not (fRecievedData[aTick mod MAX_SCHEDULE, I]
    or (not fNetworking.NetPlayers[I].IsHuman) or fNetworking.NetPlayers[I].Dropped) then
    begin
      Result[K] := I;
      Inc(K);
    end;

  SetLength(Result, K);
end;


//Timer is called after all commands from player are taken,
//upcoming commands will be stacked into next batch
procedure TKMGameInputProcess_Multi.RunningTimer(aTick: Cardinal);
var
  I, K, Tick: Cardinal;
begin
  inherited;

  fNumberConsecutiveWaits := 0; //We are not waiting if the game is running
  Tick := aTick mod MAX_SCHEDULE; //Place in a ring buffer
  fRandomCheck[Tick].OurCheck := Cardinal(KaMRandom(MaxInt, 'TKMGameInputProcess_Multi.RunningTimer')); //thats our CRC (must go before commands for replay compatibility)

  //Execute commands, in order players go (1,2,3..)
  for I := 1 to fNetworking.NetPlayers.Count do
    for K := 1 to fSchedule[Tick, I].Count do
    begin
      if not fNetworking.NetPlayers[I].Dropped
      //Don't allow exploits like moving enemy soldiers (but maybe one day you can control disconnected allies?)
      and ((fNetworking.NetPlayers[I].HandIndex = fSchedule[Tick, I].Items[K].HandIndex)
           or (fSchedule[Tick, I].Items[K].CommandType in AllowedBySpectators)) then
      begin
        StoreCommand(fSchedule[Tick, I].Items[K]); //Store the command first so if Exec fails we still have it in the replay
        ExecCommand(fSchedule[Tick, I].Items[K]);
        //Returning to the lobby ends the game
        if gGame = nil then Exit;
      end;
    end;

  //If we miss a few random checks during reconnections no one cares, inconsistencies will be detected as soon as it is over
  //To reduce network load, send random checks once every 10 ticks
  if fNetworking.Connected {and (aTick mod 10 = 1)} then //Todo: remove debug brackets: {} no need to check on every tick in release version
    SendRandomCheck(aTick);

  //It is possible that we have already recieved other player's random checks, if so check them now
  for I := 1 to fNetworking.NetPlayers.Count do
  begin
    if not fNetworking.NetPlayers[I].Dropped and fRandomCheck[Tick].PlayerCheckPending[I] then
      DoRandomCheck(aTick, I);
  end;

  FillChar(fRecievedData[Tick], SizeOf(fRecievedData[Tick]), #0); //Reset
  fSent[Tick] := False;

  if aTick mod DELAY_ADJUST = 0 then
    AdjustDelay(gGame.GameSpeed); //Adjust fDelay every X ticks
end;


procedure TKMGameInputProcess_Multi.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  inherited;

  for I := aTick + 1 to aTick + fDelay do
    //If the network is not connected then we must send the commands later (fSent will remain false)
    if (not fSent[I mod MAX_SCHEDULE]) and fNetworking.Connected
      and (fNetworking.NetGameState = lgsGame) then //Don't send commands unless game is running normally
    begin
      if not fCommandIssued[I mod MAX_SCHEDULE] then
        fSchedule[I mod MAX_SCHEDULE, gGame.Networking.MyIndex].Clear; //No one has used it since last time through the ring buffer
      fCommandIssued[I mod MAX_SCHEDULE] := False; //Make it as requiring clearing next time around

      fLastSentTick := I;
      SendCommands(I);
      fSent[I mod MAX_SCHEDULE] := True;
      fRecievedData[I mod MAX_SCHEDULE, gGame.Networking.MyIndex] := True; //Recieved commands from self
    end;
end;


end.
