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
    { Private declarations }
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
    procedure MakeInterpImagesPair(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType);
    procedure MakeCustomInterpImages(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType);
    procedure DoInterp(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aBkgRGB: Cardinal; var aPicOffset: Integer; aDryRun: Boolean);
    procedure ProcessInterpImage(outIndex: Integer; inSuffixPath, outPrefixPath: string; aBkgRGB: Cardinal; OverallMaxX, OverallMinX, OverallMaxY, OverallMinY: Integer);
    procedure DoInterpUnit(aUT: TKMUnitType; aAction: TKMUnitActionType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpSerfCarry(aWare: TKMWareType; aDir: TKMDirection; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpUnitThought(aThought: TKMUnitThought; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpTree(aTree: Integer; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; var aPicOffset: Integer; aDryRun: Boolean);
    procedure DoInterpBeast(beastHouse, beast, beastAge: Integer; var aPicOffset: Integer; aDryRun: Boolean);
  public
    { Public declarations }
  end;

var
  Form1: TForm1;

implementation
uses
  ShellApi, Math, RTTI, KM_FileIO, KromUtils,
  KM_Log, KM_IoPNG, KM_ResWares, KM_ResInterpolation;

const
  USE_BASE_BEASTS = False;
  USE_BASE_HOUSE_ACT = True;
  CANVAS_Y_OFFSET = 14;

  //This is different to TKMUnitSpec.SupportsAction because we include any used
  //animations like uaWalkArm for soliders (flag) which isn't an action.
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

{$R *.dfm}


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
  DainExe := fDainFolder+'DAINAPP.exe';
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


procedure TForm1.MakeCustomInterpImages(aInterpCount: Integer; RT: TRXType; aID_1, aID_2: Integer; aBaseDir: string; aExportType: TInterpExportType);
var
  origSpritesDir, interpSpritesDir: string;
  I: Integer;
  NeedAlpha: Boolean;
  StartupInfo: TStartupInfo;
  ProcessInfo: TProcessInformation;
begin
  MakeInterpImagesPair(RT, aID_1, aID_2, -1, -1, 0, 0, False, aBaseDir, aExportType);

  origSpritesDir := aBaseDir + 'original_frames\';
  interpSpritesDir := aBaseDir + 'interpolated_frames\';

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


procedure TForm1.MakeInterpImagesPair(RT: TRXType; aID_1, aID_2, aID_1_Base, aID_2_Base: Integer; aBaseMoveX, aBaseMoveY: Integer; aUseBase: Boolean; aBaseDir: string; aExportType: TInterpExportType);
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
    fSprites[RT].LoadFromRXXFile(ExeDir + 'data\Sprites\' + RXInfo[RT].FileName + '_a.rxx');
  end;

  origSpritesDir := aBaseDir + 'original_frames\';
  interpSpritesDir := aBaseDir + 'interpolated_frames\';
  ForceDirectories(origSpritesDir);

  KMDeleteFolderContent(origSpritesDir);
  KMDeleteFolderContent(interpSpritesDir);

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

  Worked := fSprites[RT].ExportImageForInterp(origSpritesDir + '1.png', aID_1, aID_1_Base, aBaseMoveX, aBaseMoveY, aExportType, CanvasSize);
  AllBlank := AllBlank and not Worked;

  Worked := fSprites[RT].ExportImageForInterp(origSpritesDir + '2.png', aID_2, aID_2_Base, aBaseMoveX, aBaseMoveY, aExportType, CanvasSize);
  AllBlank := AllBlank and not Worked;

  if AllBlank then
    Exit;

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


procedure TForm1.DoInterp(RT: TRXType; A, ABase: TKMAnimLoop; aUseBase, aUseBaseForTeamMask, aSimpleAlpha: Boolean; aBkgRGB: Cardinal; var aPicOffset: Integer; aDryRun: Boolean);

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

  outDirLocal := fOutDir+IntToStr(Byte(RT)+1)+'\';
  outPrefix := outDirLocal+IntToStr(Byte(RT)+1)+'_';
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
      if (fInterpCache[I].A = StepSprite) and (fInterpCache[I].B = StepNextSprite) then
      begin
        for SubStep := 0 to 6 do
          fOutputStream.Write(fInterpCache[I].interpOffset+SubStep);

        Found := True;
      end
      //Check for a reversed sequence in the cache (animations often loop backwards)
      else if (fInterpCache[I].B = StepSprite) and (fInterpCache[I].A = StepNextSprite) then
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
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirBase, ietNormal)
    else
    begin
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirBase, ietBase);
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, True, dirShad, ietShadows);
      MakeInterpImagesPair(RT, StepSprite, StepNextSprite, StepSpriteBase, StepNextSpriteBase, BaseMoveX, BaseMoveY, aUseBaseForTeamMask, dirTeam, ietTeamMask);
    end;

    //Determine maximum bounds of the pair, to crop out the base background sprite
    //Expand by 1px in case the interpolation goes slightly outside the original bounds
    OverallMinX := Min(fSprites[RT].RXData.Pivot[StepSprite].X, fSprites[RT].RXData.Pivot[StepNextSprite].X) - 1;
    OverallMinY := Min(fSprites[RT].RXData.Pivot[StepSprite].Y, fSprites[RT].RXData.Pivot[StepNextSprite].Y) - 1;
    OverallMaxX := OverallMinX + Max(fSprites[RT].RXData.Size[StepSprite].X, fSprites[RT].RXData.Size[StepNextSprite].X) + 1;
    OverallMaxY := OverallMinY + Max(fSprites[RT].RXData.Size[StepSprite].Y, fSprites[RT].RXData.Size[StepNextSprite].Y) + 1;

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
  UseBase: Boolean;
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
  ABase := fResUnits[aUT].UnitAnim[uaWalk, aDir];

  DoInterp(rxUnits, A, ABase, UseBase, True, False, bkgRGB, aPicOffset, aDryRun);
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

  DoInterp(rxUnits, A, ABase, True, True, False, $000000, aPicOffset, aDryRun);
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

  DoInterp(rxUnits, A, A, False, False, False, $FFFFFF, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpTree(aTree: Integer; var aPicOffset: Integer; aDryRun: Boolean);

  function GetAnimSpeed(A: TKMAnimLoop): Integer;
  var
    I: Integer;
  begin
    Result := 1;
    while (Result < A.Count) and (A.Step[Result] = A.Step[Result+1]) do
      Inc(Result);
  end;

var
  A: TKMAnimLoop;
  S, Step, StepFull, SubStep, InterpOffset, StepSprite, StepNextSprite: Integer;
  suffixPath, outDirLocal, outPrefix: string;
begin
  A := gMapElements[aTree].Anim;

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  S := GetAnimSpeed(A);
  if (S = 2) or (S = 4) then
  begin
    //Custom handler for tree animations that only update every 4 frames
    outDirLocal := fOutDir+IntToStr(Byte(rxTrees)+1)+'\';
    outPrefix := outDirLocal+IntToStr(Byte(rxTrees)+1)+'_';
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

      Step := ((StepFull-1) div S) + 1;

      StepSprite := A.Step[StepFull] + 1;
      StepNextSprite := A.Step[(StepFull mod A.Count) + 1] + 1;

      fOutputStream.Write(StepSprite);

      InterpOffset := aPicOffset;
      //Update return values
      Inc(aPicOffset, 8*S - 1);
      for SubStep := 0 to (8*S - 2) do
        fOutputStream.Write(InterpOffset+SubStep);

      if aDryRun then
        Continue;

      MakeCustomInterpImages(S, rxTrees, StepSprite, StepNextSprite, fWorkDir+'base\', ietBase);
      MakeCustomInterpImages(S, rxTrees, StepSprite, StepNextSprite, fWorkDir+'shad\', ietShadows);
      for SubStep := 0 to (8*S - 2) do
      begin
        //Filenames are 1-based, and skip the first one since it's the original
        suffixPath := 'interpolated_frames\' + format('%.15d.png', [SubStep+1+1]);
        ProcessInterpImage(InterpOffset+SubStep, suffixPath, outPrefix, $0, 9999, -9999, 9999, -9999);
      end;
    end;
  end
  else
    DoInterp(rxTrees, A, A, False, False, False, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpHouseAction(aHT: TKMHouseType; aHouseAct: TKMHouseActionType; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  UseBase: Boolean;
  SimpleAlpha: Boolean;
  I: Integer;
begin
  A := fResHouses.HouseDat[aHT].Anim[aHouseAct];

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  ABase.Count := 30;
  ABase.MoveX := 0;
  ABase.MoveY := 0;
  for I := Low(ABase.Step) to High(ABase.Step) do
    ABase.Step[I] := fResHouses.HouseDat[aHT].StonePic;

  UseBase := aHouseAct in [haIdle, haWork1..haWork5];
  SimpleAlpha := aHouseAct in [haSmoke, haFire1..haFire8];

  DoInterp(rxHouses, A, ABase, UseBase and USE_BASE_HOUSE_ACT, False, SimpleAlpha, $000000, aPicOffset, aDryRun);
end;


procedure TForm1.DoInterpBeast(beastHouse, beast, beastAge: Integer; var aPicOffset: Integer; aDryRun: Boolean);
var
  A, ABase: TKMAnimLoop;
  I: Integer;
const
  HOUSE_LOOKUP: array[1..3] of TKMHouseType = (htSwine, htStables, htMarketplace);
begin
  if (beastHouse = 3) and ((beast > 3) or (beastAge <> 1)) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  A := fResHouses.BeastAnim[HOUSE_LOOKUP[beastHouse], beast, beastAge];

  ABase.Count := 30;
  ABase.MoveX := 0;
  ABase.MoveY := 0;
  for I := Low(ABase.Step) to High(ABase.Step) do
    ABase.Step[I] := fResHouses.HouseDat[HOUSE_LOOKUP[beastHouse]].StonePic;

  if (A.Count <= 1) or (A.Step[1] = -1) then
  begin
    WriteEmptyAnim;
    Exit;
  end;

  DoInterp(rxHouses, A, ABase, USE_BASE_BEASTS, False, False, $000000, aPicOffset, aDryRun);
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
  begin
    for act := UNIT_ACT_MIN to UNIT_ACT_MAX do
    begin
      for dir := dirN to dirNW do
      begin
        try
          DoInterpUnit(u, act, dir, picOffset, not chkUnitActions.Checked);
        except
          on E: Exception do
          begin
            memoErrors.Text := memoErrors.Text + TRttiEnumerationType.GetName(u) + ' - ' + UNIT_ACT_STR[act] + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message + #13#10;
          end;
        end;
      end;
    end;
  end;
  Assert(SizeOf(TKMUnitActionInterp) = fOutputStream.Position - startPos);

  animData := animData + '//fOutputStream.Position = '+IntToStr(fOutputStream.Position)+#13#10;

  fOutputStream.WriteA('SerfCarry ');

  animData := animData + 'TKMSerfCarryInterp = array[WARE_MIN..WARE_MAX, dirN..dirNW] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMSerfCarryInterp) = '+IntToStr(SizeOf(TKMSerfCarryInterp))+#13#10;

  startPos := fOutputStream.Position;
  for ware := WARE_MIN to WARE_MAX do
  begin
    for dir := dirN to dirNW do
    begin
      try
        DoInterpSerfCarry(ware, dir, picOffset, not chkSerfCarry.Checked);
      except
        on E: Exception do
        begin
          memoErrors.Text := memoErrors.Text + TRttiEnumerationType.GetName(ware) + ' - ' + TRttiEnumerationType.GetName(dir) + ' - ' + E.Message + #13#10;
        end;
      end;
    end;
  end;
  Assert(SizeOf(TKMSerfCarryInterp) = fOutputStream.Position - startPos);

  fOutputStream.WriteA('UnitThoughts  ');

  animData := animData + '  TKMUnitThoughtInterp = array[TKMUnitThought] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMUnitThoughtInterp) = '+IntToStr(SizeOf(TKMUnitThoughtInterp))+#13#10;

  startPos := fOutputStream.Position;
  for th := Low(TKMUnitThought) to High(TKMUnitThought) do
  begin
    try
      DoInterpUnitThought(th, picOffset, not chkUnitThoughts.Checked);
    except
      on E: Exception do
      begin
        memoErrors.Text := memoErrors.Text + TRttiEnumerationType.GetName(th) + ' - ' + E.Message + #13#10;
      end;
    end;
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
  begin
    try
      DoInterpTree(I, picOffset, not chkTrees.Checked);
    except
      on E: Exception do
      begin
        memoErrors.Text := memoErrors.Text + ' Tree ' + IntToStr(I) + ' - ' + E.Message + #13#10+'  ';
      end;
    end;
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
  begin
    for hAct := Low(TKMHouseActionType) to High(TKMHouseActionType) do
    begin
      try
        DoInterpHouseAction(h, hAct, picOffset, not chkHouseActions.Checked);
      except
        on E: Exception do
        begin
          memoErrors.Text := memoErrors.Text + TRttiEnumerationType.GetName(h) + ' - ' + TRttiEnumerationType.GetName(hAct) + ' - ' + E.Message + #13#10;
        end;
      end;
    end;
  end;
  Assert(SizeOf(TKMHouseInterp) = fOutputStream.Position - startPos);

  fOutputStream.WriteA('Beasts');

  animData := animData + #13#10 + #13#10;
  animData := animData + 'TKMBeastInterp = array[1..3,1..5,1..3] of TKMInterpolation;'+#13#10;
  animData := animData + '//SizeOf(TKMBeastInterp) = '+IntToStr(SizeOf(TKMBeastInterp))+#13#10;

  startPos := fOutputStream.Position;
  for beastHouse := 1 to 3 do
  begin
    for beast := 1 to 5 do
    begin
      for beastAge := 1 to 3 do
      begin
        try
          DoInterpBeast(beastHouse, beast, beastAge, picOffset, not chkBeasts.Checked);
        except
          on E: Exception do
          begin
            memoErrors.Text := memoErrors.Text + ' beast ' + IntToStr(beastHouse) + ' - ' + IntToStr(beast) + ' - ' + IntToStr(beastAge) + ' - ' + E.Message + #13#10;
          end;
        end;
      end;
    end;
  end;
  Assert(SizeOf(TKMBeastInterp) = fOutputStream.Position - startPos);

  fOutputStream.SaveToFile(ExeDir+'data/defines/interp.dat');
  Memo1.Text := animData;
end;

end.
