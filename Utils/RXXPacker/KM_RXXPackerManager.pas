unit KM_RXXPackerManager;
{$I ..\..\KaM_Remake.inc}
interface
uses
  System.SysUtils,
  KM_ResTypes, KM_ResPalettes, KM_ResSprites;


type
  TKMRXXPackerManager = class
  private
    fSourcePathRX: string;
    fSourcePathInterp: string;
    fDestinationPath: string;

    fPalettes: TKMResPalettes;
    fOnMessage: TProc<string>;

    fTimeBegin: TDateTime;

    procedure DoLog(aMsg: string);

    procedure SetDestinationPath(const aValue: string);
    procedure SetSourcePathInterp(const aValue: string);
    procedure SetSourcePathRX(const aValue: string);
    procedure PackAsync(aRxSet: TRXTypeSet);
    procedure PackSync(aRxSet: TRXTypeSet);
  public
    PackToRXX: Boolean;
    PackToRXA: Boolean;
    RXXFormat: TKMRXXFormat;

    constructor Create(aPalettes: TKMResPalettes; aOnMessage: TProc<string>);

    procedure PackSet(aRxSet: TRXTypeSet);

    property SourcePathRX: string read fSourcePathRX write SetSourcePathRX;
    property SourcePathInterp: string read fSourcePathInterp write SetSourcePathInterp;
    property DestinationPath: string read fDestinationPath write SetDestinationPath;

    class function GetAvailableToPack(const aPath: string): TRXTypeSet;
  end;


implementation
uses
  System.Classes, System.Generics.Collections,
  KM_RXXPacker;


{ TKMRXXPackerManager }
constructor TKMRXXPackerManager.Create(aPalettes: TKMResPalettes; aOnMessage: TProc<string>);
begin
  inherited Create;

  // Default values
  PackToRXX := True;
  PackToRXA := False;
  RXXFormat := rxxTwo;

  fPalettes := aPalettes;
  fOnMessage := aOnMessage;
end;


class function TKMRXXPackerManager.GetAvailableToPack(const aPath: string): TRXTypeSet;
begin
  Result := [rxTiles]; //Tiles are always in the list

  for var RT := Low(TRXType) to High(TRXType) do
    if FileExists(aPath + RX_INFO[RT].FileName + '.rx') then
      Result := Result + [RT];
end;


procedure TKMRXXPackerManager.DoLog(aMsg: string);
begin
  // Packing is so lengthy, we show timestamp with minutes
  fOnMessage(Format('%s %s', [TimeToStr(Now - fTimeBegin), aMsg]));
end;


procedure TKMRXXPackerManager.PackAsync(aRxSet: TRXTypeSet);
  procedure CaptureAndCreateThread(aRT: TRXType; aThreadList: TList<TThread>);
  begin
    var t := TThread.CreateAnonymousThread(
      procedure
      begin
        TThread.NameThreadForDebugging('Packing ' + RX_INFO[aRT].FileName);

        fOnMessage('Creating thread for ' + RX_INFO[aRT].FileName);

        var rxxPacker := TKMRXXPacker.Create(aRT, fSourcePathRX, fSourcePathInterp, fDestinationPath, PackToRXX, PackToRXA, RXXFormat, fPalettes, DoLog);
        rxxPacker.Pack;
        rxxPacker.Free;
      end);

    t.FreeOnTerminate := False;

    aThreadList.Add(t);
  end;
begin
  var threadList := TList<TThread>.Create;
  try
    for var I := Low(TRXType) to High(TRXType) do
    if I in aRxSet then
      CaptureAndCreateThread(I, threadList);

    for var t in threadList do
      t.Start;

    for var t in threadList do
      t.WaitFor;
  finally
    threadList.Free;
  end;
end;


procedure TKMRXXPackerManager.PackSync(aRxSet: TRXTypeSet);
begin
  for var I := Low(TRXType) to High(TRXType) do
  if I in aRxSet then
  begin
    var rxxPacker := TKMRXXPacker.Create(I, fSourcePathRX, fSourcePathInterp, fDestinationPath, PackToRXX, PackToRXA, RXXFormat, fPalettes, DoLog);
    rxxPacker.Pack;
    rxxPacker.Free;
  end;
end;


procedure TKMRXXPackerManager.PackSet(aRxSet: TRXTypeSet);
begin
  if not DirectoryExists(SourcePathRX) then
  begin
    fOnMessage('Cannot find "' + SourcePathRX + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  if PackToRXA and not DirectoryExists(SourcePathInterp) then
  begin
    fOnMessage('Cannot find "' + SourcePathInterp + '" folder.' + sLineBreak + 'Please make sure this folder exists and has data.');
    Exit;
  end;

  fTimeBegin := Now;

  PackASync(aRxSet);
  //PackSync(aRxSet);

  fOnMessage(Format('Everything packed in %dsec', [Round((Now - fTimeBegin) * SecsPerDay)]));
end;


procedure TKMRXXPackerManager.SetDestinationPath(const aValue: string);
begin
  fDestinationPath := IncludeTrailingPathDelimiter(aValue);
end;


procedure TKMRXXPackerManager.SetSourcePathInterp(const aValue: string);
begin
  fSourcePathInterp := IncludeTrailingPathDelimiter(aValue);
end;


procedure TKMRXXPackerManager.SetSourcePathRX(const aValue: string);
begin
  fSourcePathRX := IncludeTrailingPathDelimiter(aValue);
end;


end.
