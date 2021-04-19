program RXXPacker;
{$I ..\..\KaM_Remake.inc}
{$APPTYPE CONSOLE}
uses
  Forms, SysUtils,
  {$IFDEF FPC}Interfaces,{$ENDIF}
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF FPC} LResources, LCLIntf, {$ENDIF}
  RXXPackerForm in 'RXXPackerForm.pas' {RXXForm1},
	RXXPackerProc in 'RXXPackerProc.pas',
  KM_PNG in '..\..\src\utils\KM_PNG.pas',
  KM_Pics in '..\..\src\utils\KM_Pics.pas',
  KM_ResSprites in '..\..\src\res\KM_ResSprites.pas',
  KM_ResSpritesEdit in '..\..\src\res\KM_ResSpritesEdit.pas',
  KM_ResPalettes in '..\..\src\res\KM_ResPalettes.pas',
  KM_SoftShadows in '..\..\src\utils\KM_SoftShadows.pas',
  KM_Defaults in '..\..\src\common\KM_Defaults.pas',
  KM_CommonTypes in '..\..\src\common\KM_CommonTypes.pas',
  KM_CommonClasses in '..\..\src\common\KM_CommonClasses.pas',
  KM_Points in '..\..\src\common\KM_Points.pas',
  KM_CommonUtils in '..\..\src\utils\KM_CommonUtils.pas',
  KromUtils in '..\..\src\utils\KromUtils.pas',
  KM_FileIO in '..\..\src\utils\KM_FileIO.pas',
  KM_Outline in '..\..\src\navmesh\KM_Outline.pas',
  KM_PolySimplify in '..\..\src\navmesh\KM_PolySimplify.pas',
  KM_Render in '..\..\src\render\KM_Render.pas',
  KM_RenderControl in '..\..\src\render\KM_RenderControl.pas',
  KM_BinPacking in '..\..\src\utils\KM_BinPacking.pas',
  PolyTriangulate in '..\..\src\ext\PolyTriangulate.pas',
  {$IFDEF FPC}
  BGRABitmap in '..\..\src\ext\BGRABitmap\BGRABitmap.pas',
  BGRAWinBitmap in '..\..\src\ext\BGRABitmap\BGRAWinBitmap.pas',
  BGRADefaultBitmap in '..\..\src\ext\BGRABitmap\BGRADefaultBitmap.pas',
  BGRABitmapTypes in '..\..\src\ext\BGRABitmap\BGRABitmapTypes.pas',
  BGRACanvas in '..\..\src\ext\BGRABitmap\BGRACanvas.pas',
  BGRAPen in '..\..\src\ext\BGRABitmap\BGRAPen.pas',
  BGRAPolygon in '..\..\src\ext\BGRABitmap\BGRAPolygon.pas',
  BGRAPolygonAliased in '..\..\src\ext\BGRABitmap\BGRAPolygonAliased.pas',
  BGRAFillInfo in '..\..\src\ext\BGRABitmap\BGRAFillInfo.pas',
  BGRABlend in '..\..\src\ext\BGRABitmap\BGRABlend.pas',
  BGRAGradientScanner in '..\..\src\ext\BGRABitmap\BGRAGradientScanner.pas',
  BGRATransform in '..\..\src\ext\BGRABitmap\BGRATransform.pas',
  BGRAResample in '..\..\src\ext\BGRABitmap\BGRAResample.pas',
  BGRAFilters in '..\..\src\ext\BGRABitmap\BGRAFilters.pas',
  BGRAText in '..\..\src\ext\BGRABitmap\BGRAText.pas',
  {$ENDIF}
  dglOpenGL in '..\..\src\ext\dglOpenGL.pas',
  KromOGLUtils in '..\..\src\utils\KromOGLUtils.pas';


{$IFDEF WDC}
{$R *.res}
{$ENDIF}

var
  I, K: Integer;
  ForcedConsoleMode: Boolean;
  RXType: TRXType;
  fRXXPacker: TRXXPacker;
  fPalettes: TKMResPalettes;
  Tick: Cardinal;

const
  RXToPack: array[0..5] of TRXType = (
    rxTrees,
    rxHouses,
    rxUnits,
    rxGui,
    rxGuiMain,
    rxTiles);


function IsConsoleMode: Boolean;
var
  SI: TStartupInfo;
begin
  SI.cb := SizeOf(StartUpInfo);
  GetStartupInfo(SI);
  Result := (SI.dwFlags and STARTF_USESHOWWINDOW) = 0;
  {$IFDEF FPC}
  Result := False
  {$ENDIF}
end;


begin
  ForcedConsoleMode :=
  {$IFDEF FPC}
    False //Set this to True to use as console app in lazarus
  {$ELSE}
    False
  {$ENDIF}
    ;
  if ForcedConsoleMode or IsConsoleMode then
  begin
    if ParamCount >= 1 then
    begin
      writeln(sLineBreak + 'KaM Remake RXX Packer' + sLineBreak);

      ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');
      fRXXPacker := TRXXPacker.Create;
      fPalettes := TKMResPalettes.Create;
      fPalettes.LoadPalettes(ExeDir + 'data\gfx\');
      try
        for I := 1 to ParamCount do // Skip 0, as this is the EXE-path
        begin
          if LowerCase(ParamStr(I)) = 'all' then
          begin
            for K := Low(RXToPack) to High(RXToPack) do
            begin
              Tick := GetTickCount;
              fRXXPacker.Pack(RXToPack[K], fPalettes);
              writeln(RXInfo[RXToPack[K]].FileName + '.rxx packed in ' + IntToStr(GetTickCount - Tick) + ' ms');
            end;
            Exit;
          end;
          for RXType := Low(TRXType) to High(TRXType) do
            if (LowerCase(ParamStr(I)) = LowerCase(RXInfo[RXType].FileName)) then
            begin
              Tick := GetTickCount;
              fRXXPacker.Pack(RXType, fPalettes);
              writeln(RXInfo[RXType].FileName + '.rxx packed in ' + IntToStr(GetTickCount - Tick) + ' ms');
            end;
        end;
      finally
        fRXXPacker.Free;
        fPalettes.Free;
      end;
    end else
    if ParamCount = 0 then
      begin
        writeln('No rx packages were set');
        writeln('Usage example: RXXPacker.exe gui guimain houses trees units');
        Exit;
      end;
  end else
  begin
    FreeConsole; // Used to hide the console
    Application.Initialize;
    Application.MainFormOnTaskbar := True;
    Application.CreateForm(TRXXForm1, RXXForm1);
    Application.Run;
  end;
end.
