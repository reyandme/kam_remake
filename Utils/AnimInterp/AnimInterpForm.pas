unit AnimInterpForm;
interface
uses
  Winapi.Windows, Winapi.Messages, System.SysUtils, System.Variants, System.Classes, Vcl.Graphics,
  Vcl.Controls, Vcl.Forms, Vcl.Dialogs, Vcl.StdCtrls, Vcl.ComCtrls, Vcl.Samples.Spin,
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
    memoLog: TMemo;
    Label1: TLabel;
    chkSerfCarry: TCheckBox;
    chkUnitActions: TCheckBox;
    chkUnitThoughts: TCheckBox;
    chkTrees: TCheckBox;
    chkHouseActions: TCheckBox;
    chkBeasts: TCheckBox;
    pbProgress: TProgressBar;
    Label2: TLabel;
    cbLogVerbose: TCheckBox;
    seUnitsResumeFrom: TSpinEdit;
    Label3: TLabel;
    seTreesResumeFrom: TSpinEdit;
    Label4: TLabel;
    seHousesResumeFrom: TSpinEdit;
    Label5: TLabel;
    procedure btnProcessClick(Sender: TObject);
    procedure FormCreate(Sender: TObject);
  private
    fResPalettes: TKMResPalettes;
    fResUnits: TKMResUnits;
    fResHouses: TKMResHouses;
    fResMapElem: TKMResMapElements;
    fSprites: array[TRXType] of TKMSpritePackEdit;

    fLabelProgress: TLabel;

    fOutputStream: TKMemoryStreamBinary;

    fInterpCache: array of TInterpCacheItem;

    fFolderDain: string;
    fFolderBase: string;
    fFolderShadow: string;
    fFolderTeam: string;
    fFolderOutput: string;

    fPicOffset: Integer;

    procedure ProcessAllHouseBeasts;
    procedure ProcessAllHouses;
    procedure ProcessAllSerfCarry;
    procedure ProcessAllTrees;
    procedure ProcessAllUnitActions;
    procedure ProcessAllUnitThoughts;
    procedure ProcessUnit(aUT: TKMUnitType; aAction: TKMUnitActionType; aDir: TKMDirection; aDryRun: Boolean);
    procedure ProcessSerfCarry(aWare: TKMWareType; aDir: TKMDirection; aDryRun: Boolean);
    procedure ProcessUnitThought(aThought: TKMUnitThought; aDryRun: Boolean);
    procedure ProcessTree(aTree: Integer; aDryRun: Boolean);
    procedure ProcessHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; aDryRun: Boolean);
    procedure ProcessBeast(aBeastHouse, aBeast, aBeastAge: Integer; aDryRun: Boolean);


    function GetCanvasSize(aID: Integer; RT: TRXType; aMoveX: Integer = 0; aMoveY: Integer = 0): Integer;
    function GetDainParams(aDir: string; aAlpha: Boolean; aInterpLevel: Integer): string;

    procedure WriteEmptyAnim;

    procedure InterpolateImagesNormal(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType; aSimpleShadows: Boolean; aBkgRGB: Cardinal);
    procedure InterpolateImagesSlow(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType; aBkgRGB: Cardinal);

    procedure InterpolateAnimNormal(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aSimpleShadows: Boolean; aBkgRGB: Cardinal; aDryRun: Boolean);
    procedure InterpolateAnimSlow(RT: TRXType; A: TKMAnimLoop; aDryRun: Boolean; aBkgRGB: Cardinal);

    procedure CleanupInterpBackground(var pngBase, pngShad, pngTeam: TKMCardinalArray);
    procedure ProcessInterpImage(outIndex: Integer; inSuffixPath, outPrefixPath: string; aBkgRGB: Cardinal; OverallMaxX, OverallMinX, OverallMaxY, OverallMinY: Integer);

    procedure ChangeStatus(const aText: string);
    procedure ChangeProgress(const aPart: string; aMultiplier, aSourceFrom, aSourceTo, aOutputFrom, aOutputTo: Integer);
    procedure LogError(const aText: string);
    procedure LogInfo(const aText: string);
  end;


implementation
uses
  ShellApi, Math, RTTI, KM_FileIO, KromUtils,
  KM_Log, KM_IoPNG, KM_ResInterpolation;

{$R *.dfm}

const
  INTERPOLATION_MULTIPLIER = 8;
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
    [uaWalk, uaSpec, uaDie, uaEat],             // utRecruit
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utMilitia
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utAxeFighter
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utSwordFighter
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utBowman
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utCrossbowman
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utLanceCarrier
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utPikeman
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utScout
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utKnight
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utBarbarian
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utRebel
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utRogue
    [uaWalk, uaWork, uaSpec, uaDie, uaWalkArm], // utWarrior
    [uaWalk, uaWork, uaDie, uaWalkArm],         // utVagabond
    [uaWalk],                                   // utWolf
    [uaWalk..uaWork1],                          // utFish (1..5 fish per unit)
    [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk], [uaWalk] // Animals
  );

  function GetAnimPace(aAnimLoop: TKMAnimLoop): Integer;
  begin
    Result := 1;
    while (Result < aAnimLoop.Count) and (aAnimLoop.Step[Result] = aAnimLoop.Step[Result+1]) do
      Inc(Result);
  end;


procedure TForm1.FormCreate(Sender: TObject);
var
  folderWork: string;
begin
  ExeDir := ExpandFileName(ExtractFilePath(ParamStr(0)) + '..\..\');

  Caption := 'Animation Interpolator (' + GAME_REVISION + ')';

  fResPalettes := TKMResPalettes.Create;
  fResPalettes.LoadPalettes(ExeDir + 'data\gfx\');

  fResUnits := TKMResUnits.Create;
  fResHouses := TKMResHouses.Create;
  fResMapElem := TKMResMapElements.Create;
  fResMapElem.LoadFromFile(ExeDir + 'data' + PathDelim + 'defines' + PathDelim + 'mapelem.dat');

  folderWork := ExeDir + 'SpriteInterp\';
  fFolderOutput := folderWork + 'Output\';
  fFolderDain := ExeDir + 'DAIN_APP Alpha 1.0\';

  // Name all folders wip_ to denote what they are and have them visually grouped
  fFolderBase := folderWork + 'wip_base\';
  fFolderShadow := folderWork + 'wip_shadow\';
  fFolderTeam := folderWork + 'wip_team\';

  // We need to create the label and parent it to the ProgressBar to have it on top
  fLabelProgress := TLabel.Create(Self);
  fLabelProgress.Parent := pbProgress;
  fLabelProgress.AutoSize := False;
  fLabelProgress.Transparent := True;
  fLabelProgress.Top :=  0;
  fLabelProgress.Left :=  0;
  fLabelProgress.Width := pbProgress.ClientWidth;
  fLabelProgress.Height := pbProgress.ClientHeight;
  fLabelProgress.Alignment := taCenter;
  fLabelProgress.Layout := tlCenter;
  fLabelProgress.Caption := 'Test';
end;


function TForm1.GetDainParams(aDir: string; aAlpha: Boolean; aInterpLevel: Integer): string;
var
  dainExe: string;
begin
  dainExe := '"' + fFolderDain + 'DAINAPP.exe"';
  Result := 'cmd.exe /C ' + DainExe;
  Result := Result + ' --cli 1';    // Execute application in CLI mode.
  Result := Result + ' -o ' + aDir; // Output Path to generate the folder with all the files.
  Result := Result + ' -p 0';       // Generate a version of the file limiting the pallete.
  Result := Result + ' -l 1';       // Turn on if the animation do a perfect loop.
  Result := Result + ' -in ' + IntToStr(aInterpLevel); // How much new frames will be created.
  Result := Result + ' -da 0';         // Should depth be calculated in interpolations?
  Result := Result + ' -se 0';         // Do the step of extracting all frames from the original video into the folder.
  Result := Result + ' -si 1';         // Do the step of interpolating all the original frames.
  Result := Result + ' -sr 0';         // Do the step of creating the video from all the interpolated frames.
  Result := Result + ' -ha 0';         // Use half precision float points.
  Result := Result + ' --fast_mode 0'; // Use fast interpolation mode.

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


procedure TForm1.InterpolateImagesSlow(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType; aBkgRGB: Cardinal);
var
  origSpritesDir, interpSpritesDir: string;
  I: Integer;
  NeedAlpha: Boolean;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  InterpolateImagesNormal(RT, aID_1, aID_2, -1, -1, 0, 0, False, aBaseDir, aExportType, True, aBkgRGB);

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
  LogInfo('InterpolateImagesSlow: ' + aBaseDir);
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  CreateProcess(nil, PChar(GetDainParams(aBaseDir, NeedAlpha, aInterpCount)), nil, nil, false, 0, nil, PChar(fFolderDain), StartupInfo, ProcessInfo);
  WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
  //ShellExecute(0, nil, 'cmd.exe', PChar(DainParams), PChar(DainFolder), SW_SHOWNORMAL);
end;


procedure TForm1.InterpolateImagesNormal(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType; aSimpleShadows: Boolean; aBkgRGB: Cardinal);
var
  origSpritesDir, interpSpritesDir: string;
  CanvasSize: Integer;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
  NeedAlpha, AllBlank, Worked: Boolean;
begin
  if fSprites[RT] = nil then
  begin
    fSprites[RT] := TKMSpritePackEdit.Create(RT, fResPalettes);
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
  LogInfo('InterpolateImagesNormal: ' + aBaseDir);
  ZeroMemory(@StartupInfo, SizeOf(StartupInfo));
  StartupInfo.cb := SizeOf(StartupInfo);
  StartupInfo.dwFlags := STARTF_USESHOWWINDOW;
  StartupInfo.wShowWindow := SW_HIDE;
  CreateProcess(nil, PChar(GetDainParams(aBaseDir, NeedAlpha, INTERPOLATION_MULTIPLIER)), nil, nil, false, 0, nil, PChar(fFolderDain), StartupInfo, ProcessInfo);
  WaitForSingleObject(ProcessInfo.hProcess, INFINITE);
  //ShellExecute(0, nil, 'cmd.exe', PChar(DainParams), PChar(DainFolder), SW_SHOWNORMAL);
end;


procedure TForm1.WriteEmptyAnim;
var
  Step, SubStep: Integer;
begin
  for Step := 1 to 30 do
    for SubStep := 1 to INTERPOLATION_MULTIPLIER do
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


procedure TForm1.InterpolateAnimNormal(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aSimpleShadows: Boolean; aBkgRGB: Cardinal; aDryRun: Boolean);

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
  suffixPath, outDirLocal, outPrefix: string;
  Found: Boolean;
begin
  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  outDirLocal := fFolderOutput+IntToStr(Ord(RT)+1)+'\';
  outPrefix := outDirLocal+IntToStr(Ord(RT)+1)+'_';
  ForceDirectories(outDirLocal);

  //Import and reprocess
  for Step := 1 to 30 do
  begin
    if Step > A.Count then
    begin
      for SubStep := 1 to INTERPOLATION_MULTIPLIER do
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
      for SubStep := 1 to INTERPOLATION_MULTIPLIER do
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
        for SubStep := 0 to INTERPOLATION_MULTIPLIER-2 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end
      //Check for a reversed sequence in the cache (animations often loop backwards)
      else if (fInterpCache[I].B = StepSprite) and (fInterpCache[I].A = StepNextSprite) and (fInterpCache[I].Speed = 1) then
      begin
        for SubStep := INTERPOLATION_MULTIPLIER-2 downto 0 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end;
    end;
    if Found then
      Continue;

    InterpOffset := fPicOffset;

    //Cache it
    SetLength(fInterpCache, Length(fInterpCache)+1);
    fInterpCache[Length(fInterpCache)-1].A := StepSprite;
    fInterpCache[Length(fInterpCache)-1].B := StepNextSprite;
    fInterpCache[Length(fInterpCache)-1].Speed := 1;
    fInterpCache[Length(fInterpCache)-1].interpOffset := InterpOffset;

    //Update return values
    Inc(fPicOffset, INTERPOLATION_MULTIPLIER-1);
    for SubStep := 0 to INTERPOLATION_MULTIPLIER-2 do
      fOutputStream.Write(InterpOffset+SubStep);

    if aDryRun then
      Continue;

    //Interpolate!
    KMDeleteFolder(fFolderBase);
    KMDeleteFolder(fFolderShadow);
    KMDeleteFolder(fFolderTeam);

    BaseMoveX := ABase.MoveX - A.MoveX;
    BaseMoveY := ABase.MoveY - A.MoveY;

    if aSimpleAlpha then
    begin
      ChangeProgress('base', INTERPOLATION_MULTIPLIER, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
      InterpolateImagesNormal(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, fFolderBase, ietNormal, aSimpleShadows, aBkgRGB);
    end else
    begin
      ChangeProgress('base', INTERPOLATION_MULTIPLIER, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
      InterpolateImagesNormal(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, fFolderBase, ietBase, aSimpleShadows, aBkgRGB);
      ChangeProgress('shadow', INTERPOLATION_MULTIPLIER, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
      InterpolateImagesNormal(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, fFolderShadow, ietShadows, aSimpleShadows, aBkgRGB);
      ChangeProgress('team', INTERPOLATION_MULTIPLIER, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
      InterpolateImagesNormal(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, aUseBaseForTeamMask, fFolderTeam, ietTeamMask, aSimpleShadows, aBkgRGB);
    end;

    ChangeProgress('processing', INTERPOLATION_MULTIPLIER, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
    //Determine maximum bounds of the pair, to crop out the base background sprite
    //Expand by 1px in case the interpolation goes slightly outside the original bounds
    OverallMinX := Min(fSprites[RT].RXData.Pivot[StepSprite].X, fSprites[RT].RXData.Pivot[StepNextSprite].X);
    OverallMinY := Min(fSprites[RT].RXData.Pivot[StepSprite].Y, fSprites[RT].RXData.Pivot[StepNextSprite].Y);
    OverallMaxX := OverallMinX + Max(fSprites[RT].RXData.Size[StepSprite].X, fSprites[RT].RXData.Size[StepNextSprite].X);
    OverallMaxY := OverallMinY + Max(fSprites[RT].RXData.Size[StepSprite].Y, fSprites[RT].RXData.Size[StepNextSprite].Y);

    //Import and process interpolated steps
    for SubStep := 0 to INTERPOLATION_MULTIPLIER-2 do
    begin
      //Filenames are 1-based, and skip the first one since it's the original
      suffixPath := 'interpolated_frames\' + format('%.15d.png', [SubStep+1+1]);
      ProcessInterpImage(InterpOffset+SubStep, suffixPath, outPrefix, aBkgRGB, OverallMaxX, OverallMinX, OverallMaxY, OverallMinY);
    end;
  end;
end;


procedure TForm1.InterpolateAnimSlow(RT: TRXType; A: TKMAnimLoop; aDryRun: Boolean; aBkgRGB: Cardinal);
var
  I, animPace: Integer;
  SInterp, SOffset, StepFull, SubStep, InterpOffset, StepSprite, StepNextSprite: Integer;
  suffixPath, outDirLocal, outPrefix: string;
  Found: Boolean;
begin
  animPace := GetAnimPace(A);

  //We can't do 3x interp, so interp 4x and skip some of them using SOffset below
  if animPace = 3 then
    SInterp := 4
  else
    SInterp := animPace;

  if not (animPace in [2, 3, 4]) then
  begin
    LogError('Not a slow animation!');
    Exit;
  end;

  //Custom handler for animations that only update every 2/3/4 frames
  outDirLocal := fFolderOutput+IntToStr(Ord(RT)+1)+'\';
  outPrefix := outDirLocal+IntToStr(Ord(RT)+1)+'_';
  ForceDirectories(outDirLocal);

  for StepFull := 1 to 30 do
  begin
    if StepFull > A.Count then
    begin
      for SubStep := 1 to INTERPOLATION_MULTIPLIER do
        fOutputStream.Write(Integer(-1));
      Continue;
    end;

    if (StepFull-1) mod animPace <> 0 then
      Continue;

    StepSprite := A.Step[StepFull] + 1;
    StepNextSprite := A.Step[(((StepFull-1 + animPace) mod A.Count) + 1)] + 1;

    fOutputStream.Write(StepSprite);

    //Check the cache
    Found := False;
    for I := Low(fInterpCache) to High(fInterpCache) do
    begin
      if (fInterpCache[I].A = StepSprite) and (fInterpCache[I].B = StepNextSprite) and (fInterpCache[I].Speed = animPace) then
      begin
        for SubStep := 0 to (INTERPOLATION_MULTIPLIER * animPace - 2) do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end
      //Check for a reversed sequence in the cache (animations often loop backwards)
      else if (fInterpCache[I].B = StepSprite) and (fInterpCache[I].A = StepNextSprite) and (fInterpCache[I].Speed = animPace) then
      begin
        for SubStep := (INTERPOLATION_MULTIPLIER * animPace - 2) downto 0 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end;
    end;
    if Found then
      Continue;

    InterpOffset := fPicOffset;

    //Cache it
    SetLength(fInterpCache, Length(fInterpCache)+1);
    fInterpCache[Length(fInterpCache)-1].A := StepSprite;
    fInterpCache[Length(fInterpCache)-1].B := StepNextSprite;
    fInterpCache[Length(fInterpCache)-1].Speed := animPace;
    fInterpCache[Length(fInterpCache)-1].interpOffset := InterpOffset;

    //Update return values
    Inc(fPicOffset, INTERPOLATION_MULTIPLIER * animPace - 1);
    for SubStep := 0 to (INTERPOLATION_MULTIPLIER * animPace - 2) do
      fOutputStream.Write(InterpOffset+SubStep);

    if aDryRun then
      Continue;

    ChangeProgress('base', INTERPOLATION_MULTIPLIER * SInterp, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
    InterpolateImagesSlow(SInterp, RT, StepSprite, StepNextSprite, fFolderBase, ietBase, aBkgRGB);
    ChangeProgress('shadow', INTERPOLATION_MULTIPLIER * SInterp, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
    InterpolateImagesSlow(SInterp, RT, StepSprite, StepNextSprite, fFolderShadow, ietShadows, aBkgRGB);
    ChangeProgress('team', INTERPOLATION_MULTIPLIER * SInterp, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
    InterpolateImagesSlow(SInterp, RT, StepSprite, StepNextSprite, fFolderTeam, ietTeamMask, aBkgRGB);

    ChangeProgress('processing', INTERPOLATION_MULTIPLIER * SInterp, StepSprite, StepNextSprite, InterpOffset, fPicOffset-1);
    for SubStep := 0 to (INTERPOLATION_MULTIPLIER * animPace - 2) do
    begin
      if animPace <> SInterp then
        SOffset := (SubStep+1+1) div SInterp
      else
        SOffset := 0;

      //Filenames are 1-based, and skip the first one since it's the original
      suffixPath := 'interpolated_frames\' + format('%.15d.png', [SubStep+1+1 + SOffset]);
      ProcessInterpImage(InterpOffset+SubStep, suffixPath, outPrefix, $0, 9999, -9999, 9999, -9999);
    end;
  end;
end;


procedure TForm1.ChangeStatus(const aText: string);
begin
  Label2.Caption := 'Status: ' + aText;
  Label2.Repaint;
end;


procedure TForm1.ChangeProgress(const aPart: string; aMultiplier, aSourceFrom, aSourceTo, aOutputFrom, aOutputTo: Integer);
begin
  fLabelProgress.Caption := Format('%s:  [%d - %d]  ---(x%d)--->  [%d - %d]', [aPart, aSourceFrom, aSourceTo, aMultiplier, aOutputFrom, aOutputTo]);
  fLabelProgress.Repaint;
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
  if FileExists(fFolderBase + 'base.png') then
    LoadFromPng(fFolderBase + 'base.png', pngWidth, pngHeight, pngBaseBackground);

  if FileExists(fFolderBase + '1.png') then
    LoadFromPng(fFolderBase + '1.png', pngWidth, pngHeight, pngClean1);

  if FileExists(fFolderBase + '2.png') then
    LoadFromPng(fFolderBase + '2.png', pngWidth, pngHeight, pngClean2);

  if FileExists(fFolderShadow + 'base.png') then
    LoadFromPng(fFolderShadow + 'base.png', pngWidth, pngHeight, pngShadBackground);

  if FileExists(fFolderShadow + '1.png') then
    LoadFromPng(fFolderShadow + '1.png', pngWidth, pngHeight, pngShad1);

  if FileExists(fFolderShadow + '2.png') then
    LoadFromPng(fFolderShadow + '2.png', pngWidth, pngHeight, pngShad2);

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
begin
  //Clear all our buffers so they get rezeroed
  SetLength(pngBase, 0);
  SetLength(pngShad, 0);
  SetLength(pngTeam, 0);
  SetLength(pngCrop, 0);
  SetLength(pngCropMask, 0);

  LoadFromPng(fFolderBase + inSuffixPath, pngWidth, pngHeight, pngBase);

  if FileExists(fFolderShadow + inSuffixPath) then
    LoadFromPng(fFolderShadow + inSuffixPath, pngWidth, pngHeight, pngShad);

  if FileExists(fFolderTeam + inSuffixPath) then
    LoadFromPng(fFolderTeam + inSuffixPath, pngWidth, pngHeight, pngTeam);

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


procedure TForm1.ProcessUnit(aUT: TKMUnitType; aAction: TKMUnitActionType; aDir: TKMDirection; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  bkgRGB: Cardinal;
  UseBase, SimpleShadows: Boolean;
begin
  if fPicOffset < seUnitsResumeFrom.Value then
    aDryRun := True;

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

  InterpolateAnimNormal(rxUnits, A, ABase, UseBase, True, False, SimpleShadows, bkgRGB, aDryRun);
end;


procedure TForm1.ProcessSerfCarry(aWare: TKMWareType; aDir: TKMDirection; aDryRun: Boolean);
var
  animLoop, animLoopBase: TKMAnimLoop;
begin
  if fPicOffset < seUnitsResumeFrom.Value then
    aDryRun := True;

  if (aDir = dirNA) or not (aWare in [WARE_MIN..WARE_MAX]) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  animLoop := fResUnits.SerfCarry[aWare, aDir];
  animLoopBase := fResUnits[utSerf].UnitAnim[uaWalk, aDir];

  InterpolateAnimNormal(rxUnits, animLoop, animLoopBase, True, True, False, True, $000000, aDryRun);
end;


procedure TForm1.ProcessUnitThought(aThought: TKMUnitThought; aDryRun: Boolean);
var
  animLoop: TKMAnimLoop;
  I: Integer;
begin
  if fPicOffset < seUnitsResumeFrom.Value then
    aDryRun := True;

  if aThought = thNone then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  animLoop.Count := 1 + UNIT_THOUGHT_BOUNDS[aThought, 2] - UNIT_THOUGHT_BOUNDS[aThought, 1];
  for I := 1 to 30 do
  begin
    if I <= animLoop.Count then
      animLoop.Step[I] := UNIT_THOUGHT_BOUNDS[aThought, 2] - (I-1) // Thought bubbles are animated in reverse
    else
      animLoop.Step[I] := -1;
  end;

  InterpolateAnimNormal(rxUnits, animLoop, animLoop, False, False, False, False, $FFFFFF, aDryRun);
end;


procedure TForm1.ProcessTree(aTree: Integer; aDryRun: Boolean);
var
  animLoop: TKMAnimLoop;
  animPace: Integer;
begin
  if fPicOffset < seTreesResumeFrom.Value then
    aDryRun := True;

  animLoop := gMapElements[aTree].Anim;

  if (animLoop.Count <= 1) or (animLoop.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  animPace := GetAnimPace(animLoop);
  if (animPace = 2) or (animPace = 3) or (animPace = 4) then
  begin
    InterpolateAnimSlow(rxTrees, animLoop, aDryRun, $0);
  end
  else
    InterpolateAnimNormal(rxTrees, animLoop, animLoop, False, False, False, True, $000000, aDryRun);
end;


procedure TForm1.ProcessHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; aDryRun: Boolean);
var
  animLoop, animLoopBase: TKMAnimLoop;
  useBase: Boolean;
  simpleAlpha, simpleShadows: Boolean;
  I, Step, SubStep: Integer;
begin
  if fPicOffset < seHousesResumeFrom.Value then
    aDryRun := True;

  animLoop := fResHouses[aHT].Anim[aHouseAct];

  if (animLoop.Count <= 1) or (animLoop.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  //School clock shouldn't be interpolated, it's supposed to tick
  if (aHT = htSchool) and (aHouseAct in [haWork1..haWork5]) then
  begin
    for Step := 1 to 30 do
      for SubStep := 1 to INTERPOLATION_MULTIPLIER do
        fOutputStream.Write(Integer(animLoop.Step[Step] + 1));

    Exit;
  end;

  animLoopBase.Count := 30;
  animLoopBase.MoveX := 0;
  animLoopBase.MoveY := 0;
  for I := Low(animLoopBase.Step) to High(animLoopBase.Step) do
    animLoopBase.Step[I] := fResHouses[aHT].StonePic;

  useBase := aHouseAct in [haIdle, haWork1..haWork5];
  simpleAlpha := aHouseAct in [haSmoke, haFire1..haFire8];
  simpleShadows := not (aHouseAct in [haSmoke, haFire1..haFire8]);

  //Hard coded rules
  if aHT in [htArmorWorkshop, htStables, htWatchTower, htFishermans, htWoodcutters, htWatchTower, htTannery] then
    useBase := False;

  if (aHT = htButchers) and (aHouseAct = haIdle) then
  begin
    InterpolateAnimSlow(rxHouses, animLoop, aDryRun, $0);
    Exit;
  end;

  InterpolateAnimNormal(rxHouses, animLoop, animLoopBase, useBase and USE_BASE_HOUSE_ACT, False, simpleAlpha, simpleShadows, $000000, aDryRun);
end;


procedure TForm1.ProcessBeast(aBeastHouse, aBeast, aBeastAge: Integer; aDryRun: Boolean);
var
  animLoop, animLoopBase: TKMAnimLoop;
  I: Integer;
const
  HOUSE_LOOKUP: array[1..3] of TKMHouseType = (htSwine, htStables, htMarket);
begin
  if fPicOffset < seHousesResumeFrom.Value then
    aDryRun := True;

  if (aBeastHouse = 3) and ((aBeast > 3) or (aBeastAge <> 1)) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  animLoop := fResHouses.BeastAnim[HOUSE_LOOKUP[aBeastHouse], aBeast, aBeastAge];

  animLoopBase.Count := 30;
  animLoopBase.MoveX := 0;
  animLoopBase.MoveY := 0;
  for I := Low(animLoopBase.Step) to High(animLoopBase.Step) do
    animLoopBase.Step[I] := fResHouses[HOUSE_LOOKUP[aBeastHouse]].StonePic;

  if (animLoop.Count <= 1) or (animLoop.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  InterpolateAnimNormal(rxHouses, animLoop, animLoopBase, USE_BASE_BEASTS, False, False, True, $000000, aDryRun);
end;


procedure TForm1.LogError(const aText: string);
begin
  memoLog.Lines.Append('ERROR: ' + aText);
end;


procedure TForm1.LogInfo(const aText: string);
begin
  if cbLogVerbose.Checked then
    memoLog.Lines.Append(aText);
end;


procedure TForm1.btnProcessClick(Sender: TObject);
const
  UNITS_RX_OFFSET = 9300;
  TREES_RX_OFFSET = 260;
  HOUSES_RX_OFFSET = 2100;
begin
  if not DirectoryExists(fFolderDain) then
  begin
    LogError(Format('DAIN folder "%s" not found', [fFolderDain]));
    Exit;
  end;

  // Run everything in thread to have responsive UI
  btnProcess.Enabled := False;
  TThread.CreateAnonymousThread(
    procedure
    begin
      SetLength(fInterpCache, 0);

      FreeAndNil(fOutputStream);
      fOutputStream := TKMemoryStreamBinary.Create;

      Memo1.Lines.Append('type');
      Memo1.Lines.Append('  TKMInterpolation = array[1..30, 0..7] of Integer;');

      fPicOffset := UNITS_RX_OFFSET;
      ProcessAllUnitActions;
      ProcessAllSerfCarry;
      ProcessAllUnitThoughts;

      Memo1.Lines.Append('');
      Memo1.Lines.Append('');

      fPicOffset := TREES_RX_OFFSET;

      ProcessAllTrees;

      Memo1.Lines.Append('');
      Memo1.Lines.Append('');

      fPicOffset := HOUSES_RX_OFFSET;

      ProcessAllHouses;

      ProcessAllHouseBeasts;

      fOutputStream.SaveToFile(ExeDir+'data/defines/interp.dat');

      btnProcess.Enabled := True;
    end).Start;
end;


procedure TForm1.ProcessAllUnitActions;
var
  startPos: Integer;
  dir: TKMDirection;
  act: TKMUnitActionType;
  u: TKMUnitType;
begin
  fOutputStream.WriteA('UnitAction');

  Memo1.Lines.Append('  TKMUnitActionInterp = array[TKMUnitType, UNIT_ACT_MIN..UNIT_ACT_MAX, dirN..dirNW] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMUnitActionInterp) = '+IntToStr(SizeOf(TKMUnitActionInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  startPos := fOutputStream.Position;
  for u := UNIT_MIN to UNIT_MAX do
    for act := UNIT_ACT_MIN to UNIT_ACT_MAX do
      for dir := dirN to dirNW do
        try
          ChangeStatus(Format('UnitAction %d/%d %d/%d %d/%d', [Ord(u), Ord(UNIT_MAX), Ord(act), Ord(UNIT_ACT_MAX), Ord(dir), Ord(dirNW)]));
          ProcessUnit(u, act, dir, not chkUnitActions.Checked);
        except
          on E: Exception do
            LogError(TRttiEnumerationType.GetName(u) + ' - ' + UNIT_ACT_STR[act] + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message);
        end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMUnitActionInterp) = fOutputStream.Position - startPos);

  Memo1.Lines.Append('//fOutputStream.Position = '+IntToStr(fOutputStream.Position));
end;


procedure TForm1.ProcessAllSerfCarry;
var
  startPos: Integer;
  ware: TKMWareType;
  dir: TKMDirection;
begin
  fOutputStream.WriteA('SerfCarry ');

  Memo1.Lines.Append('TKMSerfCarryInterp = array[WARE_MIN..WARE_MAX, dirN..dirNW] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMSerfCarryInterp) = '+IntToStr(SizeOf(TKMSerfCarryInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  startPos := fOutputStream.Position;
  for ware := WARE_MIN to WARE_MAX do
    for dir := dirN to dirNW do
      try
        ChangeStatus(Format('SerfCarry %d/%d %d/%d', [Ord(ware), Ord(WARE_MAX), Ord(dir), Ord(dirNW)]));
        ProcessSerfCarry(ware, dir, not chkSerfCarry.Checked);
      except
        on E: Exception do
          LogError(TRttiEnumerationType.GetName(ware) + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message);
      end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMSerfCarryInterp) = fOutputStream.Position - startPos);
end;


procedure TForm1.ProcessAllUnitThoughts;
var
  startPos: Integer;
  th: TKMUnitThought;
begin
  fOutputStream.WriteA('UnitThoughts  ');

  Memo1.Lines.Append('  TKMUnitThoughtInterp = array[TKMUnitThought] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMUnitThoughtInterp) = '+IntToStr(SizeOf(TKMUnitThoughtInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  startPos := fOutputStream.Position;
  for th := Low(TKMUnitThought) to High(TKMUnitThought) do
    try
      ChangeStatus(Format('UnitThoughts %d/%d', [Ord(th), Ord(High(TKMUnitThought))]));
      ProcessUnitThought(th, not chkUnitThoughts.Checked);
    except
      on E: Exception do
        LogError(TRttiEnumerationType.GetName(th) + ' - ' + E.Message);
    end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMUnitThoughtInterp) = fOutputStream.Position - startPos);
end;


procedure TForm1.ProcessAllTrees;
var
  I, startPos: Integer;
begin
  ChangeStatus('Trees');
  fOutputStream.WriteA('Trees ');

  Memo1.Lines.Append('TKMTreeInterp = array[0..OBJECTS_CNT] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMTreeInterp) = '+IntToStr(SizeOf(TKMTreeInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  SetLength(fInterpCache, 0);

  startPos := fOutputStream.Position;
  for I := 0 to OBJECTS_CNT do
    try
      ChangeStatus(Format('Trees %d/%d', [I, OBJECTS_CNT]));
      ProcessTree(I, not chkTrees.Checked);
    except
      on E: Exception do
        LogError('Tree ' + IntToStr(I) + ' - ' + E.Message);
    end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMTreeInterp) = fOutputStream.Position - startPos);
end;


procedure TForm1.ProcessAllHouses;
var
  startPos: Integer;
  h: TKMHouseType;
  hAct: TKMHouseActionType;
begin
  SetLength(fInterpCache, 0);

  fOutputStream.WriteA('Houses');

  Memo1.Lines.Append('TKMHouseInterp = array[HOUSE_MIN..HOUSE_MAX, TKMHouseActionType] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMHouseInterp) = '+IntToStr(SizeOf(TKMHouseInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  startPos := fOutputStream.Position;
  for h := HOUSE_MIN to HOUSE_MAX do
    for hAct := Low(TKMHouseActionType) to High(TKMHouseActionType) do
      try
        ChangeStatus(Format('Houses %d/%d %d/%d', [Ord(h), Ord(HOUSE_MAX), Ord(hAct), Ord(High(TKMHouseActionType))]));
        ProcessHouseAction(h, hAct, not chkHouseActions.Checked);
      except
        on E: Exception do
          LogError(TRttiEnumerationType.GetName(h) + ' - ' + TRttiEnumerationType.GetName(hAct) + ' - ' + E.Message);
      end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMHouseInterp) = fOutputStream.Position - startPos);
end;


procedure TForm1.ProcessAllHouseBeasts;
var
  startPos: Integer;
  beastHouse, beast, beastAge: Integer;
begin
  fOutputStream.WriteA('Beasts');

  Memo1.Lines.Append('TKMBeastInterp = array[1..3,1..5,1..3] of TKMInterpolation;');
  Memo1.Lines.Append('//SizeOf(TKMBeastInterp) = '+IntToStr(SizeOf(TKMBeastInterp)));
  Memo1.Lines.Append('//PicOffset from ' + IntToStr(fPicOffset));

  startPos := fOutputStream.Position;
  for beastHouse := 1 to 3 do
    for beast := 1 to 5 do
      for beastAge := 1 to 3 do
        try
          ChangeStatus(Format('Beasts %d/%d %d/%d %d/%d', [beastHouse, 3, beast, 5, beastAge, 3]));
          ProcessBeast(beastHouse, beast, beastAge, not chkBeasts.Checked);
        except
          on E: Exception do
            LogError(' beast ' + IntToStr(beastHouse) + ' - ' + IntToStr(beast) + ' - ' + IntToStr(beastAge) + ' - ' + E.Message);
        end;
  Memo1.Lines.Append('//PicOffset to ' + IntToStr(fPicOffset));
  Assert(SizeOf(TKMBeastInterp) = fOutputStream.Position - startPos);
end;


end.
