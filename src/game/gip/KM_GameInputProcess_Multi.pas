unit KM_GameInputProcess_Multi;
{$I KaM_Remake.inc}
interface
uses
  KM_GameInputProcess,
  KM_Hand,
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
    fCount: Word;
    fItems: array of TKMGameInputCommand; //1..n
    function GetItem(aIndex: Integer): TKMGameInputCommand;
  public
    property  Count: Word read fCount;
    procedure Clear;
    procedure Add(aCommand: TKMGameInputCommand);
    function CRC: Cardinal;
    property Items[aIndex: Integer]: TKMGameInputCommand read GetItem;
    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
  end;

  TKMRandomCheck = record
    OurCheck: Cardinal;
    PlayerCheck: array [1..MAX_LOBBY_SLOTS] of Cardinal;
    PlayerCheckPending: array [1..MAX_LOBBY_SLOTS] of Boolean;
  end;

  TKMGameInputProcess_Multi = class(TKMGameInputProcess)
  private
    fDelay: Word; //How many ticks ahead the commands are scheduled
    fLastSentCmdsTick: Cardinal; //Needed for resync (last tick, for which commands were sent)

    fNumberConsecutiveWaits: Word; //Number of consecutive times we have been waiting for network

    //Each player can have any number of commands scheduled for execution in one tick
    fSchedule: array [0..MAX_SCHEDULE-1, 1..MAX_LOBBY_SLOTS] of TKMCommandsPack; //Ring buffer

    //All players must send us data every tick
    fRecievedData: array [0..MAX_SCHEDULE-1, 1..MAX_LOBBY_SLOTS] of Boolean; //Ring buffer

    //Mark commands we've already sent to other players
    fSent: array [0..MAX_SCHEDULE-1] of Boolean; //Ring buffer

    //Did the player issue a command for this tick?
    //If not it must be cleared from last time (we can't clear it earlier as it might be needed for resync)
    fCommandIssued: array [0..MAX_SCHEDULE-1] of Boolean;

    //Store random seeds at each tick then confirm with other players
    fRandomCheck: array [0..MAX_SCHEDULE-1] of TKMRandomCheck; //Ring buffer

    procedure SendCommands(aTick: Cardinal; aPlayerIndex: ShortInt = -1);
    procedure SendRandomCheck(aTick: Cardinal);
    procedure DoRandomCheck(aTick: Cardinal; aPlayerIndex: ShortInt);

    procedure SetDelay(aNewDelay: Integer);
  protected
    procedure DoTakeCommand(const aCommand: TKMGameInputCommand); override;
  public
    constructor Create(aReplayState: TKMGIPReplayState);
    destructor Destroy; override;
    procedure WaitingForConfirmation(aTick: Cardinal);
    procedure AdjustDelay(aGameSpeed: Single);
    function GetNetworkDelay: Word;
    property NumberConsecutiveWaits: Word read fNumberConsecutiveWaits;
    property LastSentCmdsTick: Cardinal read fLastSentCmdsTick;
    function GetWaitingPlayers(aTick: Cardinal): TKMByteArray;
    procedure RecieveCommands(aStream: TKMemoryStream; aSenderIndex: ShortInt); //Called by TKMNetwork when it has data for us
    procedure ResyncFromTick(aSender: ShortInt; aTick: Cardinal);
    function CommandsConfirmed(aTick: Cardinal): Boolean;
    procedure RunningTimer(aTick: Cardinal); override;
    procedure UpdateState(aTick: Cardinal); override;
  end;


implementation
uses
  TypInfo,
  SysUtils, Math, KromUtils,
  KM_Game, KM_GameParams, KM_HandsCollection, KM_NetTypes,
  KM_ResTexts, KM_ResSound, KM_Sound, KM_CommonUtils,
  KM_GameTypes,
  KM_Networking;

type
  TKMRngCheckPlayerData = record
    PlayerIndex: Integer;
    HandID: TKMHandID;
    Nickname: AnsiString;
    Check: Cardinal;
    function ToStr: string;
  end;


{ TKMRngCheckPlayerData }
function TKMRngCheckPlayerData.ToStr: string;
begin
  Result := Format('PlayerIndex = %d; Hand = %d; Nick = %s; Check = %d', [PlayerIndex, HandID, Nickname, Check]);
end;


{ TKMCommandsPack }
procedure TKMCommandsPack.Clear;
begin
  fCount := 0;
end;


procedure TKMCommandsPack.Add(aCommand: TKMGameInputCommand);
begin
  Inc(fCount);
  if fCount >= Length(fItems) then
    SetLength(fItems, fCount + 8);

  fItems[fCount] := aCommand;
end;


function TKMCommandsPack.GetItem(aIndex:integer): TKMGameInputCommand;
begin
  Result := fItems[aIndex];
end;


// Return CRC of the pack
function TKMCommandsPack.CRC: Cardinal;
var
  I: Integer;
begin
  Result := 0;
  for I := 1 to fCount do
    Result := Result xor Adler32CRC(@fItems[I], SizeOf(fItems[I]));
end;


procedure TKMCommandsPack.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.Write(fCount);
  for I := 1 to fCount do
  begin
    //gLog.AddTime('Saving "%s"', [GetEnumName(TypeInfo(TGameInputCommandType), Integer(fItems[I].CommandType))]);
    SaveCommandToMemoryStream(fItems[I], SaveStream);
  end;
end;


procedure TKMCommandsPack.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.Read(fCount);
  SetLength(fItems, fCount + 1);

  for I := 1 to fCount do
    LoadCommandFromMemoryStream(fItems[I], LoadStream);
end;


{ TKMGameInputProcess_Multi }
constructor TKMGameInputProcess_Multi.Create(aReplayState: TKMGIPReplayState);
var
  I: Integer;
  K: ShortInt;
begin
  inherited Create(aReplayState);

  gNetworking.OnCommands := RecieveCommands;
  gNetworking.OnResyncFromTick := ResyncFromTick;
  AdjustDelay(1); //Initialise the delay

  //Allocate memory for all commands packs
  for I := 0 to MAX_SCHEDULE - 1 do
    for K := 1 to MAX_LOBBY_SLOTS do
    begin
      fSchedule[I, K] := TKMCommandsPack.Create;
      fRandomCheck[I].PlayerCheckPending[K] := False; //We don't have anything to be checked yet
    end;
end;


destructor TKMGameInputProcess_Multi.Destroy;
var
  I: Integer;
  K: ShortInt;
begin
  for I := 0 to MAX_SCHEDULE - 1 do
    for K := 1 to MAX_LOBBY_SLOTS do
      fSchedule[I, K].Free;
  inherited;
end;


// Stack the command into schedule
procedure TKMGameInputProcess_Multi.DoTakeCommand(const aCommand: TKMGameInputCommand);
var
  I, tick: Cardinal;
begin
  Assert(fDelay < MAX_SCHEDULE, 'Error, fDelay >= MAX_SCHEDULE');
  if ((gGameParams.Mode = gmMultiSpectate) and not (aCommand.CommandType in ALLOWED_BY_SPECTATORS)) // Do not allow spectators to command smth
    or (gGameParams.IsMultiplayerGame                  // in multiplayer game
      and IsSelectedObjectCommand(aCommand.CommandType) // block only commands for selected object
      and (gMySpectator.Selected <> nil)                // if there is selected object
      and not gMySpectator.IsSelectedMyObj) then        // and we try to make command to ally's object
    Exit;

  if gGame.IsPeaceTime and (aCommand.CommandType in BLOCKED_BY_PEACETIME) then
  begin
    gNetworking.PostLocalMessage(gResTexts[TX_MP_BLOCKED_BY_PEACETIME], csNone);
    gSoundPlayer.Play(sfxCantPlace);
    Exit;
  end;

  if not gGameParams.IsSpectatorGame
    and gMySpectator.Hand.AI.HasLost
    and not (aCommand.CommandType in ALLOWED_AFTER_DEFEAT) then
  begin
    gSoundPlayer.Play(sfxCantPlace);
    Exit;
  end;

  //Find first unsent pack
  tick := MAX_SCHEDULE; //Out of range value
  for I := gGameParams.Tick + fDelay to gGameParams.Tick + MAX_SCHEDULE - 1 do
    if not fSent[I mod MAX_SCHEDULE] then
    begin
      tick := I mod MAX_SCHEDULE; //Place in a ring buffer
      Break;
    end;
  Assert(tick < MAX_SCHEDULE, 'Could not find place for new commands');

  if not fCommandIssued[tick] then
  begin
    // Clear old data (it was kept in case it was required for resync)
    fSchedule[tick, gNetworking.MySlotIndex].Clear;
    fCommandIssued[tick] := True;
  end;
  fSchedule[tick, gNetworking.MySlotIndex].Add(aCommand);
//  gLog.AddTime('Scheduled cmd Tick: %d, CMD_TYPE = %s', [Tick, GetEnumName(TypeInfo(TKMGameInputCommandType), Integer(aCommand.CommandType))]);
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
  // Half of the maximum round trip is a good guess for delay. +1.2 is our safety net to account
  // for processing the packet and random variations in ping. It's always better for commands to
  // be slightly delayed than for the game to freeze/lag regularly.
  if (gNetworking.Room.GetNotDroppedCount = 1) then
    SetDelay(MIN_DELAY) //We can set the lowest delay if we are the only MP player
  else
    SetDelay(Ceil(aGameSpeed * (gNetworking.Room.GetMaxHighestRoundTripLatency / 200 + 1.2)));
end;


procedure TKMGameInputProcess_Multi.SendCommands(aTick: Cardinal; aPlayerIndex: ShortInt = -1);
var
  sendStream: TKMemoryStream;
begin
  sendStream := TKMemoryStreamBinary.Create;
  try
    sendStream.Write(Byte(kdpCommands));
    // Target Tick in 1..n range
    sendStream.Write(aTick);
    // Write all commands to the stream
    fSchedule[aTick mod MAX_SCHEDULE, gNetworking.MySlotIndex].Save(sendStream);

    gNetworking.SendCommands(sendStream, aPlayerIndex); //Send to all players by default
  finally
    sendStream.Free;
  end;
end;


procedure TKMGameInputProcess_Multi.SendRandomCheck(aTick: Cardinal);
var
  sendStream: TKMemoryStream;
begin
  sendStream := TKMemoryStreamBinary.Create;
  try
    sendStream.Write(Byte(kdpRandomCheck));
    sendStream.Write(aTick); //Target Tick in 1..n range
    sendStream.Write(fRandomCheck[aTick mod MAX_SCHEDULE].OurCheck); //Write our random check to the stream
    gNetworking.SendCommands(sendStream); //Send to all opponents
  finally
    sendStream.Free;
  end;
end;


procedure TKMGameInputProcess_Multi.DoRandomCheck(aTick: Cardinal; aPlayerIndex: ShortInt);
var
  myData, otherData: TKMRngCheckPlayerData;
  errorStr: string;
begin
  with fRandomCheck[aTick mod MAX_SCHEDULE] do
  begin
    if OurCheck <> PlayerCheck[aPlayerIndex] then
    begin
      myData.PlayerIndex := gNetworking.MySlotIndex;
      myData.HandID      := gNetworking.MyRoomSlot.HandIndex;
      myData.Nickname    := gNetworking.MyRoomSlot.Nickname;
      myData.Check       := OurCheck;

      otherData.PlayerIndex := aPlayerIndex;
      otherData.HandID      := gNetworking.Room[aPlayerIndex].HandIndex;
      otherData.Nickname    := gNetworking.Room[aPlayerIndex].Nickname;
      otherData.Check       := PlayerCheck[aPlayerIndex];

      errorStr := Format(#13#10 + 'Random check mismatch for tick %d processed at tick %d:' + #13#10 +
                         'MyPlayer: [%s],' + #13#10 +
                         'OtherPlayer: [%s]',
                         [aTick, gGameParams.Tick, myData.ToStr, otherData.ToStr]);
      gNetworking.AskToSendCrashreport(aPlayerIndex, errorStr);
      raise Exception.Create(errorStr);
    end;
    PlayerCheckPending[aPlayerIndex] := False;
  end;
end;


//Decode recieved messages (Commands from other players, Confirmations, Errors)
procedure TKMGameInputProcess_Multi.RecieveCommands(aStream: TKMemoryStream; aSenderIndex: ShortInt);
var
  dataType: TKMDataType;
  tick: Cardinal;
  CRC: Cardinal;
begin
  aStream.Read(dataType, 1); //Decode header
  aStream.Read(tick); //Target tick

//  gLog.AddTime('Received commands for Tick %d', [Tick]);

  case dataType of
    kdpCommands:
        begin
          //Recieving commands too late will happen during reconnections, so just ignore it
          if (tick > gGameParams.Tick) then
            // Do not check if player is dropped - we could receive scheduled commmands from already dropped player,
            // that we should store/execute to be in sync with other players
            {and not gNetworking.Room[aSenderIndex].Dropped}
          begin
            fSchedule[tick mod MAX_SCHEDULE, aSenderIndex].Load(aStream);
            fRecievedData[tick mod MAX_SCHEDULE, aSenderIndex] := True;
          end;
        end;
    kdpRandomCheck: //Other player is confirming that random seeds matched at a tick in the past
        begin
          aStream.Read(CRC); //Read the random check from the message
          fRandomCheck[tick mod MAX_SCHEDULE].PlayerCheck[aSenderIndex] := CRC; //Store it for this player
          fRandomCheck[tick mod MAX_SCHEDULE].PlayerCheckPending[aSenderIndex] := True;
          //If we have processed this tick already, check now
          if tick <= gGameParams.Tick then
            DoRandomCheck(tick, aSenderIndex);
        end;
  end;
end;


//We must resend the commands from aTick to the last sent tick to the specified player
procedure TKMGameInputProcess_Multi.ResyncFromTick(aSender: ShortInt; aTick: Cardinal);
var
  I: Cardinal;
begin
  for I := aTick to fLastSentCmdsTick do
    SendCommands(I, aSender);
end;


//Are all the commands are confirmed?
function TKMGameInputProcess_Multi.CommandsConfirmed(aTick: Cardinal): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 1 to gNetworking.Room.Count do
    Result := Result and
                (fRecievedData[aTick mod MAX_SCHEDULE, I] or gNetworking.Room[I].NoNeedToWait(aTick));
end;


//Indexes of players we are waiting for
function TKMGameInputProcess_Multi.GetWaitingPlayers(aTick: Cardinal): TKMByteArray;
var
  I, K: Integer;
begin
  SetLength(Result, MAX_LOBBY_SLOTS);

  K := 0;
  for I := 1 to gNetworking.Room.Count do
    if not (fRecievedData[aTick mod MAX_SCHEDULE, I] or gNetworking.Room[I].NoNeedToWait(aTick)) then
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
  I, K, tick: Cardinal;
begin
  inherited;

  fNumberConsecutiveWaits := 0; //We are not waiting if the game is running
  tick := aTick mod MAX_SCHEDULE; //Place in a ring buffer
  fRandomCheck[tick].OurCheck := Cardinal(KaMRandom(MaxInt{$IFDEF DBG_RNG_SPY}, 'TKMGameInputProcess_Multi.RunningTimer'{$ENDIF})); //thats our CRC (must go before commands for replay compatibility)

  // Execute commands
  for I := 1 to gNetworking.Room.Count do
    for K := 1 to fSchedule[tick, I].Count do
    begin
      // We should store/execute last commands from dropped players too to be in sync with other players,
      // that could receive mkDisconnect in other tick, then we do.
      // --------------------------------------------------------------------------------
      // But we should store/execute commands of dropped players only for a certain ticks
      // because dropped players commands will not be cleared in schedule by this player,
      // since we call schedule[].Clear only for MyNetPlayer
      // So we have to skip those old commands
      //   (There was a bug, that gicGameSpeed / gicWareDistribution commands from dropped player
      //    were stored/executed after he left the game every MAX_SCHEDULE ticks,
      //    because they were stored in the ring buffer of fSchedule)
      if (not gNetworking.Room[I].Dropped or gNetworking.Room[I].NeedWaitForLastCommands(aTick))
      //Don't allow exploits like moving enemy soldiers (but maybe one day you can control disconnected allies?)
        and ((gNetworking.Room[I].HandIndex = fSchedule[tick, I].Items[K].HandIndex)
           or (fSchedule[tick, I].Items[K].CommandType in ALLOWED_BY_SPECTATORS)) then
      begin
        // Store the command first so if Exec fails we still have it in the replay
        StoreCommand(fSchedule[tick, I].Items[K]);
        ExecCommand(fSchedule[tick, I].Items[K]);
        // Returning to the lobby ends the game
        if gGame = nil then Exit;
      end;
    end;

  // If we miss a few random checks during reconnections no one cares, inconsistencies will be detected as soon as it is over
  // To reduce network load, send random checks once every 10 ticks
  if gNetworking.Connected {and (aTick mod 10 = 1)} then //todo: DEBUG. remove debug brackets: {} no need to check on every tick in release version
    SendRandomCheck(aTick);

  // It is possible that we have already recieved other player's random checks, if so check them now
  for I := 1 to gNetworking.Room.Count do
  begin
    if not gNetworking.Room[I].Dropped and fRandomCheck[tick].PlayerCheckPending[I] then
      DoRandomCheck(aTick, I);
  end;

  FillChar(fRecievedData[tick], SizeOf(fRecievedData[tick]), #0); //Reset
  fSent[tick] := False;

  if aTick mod DELAY_ADJUST = 0 then
    AdjustDelay(gGame.SpeedActual); //Adjust fDelay every X ticks
end;


procedure TKMGameInputProcess_Multi.UpdateState(aTick: Cardinal);
var
  I: Integer;
begin
  inherited;

  for I := aTick + 1 to aTick + fDelay do
    //If the network is not connected then we must send the commands later (fSent will remain False)
    if (not fSent[I mod MAX_SCHEDULE]) and gNetworking.Connected
      and (gNetworking.NetGameState = lgsGame) then //Don't send commands unless game is running normally
    begin
      if not fCommandIssued[I mod MAX_SCHEDULE] then
        // No one has used it since last time through the ring buffer
        fSchedule[I mod MAX_SCHEDULE, gNetworking.MySlotIndex].Clear;
      fCommandIssued[I mod MAX_SCHEDULE] := False; //Make it as requiring clearing next time around

      fLastSentCmdsTick := I;
      SendCommands(I);
//      gLog.AddTime('fDelay = %d; Send Commands for Tick = %d', [fDelay, I]);
      fSent[I mod MAX_SCHEDULE] := True;
      fRecievedData[I mod MAX_SCHEDULE, gNetworking.MySlotIndex] := True; //Recieved commands from self
    end;
end;


end.
