unit RXXPackerConsole;
{$I ..\..\KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Windows,
  KM_ResTypes, KM_ResPalettes, KM_ResSprites;


type
  TKMRXXPackerConsole = class
  private class var
    fParams: TStringList;
    fSourcePathRX: string;
    fSourcePathInterp: string;
    fDestinationPath: string;
    fPackToRXA: Boolean;
    fRxSet: TRXTypeSet;
  private
    class procedure OutputInstructions;
    class procedure ParseArguments;
    class procedure Pack;
  public
    class procedure Execute;
  end;


implementation
uses
  KM_Defaults, KM_RXXPacker;

const
  // Everything except rxCustom
  RXX_TO_PACK: TRXTypeSet = [rxTrees, rxHouses, rxUnits, rxGui, rxGuiMain, rxTiles];


{ TKMRXXPackerConsole }
class procedure TKMRXXPackerConsole.OutputInstructions;
begin
  Writeln('Arguments:');
  Writeln(' - srx %s - RX sprites source path');
  Writeln(' - sint %s - Interpolated sprites source path');
  Writeln(' - d %s - destination path');
  Writeln(' - rxa - pack to RXA files');
  Writeln(' - all - pack all RX libraries');
  Writeln(' - %s - pack specific RX library');
  Writeln('');
  Writeln('Usage examples:');
  Writeln(' - RxxPacker.exe srx "C:\kmr_sprites\" sint "C:\kmr_sprites_interp\" d "C:\kmr_sprites\out\" all');
  Writeln(' - RxxPacker.exe srx "C:\kmr_sprites\" sint "C:\kmr_sprites_interp\" d "C:\kmr_sprites\out\" rxa trees units');
end;


class procedure TKMRXXPackerConsole.ParseArguments;
var
  I: Integer;
  rxType: TRXType;
begin
  Writeln('Supplied arguments:');

  // Take in all params for simpler parsing down below
  for I := 1 to ParamCount do
  begin
    Writeln(' - ' + ParamStr(I));
    fParams.Append(ParamStr(I));
  end;

  for I := 0 to fParams.Count - 1 do
  begin
    if LowerCase(fParams[I]) = 'srx' then
      if I < fParams.Count - 1 then
      begin
        fSourcePathRX := fParams[I+1];
        fParams[I+1] := ''; // Make sure we dont parse it as some other key
      end else
        raise Exception.Create('Source RX sprites path ("srx") not specified');

    if LowerCase(fParams[I]) = 'sint'then
      if I < fParams.Count - 1 then
      begin
        fSourcePathInterp := fParams[I+1];
        fParams[I+1] := ''; // Make sure we dont parse it as some other key
      end else
        raise Exception.Create('Source interpolated sprites path ("sint") not specified');

    if LowerCase(fParams[I]) = 'd' then
      if I < fParams.Count - 1 then
      begin
        fDestinationPath := fParams[I+1];
        fParams[I+1] := ''; // Make sure we dont parse it as some other key
      end else
        raise Exception.Create('Destination path ("d") not specified');

    if LowerCase(fParams[I]) = 'rxa' then
      fPackToRXA := True;

    for rxType := Low(TRXType) to High(TRXType) do
    if LowerCase(fParams[I]) = 'all' then
      fRxSet := RXX_TO_PACK
    else
    if LowerCase(fParams[I]) = LowerCase(RX_INFO[rxType].FileName) then
      fRxSet := fRxSet + [rxType];
  end;
end;


class procedure TKMRXXPackerConsole.Pack;
var
  rxxPacker: TKMRXXPacker;
  resPalettes: TKMResPalettes;
begin
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  rxxPacker := TKMRXXPacker.Create;
  rxxPacker.SourcePathRX := fSourcePathRX;
  rxxPacker.SourcePathInterp := fSourcePathInterp;
  rxxPacker.DestinationPath := fDestinationPath;
  rxxPacker.PackToRXA := fPackToRXA;
  rxxPacker.RXXFormat := rxxTwo;

  resPalettes := TKMResPalettes.Create;
  resPalettes.LoadPalettes(ExeDir + 'data\gfx\');
  try
    rxxPacker.PackSet(fRxSet, resPalettes, procedure (aMsg: string) begin Writeln(aMsg); end);
  finally
    rxxPacker.Free;
    resPalettes.Free;
  end;
end;


class procedure TKMRXXPackerConsole.Execute;
begin
  Writeln('KaM Remake RXX Packer');
  Writeln('');

  fParams := TStringList.Create;
  try
    ParseArguments;

    if fParams.Count = 0 then
    begin
      OutputInstructions;
      Exit;
    end;

    Pack;
  except
    on E: Exception do
    begin
      Writeln('Exception occurred:');
      Writeln(E.Message);
    end;
  end;
end;


end.
