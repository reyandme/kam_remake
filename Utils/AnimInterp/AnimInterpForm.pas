unit AnimInterpForm;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls,
  KM_ResPalettes, KM_Defaults, KM_CommonTypes, KM_Points, KM_ResSprites, KM_ResSpritesEdit, KM_Pics, KM_ResUnits,
  KM_ResTypes, KM_ResMapElements, KM_ResHouses, KM_CommonClasses;

type
  TInterpCacheItem = record
    A, B: Integer;
    Speed: Integer;
    interpOffset: Integer;
  end;

  TForm1 = class(TForm)
    btnProcess: TButton;
    Memo1: TMemo;
    memoErrors: TMemo;
    Label1: TLabel;
    chkSerfCarry: TCheckBox;
    chkUnitActions: TCheckBox;
    chkUnitThoughts: TCheckBox;
    chkTrees: TCheckBox;
    chkHouseActions: TCheckBox;
    chkBeasts: TCheckBox;
    procedure btnProcessClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    fPalettes: TKMResPalettes;
    fResUnits: TKMResUnits;
    fResHouses: TKMResHouses;
    fResMapElem: TKMResMapElements;
    fSprites: array[TRXType] of TKMSpritePackEdit;

    fOutputStream: TKMemoryStreamBinary;

    fInterpCache: array of TInterpCacheItem;

    fWorkDir: string;
    fOutDir: string;
    fDainFolder: string;

    function GetCanvasSize(aID: Integer; RT: TRXType; aMoveX: Integer = 0; aMoveY: Integer = 0): Integer;
    function GetDainParams(aDir: string; aAlpha: Boolean; aInterpLevel: Integer = 8): string;

    procedure WriteEmptyAnim;

    procedure MakeInterpImagesPair(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType; aSimpleShadows: Boolean; aBkgRGB: Cardinal);
    procedure MakeSlowInterpImages(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType; aBkgRGB: Cardinal);

    procedure DoInterp(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aSimpleShadows: Boolean; aBkgRGB: Cardinal; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpSlow(RT: TRXType; A: TKMAnimLoop; var aPicOffset: Integer; aDryRun: Boolean; aBkgRGB: Cardinal);

    procedure CleanupInterpBackground(var pngBase, pngShad, pngTeam: TKMCardinalArray);
    procedure ProcessInterpImage(outIndex: Integer; inSuffixPath, outPrefixPath: string; aBkgRGB: Cardinal; OverallMaxX, OverallMinX, OverallMaxY, OverallMinY: Integer);

    procedure DoInterpUnit(aUT: TKMUnitType; aAction: TKMUnitActionType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpSerfCarry(aWare: TKMWareType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpUnitThought(aThought: TKMUnitThought; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpTree(aTree: Integer; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpBeast(aBeastHouse, aBeast, aBeastAge: Integer; var aPicOffset: Integer; aDryRun: Boolean);
  end;


implementation
uses
  ShellApi, Math, RTTI, KM_FileIO, KromUtils,
  KM_Log, KM_IoPNG, KM_ResInterpolation;

{$R *.dfm}

const
  USE_BASE_BEASTS = False;
  USE_BASE_HOUSE_ACT = True;
  CANVAS_Y_OFFSET = 14;

  //This is different to TKMUnitSpec.SupportsAction because we include any used
  //animations like uaWalkArm for soldiers (flag) which isn't an action.
  UNIT_SUPPORTED_ANIMS: array [TKMUnitType] of TKMUnitActionTypeSet = (
    [], [], //None, Any
    [uaWalk, uaDie, uaEat, uaWalkArm], //Serf
    [uaWalk, uaWork, uaDie, uaWork1, uaEat..uaWalkTool2],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaWork1, uaEat..uaWalkBooty2],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaWork, uaDie, uaWork1..uaEat, uaWalkTool, uaWalkBooty], //Fisher
    [uaWalk, uaWork, uaDie, uaWork1, uaWork2, uaEat], //Worker
    [uaWalk, uaWork, uaDie, uaWork1, uaEat..uaWalkTool], //Stonecutter
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaDie, uaEat],
    [uaWalk, uaSpec, uaDie, uaEat], //Recruit
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Militia
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Axeman
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Swordsman
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Bowman
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Crossbowman
    [uaWalk, uaWork, uaDie, uaWalkArm],
    [uaWalk, uaWork, uaDie, uaWalkArm],
    [uaWalk, uaWork, uaDie, uaWalkArm],
    [uaWalk, uaWork, uaDie, uaWalkArm], //Cavalry
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Barbarian
    [uaWalk, uaWork, uaDie, uaWalkArm], //Rebel
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Slingshot
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], //Warrior
    [uaWalk, uaWork, uaDie, uaWalkArm], //Horseman
    [uaWalk], //Wolf
    [uaWalk..uaWork1], //Fish (1..5 fish per unit)
    [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk] //Animals
  );

  function GetAnimSpeed(A: TKMAnimLoop): Integer;
  begin
    Result := 1;
    while (Result < A.Count) and (A.Step[Result] = A.Step[Result+1]) do
      Inc(Result);
  end;


procedure TForm1.FormCreate(Sender: TObject);
begin
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  Caption := 'Animation Interpolator (' + GAME_REVISION + ')';

  fPalettes := TKMResPalettes.Create;
  fPalettes.LoadPalettes(ExeDir + 'data\gfx\');

  fResUnits := TKMResUnits.Create;
  fResHouses := TKMResHouses.Create;
  fResMapElem := TKMResMapElements.Create;
  fResMapElem.LoadFromFile(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'mapelem.dat');

  fWorkDir := ExeDir + 'SpriteInterp\';
  fOutDir := fWorkDir + 'Output\';
  fDainFolder := 'C:\Dev\kam_sprites\DAIN_APP Alpha 1.0\';
end;


function TForm1.GetDainParams(aDir: string; aAlpha: Boolean; aInterpLevel: Integer = 8): string;
var
  DainExe: string;
begin
  DainExe := fDainFolder + 'DAINAPP.exe';
  Result := 'cmd.exe /C "'+DainExe+'" --cli 1 -o '+aDir+' -p 0 -l 1 -in '+IntToStr(aInterpLevel)+' -da 0 -se 0 -si 1 -sr 0 -ha 0 --fast_mode 0';
  if aAlpha then
    Result := Result + ' -a 1';

  //Result := 'cmd.exe /C python inference_video.py --exp=3 --scale=4.0 --png --img='+aDir+'original_frames --output='+aDir+'interpolated_frames & pause';

  //Useful for checking error messages
  //Result := Result + ' & pause';
end;


function TForm1.GetCanvasSize(aID: Integer; RT: TRXType; aMoveX, aMoveY: Integer): Integer;
var
  MaxSoFar, X, Y, W, H: Integer;
begin
  MaxSoFar := 32;

  W := fSprites[RT].RXData.Size[aID].X;
  H := fSprites[RT].RXData.Size[aID].Y;
  X := fSprites[RT].RXData.Pivot[aID].X + aMoveX;
  Y := fSprites[RT].RXData.Pivot[aID].Y + aMoveY + CANVAS_Y_OFFSET;
  MaxSoFar := Max(MaxSoFar, -X);
  MaxSoFar := Max(MaxSoFar, X + W);
  MaxSoFar := Max(MaxSoFar, -Y);
  MaxSoFar := Max(MaxSoFar, Y + H);

  //Sprite is centred so we need this much padding on both sides
  MaxSoFar := 2*MaxSoFar;
  //Keep 1px padding on all sides
  MaxSoFar := MaxSoFar + 2;
  Result := ((MaxSoFar div 32) + 1)*32;
end;


procedure TForm1.MakeSlowInterpImages(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType; aBkgRGB: Cardinal);
var
  origSpritesDir, interpSpritesDir: string;
  I: Integer;
  NeedAlpha: Boolean;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  MakeInterpImagesPair(RT, aID_1, aID_2, -1, -1, 0, 0, False, aBaseDir, aExportType, True, aBkgRGB);

  origSpritesDir := aBaseDir + 'original_frames\';
  interpSpritesDir := aBaseDir + 'interpolated_frames\';

  if not FileExists(origSpritesDir + format('%d.png', [2]))
  or not FileExists(interpSpritesDir + format('%.15d.png', [1])) then
    Exit;

  KMCopyFile(origSpritesDir + format('%d.png', [2]), interpSpritesDir + format('%.15d.png', [9]));
  KMDeleteFolderContent(origSpritesDir);

  for I := 1 to 9 do
    KMCopyFile(interpSpritesDir + format('%.15d.png', [I]), origSpritesDir + format('%d.png', [I]));

  KMDeleteFolderContent(interpSpritesDir);

  NeedAlpha := aExportType in [ietBase, ietNormal];

  //Interpolate
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  CreateProcess(nil, PChar(GetDainParams(aBaseDir, NeedAlpha, aInterpCount)), nil, nil, false, 0, nil, PChar(fDainFolder), StartupInfo, ProcessInfo);
  WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
  //ShellExecute(0, nil, 'cmd.exe', PChar(DainParams), PChar(DainFolder), SW_SHOWNORMAL);
end;


procedure TForm1.MakeInterpImagesPair(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType; aSimpleShadows: Boolean; aBkgRGB: Cardinal);
var
  origSpritesDir, interpSpritesDir: string;
  CanvasSize: Integer;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  NeedAlpha, AllBlank, Worked: Boolean;
begin
  if fSprites[RT] = nil then
  begin
    fSprites[RT] := TKMSpritePackEdit.Create(RT, fPalettes);
    fSprites[RT].LoadFromRXXFile(ExeDir + 'data\Sprites\' + RX_INFO[RT].FileName + '_a.rxx');
  end;

  origSpritesDir := aBaseDir + 'original_frames\';
  interpSpritesDir := aBaseDir + 'interpolated_frames\';
  ForceDirectories(origSpritesDir);

  KMDeleteFolderContent(origSpritesDir);
  KMDeleteFolderContent(interpSpritesDir);
  DeleteFile(aBaseDir + 'base.png');
  DeleteFile(aBaseDir + '1.png');
  DeleteFile(aBaseDir + '2.png');

  AllBlank := True;
  CanvasSize := Max(GetCanvasSize(aID_1, RT), GetCanvasSize(aID_2, RT));

  if aID_1_Base >= 0 then
    CanvasSize := Max(CanvasSize, GetCanvasSize(aID_1_Base, RT, aBaseMoveX, aBaseMoveY));
  if aID_2_Base >= 0 then
    CanvasSize := Max(CanvasSize, GetCanvasSize(aID_2_Base, RT, aBaseMoveX, aBaseMoveY));

  if not aUseBase then
  begin
    aID_1_Base := -1;
    aID_2_Base := -1;
  end;

  Worked := fSprites[RT].ExportImageForInterp(origSpritesDir + '1.png', aID_1, aID_1_Base, aBaseMoveX, aBaseMoveY, aExportType, CanvasSize, aSimpleShadows, aBkgRGB);
  AllBlank := AllBlank and not Worked;

  Worked := fSprites[RT].ExportImageForInterp(origSpritesDir + '2.png', aID_2, aID_2_Base, aBaseMoveX, aBaseMoveY, aExportType, CanvasSize, aSimpleShadows, aBkgRGB);
  AllBlank := AllBlank and not Worked;

  if AllBlank then
    Exit;

  //Export extra stuff for the special cleanup for house work to remove background
  if aUseBase and (aID_1_Base <> -1) and (aID_1_Base = aID_2_Base) then
  begin
    fSprites[RT].ExportImageForInterp(aBaseDir + '1.png', aID_1, -1, 0, 0, aExportType, CanvasSize, aSimpleShadows, aBkgRGB);
    fSprites[RT].ExportImageForInterp(aBaseDir + '2.png', aID_2, -1, 0, 0, aExportType, CanvasSize, aSimpleShadows, aBkgRGB);
    fSprites[RT].ExportImageForInterp(aBaseDir + 'base.png', -1, aID_1_Base, aBaseMoveX, aBaseMoveY, aExportType, CanvasSize, aSimpleShadows, aBkgRGB);
  end;

  NeedAlpha := aExportType in [ietBase, ietNormal];

  //Interpolate
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  CreateProcess(nil, PChar(GetDainParams(aBaseDir, NeedAlpha)), nil, nil, false, 0, nil, PChar(fDainFolder), StartupInfo, ProcessInfo);
  WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
  //ShellExecute(0, nil, 'cmd.exe', PChar(DainParams), PChar(DainFolder), SW_SHOWNORMAL);
end;


procedure TForm1.WriteEmptyAnim;
var
  Step, SubStep: Integer;
begin
  for Step := 1 to 30 do
    for SubStep := 1 to 8 do
      fOutputStream.Write(Integer(-1));
end;


function BlendRGBA(Back, Fore: Cardinal): Cardinal;
var
  R1, R2, G1, G2, B1, B2, A1, A2: Single;
  Ro, Go, Bo, Ao: Single;
begin
  //Extract and normalise
  R1 := ((Back shr 0) and $FF) / 255;
  R2 := ((Fore shr 0) and $FF) / 255;
  G1 := ((Back shr 8) and $FF) / 255;
  G2 := ((Fore shr 8) and $FF) / 255;
  B1 := ((Back shr 16) and $FF) / 255;
  B2 := ((Fore shr 16) and $FF) / 255;
  A1 := ((Back shr 24) and $FF) / 255;
  A2 := ((Fore shr 24) and $FF) / 255;

  //https://en.wikipedia.org/wiki/Alpha_compositing
  Ao := A1 + A2*(1.0 - A1);
  if Ao > 0.0 then
  begin
    Ro := (R1*A1 + R2*A2*(1.0 - A1)) / Ao;
    Go := (G1*A1 + G2*A2*(1.0 - A1)) / Ao;
    Bo := (B1*A1 + B2*A2*(1.0 - A1)) / Ao;

    Ro := EnsureRange(Ro, 0.0, 1.0);
    Go := EnsureRange(Go, 0.0, 1.0);
    Bo := EnsureRange(Bo, 0.0, 1.0);

    Result :=
      ((Trunc(Ro*255) and $FF) shl 0) or
      ((Trunc(Go*255) and $FF) shl 8) or
      ((Trunc(Bo*255) and $FF) shl 16) or
      ((Trunc(Ao*255) and $FF) shl 24);
  end
  else
    Result := 0;
end;


procedure TForm1.DoInterp(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aSimpleShadows: Boolean; aBkgRGB: Cardinal; var aPicOffset: Integer; aDryRun: Boolean);

  function SameAnim(A, B: TKMAnimLoop): Boolean;
  var
    I: Integer;
  begin
    Result := A.Count = B.Count;
    for I := 1 to 30 do
      Result := Result and (A.Step[I] = B.Step[I]);
  end;

var
  I, Step, NextStep, SubStep, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, InterpOffset: Integer;
  OverallMaxX, OverallMinX, OverallMaxY, OverallMinY: Integer;
  BaseMoveX, BaseMoveY: Integer;
  StrList: TStringList;
  suffixPath, outDirLocal, outPrefix: string;
  dirBase, dirShad, dirTeam: string;
  Found: Boolean;
begin
  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  StrList := TStringList.Create;

  outDirLocal := fOutDir+IntToStr(Ord(RT)+1)+'\';
  outPrefix := outDirLocal+IntToStr(Ord(RT)+1)+'_';
  ForceDirectories(outDirLocal);

  //Import and reprocess
  for Step := 1 to 30 do
  begin
    if Step > A.Count then
    begin
      for SubStep := 1 to 8 do
        fOutputStream.Write(Integer(-1));
      Continue;
    end;

    StepSprite := A.Step[Step] + 1;
    StepNextSprite := A.Step[(Step mod A.Count) + 1] + 1;

    //Determine background sprite (if used)
    if aUseBase and (Step <= ABase.Count) then
    begin
      StepSpriteBase := ABase.Step[Step] + 1;
      StepNextSpriteBase := ABase.Step[(Step mod A.Count) + 1] + 1;
    end
    else
    begin
      StepSpriteBase := -1;
      StepNextSpriteBase := -1;
    end;

    //Same image is repeated next frame
    if StepSprite = StepNextSprite then
    begin
      for SubStep := 1 to 8 do
        fOutputStream.Write(StepSprite);
      Continue;
    end;

    fOutputStream.Write(StepSprite);

    //Check the cache
    Found := False;
    for I := Low(fInterpCache) to High(fInterpCache) do
    begin
      if (fInterpCache[I].A = StepSprite) and (fInterpCache[I].B = StepNextSprite) and (fInterpCache[I].Speed = 1) then
      begin
        for SubStep := 0 to 6 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end
      //Check for a reversed sequence in the cache (animations often loop backwards)
      else if (fInterpCache[I].B = StepSprite) and (fInterpCache[I].A = StepNextSprite) and (fInterpCache[I].Speed = 1) then
      begin
        for SubStep := 6 downto 0 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end;
    end;
    if Found then
      Continue;

    InterpOffset := aPicOffset;

    //Cache it
    SetLength(fInterpCache, Length(fInterpCache)+1);
    fInterpCache[Length(fInterpCache)-1].A := StepSprite;
    fInterpCache[Length(fInterpCache)-1].B := StepNextSprite;
    fInterpCache[Length(fInterpCache)-1].Speed := 1;
    fInterpCache[Length(fInterpCache)-1].interpOffset := InterpOffset;

    //Update return values
    Inc(aPicOffset, 7);
    for SubStep := 0 to 6 do
      fOutputStream.Write(InterpOffset+SubStep);

    if aDryRun then
      Continue;

    dirBase := fWorkDir + 'base\';
    dirShad := fWorkDir + 'shad\';
    dirTeam := fWorkDir + 'team\';

    //Interpolate!
    KMDeleteFolder(dirBase);
    KMDeleteFolder(dirShad);
    KMDeleteFolder(dirTeam);

    BaseMoveX := ABase.MoveX - A.MoveX;
    BaseMoveY := ABase.MoveY - A.MoveY;

    if aSimpleAlpha then
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirBase, ietNormal, aSimpleShadows, aBkgRGB)
    else
    begin
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirBase, ietBase, aSimpleShadows, aBkgRGB);
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirShad, ietShadows, aSimpleShadows, aBkgRGB);
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, aUseBaseForTeamMask, dirTeam, ietTeamMask, aSimpleShadows, aBkgRGB);
    end;

    //Determine maximum bounds of the pair, to crop out the base background sprite
    //Expand by 1px in case the interpolation goes slightly outside the original bounds
    OverallMinX := Min(fSprites[RT].RXData.Pivot[StepSprite].X, fSprites[RT].RXData.Pivot[StepNextSprite].X);
    OverallMinY := Min(fSprites[RT].RXData.Pivot[StepSprite].Y, fSprites[RT].RXData.Pivot[StepNextSprite].Y);
    OverallMaxX := OverallMinX + Max(fSprites[RT].RXData.Size[StepSprite].X, fSprites[RT].RXData.Size[StepNextSprite].X);
    OverallMaxY := OverallMinY + Max(fSprites[RT].RXData.Size[StepSprite].Y, fSprites[RT].RXData.Size[StepNextSprite].Y);

    //Import and process interpolated steps
    for SubStep := 0 to 6 do
    begin
      //Filenames are 1-based, and skip the first one since it's the original
      suffixPath := 'interpolated_frames\' + format('%.15d.png', [SubStep+1+1]);
      ProcessInterpImage(InterpOffset+SubStep, suffixPath, outPrefix, aBkgRGB, OverallMaxX, OverallMinX, OverallMaxY, OverallMinY);
    end;
  end;

  FreeAndNil(StrList);
end;


procedure TForm1.DoInterpSlow(RT: TRXType; A: TKMAnimLoop; var aPicOffset: Integer; aDryRun: Boolean; aBkgRGB: Cardinal);
var
  I, S, SInterp, SOffset, StepFull, SubStep, InterpOffset, StepSprite, StepNextSprite: Integer;
  suffixPath, outDirLocal, outPrefix: string;
  Found: Boolean;
begin
  S := GetAnimSpeed(A);

  //We can't do 3x interp, so interp 4x and skip some of them using SOffset below
  if S = 3 then
    SInterp := 4
  else
    SInterp := S;

  if (S = 2) or (S = 3) or (S = 4) then
  begin
    //Custom handler for animations that only update every 2/3/4 frames
    outDirLocal := fOutDir+IntToStr(Ord(RT)+1)+'\';
    outPrefix := outDirLocal+IntToStr(Ord(RT)+1)+'_';
    ForceDirectories(outDirLocal);

    for StepFull := 1 to 30 do
    begin
      if StepFull > A.Count then
      begin
        for SubStep := 1 to 8 do
          fOutputStream.Write(Integer(-1));
        Continue;
      end;

      if (StepFull-1) mod S <> 0 then
        Continue;

      StepSprite := A.Step[StepFull] + 1;
      StepNextSprite := A.Step[(((StepFull-1 + S) mod A.Count) + 1)] + 1;

      fOutputStream.Write(StepSprite);

      //Check the cache
      Found := False;
      for I := Low(fInterpCache) to High(fInterpCache) do
      begin
        if (fInterpCache[I].A = StepSprite) and (fInterpCache[I].B = StepNextSprite) and (fInterpCache[I].Speed = S) then
        begin
          for SubStep := 0 to (8*S - 2) do
            fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

          Found := True;
        end
        //Check for a reversed sequence in the cache (animations often loop backwards)
        else if (fInterpCache[I].B = StepSprite) and (fInterpCache[I].A = StepNextSprite) and (fInterpCache[I].Speed = S) then
        begin
          for SubStep := (8*S - 2) downto 0 do
            fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

          Found := True;
        end;
      end;
      if Found then
        Continue;

      InterpOffset := aPicOffset;

      //Cache it
      SetLength(fInterpCache, Length(fInterpCache)+1);
      fInterpCache[Length(fInterpCache)-1].A := StepSprite;
      fInterpCache[Length(fInterpCache)-1].B := StepNextSprite;
      fInterpCache[Length(fInterpCache)-1].Speed := S;
      fInterpCache[Length(fInterpCache)-1].interpOffset := InterpOffset;

      //Update return values
      Inc(aPicOffset, 8*S - 1);
      for SubStep := 0 to (8*S - 2) do
        fOutputStream.Write(InterpOffset+SubStep);

      if aDryRun then
        Continue;

      MakeSlowInterpImages(SInterp, RT, StepSprite, StepNextSprite, fWorkDir+'base\', ietBase, aBkgRGB);
      MakeSlowInterpImages(SInterp, RT, StepSprite, StepNextSprite, fWorkDir+'shad\', ietShadows, aBkgRGB);
      MakeSlowInterpImages(SInterp, RT, StepSprite, StepNextSprite, fWorkDir+'team\', ietTeamMask, aBkgRGB);
      for SubStep := 0 to (8*S - 2) do
      begin
        if S <> SInterp then
          SOffset := (SubStep+1+1) div SInterp
        else
          SOffset := 0;

        //Filenames are 1-based, and skip the first one since it's the original
        suffixPath := 'interpolated_frames\' + format('%.15d.png', [SubStep+1+1 + SOffset]);
        ProcessInterpImage(InterpOffset+SubStep, suffixPath, outPrefix, $0, 9999, -9999, 9999, -9999);
      end;
    end;
  end
  else
    memoErrors.Lines.Add('Not a slow animation!');
end;


procedure TForm1.CleanupInterpBackground(var pngBase, pngShad, pngTeam: TKMCardinalArray);

  function RGBDiff(A, B: Cardinal): Integer;
  begin
    Result := Abs(Integer(A and $FF) - Integer(B and $FF));
    Result := Max(Result, Abs(Integer((A shr 8) and $FF) - Integer((B shr 8) and $FF)));
    Result := Max(Result, Abs(Integer((A shr 16) and $FF) - Integer((B shr 16) and $FF)));
  end;

var
  X, Y: Integer;
  pngWidth, pngHeight: Word;
  pngBaseBackground, pngShadBackground, pngClean1, pngClean2, pngShad1, pngShad2: TKMCardinalArray;
begin
  if FileExists(fWorkDir + 'base\base.png') then
    LoadFromPng(fWorkDir + 'base\base.png', pngWidth, pngHeight, pngBaseBackground);

  if FileExists(fWorkDir + 'base\1.png') then
    LoadFromPng(fWorkDir + 'base\1.png', pngWidth, pngHeight, pngClean1);

  if FileExists(fWorkDir + 'base\2.png') then
    LoadFromPng(fWorkDir + 'base\2.png', pngWidth, pngHeight, pngClean2);

  if FileExists(fWorkDir + 'shad\base.png') then
    LoadFromPng(fWorkDir + 'shad\base.png', pngWidth, pngHeight, pngShadBackground);

  if FileExists(fWorkDir + 'shad\1.png') then
    LoadFromPng(fWorkDir + 'shad\1.png', pngWidth, pngHeight, pngShad1);

  if FileExists(fWorkDir + 'shad\2.png') then
    LoadFromPng(fWorkDir + 'shad\2.png', pngWidth, pngHeight, pngShad2);

  if (Length(pngBaseBackground) = 0) or (Length(pngShadBackground) = 0)
  or (Length(pngClean1) = 0) or (Length(pngClean2) = 0)
  or (Length(pngShad1) = 0) or (Length(pngShad2) = 0) then
    Exit;

  for Y := 0 to pngHeight-1 do
  begin
    for X := 0 to pngWidth-1 do
    begin
      //If the pixel exists in either of the source sprites, don't change it
      if (pngClean1[Y*pngWidth + X] shr 24 >= 128)
      or (pngClean2[Y*pngWidth + X] shr 24 >= 128)
      or (pngShad1[Y*pngWidth + X] and $FF > 0)
      or (pngShad2[Y*pngWidth + X] and $FF > 0) then
        Continue;

      //If this pixels is unchanged from the base sprite we can skip it
      //For example, part of the house in the background not the work animation
      //This prevents the interpolated sprites covering up snow roofs or piles of wares
      if ((pngBaseBackground[Y*pngWidth + X] shr 24 > 0) and
          (RGBDiff(pngBaseBackground[Y*pngWidth + X], pngBase[Y*pngWidth + X]) <= 16))
      or ((pngShadBackground[Y*pngWidth + X] shr 24 > 0) and
          (pngBaseBackground[Y*pngWidth + X] shr 24 = 0) and
          (pngBase[Y*pngWidth + X] shr 24 <= 32) and
          (RGBDiff(pngShadBackground[Y*pngWidth + X], pngShad[Y*pngWidth + X]) <= 32)) then
      begin
        pngBase[Y*pngWidth + X] := $0;
        pngShad[Y*pngWidth + X] := $FF000000;
        if Length(pngTeam) > 0 then
          pngTeam[Y*pngWidth + X] := $FF000000;
      end;
    end;
  end;
end;


procedure TForm1.ProcessInterpImage(outIndex: Integer; inSuffixPath, outPrefixPath: string; aBkgRGB: Cardinal; OverallMaxX, OverallMinX, OverallMaxY, OverallMinY: Integer);
var
  pngWidth, pngHeight, newWidth, newHeight: Word;
  pngBase, pngShad, pngTeam, pngCrop, pngCropMask: TKMCardinalArray;
  I, X, Y, MinX, MinY, MaxX, MaxY: Integer;
  NoShadMinX, NoShadMinY, NoShadMaxX, NoShadMaxY: Integer;
  needsMask: Boolean;
  StrList: TStringList;
  dirBase, dirShad, dirTeam: string;
begin
  dirBase := fWorkDir + 'base\';
  dirShad := fWorkDir + 'shad\';
  dirTeam := fWorkDir + 'team\';

  //Clear all our buffers so they get rezeroed
  SetLength(pngBase, 0);
  SetLength(pngShad, 0);
  SetLength(pngTeam, 0);
  SetLength(pngCrop, 0);
  SetLength(pngCropMask, 0);

  LoadFromPng(dirBase + inSuffixPath, pngWidth, pngHeight, pngBase);

  if FileExists(dirShad + inSuffixPath) then
    LoadFromPng(dirShad + inSuffixPath, pngWidth, pngHeight, pngShad);

  if FileExists(dirTeam + inSuffixPath) then
    LoadFromPng(dirTeam + inSuffixPath, pngWidth, pngHeight, pngTeam);

  CleanupInterpBackground(pngBase, pngShad, pngTeam);

  //Determine Min/Max X/Y
  MinX := MaxInt;
  MinY := MaxInt;
  MaxX := -1;
  MaxY := -1;
  NoShadMinX := pngWidth-1;
  NoShadMinY := pngHeight-1;
  NoShadMaxX := 0;
  NoShadMaxY := 0;
  needsMask := False;
  for Y := 0 to pngHeight-1 do
  begin
    for X := 0 to pngWidth-1 do
    begin
      if (pngBase[Y*pngWidth + X] shr 24 > 50) or
      ((Length(pngShad) > 0) and ((pngShad[Y*pngWidth + X] and $FF) > 10)) then
      begin
        MinX := Min(MinX, X);
        MinY := Min(MinY, Y);
        MaxX := Max(MaxX, X);
        MaxY := Max(MaxY, Y);
      end;
      //Tighter "no shadow" bounds. Also ignore areas where alpha < 50%
      if pngBase[Y*pngWidth + X] shr 24 >= $7F then
      begin
        NoShadMinX := Min(NoShadMinX, X);
        NoShadMinY := Min(NoShadMinY, Y);
        NoShadMaxX := Max(NoShadMaxX, X);
        NoShadMaxY := Max(NoShadMaxY, Y);
      end;
      if (Length(pngTeam) > 0) and ((pngTeam[Y*pngWidth + X] and $FF) > 0) then
        needsMask := True;
    end;
  end;

  //Apply overall bounds to crop out the base background sprite
  MinX := Max(MinX, OverallMinX + (pngWidth div 2));
  MinY := Max(MinY, OverallMinY + (pngHeight div 2) + CANVAS_Y_OFFSET);
  MaxX := Min(MaxX, OverallMaxX + (pngWidth div 2));
  MaxY := Min(MaxY, OverallMaxY + (pngHeight div 2) + CANVAS_Y_OFFSET);

  //Crop
  if (MaxX > MinX) and (MaxY > MinY) then
  begin
    newWidth := MaxX - MinX + 1;
    newHeight := MaxY - MinY + 1;
    SetLength(pngCrop, newWidth*newHeight);
    SetLength(pngCropMask, newWidth*newHeight);
    I := 0;
    for Y := MinY to MaxY do
    begin
      for X := MinX to MaxX do
      begin
        //Background is black with alpha from the shadow mask
        if Length(pngShad) > 0 then
          pngCrop[I] := (pngShad[Y*pngWidth + X] shl 24) or aBkgRGB;

        //Layer base sprite on top
        pngCrop[I] := BlendRGBA(pngCrop[I], pngBase[Y*pngWidth + X]);

        if Length(pngTeam) > 0 then
          pngCropMask[I] := pngTeam[Y*pngWidth + X];

        Inc(I);
      end;
    end;

    //Save offsets .txt file
    StrList := TStringList.Create;
    StrList.Append(IntToStr(MinX - pngWidth div 2));
    StrList.Append(IntToStr(MinY - CANVAS_Y_OFFSET - pngHeight div 2));
    StrList.Append(IntToStr(NoShadMinX - MinX));
    StrList.Append(IntToStr(NoShadMinY - MinY));
    StrList.Append(IntToStr(newWidth-1 - (MaxX - NoShadMaxX)));
    StrList.Append(IntToStr(newHeight-1 - (MaxY - NoShadMaxY)));

    StrList.SaveToFile(outPrefixPath+format('%d.txt', [outIndex]));
    SaveToPng(newWidth, newHeight, pngCrop, outPrefixPath+format('%d.png', [outIndex]));
    if needsMask and (Length(pngTeam) > 0) then
      SaveToPng(newWidth, newHeight, pngCropMask, outPrefixPath+format('%dm.png', [outIndex]));

    FreeAndNil(StrList);
  end;
end;


procedure TForm1.DoInterpUnit(aUT: TKMUnitType; aAction: TKMUnitActionType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  bkgRGB: Cardinal;
  UseBase, SimpleShadows: Boolean;
begin
  if aDir = dirNA then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  A := fResUnits[aUT].UnitAnim[aAction,aDir];

  if (A.Count <= 1) or (A.Step[1] = -1) or not (aAction in UNIT_SUPPORTED_ANIMS[aUT]) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  //Death animations have semi-transparent white that we treat as shadows
  if aAction = uaDie then
    bkgRGB := $FFFFFF
  else
    bkgRGB := $000000;

  UseBase := aAction in [uaWalkArm, uaWalkTool, uaWalkBooty, uaWalkTool2, uaWalkBooty2];
  UseBase := UseBase and (aUT in [CITIZEN_MIN..CITIZEN_MAX]); //Don't use base for warrior flags
  ABase := fResUnits[aUT].UnitAnim[uaWalk, aDir];

  SimpleShadows := aAction <> uaDie;

  DoInterp(rxUnits, A, ABase, UseBase, True, False, SimpleShadows, bkgRGB, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpSerfCarry(aWare: TKMWareType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
begin
  if (aDir = dirNA) or not (aWare in [WARE_MIN..WARE_MAX]) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  A := fResUnits.SerfCarry[aWare, aDir];
  ABase := fResUnits[utSerf].UnitAnim[uaWalk, aDir];

  DoInterp(rxUnits, A, ABase, True, True, False, True, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpUnitThought(aThought: TKMUnitThought; var aPicOffset: Integer; aDryRun: Boolean);
var
  A: TKMAnimLoop;
  I: Integer;
begin
  if aThought = thNone then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  A.Count := 1 + THOUGHT_BOUNDS[aThought, 2] - THOUGHT_BOUNDS[aThought, 1];
  for I := 1 to 30 do
  begin
    if I <= A.Count then
      A.Step[I] := THOUGHT_BOUNDS[aThought, 2] - (I-1) // Thought bubbles are animated in reverse
    else
      A.Step[I] := -1;
  end;

  DoInterp(rxUnits, A, A, False, False, False, False, $FFFFFF, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpTree(aTree: Integer; var aPicOffset: Integer; aDryRun: Boolean);
var
  A: TKMAnimLoop;
  S: Integer;
begin
  A := gMapElements[aTree].Anim;

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  S := GetAnimSpeed(A);
  if (S = 2) or (S = 3) or (S = 4) then
  begin
    DoInterpSlow(rxTrees, A, aPicOffset, aDryRun, $0);
  end
  else
    DoInterp(rxTrees, A, A, False, False, False, True, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  UseBase: Boolean;
  SimpleAlpha, SimpleShadows: Boolean;
  I, Step, SubStep: Integer;
begin
  A := fResHouses[aHT].Anim[aHouseAct];

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  //School clock shouldn't be interpolated, it's supposed to tick
  if (aHT = htSchool) and (aHouseAct in [haWork1..haWork5]) then
  begin
    for Step := 1 to 30 do
      for SubStep := 1 to 8 do
        fOutputStream.Write(Integer(A.Step[Step] + 1));

    Exit;
  end;

  ABase.Count := 30;
  ABase.MoveX := 0;
  ABase.MoveY := 0;
  for I := Low(ABase.Step) to High(ABase.Step) do
    ABase.Step[I] := fResHouses[aHT].StonePic;

  UseBase := aHouseAct in [haIdle, haWork1..haWork5];
  SimpleAlpha := aHouseAct in [haSmoke, haFire1..haFire8];
  SimpleShadows := not (aHouseAct in [haSmoke, haFire1..haFire8]);

  //Hard coded rules
  if aHT in [htArmorWorkshop, htStables, htWatchTower, htFishermans, htWoodcutters, htWatchTower, htTannery] then
    UseBase := False;

  if (aHT = htButchers) and (aHouseAct = haIdle) then
  begin
    DoInterpSlow(rxHouses, A, aPicOffset, aDryRun, $0);
    Exit;
  end;

  DoInterp(rxHouses, A, ABase, UseBase and USE_BASE_HOUSE_ACT, False, SimpleAlpha, SimpleShadows, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpBeast(aBeastHouse, aBeast, aBeastAge: Integer; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  I: Integer;
const
  HOUSE_LOOKUP: array[1..3] of TKMHouseType = (htSwine, htStables, htMarket);
begin
  if (aBeastHouse = 3) and ((aBeast > 3) or (aBeastAge <> 1)) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  A := fResHouses.BeastAnim[HOUSE_LOOKUP[aBeastHouse], aBeast, aBeastAge];

  ABase.Count := 30;
  ABase.MoveX := 0;
  ABase.MoveY := 0;
  for I := Low(ABase.Step) to High(ABase.Step) do
    ABase.Step[I] := fResHouses[HOUSE_LOOKUP[aBeastHouse]].StonePic;

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  DoInterp(rxHouses, A, ABase, USE_BASE_BEASTS, False, False, True, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.btnProcessClick(Sender: TObject);
type
  TKMInterpolation = array[1..30, 0..7] of Integer;
var
  I, picOffset, startPos: Integer;
  dir: TKMDirection;
  act: TKMUnitActionType;
  u: TKMUnitType;
  ware: TKMWareType;
  th: TKMUnitThought;
  h: TKMHouseType;
  hAct: TKMHouseActionType;
  animData: string;
  beastHouse, beast, beastAge: Integer;
const
  UNITS_RX_OFFSET = 9300;
  TREES_RX_OFFSET = 260;
  HOUSES_RX_OFFSET = 2100;
begin
  SetLength(fInterpCache, 0);

  FreeAndNil(fOutputStream);
  fOutputStream := TKMemoryStreamBinary.Create;

  animData := 'type'+#13#10;
  animData := animData + '  TKMInterpolation = array[1..30, 0..7] of Integer;'+#13#10;

  //UNITS
  picOffset := UNITS_RX_OFFSET;
  fOutputStream.WriteA('UnitAction');

  animData := animData + '  TKMUnitActionInterp = array[TKMUnitType, UNIT_ACT_MIN..UNIT_ACT_MAX, dirN..dirNW] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMUnitActionInterp) = '+IntToStr(SizeOf(TKMUnitActionInterp))+#13#10;

  startPos := fOutputStream.Position;
  for u := UNIT_MIN to UNIT_MAX do
    for act := UNIT_ACT_MIN to UNIT_ACT_MAX do
      for dir := dirN to dirNW do
        try
          DoInterpUnit(u, act, dir, picOffset, not chkUnitActions.Checked);
        except
          on E: Exception do
            memoErrors.Lines.Add(TRttiEnumerationType.GetName(u) + ' - ' + UNIT_ACT_STR[act] + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message);
        end;
  Assert(SizeOf(TKMUnitActionInterp) = fOutputStream.Position - startPos);

  animData := animData + '//fOutputStream.Position = '+IntToStr(fOutputStream.Position)+#13#10;

  fOutputStream.WriteA('SerfCarry ');

  animData := animData + 'TKMSerfCarryInterp = array[WARE_MIN..WARE_MAX, dirN..dirNW] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMSerfCarryInterp) = '+IntToStr(SizeOf(TKMSerfCarryInterp))+#13#10;

  startPos := fOutputStream.Position;
  for ware := WARE_MIN to WARE_MAX do
    for dir := dirN to dirNW do
      try
        DoInterpSerfCarry(ware, dir, picOffset, not chkSerfCarry.Checked);
      except
        on E: Exception do
          memoErrors.Lines.Add(TRttiEnumerationType.GetName(ware) + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message);
      end;
  Assert(SizeOf(TKMSerfCarryInterp) = fOutputStream.Position - startPos);

  fOutputStream.WriteA('UnitThoughts  ');

  animData := animData + '  TKMUnitThoughtInterp = array[TKMUnitThought] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMUnitThoughtInterp) = '+IntToStr(SizeOf(TKMUnitThoughtInterp))+#13#10;

  startPos := fOutputStream.Position;
  for th := Low(TKMUnitThought) to High(TKMUnitThought) do
    try
      DoInterpUnitThought(th, picOffset, not chkUnitThoughts.Checked);
    except
      on E: Exception do
        memoErrors.Lines.Add(TRttiEnumerationType.GetName(th) + ' - ' + E.Message);
    end;
  Assert(SizeOf(TKMUnitThoughtInterp) = fOutputStream.Position - startPos);

  fOutputStream.WriteA('Trees ');

  animData := animData + #13#10 + #13#10;
  animData := animData + 'TKMTreeInterp = array[0..OBJECTS_CNT] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMTreeInterp) = '+IntToStr(SizeOf(TKMTreeInterp))+#13#10;


  //TREES
  picOffset := TREES_RX_OFFSET;
  SetLength(fInterpCache, 0);

  startPos := fOutputStream.Position;
  for I := 0 to OBJECTS_CNT do
    try
      DoInterpTree(I, picOffset, not chkTrees.Checked);
    except
      on E: Exception do
        memoErrors.Lines.Add('Tree ' + IntToStr(I) + ' - ' + E.Message);
    end;
  Assert(SizeOf(TKMTreeInterp) = fOutputStream.Position - startPos);


  //HOUSES
  picOffset := HOUSES_RX_OFFSET;
  SetLength(fInterpCache, 0);

  fOutputStream.WriteA('Houses');

  animData := animData + #13#10 + #13#10;
  animData := animData + 'TKMHouseInterp = array[HOUSE_MIN..HOUSE_MAX, TKMHouseActionType] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMHouseInterp) = '+IntToStr(SizeOf(TKMHouseInterp))+#13#10;

  startPos := fOutputStream.Position;
  for h := HOUSE_MIN to HOUSE_MAX do
    for hAct := Low(TKMHouseActionType) to High(TKMHouseActionType) do
      try
        DoInterpHouseAction(h, hAct, picOffset, not chkHouseActions.Checked);
      except
        on E: Exception do
          memoErrors.Lines.Add(TRttiEnumerationType.GetName(h) + ' - ' + TRttiEnumerationType.GetName(hAct) + ' - ' + E.Message);
      end;
  Assert(SizeOf(TKMHouseInterp) = fOutputStream.Position - startPos);

  fOutputStream.WriteA('Beasts');

  animData := animData + #13#10 + #13#10;
  animData := animData + 'TKMBeastInterp = array[1..3,1..5,1..3] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMBeastInterp) = '+IntToStr(SizeOf(TKMBeastInterp))+#13#10;

  startPos := fOutputStream.Position;
  for beastHouse := 1 to 3 do
    for beast := 1 to 5 do
      for beastAge := 1 to 3 do
        try
          DoInterpBeast(beastHouse, beast, beastAge, picOffset, not chkBeasts.Checked);
        except
          on E: Exception do
            memoErrors.Lines.Add(' beast ' + IntToStr(beastHouse) + ' - ' + IntToStr(beast) + ' - ' + IntToStr(beastAge) + ' - ' + E.Message);
        end;
  Assert(SizeOf(TKMBeastInterp) = fOutputStream.Position - startPos);

  fOutputStream.SaveToFile(ExeDir+'data/defines/interp.dat');
  Memo1.Text := animData;
end;


end.
