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
  KaMRandom(MaxInt{$IFDEF RNG_SPY}, 'TKMGameInputProcess_Single.ReplayTimer'{$ENDIF});

  //There are still more commands left
  if fCursor <= Count then
  begin
    while (aTick > fQueue[fCursor].Tick) and (fQueue[fCursor].Command.CmdType <> gicNone) and (fCursor < Count) do
      Inc(fCursor);

    while (fCursor <= Count) and (aTick = fQueue[fCursor].Tick) do //Could be several commands in one Tick
    begin
      //Call to KaMRandom, just like in StoreCommand
      //We did not generate random checks for those commands
      if SKIP_RNG_CHECKS_FOR_SOME_GIC and (fQueue[fCursor].Command.CmdType in SKIP_RANDOM_CHECKS_FOR) then
        myRand := 0
      else
        myRand := Cardinal(KaMRandom(MaxInt{$IFDEF RNG_SPY}, 'TKMGameInputProcess_Single.ReplayTimer 2'{$ENDIF}));

      while not fGic2StoredConverter.ParseNextStoredPackedCommand(fQueue[fCursor].Command, gicCommand) do
        Inc(fCursor);

      ExecCommand(gicCommand); // Should always be called to maintain randoms flow
      // CRC check after the command
      if (fQueue[fCursor].Rand <> myRand)
      and not gGame.IgnoreConsistencyCheckErrors then
      begin
        if Assigned(fOnReplayDesync) then // Call before ReplayInconsistency, fOnReplayDesync could be free after it!
          fOnReplayDesync(fCursor);

        if CRASH_ON_REPLAY then
        begin
          Inc(fCursor); // Must be done before exiting in case user decides to continue the replay
          gGame.ReplayInconsistency(fQueue[fCursor-1], myRand);
          Exit; // ReplayInconsistency sometimes calls GIP.Free, so exit immidiately
        end;

        Exit;
      end;
      Inc(fCursor);
    end;
  end;
end;


procedure TKMGameInputProcess_Single.RunningTimer(aTick: Cardinal);
begin
  inherited;

  // This is to match up with multiplayer CRC generation, so multiplayer replays can be replayed in singleplayer mode
  KaMRandom(MaxInt{$IFDEF RNG_SPY}, 'TKMGameInputProcess_Single.RunningTimer'{$ENDIF});
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

