unit KM_ResWares;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_CommonClasses;

  //Collection of types and arrays for Wares usage

type
  TKMWareType = (
    wtNone,
    wtTrunk,   wtStone,   wtWood,        wtIronOre,   wtGoldOre,
    wtCoal,    wtSteel,   wtGold,        wtWine,      wtCorn,
    wtBread,   wtFlour,   wtLeather,     wtSausages,  wtPig,
    wtSkin,    wtShield,  wtMetalShield, wtArmor,     wtMetalArmor,
    wtAxe,     wtSword,   wtPike,        wtHallebard, wtBow,
    wtArbalet, wtHorse,   wtFish,
    wtAll,     wtWarfare, wtFood //Special ware types
  );

  TKMWare = class
  private
    fType: TKMWareType;
    fMarketPrice: Single;
    fMarketPriceMultiplier: Single;
    function GetGUIIcon: Word;
    function GetTextID: Integer;
    function GetTitle: UnicodeString;
    function GetGUIColor: Cardinal;
    function GetMarketPrice: Single;
    procedure SetMarketPriceMultiplier(aValue: Single);
  public
    constructor Create(aType: TKMWareType);
    function IsValid: Boolean;
    property GUIColor: Cardinal read GetGUIColor;
    property GUIIcon: Word read GetGUIIcon;
    property MarketPriceMultiplier: Single read fMarketPriceMultiplier write SetMarketPriceMultiplier;
    property MarketPrice: Single read GetMarketPrice;
    property Title: UnicodeString read GetTitle;
    property TextID: Integer read GetTextID;
  end;

  TKMResWares = class
  private
    fList: array [TKMWareType] of TKMWare;
    procedure CalculateCostsTable;
    function GetWare(aIndex: TKMWareType): TKMWare;
  public
    constructor Create;
    destructor Destroy; override;
    property Wares[aIndex: TKMWareType]: TKMWare read GetWare; default;
    procedure ExportCostsTable(const aFilename: string);

    procedure ResetToDefaults;

    procedure SaveCustomData(aSaveStream: TKMemoryStream);
    procedure LoadCustomData(aLoadStream: TKMemoryStream);
  end;


const
  WARE_MIN = wtTrunk;
  WARE_MAX = wtFish;
  WARFARE_MIN = wtShield;
  WEAPON_MIN = wtShield;
  WEAPON_MAX = wtArbalet;
  WARFARE_MAX = wtHorse;

  WARE_CNT = Integer(WARE_MAX) - Integer(WARE_MIN) + 1;
  WARFARE_CNT = Integer(WARFARE_MAX) - Integer(WEAPON_MIN) + 1;

  WARFARE_IRON = [wtMetalShield, wtMetalArmor, wtSword, wtHallebard, wtArbalet];

  MARKET_TRADEOFF_FACTOR = 2.2; //X resources buys 1 resource of equal value

  WareTypeToIndex: array [TKMWareType] of byte = (0, //rtNone
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27,
    0, 0, 0); //rtAll, rtWarfare, rtFood

  RES_COUNT = 28;
  WareIndexToType: array [0..RES_COUNT-1] of TKMWareType = (
    wtTrunk, wtStone, wtWood, wtIronOre, wtGoldOre,
    wtCoal, wtSteel, wtGold, wtWine, wtCorn,
    wtBread, wtFlour, wtLeather, wtSausages, wtPig,
    wtSkin, wtShield, wtMetalShield, wtArmor, wtMetalArmor,
    wtAxe, wtSword, wtPike, wtHallebard, wtBow,
    wtArbalet, wtHorse, wtFish);

  ORE_MAX_TYPES_CNT = 5; //Maximum number of ore tiles types


  //Aligned to right to use them in GUI costs display as well
  WarfareCosts: array [WEAPON_MIN..WEAPON_MAX, 1..2] of TKMWareType = (
    (wtNone,   wtWood), //rtShield
    (wtCoal,  wtSteel), //rtMetalShield
    (wtNone,wtLeather), //rtArmor
    (wtCoal,  wtSteel), //rtMetalArmor
    (wtWood,   wtWood), //rtAxe
    (wtCoal,  wtSteel), //rtSword
    (wtWood,   wtWood), //rtPike
    (wtCoal,  wtSteel), //rtHallebard
    (wtWood,   wtWood), //rtBow
    (wtCoal,  wtSteel)  //rtArbalet
  );

  //How many of resource gets produced per minute on AVERAGE
  //Measured on a test map RES_COUNT / TIME in minutes
  ProductionRate: array [WARE_MIN..WARE_MAX] of Single = (
     88/120, 414/120, 390/120, 160/120, 160/120,
    155/120, 218/120, 330/120, 120/120, 138/120,
    336/120, 162/120, 324/120, 510/120,  84/180,
     84/180, 180/120, 155/120, 180/120, 155/120,
    200/120, 195/120, 200/120, 195/120, 200/120,
    195/120,  69/120, 122/120);

  //How much time it takes from owner taking a house till stable production
  //1 minute on average for the time it takes to process input into output
  //Some wares need extra time to grow (e.g. Horses) and some
  //depend on environment supply (e.g. Trunks)
  //Trunks 1-15
  //Wine 1-8
  //Corn 1-11
  //Pigs 6
  //Skins 6
  //Horses 6
  ProductionLag: array [WARE_MIN..WARE_MAX] of Byte = (
     6, 1, 1, 1, 1,
     1, 1, 1, 4, 5,
     1, 1, 1, 1, 6,
     6, 1, 1, 1, 1,
     1, 1, 1, 1, 1,
     1, 6, 1);


implementation
uses
  Math, KM_ResTexts;


{ TKMWare }
constructor TKMWare.Create(aType: TKMWareType);
begin
  inherited Create;

  fMarketPriceMultiplier := 1;

  fType := aType;
end;


function TKMWare.GetGUIColor: Cardinal;
const
  //Resources colors for Results charts
  //Made by naospor from kamclub.ru
  WareColor: array [WARE_MIN..WARE_MAX] of Cardinal = (
    $004080, $BFBFBF, $0080BF, $BF4040, $00FFFF,
    $606060, $BF0000, $00BFFF, $000080, $80FFFF,
    $80BFFF, $FFFFFF, $4040BF, $0000FF, $0040BF,
    $008080, $00BF00, $00FF7F, $FFBF00, $BF0080,
    $FF0040, $00FF40, $FFFF40, $FF0080, $FFFF80,
    $101080, $0080FF, $FFBF00);
begin
  Result := WareColor[fType];
end;


function TKMWare.GetMarketPrice: Single;
begin
  Result := fMarketPrice * fMarketPriceMultiplier;
end;


procedure TKMWare.SetMarketPriceMultiplier(aValue: Single);
begin
  fMarketPriceMultiplier := EnsureRange(aValue, 0.01, 100);
end;


function TKMWare.GetGUIIcon: Word;
begin
  case fType of
    WARE_MIN..WARE_MAX: Result := 351 + WareTypeToIndex[fType];
    wtAll:             Result := 657;
    wtWarfare:         Result := 658;
    wtFood:            Result := 659;
  else
    Result := 41; // "Question mark"
  end;
end;


function TKMWare.GetTextID: Integer;
begin
  case fType of
    WARE_MIN..WARE_MAX: Result := TX_RESOURCES_NAMES__27 + WareTypeToIndex[fType];
    wtAll:             Result := TX_RESOURCES_ALL;
    wtWarfare:         Result := TX_RESOURCES_WARFARE;
    wtFood:            Result := TX_RESOURCES_FOOD;
  else
    Result := -1;
  end;
end;


function TKMWare.GetTitle: UnicodeString;
begin
  if GetTextID <> -1 then
    Result := gResTexts[GetTextID]
  else
    Result := 'N/A';
end;


function TKMWare.IsValid: Boolean;
begin
  Result := fType in [WARE_MIN..WARE_MAX];
end;


{ TKMResWares }
constructor TKMResWares.Create;
var
  I: TKMWareType;
begin
  inherited;

  for I := Low(TKMWareType) to High(TKMWareType) do
    fList[I] := TKMWare.Create(I);

  // Calcuate the trade costs for marketplace once
  CalculateCostsTable;
end;


destructor TKMResWares.Destroy;
var
  I: TKMWareType;
begin
  for I := Low(TKMWareType) to High(TKMWareType) do
    fList[I].Free;

  inherited;
end;


function TKMResWares.GetWare(aIndex: TKMWareType): TKMWare;
begin
  Result := fList[aIndex];
end;


procedure TKMResWares.ResetToDefaults;
var
  I: TKMWareType;
begin
  for I := Low(TKMWareType) to High(TKMWareType) do
    fList[I].fMarketPriceMultiplier := 1;
end;


procedure TKMResWares.SaveCustomData(aSaveStream: TKMemoryStream);
var
  I: TKMWareType;
begin
  for I := Low(TKMWareType) to High(TKMWareType) do
    aSaveStream.Write(fList[I].fMarketPriceMultiplier);
end;


procedure TKMResWares.LoadCustomData(aLoadStream: TKMemoryStream);
var
  I: TKMWareType;
begin
  for I := Low(TKMWareType) to High(TKMWareType) do
    aLoadStream.Read(fList[I].fMarketPriceMultiplier);
end;


// Export costs table for analysis in human-friendly form
procedure TKMResWares.ExportCostsTable(const aFilename: string);
var
  SL: TStringList;
  I: TKMWareType;
begin
  SL := TStringList.Create;
  try
    for I := WARE_MIN to WARE_MAX do
      SL.Add(fList[I].GetTitle + #9 + #9 + FloatToStr(fList[I].fMarketPrice));

    SL.SaveToFile(aFilename);
  finally
    SL.Free;
  end;
end;


procedure TKMResWares.CalculateCostsTable;
const
  NON_RENEW = 1.25; //Non-renewable resources are more valuable than renewable ones
  TREE_ADDN = 0.15; //Trees require a large area (e.g. compared to corn)
  WINE_ADDN = 0.1; //Wine takes extra wood to build
  ORE_ADDN = 0.2; //You can only build a few iron/gold mines on most maps (compared to coal)
begin
  //Take advantage of the fact that we have both classes in same unit
  //and assign to private field directly
  Wares[wtTrunk      ].fMarketPrice := (1/ProductionRate[wtTrunk]) + TREE_ADDN;
  Wares[wtStone      ].fMarketPrice := NON_RENEW*(1/ProductionRate[wtStone]);
  Wares[wtWood       ].fMarketPrice := (1/ProductionRate[wtWood]) + (1/2)*Wares[wtTrunk].MarketPrice;
  Wares[wtIronOre    ].fMarketPrice := NON_RENEW*(1/ProductionRate[wtIronOre]) + ORE_ADDN;
  Wares[wtGoldOre    ].fMarketPrice := NON_RENEW*(1/ProductionRate[wtGoldOre]) + ORE_ADDN;
  Wares[wtCoal       ].fMarketPrice := NON_RENEW*(1/ProductionRate[wtCoal]);
  Wares[wtSteel      ].fMarketPrice := (1/ProductionRate[wtSteel]) + Wares[wtIronOre].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtGold       ].fMarketPrice := (1/ProductionRate[wtGold]) + (1/2)*(Wares[wtGoldOre].MarketPrice + Wares[wtCoal].MarketPrice);
  Wares[wtWine       ].fMarketPrice := (1/ProductionRate[wtWine]) + WINE_ADDN;
  Wares[wtCorn       ].fMarketPrice := (1/ProductionRate[wtCorn]);
  Wares[wtFlour      ].fMarketPrice := (1/ProductionRate[wtFlour]) + Wares[wtCorn].MarketPrice;
  Wares[wtBread      ].fMarketPrice := (1/ProductionRate[wtBread]) + (1/2)*Wares[wtFlour].MarketPrice;
  Wares[wtPig        ].fMarketPrice := (1/ProductionRate[wtPig]) + (1/2)*4*Wares[wtCorn].MarketPrice; //1/2 because two products are made simultaneously
  Wares[wtSkin       ].fMarketPrice := (1/ProductionRate[wtSkin]) + (1/2)*4*Wares[wtCorn].MarketPrice; //1/2 because two products are made simultaneously
  Wares[wtLeather    ].fMarketPrice := (1/ProductionRate[wtLeather]) + (1/2)*Wares[wtSkin].MarketPrice;
  Wares[wtSausages   ].fMarketPrice := (1/ProductionRate[wtSausages]) + (1/3)*Wares[wtPig].MarketPrice;
  Wares[wtShield     ].fMarketPrice := (1/ProductionRate[wtShield]) + Wares[wtWood].MarketPrice;
  Wares[wtMetalShield].fMarketPrice := (1/ProductionRate[wtMetalShield]) + Wares[wtSteel].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtArmor      ].fMarketPrice := (1/ProductionRate[wtArmor]) + Wares[wtLeather].MarketPrice;
  Wares[wtMetalArmor ].fMarketPrice := (1/ProductionRate[wtMetalArmor]) + Wares[wtSteel].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtAxe        ].fMarketPrice := (1/ProductionRate[wtAxe]) + 2*Wares[wtWood].MarketPrice;
  Wares[wtSword      ].fMarketPrice := (1/ProductionRate[wtSword]) + Wares[wtSteel].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtPike       ].fMarketPrice := (1/ProductionRate[wtPike]) + 2*Wares[wtWood].MarketPrice;
  Wares[wtHallebard  ].fMarketPrice := (1/ProductionRate[wtHallebard]) + Wares[wtSteel].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtBow        ].fMarketPrice := (1/ProductionRate[wtBow]) + 2*Wares[wtWood].MarketPrice;
  Wares[wtArbalet    ].fMarketPrice := (1/ProductionRate[wtArbalet]) + Wares[wtSteel].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtHorse      ].fMarketPrice := (1/ProductionRate[wtHorse]) + 4*Wares[wtCorn].MarketPrice;
  Wares[wtFish       ].fMarketPrice := NON_RENEW*(1/ProductionRate[wtFish]);
end;


end.
