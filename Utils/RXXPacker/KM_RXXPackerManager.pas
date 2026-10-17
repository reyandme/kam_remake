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
    fSourcePathHD: string;
    fDestinationPath: string;

    fPalettes: TKMResPalettes;
    fOnMessage: TProc<string>;

    fTimeBegin: TDateTime;

    procedure DoLog(aMsg: string);

    procedure SetDestinationPath(const aValue: string);
    procedure SetSourcePathInterp(const aValue: string);
    procedure SetSourcePathHD(const aValue: string);
    procedure SetSourcePathRX(const aValue: string);
    procedure PackAsync(aRxSet: TRXTypeSet);
    procedure PackSync(aRxSet: TRXTypeSet);
  public
    PackToRXX: Boolean;
    PackToRXA: Boolean;
    RXXFormat: TKMRXXFormat;

    constructor Create(aPalettes: TKMResPalettes; aOnMessage: TProc<string>);

    procedure PackSet(aRxSet: TRXTypeSet);
    // Applies the HD replacement PNGs from SourcePathHD onto the RXX files in SourcePathRX, see TKMRXXPacker.PackHD
    procedure PackHDSet(aRxSet: TRXTypeSet);

    property SourcePathRX: string read fSourcePathRX write SetSourcePathRX;
    property SourcePathInterp: string read fSourcePathInterp write SetSourcePathInterp;
    property SourcePathHD: string read fSourcePathHD write SetSourcePathHD;
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


procedure TKMRXXPackerManager.PackHDSet(aRxSet: TRXTypeSet);
begin
  if not DirectoryExists(SourcePathRX) then
  begin
    fOnMessage('Cannot find "' + SourcePathRX + '" folder.' + sLineBreak + 'It should contain the RXX files to start from (e.g. data\Sprites).');
    Exit;
  end;

  if not DirectoryExists(SourcePathHD) then
  begin
    fOnMessage('Cannot find "' + SourcePathHD + '" folder.' + sLineBreak + 'It should contain the HD replacement PNGs (e.g. Modding graphics).');
    Exit;
  end;

  fTimeBegin := Now;

  // One RX after another, not in threads like PackSet: a 4x pack is up to ~1 GB of pixels, several of them do not fit
  // into the 32-bit packer at once, and the PNG overload path has never been checked for thread safety
  for var I := Low(TRXType) to High(TRXType) do
  if I in aRxSet then
  begin
    var rxxPacker := TKMRXXPacker.Create(I, fSourcePathRX, fSourcePathInterp, fDestinationPath, PackToRXX, PackToRXA, RXXFormat, fPalettes, DoLog);
    try
      rxxPacker.SourcePathHD := fSourcePathHD;
      rxxPacker.PackHD;
    finally
      rxxPacker.Free;
    end;
  end;

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


procedure TKMRXXPackerManager.SetSourcePathHD(const aValue: string);
begin
  fSourcePathHD := IncludeTrailingPathDelimiter(aValue);
end;


procedure TKMRXXPackerManager.SetSourcePathRX(const aValue: string);
begin
  fSourcePathRX := IncludeTrailingPathDelimiter(aValue);
end;


end.
