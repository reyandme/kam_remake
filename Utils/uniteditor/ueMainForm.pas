unit ueMainForm;

{$I uniteditor.inc}
{$IFDEF FPC}
  {$Mode Delphi} {$H+}
{$ENDIF}

interface

uses
  Windows, Messages,
  SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, StdCtrls, Menus, Spin,
  KM_ResUnits, KM_ResTypes, KM_CommonTypes, KM_Points;

type
  TAppState = (asWait, asView);

  UEUnitType = (
    utSerf,         utWoodcutter,   utMiner,         utAnimalBreeder, // Units
    utFarmer,       utCarpenter,    utBaker,         utButcher,
    utFisher,       utBuilder,      utStonemason,    utSmith,
    utMetallurgist, utRecruit,

    utMilitia,      utAxeFighter,   utSwordFighter,  utBowman,        // TSK Troops
    utCrossbowman,  utLanceCarrier, utPikeman,       utScout,
    utKnight,       utBarbarian,

    utRebel,        utRogue,        utWarrior,       utVagabond,      // TPR Troops

    utCatapult,     utBallista,                                       // Seige weapons

    utWolf,         utFish,         utWatersnake,    utSeastar,       // Animals
    utCrab,         utWaterflower,  utWaterleaf,     utDuck,

    utUnknown1,     utUnknown2,     utUnknown3                        // Padding/Unknown
  );

  UEUnitSpec = class
  private
    fUnitType: UEUnitType;
    fUnitDat: TKMUnitDat;
    fUnitSprite: TKMUnitSprite;
    fUnitSprite2: TKMUnitSprite2;
  public
    constructor Create(aType: UEUnitType);
    procedure LoadFromStream(Stream: TMemoryStream);
    procedure WriteToStream(Stream: TMemoryStream);
    //Derived from KaM
    property HitPoints: SmallInt read fUnitDat.HitPoints write fUnitDat.HitPoints;
    property Attack: SmallInt read fUnitDat.Attack write fUnitDat.Attack;
    property AttackHorse: SmallInt read fUnitDat.AttackHorse write fUnitDat.AttackHorse;
    property x4: SmallInt read fUnitDat.x4 write fUnitDat.x4;
    property Defence: SmallInt read fUnitDat.Defence write fUnitDat.Defence;
    property Speed: SmallInt read fUnitDat.Speed write fUnitDat.Speed;
    property x7: SmallInt read fUnitDat.x7 write fUnitDat.x7;
    property Sight: SmallInt read fUnitDat.Sight write fUnitDat.Sight;
    property x9: ShortInt read fUnitDat.x9 write fUnitDat.x9;
    property x10: ShortInt read fUnitDat.x10 write fUnitDat.x10;
    property CanWalkOut: SmallInt read fUnitDat.CanWalkOut write fUnitDat.CanWalkOut;
    property x11: SmallInt read fUnitDat.x11 write fUnitDat.x11;
  end;

  TMainForm = class(TForm)
    SaveDialog1: TSaveDialog;
    OpenDialog1: TOpenDialog;
    ListBox1: TListBox;
    btnOpen: TButton;
    btnSave: TButton;
    Label1: TLabel;
    lblOldCRC: TLabel;
    Label2: TLabel;
    lblNewCRC: TLabel;
    Label3: TLabel;
    seHitPoints: TSpinEdit;
    seAttack: TSpinEdit;
    Label4: TLabel;
    seAttackHorseBonus: TSpinEdit;
    Label5: TLabel;
    sex4: TSpinEdit;
    Label6: TLabel;
    seDefence: TSpinEdit;
    Label7: TLabel;
    seSpeed: TSpinEdit;
    Label8: TLabel;
    sex11: TSpinEdit;
    Label9: TLabel;
    seCanWalkOut: TSpinEdit;
    Label10: TLabel;
    sex10: TSpinEdit;
    Label11: TLabel;
    sex9: TSpinEdit;
    Label12: TLabel;
    seSight: TSpinEdit;
    Label13: TLabel;
    sex7: TSpinEdit;
    Label14: TLabel;
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
  published
    procedure FormCreate(Sender: TObject);
    procedure ChangeSpinEdits(Sender: TObject);
    procedure OpenFile(Sender: TObject);
    procedure ShowDAT(Sender: TObject);
    procedure SaveDAT(Sender: TObject);
  private
    fAppState:  TAppState;
    fItems:     array [UEUnitType] of UEUnitSpec;
    fSerfCarry: array [WARE_MIN..WARE_MAX, dirN..dirNW] of TKMAnimLoop;
    function LoadDATFile(aFilename: string): Cardinal;
    function SaveDATFile(aFilename: string): Cardinal;
  public
    { Public declarations }
  end;

var
  MainForm: TMainForm;

implementation
uses
  KromUtils, KM_CommonClasses;

{$IFDEF WDC}
  {$R ueMainForm.dfm}
{$ENDIF}

const
  // String representation of `KM_ResUnits.UNIT_ID_TO_TYPE`
  UnitNames: array[UEUnitType] of string = (
    'Serf',         'Woodcutter',    'Miner',         'Animal Breeder', // Units
    'Farmer',       'Carpenter',     'Baker',         'Butcher',
    'Fisherman',    'Laborer',       'Stonemason',    'Blacksmith',
    'Metallurgist', 'Recruit',

    'Militia',      'Axe Fighter',   'Sword Fighter', 'Bowman',         // TSK Troops
    'Crossbowman',  'Lance Carrier', 'Pikeman',       'Scout',
    'Knight',       'Barbarian',

    'Rebel',        'Rogue',         'Warrior',       'Vagabond',       // TPR Troops

    'Catapult',     'Ballista',                                         // Seige weapons

    'Wolf',         'Fish',          'Watersnake',    'Seastar',        // Animals
    'Crab',         'Waterflower',   'Waterleaf',     'Duck',

    'Unknown',      'Unknown',       'Unknown'                          // Padding/Unknown
  );

{ UEUnitSpec }

constructor UEUnitSpec.Create(aType: UEUnitType);
begin
  inherited Create;
  fUnitType := aType;
end;

procedure UEUnitSpec.LoadFromStream(Stream: TMemoryStream);
begin
  Stream.Read(fUnitDat, SizeOf(TKMUnitDat));
  Stream.Read(fUnitSprite, SizeOf(TKMUnitSprite));
  Stream.Read(fUnitSprite2, SizeOf(TKMUnitSprite2));
end;

procedure UEUnitSpec.WriteToStream(Stream: TMemoryStream);
begin
  Stream.Write(fUnitDat, SizeOf(TKMUnitDat));
  Stream.Write(fUnitSprite, SizeOf(TKMUnitSprite));
  Stream.Write(fUnitSprite2, SizeOf(TKMUnitSprite2));
end;


{ TMainForm }

procedure TMainForm.FormCreate(Sender: TObject);
var
  I: UEUnitType;
begin
  for I := Low(UEUnitType) to High(UEUnitType) do
  begin
    ListBox1.Items.Add(UnitNames[I]);
    fItems[I] := UEUnitSpec.Create(I);
  end;

  fAppState := asWait;
end;

procedure TMainForm.FormClose(Sender: TObject; var Action: TCloseAction);
var
  I: UEUnitType;
begin
  for I := Low(UEUnitType) to High(UEUnitType) do
    FreeAndNil(fItems[I]);
end;

procedure TMainForm.ChangeSpinEdits(Sender: TObject);
var
  id:      Integer;
  idTyped: UEUnitType;
begin
  if fAppState <> asWait then
    Exit;

  id := ListBox1.ItemIndex;

  if id < 0 then
    Exit;

  { X* items are read-only since we don't know what they do. }
  idTyped := UEUnitType(id);
  fItems[idTyped].HitPoints        := seHitPoints.Value;
  fItems[idTyped].Attack           := seAttack.Value;
  fItems[idTyped].AttackHorse      := seAttackHorseBonus.Value;
  // fItems[idTyped].x4               := sex4.Value;
  fItems[idTyped].Defence          := seDefence.Value;
  fItems[idTyped].Speed            := seSpeed.Value;
  // fItems[idTyped].x7               := sex7.Value;
  fItems[idTyped].Sight            := seSight.Value;
  // fItems[idTyped].x9               := sex9.Value;
  // fItems[idTyped].x10              := sex10.Value;
  fItems[idTyped].CanWalkOut       := seCanWalkOut.Value;
  // fItems[idTyped].x11              := sex11.Value;
end;

procedure TMainForm.OpenFile(Sender: TObject);
var
  crc: Cardinal;
begin
  if DirectoryExists('..\..\Data\Defines\') then
    OpenDialog1.InitialDir := '..\..\Data\Defines\'
  else
    OpenDialog1.InitialDir := '';

  if OpenDialog1.Execute then
  begin
    crc := LoadDATFile(OpenDialog1.Filename);
    lblOldCRC.Caption := UIntToStr(crc);
    SaveDialog1.InitialDir := OpenDialog1.GetNamePath;
  end;

  fAppState := asWait;
end;

procedure TMainForm.ShowDAT(Sender: TObject);
var
  id:      Integer;
  idTyped: UEUnitType;
begin
  id := ListBox1.ItemIndex;

  if id < 0 then
    Exit;

  idTyped := UEUnitType(id);
  fAppState := asView;
  seHitPoints.Value        := fItems[idTyped].HitPoints;
  seAttack.Value           := fItems[idTyped].Attack;
  seAttackHorseBonus.Value := fItems[idTyped].AttackHorse;
  sex4.Value               := fItems[idTyped].x4;
  seDefence.Value          := fItems[idTyped].Defence;
  seSpeed.Value            := fItems[idTyped].Speed;
  sex7.Value               := fItems[idTyped].x7;
  seSight.Value            := fItems[idTyped].Sight;
  sex9.Value               := fItems[idTyped].x9;
  sex10.Value              := fItems[idTyped].x10;
  seCanWalkOut.Value       := fItems[idTyped].CanWalkOut;
  sex11.Value              := fItems[idTyped].x11;
  fAppState := asWait;
end;

procedure TMainForm.SaveDAT(Sender: TObject);
var
  crc: Cardinal;
begin
  if SaveDialog1.Execute then
  begin
    crc := SaveDATFile(SaveDialog1.Filename);
    lblOldCRC.Caption := UIntToStr(crc);
  end;
end;


function TMainForm.LoadDATFile(aFilename: string): Cardinal;
var
  S: TKMemoryStream;
  I: UEUnitType;
begin
  Assert(FileExists(aFilename), 'unit.dat not found at: ' + aFilename);
  S := TKMemoryStreamBinary.Create;

  try
    S.LoadFromFile(aFilename);
    S.Read(fSerfCarry, SizeOf(fSerfCarry){28*8*70});

    for I := Low(UEUnitType) to High(UEUnitType) do
      fItems[I].LoadFromStream(S);

    Result := Adler32CRC(S);
  finally
    FreeAndNil(S);
  end;
end;

function TMainForm.SaveDATFile(aFilename: string): Cardinal;
var
  S: TKMemoryStream;
  I: UEUnitType;
begin
  S := TKMemoryStreamBinary.Create;

  try
    S.Write(fSerfCarry, SizeOf(fSerfCarry){28*8*70});

    for I := Low(UEUnitType) to High(UEUnitType) do
      fItems[I].WriteToStream(S);

    S.SaveToFile(aFilename);
    Result := Adler32CRC(S);
  finally
    FreeAndNil(S);
  end;
end;

end.
