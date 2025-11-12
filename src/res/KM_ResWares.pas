unit KM_ResWares;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, KM_CommonClasses,
  KM_ResTypes;

type
  // Ware type specification
  TKMWareSpec = class
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
    fList: array [TKMWareType] of TKMWareSpec;
    procedure CalculateMarketPrice;
    function GetWare(aIndex: TKMWareType): TKMWareSpec;
  public
    constructor Create;
    destructor Destroy; override;
    property Wares[aIndex: TKMWareType]: TKMWareSpec read GetWare; default;
    procedure ExportCostsTable(const aFilename: string);

    procedure ResetToDefaults;

    procedure SaveCustomData(aSaveStream: TKMemoryStream);
    procedure LoadCustomData(aLoadStream: TKMemoryStream);
  end;


const
  MARKET_TRADEOFF_FACTOR = 2.2; //X resources buys 1 resource of equal value

  WARE_TY_TO_ID: array [TKMWareType] of byte = (0, //rtNone
    0, 1, 2, 3, 4, 5, 6, 7, 8, 9, 10,
    11, 12, 13, 14, 15, 16, 17, 18, 19, 20, 21,
    22, 23, 24, 25, 26, 27,
    0, 0, 0); //rtAll, rtWarfare, rtFood

  RES_COUNT = 28;
  WARE_ID_TO_TYPE: array [0..RES_COUNT-1] of TKMWareType = (
    wtTrunk, wtStone, wtTimber, wtIronOre, wtGoldOre,
    wtCoal, wtIron, wtGold, wtWine, wtCorn,
    wtBread, wtFlour, wtLeather, wtSausage, wtPig,
    wtSkin, wtWoodenShield, wtIronShield, wtLeatherArmor, wtIronArmor,
    wtAxe, wtSword, wtLance, wtPike, wtBow,
    wtCrossbow, wtHorse, wtFish);

  ORE_DENSITY_MAX_TYPES = 5; // How many different ore densities there are


  //Aligned to right to use them in GUI costs display as well
  WARFARE_COSTS: array [WEAPON_MIN..WEAPON_MAX, 1..2] of TKMWareType = (
    (wtNone,   wtTimber), //rtShield
    (wtCoal,  wtIron), //rtMetalShield
    (wtNone,wtLeather), //rtArmor
    (wtCoal,  wtIron), //rtMetalArmor
    (wtTimber,   wtTimber), //rtAxe
    (wtCoal,  wtIron), //rtSword
    (wtTimber,   wtTimber), //rtPike
    (wtCoal,  wtIron), //rtHallebard
    (wtTimber,   wtTimber), //rtBow
    (wtCoal,  wtIron)  //rtArbalet
  );

  //How many of resource gets produced per minute on AVERAGE
  //Measured on a test map RES_COUNT / TIME in minutes
  PRODUCTION_RATE: array [WARE_MIN..WARE_MAX] of Single = (
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
  PRODUCTION_LAG: array [WARE_MIN..WARE_MAX] of Byte = (
     6, 1, 1, 1, 1,
     1, 1, 1, 4, 5,
     1, 1, 1, 1, 6,
     6, 1, 1, 1, 1,
     1, 1, 1, 1, 1,
     1, 6, 1);


implementation
uses
  Math, KM_ResTexts;


{ TKMWareSpec }
constructor TKMWareSpec.Create(aType: TKMWareType);
begin
  inherited Create;

  fMarketPriceMultiplier := 1;

  fType := aType;
end;


function TKMWareSpec.GetGUIColor: Cardinal;
const
  //Resources colors for Results charts
  //Made by naospor from kamclub.ru
  WARE_COLOR: array [WARE_MIN..WARE_MAX] of Cardinal = (
    $004080, $BFBFBF, $0080BF, $BF4040, $00FFFF,
    $606060, $BF0000, $00BFFF, $000080, $80FFFF,
    $80BFFF, $FFFFFF, $4040BF, $0000FF, $0040BF,
    $008080, $00BF00, $00FF7F, $FFBF00, $BF0080,
    $FF0040, $00FF40, $FFFF40, $FF0080, $FFFF80,
    $101080, $0080FF, $FFBF00);
begin
  Result := WARE_COLOR[fType];
end;


function TKMWareSpec.GetMarketPrice: Single;
begin
  Result := fMarketPrice * fMarketPriceMultiplier;
end;


procedure TKMWareSpec.SetMarketPriceMultiplier(aValue: Single);
begin
  fMarketPriceMultiplier := EnsureRange(aValue, 0.01, 100);
end;


function TKMWareSpec.GetGUIIcon: Word;
begin
  case fType of
    WARE_MIN..WARE_MAX: Result := 351 + WARE_TY_TO_ID[fType];
    wtAll:             Result := 657;
    wtWarfare:         Result := 658;
    wtFood:            Result := 659;
  else
    Result := 41; // "Question mark"
  end;
end;


function TKMWareSpec.GetTextID: Integer;
begin
  case fType of
    WARE_MIN..WARE_MAX: Result := TX_RESOURCES_NAMES__27 + WARE_TY_TO_ID[fType];
    wtAll:             Result := TX_RESOURCES_ALL;
    wtWarfare:         Result := TX_RESOURCES_WARFARE;
    wtFood:            Result := TX_RESOURCES_FOOD;
  else
    Result := -1;
  end;
end;


function TKMWareSpec.GetTitle: UnicodeString;
begin
  if GetTextID <> -1 then
    Result := gResTexts[GetTextID]
  else
    Result := 'N/A';
end;


function TKMWareSpec.IsValid: Boolean;
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
    fList[I] := TKMWareSpec.Create(I);

  // Calcuate the trade costs for marketplace once
  CalculateMarketPrice;
end;


destructor TKMResWares.Destroy;
var
  I: TKMWareType;
begin
  for I := Low(TKMWareType) to High(TKMWareType) do
    fList[I].Free;

  inherited;
end;


function TKMResWares.GetWare(aIndex: TKMWareType): TKMWareSpec;
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
  aSaveStream.PlaceMarker('WaresCustomData');
  for I := Low(TKMWareType) to High(TKMWareType) do
    aSaveStream.Write(fList[I].fMarketPriceMultiplier);
end;


procedure TKMResWares.LoadCustomData(aLoadStream: TKMemoryStream);
var
  I: TKMWareType;
begin
  aLoadStream.CheckMarker('WaresCustomData');
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


procedure TKMResWares.CalculateMarketPrice;
const
  NON_RENEW = 1.25; // Non-renewable resources are more valuable than renewable ones
  TREE_ADDN = 0.15; // Trees require a large area (e.g. compared to corn)
  WINE_ADDN = 0.1;  // Wine takes extra wood to build
  IRON_ORE_ADDN = 0.2;   // You can only build a few iron/gold mines on most maps (compared to coal)
  GOLD_ORE_ADDN = 0.3;   // gold ore needs higher price, to balance popular Town Hall trades
begin
  // We have both classes in the same unit and can assign to private field directly
  Wares[wtTrunk       ].fMarketPrice := 1/PRODUCTION_RATE[wtTrunk       ] + TREE_ADDN;
  Wares[wtStone       ].fMarketPrice := 1/PRODUCTION_RATE[wtStone       ] * NON_RENEW;
  Wares[wtTimber      ].fMarketPrice := 1/PRODUCTION_RATE[wtTimber      ] + (1/2)*Wares[wtTrunk].MarketPrice;
  Wares[wtIronOre     ].fMarketPrice := 1/PRODUCTION_RATE[wtIronOre     ] * NON_RENEW + IRON_ORE_ADDN;
  Wares[wtGoldOre     ].fMarketPrice := 1/PRODUCTION_RATE[wtGoldOre     ] * NON_RENEW + GOLD_ORE_ADDN;
  Wares[wtCoal        ].fMarketPrice := 1/PRODUCTION_RATE[wtCoal        ] * NON_RENEW;
  Wares[wtIron        ].fMarketPrice := 1/PRODUCTION_RATE[wtIron        ] + Wares[wtIronOre].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtGold        ].fMarketPrice := 1/PRODUCTION_RATE[wtGold        ] + (1/2)*(Wares[wtGoldOre].MarketPrice + Wares[wtCoal].MarketPrice);
  Wares[wtWine        ].fMarketPrice := 1/PRODUCTION_RATE[wtWine        ] + WINE_ADDN;
  Wares[wtCorn        ].fMarketPrice := 1/PRODUCTION_RATE[wtCorn        ];
  Wares[wtFlour       ].fMarketPrice := 1/PRODUCTION_RATE[wtFlour       ] + Wares[wtCorn].MarketPrice;
  Wares[wtBread       ].fMarketPrice := 1/PRODUCTION_RATE[wtBread       ] + (1/2)*Wares[wtFlour].MarketPrice;
  Wares[wtPig         ].fMarketPrice := 1/PRODUCTION_RATE[wtPig         ] + (1/2)*4*Wares[wtCorn].MarketPrice; //1/2 because two products are made simultaneously
  Wares[wtSkin        ].fMarketPrice := 1/PRODUCTION_RATE[wtSkin        ] + (1/2)*4*Wares[wtCorn].MarketPrice; //1/2 because two products are made simultaneously
  Wares[wtLeather     ].fMarketPrice := 1/PRODUCTION_RATE[wtLeather     ] + (1/2)*Wares[wtSkin].MarketPrice;
  Wares[wtSausage     ].fMarketPrice := 1/PRODUCTION_RATE[wtSausage     ] + (1/3)*Wares[wtPig].MarketPrice;
  Wares[wtWoodenShield].fMarketPrice := 1/PRODUCTION_RATE[wtWoodenShield] + Wares[wtTimber].MarketPrice;
  Wares[wtIronShield  ].fMarketPrice := 1/PRODUCTION_RATE[wtIronShield  ] + Wares[wtIron].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtLeatherArmor].fMarketPrice := 1/PRODUCTION_RATE[wtLeatherArmor] + Wares[wtLeather].MarketPrice;
  Wares[wtIronArmor   ].fMarketPrice := 1/PRODUCTION_RATE[wtIronArmor   ] + Wares[wtIron].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtAxe         ].fMarketPrice := 1/PRODUCTION_RATE[wtAxe         ] + 2*Wares[wtTimber].MarketPrice;
  Wares[wtSword       ].fMarketPrice := 1/PRODUCTION_RATE[wtSword       ] + Wares[wtIron].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtLance       ].fMarketPrice := 1/PRODUCTION_RATE[wtLance       ] + 2*Wares[wtTimber].MarketPrice;
  Wares[wtPike        ].fMarketPrice := 1/PRODUCTION_RATE[wtPike        ] + Wares[wtIron].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtBow         ].fMarketPrice := 1/PRODUCTION_RATE[wtBow         ] + 2*Wares[wtTimber].MarketPrice;
  Wares[wtCrossbow    ].fMarketPrice := 1/PRODUCTION_RATE[wtCrossbow    ] + Wares[wtIron].MarketPrice + Wares[wtCoal].MarketPrice;
  Wares[wtHorse       ].fMarketPrice := 1/PRODUCTION_RATE[wtHorse       ] + 4*Wares[wtCorn].MarketPrice;
  Wares[wtFish        ].fMarketPrice := 1/PRODUCTION_RATE[wtFish        ] * NON_RENEW;
end;


end.
