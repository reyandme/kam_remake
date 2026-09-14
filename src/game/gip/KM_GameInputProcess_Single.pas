unit KM_GameInputProcess_Single;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_GameInputProcess;


type
  TKMGameInputProcess_Single = class(TKMGameInputProcess)
  protected
    procedure DoTakeCommand(const aCommand: TKMGameInputCommand); override;
    procedure SaveExtra(SaveStream: TKMemoryStream); override;
    procedure LoadExtra(LoadStream: TKMemoryStream); override;
  public
    procedure ReplayTimer(aTick: Cardinal); override;
    procedure RunningTimer(aTick: Cardinal); override;
  end;


implementation
uses
  Math, KM_Game, KM_GameParams, KM_Defaults, KM_CommonUtils;


procedure TKMGameInputProcess_Single.DoTakeCommand(const aCommand: TKMGameInputCommand);
begin
  if gGameParams.IsReplay then Exit;

  StoreCommand(aCommand); //Store the command for the replay (store it first in case Exec crashes and we want to debug it)
  ExecCommand(aCommand);  //Execute the command now
end;


procedure TKMGameInputProcess_Single.ReplayTimer(aTick: Cardinal);
var
  myRand: Cardinal;
  gicCommand: TKMGameInputCommand;
begin
  //This is to match up with multiplayer random check generation, so multiplayer replays can be replayed in singleplayer mode
  KaMRandom(MaxInt{$IFDEF DBG_RNG_SPY}, 'TKMGameInputProcess_Single.ReplayTimer'{$ENDIF});

  //There are still more commands left
  if fCursorPosition <= Count then
  begin
    while (aTick > fQueue[fCursorPosition].Tick) and (fQueue[fCursorPosition].Command.CmdType <> gicNone) and (fCursorPosition < Count) do
      Inc(fCursorPosition);

    while (fCursorPosition <= Count) and (aTick = fQueue[fCursorPosition].Tick) do //Could be several commands in one Tick
    begin
      //Call to KaMRandom, just like in StoreCommand
      //We did not generate random checks for those commands
      if fQueue[fCursorPosition].Command.CmdType in SKIP_RANDOM_CHECKS_FOR then
        myRand := 0
      else
        myRand := Cardinal(KaMRandom(MaxInt{$IFDEF DBG_RNG_SPY}, 'TKMGameInputProcess_Single.ReplayTimer 2'{$ENDIF}));

      while not fGic2StoredConverter.ParseNextStoredPackedCommand(fQueue[fCursorPosition].Command, gicCommand) do
        Inc(fCursorPosition);

      ExecCommand(gicCommand); // Should always be called to maintain randoms flow
      // CRC check after the command
      if (fQueue[fCursorPosition].Rand <> myRand)
      and not gGame.IgnoreConsistencyCheckErrors then
      begin
        if Assigned(fOnReplayDesync) then // Call before ReplayInconsistency, fOnReplayDesync could be free after it!
          fOnReplayDesync(fCursorPosition);

        if CRASH_ON_REPLAY then
        begin
          Inc(fCursorPosition); // Must be done before exiting in case user decides to continue the replay
          gGame.ReplayInconsistency(fQueue[fCursorPosition-1], myRand);
          Exit; // ReplayInconsistency sometimes calls GIP.Free, so exit immediately
        end;

        Exit;
      end;
      Inc(fCursorPosition);
    end;
  end;
end;


procedure TKMGameInputProcess_Single.RunningTimer(aTick: Cardinal);
begin
  inherited;

  // This is to match up with multiplayer CRC generation, so multiplayer replays can be replayed in singleplayer mode
  KaMRandom(MaxInt{$IFDEF DBG_RNG_SPY}, 'TKMGameInputProcess_Single.RunningTimer'{$ENDIF});
end;


procedure TKMGameInputProcess_Single.SaveExtra(SaveStream: TKMemoryStream);
begin
  SaveStream.Write(gGame.LastReplayTickLocal);
end;


procedure TKMGameInputProcess_Single.LoadExtra(LoadStream: TKMemoryStream);
var
  lastReplayTick: Cardinal;
begin
  LoadStream.Read(lastReplayTick);
  gGame.LastReplayTickLocal := lastReplayTick;
end;


end.

