unit KM_GUIGameSpectator;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  Classes, Math, StrUtils, SysUtils,
  KM_Controls, KM_HandsCollection, KM_Defaults, KromOGLUtils, KM_Hand, KM_Units,
  KM_ResWares, KM_ResHouses, KM_Pics, KM_CommonTypes, KM_Points, KM_Houses;


type
  TKMGUIGameSpectatorItem = class(TKMPanel)
  private
    fHandID: Integer;
    fImageID: Word;
    fValue: String;
    fAdditionalValue: String;
    fProgress: Single;
    fItemTag: Integer;
    fShowItem: Boolean;
    FOnItemClick: TIntBoolEvent;
    FDoHighlight: TBoolIntFuncSimple;
    procedure ItemClicked(Sender: TObject; Shift: TShiftState);
  protected
    Bevel: TKMBevel;
    Image: TKMImage;
    PercentBar: TKMPercentBar;
    Label_Text: TKMLabel;
    Label_AddText: TKMLabel;
  public
    constructor Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String; AHandID: Integer;
                       aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntBoolEvent);
    property ItemTag: Integer read FItemTag;
    property Value: String read FValue write FValue;
    property AdditionalValue: String read FAdditionalValue write FAdditionalValue;
    property Progress: Single read FProgress write FProgress;
    property ShowItem: Boolean read fShowItem write fShowItem;
    procedure CreateChilds;
    procedure PaintPanel(aPaintLayer: Integer); override;
  end;

  TKMGameSpectatorItemLinesAggregator = class
  private
    fItemsVisibility: array of Boolean;
    fCount: Integer;
    procedure ResetItems;
    procedure SetCount(aCount: Integer);
  end;

  TKMGUIGameSpectatorItemLine = class;
  TKMGUIGameSpectatorItemLineClass = class of TKMGUIGameSpectatorItemLine;

  TKMGUIGameSpectatorItemLine = class(TKMPanel)
  private
    fLinesAggregator: TKMGameSpectatorItemLinesAggregator;
    FOnJumpToPlayer: TIntegerEvent;
    FSetViewportPos: TPointFEvent;
    FHandIndex: Integer;
    FItems: array of TKMGUIGameSpectatorItem;
    procedure LineClicked(Sender: TObject);
    procedure LineItemClicked(aItemTag: Integer; aMainFunction: Boolean);
    procedure Update;
    procedure UpdateItemsVisibility;
    procedure CreateChilds;
  protected
    Bevel: TKMBevel;
    Image: TKMImage;
    Label_Text: TKMLabel;

    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; virtual; abstract;
    function GetTagCount: Integer; virtual; abstract;
    function GetTag(AIndex: Integer): Integer; virtual; abstract;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; virtual; abstract;
    function GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String; virtual;
    function GetProgress(AHandIndex: Integer; ATag: Integer): Single; virtual;
    function GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; virtual;
    property SetViewportPos: TPointFEvent read FSetViewportPos;
    function DontHighlight(aIndex: Integer): Boolean;
    function DoHighlight(aIndex: Integer): Boolean;
  public
    constructor Create(aParent: TKMPanel; AHandIndex: Integer;
                       aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                       aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil); virtual;
    procedure PaintPanel(aPaintLayer: Integer); override;
    property HandIndex: Integer read FHandIndex;
  end;


  TKMGUIGameSpectatorItemLineResources = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;


  TKMGUIGameSpectatorItemLineWarFare = class(TKMGUIGameSpectatorItemLine)
  private
    class function GetIcon(aTag: Integer): Word;
    class function GetTitle(aTag: Integer): UnicodeString;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  // Buildings
  TKMGUIGameSpectatorItemLineCustomBuildings = class(TKMGUIGameSpectatorItemLine)
  private
    fHouseSketch: TKMHouseSketchEdit;
    fLastHouseUIDs: array [HOUSE_MIN..HOUSE_MAX] of Cardinal;
    procedure ResetUIDs;
    function CheckHighlight(aIndex: Integer): Boolean;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; virtual; abstract;
  public
    constructor Create(aParent: TKMPanel; AHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                       aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil); override;
    destructor Destroy; override;
  end;

  TKMGUIGameSpectatorItemLineConstructing = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetProgress(AHandIndex: Integer; ATag: Integer): Single; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  TKMGUIGameSpectatorItemLineHouses = class(TKMGUIGameSpectatorItemLineCustomBuildings)
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String; override;
    function GetProgress(AHandIndex: Integer; ATag: Integer): Single; override;
    function GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn; override;
  end;

  // Units
  TKMGUIGameSpectatorItemLinePopulation = class(TKMGUIGameSpectatorItemLine)
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmy = class(TKMGUIGameSpectatorItemLine)
  private
    fLastWarriorUIDs: array [WARRIOR_MIN..WARRIOR_MAX] of Cardinal;
    procedure ResetUIDs;
  protected
    function CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; override;
    function GetTagCount: Integer; override;
    function GetTag(AIndex: Integer): Integer; override;
    function GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; override;
    function CheckHighlight(aIndex: Integer): Boolean; virtual;
  end;

  TKMGUIGameSpectatorItemLineArmyInstantenious = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
    function CheckHighlight(aIndex: Integer): Boolean; override;
  end;

  TKMGUIGameSpectatorItemLineArmyTotal = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyKilling = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  TKMGUIGameSpectatorItemLineArmyLost = class(TKMGUIGameSpectatorItemLineArmy)
  protected
    function GetValue(AHandIndex: Integer; ATag: Integer): String; override;
  end;

  ///
  TKMGUIGameSpectator = class
  private
    FDropBoxPanel: TKMPanel;
    FDropBox: TKMDropList;
    FLastIndex: Integer;

    FOnJumpToPlayer: TIntegerEvent;
    FSetViewportPos: TPointFEvent;

    FLinesAggregator: array of TKMGameSpectatorItemLinesAggregator;
    FLines: array of array[0..MAX_HANDS - 1] of TKMGUIGameSpectatorItemLine;

    procedure AddLineType(aParent: TKMPanel; AIndex: Integer; ALineClass: TKMGUIGameSpectatorItemLineClass);
    procedure ChangePage(Sender: TObject);
  public
    constructor Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
    destructor Destroy; override;

    function GetOpenedPage: Integer;
    procedure OpenPage(aIndex: Integer);
    procedure CloseDropBox;

    procedure UpdateState(aTick: Cardinal);
  end;

implementation

uses
  KM_InterfaceGame, KM_Game, KM_RenderUI, KM_ResFonts, KM_Resource, KM_ResTexts, KM_ResUnits, KM_UnitGroup;

const
  GUI_SPEC_ITEM_WIDTH = 28;
  GUI_SPEC_ITEM_HEIGHT = 36;
  GUI_SPEC_ITEM_SRLITE_H = 4;
  GUI_SPEC_ITEM_SPRITE_V = 4;
  GUI_SPEC_ITEM_TEAM = 14;

  GUI_SPEC_HEADER_HEIGHT = 14;

  GUI_SPEC_HEADER_FLAG = 1164;
  GUI_SPEC_HEADER_FLAG_FRAME = 5;

  BEVEL_RENDER_LAYER = 1;
  PERCENTBAR_RENDER_LAYER = 1;
  IMAGE_RENDER_LAYER = 2;
  TEXT_RENDER_LAYER = 3;
  DROPBOX_RENDER_LAYER = 3;

{ TKMGUIGameSpectatorItem }
constructor TKMGUIGameSpectatorItem.Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String;
                                           AHandID: Integer; aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntBoolEvent);
begin
  inherited Create(aParent, 0, 0, GUI_SPEC_ITEM_WIDTH, GUI_SPEC_ITEM_HEIGHT);

  FItemTag := ATag;
  Hint := AHint;
  fHandID := AHandID;
  FImageID := AImageID;
  FValue := '';
  FAdditionalValue := '';
  FProgress := -1;
  fShowItem := False;
  FDoHighlight := aDoHighlight;
  FOnItemClick := aOnItemClick;
  CreateChilds;
end;

procedure TKMGUIGameSpectatorItem.ItemClicked(Sender: TObject; Shift: TShiftState);
begin
  if Assigned(FOnItemClick) then
    FOnItemClick(FItemTag, ssLeft in Shift);
end;

procedure TKMGUIGameSpectatorItem.CreateChilds;
begin
  Bevel := TKMBevel.Create(Self, 0, 0, Width, Height, BEVEL_RENDER_LAYER);
  Bevel.AnchorsStretch;
  Bevel.OnClickShift := ItemClicked;
  Image := TKMImage.Create(Self, 2, 0, Width - 4, Height - 4, FImageID, rxGui, IMAGE_RENDER_LAYER);
  if fHandID < gHands.Count then
    Image.FlagColor := gHands[fHandID].FlagColor;
  Image.ImageCenter;
  Image.Anchors := [anRight, anTop];
  Image.OnClickShift := ItemClicked;
  PercentBar := TKMPercentBar.Create(Self, 0, Height - 6, Width, 6, fntMini, PERCENTBAR_RENDER_LAYER);
  PercentBar.AnchorsStretch;
  Label_Text := TKMLabel.Create(Self, Width div 2, Height - 16, FValue, fntGrey, taCenter, TEXT_RENDER_LAYER);
  Label_Text.Anchors := [anRight, anTop];
  Label_AddText := TKMLabel.Create(Self, Width - 2, -2, FValue, fntGrey, taRight, TEXT_RENDER_LAYER);
  Label_AddText.Anchors := [anRight, anTop];
end;

procedure TKMGUIGameSpectatorItem.PaintPanel(aPaintLayer: Integer);
var
  PaintLightness: Single;
begin
  if fShowItem then
    PaintLightness := DEFAULT_HIGHLIGHT_COEF * Byte(((csOver in Image.State) or (csOver in Bevel.State)) and FDoHighlight(FItemTag))
  else
    PaintLightness := -DEFAULT_HIGHLIGHT_COEF;

  Image.Lightness := PaintLightness;

  PercentBar.Visible := FProgress >= 0;
  PercentBar.Position := FProgress;

  Label_Text.Caption := FValue;
  Label_AddText.Caption := FAdditionalValue;

  inherited PaintPanel(aPaintLayer);
end;

{ TKMGUIGameSpectatorItemLine }
constructor TKMGUIGameSpectatorItemLine.Create(aParent: TKMPanel; AHandIndex: Integer;
                                               aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                                               aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil);
var
  I: Integer;
begin
  inherited Create(aParent, aParent.Width, 32 + AHandIndex * (GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_ITEM_SPRITE_V), 0, GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_HEADER_HEIGHT + GUI_SPEC_ITEM_SPRITE_V);
  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;
  fLinesAggregator := aLinesAggregator;
  Anchors := [anTop, anRight];
  Focusable := False;
  FHandIndex := AHandIndex;
  SetLength(fItems, GetTagCount);
  CreateChilds;
  for I := 0 to GetTagCount - 1 do
    fItems[I] := CreateItem(AHandIndex, GetTag(I), LineItemClicked);
end;

procedure TKMGUIGameSpectatorItemLine.LineClicked(Sender: TObject);
begin
  if Assigned(fOnJumpToPlayer) then
    fOnJumpToPlayer(FHandIndex);
end;

procedure TKMGUIGameSpectatorItemLine.LineItemClicked(aItemTag: Integer; aMainFunction: Boolean);
var
  Loc: TKMPointF;
begin
  if Assigned(FSetViewportPos) then
  begin
    Loc := GetNextLoc(FHandIndex, aItemTag, aMainFunction);
    if Loc <> KMPOINTF_INVALID_TILE then
      FSetViewportPos(Loc);
  end;
end;

function TKMGUIGameSpectatorItemLine.DontHighlight(aIndex: Integer): Boolean;
begin
  Result := False;
end;

function TKMGUIGameSpectatorItemLine.DoHighlight(aIndex: Integer): Boolean;
begin
  Result := True;
end;

procedure TKMGUIGameSpectatorItemLine.UpdateItemsVisibility;
var
  i, Position, Count: Integer;
  Str: UnicodeString;
begin
  if not Visible then
    Exit;

  Count := 0;
  for i := 0 to GetTagCount - 1 do
  begin
    fItems[i].Visible := fLinesAggregator.FItemsVisibility[I];
    if fItems[i].Visible then
      Inc(Count);
  end;

  Str := IfThen(gHands[FHandIndex].OwnerNiknameU <> '', gHands[FHandIndex].OwnerNiknameU, gHands[FHandIndex].OwnerName);
  Width := Max(Count * (GUI_SPEC_ITEM_WIDTH + GUI_SPEC_ITEM_SRLITE_H) + GUI_SPEC_ITEM_SRLITE_H, gRes.Fonts[fntGrey].GetTextSize(Str).X + 32 + 4);
  Left := Parent.Width - Width;

  Position := Width - GUI_SPEC_ITEM_SRLITE_H - GUI_SPEC_ITEM_WIDTH;
  for i := 0 to GetTagCount - 1 do
    if fItems[i].Visible then
    begin
      fItems[i].Top := GUI_SPEC_HEADER_HEIGHT;
      fItems[i].Left := Position;
      Dec(Position, GUI_SPEC_ITEM_WIDTH + GUI_SPEC_ITEM_SRLITE_H);
    end;
end;

procedure TKMGUIGameSpectatorItemLine.Update;
var
  I: Integer;
begin
  if not Visible then
    Exit;

  for I := 0 to GetTagCount - 1 do
  begin
    fItems[I].Value := GetValue(FHandIndex, GetTag(I));
    fItems[I].AdditionalValue := GetAdditionalValue(FHandIndex, GetTag(I));
    fItems[I].Progress := GetProgress(FHandIndex, GetTag(I));
    fItems[I].ShowItem := (fItems[I].Value <> '')
                          or (fItems[I].AdditionalValue <> '')
                          or (fItems[I].Progress >= 0);
    if fItems[I].ShowItem then
      fLinesAggregator.FItemsVisibility[I] := True;
  end;
end;

function TKMGUIGameSpectatorItemLine.GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String;
begin
  Result := '';
end;


function TKMGUIGameSpectatorItemLine.GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
begin
  Result := KMPOINTF_INVALID_TILE;
end;


function TKMGUIGameSpectatorItemLine.GetProgress(AHandIndex: Integer; ATag: Integer): Single;
begin
  Result := -1;
end;

procedure TKMGUIGameSpectatorItemLine.CreateChilds;
begin
  Bevel := TKMBevel.Create(Self, 0, 0, Width, Height, BEVEL_RENDER_LAYER);
  Bevel.AnchorsStretch;
  Bevel.OnClick := LineClicked;
  Image := TKMImage.Create(Self, Width - 32, 0, 32, GUI_SPEC_HEADER_HEIGHT, 0, rxHouses, IMAGE_RENDER_LAYER);
  if FHandIndex < gHands.Count then
    Image.FlagColor := gHands[FHandIndex].FlagColor;
  Image.ImageCenter;
  Image.Anchors := [anTop, anRight];
  Image.OnClick := LineClicked;
  Label_Text := TKMLabel.Create(Self, Width - 32, 0, '', fntGrey, taRight, TEXT_RENDER_LAYER);
  Label_Text.Anchors := [anRight];
end;

procedure TKMGUIGameSpectatorItemLine.PaintPanel(aPaintLayer: Integer);
begin
  Image.TexId := GUI_SPEC_HEADER_FLAG + gGame.GameTick mod GUI_SPEC_HEADER_FLAG_FRAME;
  Label_Text.Caption := IfThen(gHands[FHandIndex].OwnerNiknameU <> '', gHands[FHandIndex].OwnerNiknameU, gHands[FHandIndex].OwnerName);

  inherited;
end;

{ TKMGUIGameSpectatorItemLineResources }
function TKMGUIGameSpectatorItemLineResources.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag, gRes.Wares[TKMWareType(ATag)].GUIIcon, gRes.Wares[TKmWareType(ATag)].Title,
                                           FHandIndex, DontHighlight, aOnItemClick);
  Result.Visible := False;
end;

function TKMGUIGameSpectatorItemLineResources.GetTagCount: Integer;
begin
  Result := WARE_CNT - WARFARE_CNT; //Do not show warfare on resources page
end;

function TKMGUIGameSpectatorItemLineResources.GetTag(AIndex: Integer): Integer;
begin
  if AIndex = 0 then
    Result := Integer(wtFish)
  else
    Result := Integer(StoreResType[Length(StoreResType) - AIndex - WARFARE_CNT]); //opposite order, we draw items from the right
end;

function TKMGUIGameSpectatorItemLineResources.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetWareBalance(TKMWareType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineWareFare }
function TKMGUIGameSpectatorItemLineWarFare.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           TKMGUIGameSpectatorItemLineWarFare.GetIcon(ATag),
                                           TKMGUIGameSpectatorItemLineWarFare.GetTitle(ATag), FHandIndex,
                                           DontHighlight, aOnItemClick);
  Result.Visible := False;
end;

class function TKMGUIGameSpectatorItemLineWarFare.GetIcon(aTag: Integer): Word;
begin
  if aTag = -1 then
    Result := gRes.Units[utRecruit].GUIIcon
  else
    Result := gRes.Wares[TKMWareType(ATag)].GUIIcon;
end;

class function TKMGUIGameSpectatorItemLineWarFare.GetTitle(aTag: Integer): UnicodeString;
begin
  if aTag = -1 then
    Result := gRes.Units[utRecruit].GUIName
  else
    Result := gRes.Wares[TKMWareType(ATag)].Title;
end;

function TKMGUIGameSpectatorItemLineWarFare.GetTagCount: Integer;
begin
  Result := WARFARE_CNT + 1; //+1 for recruit
end;

function TKMGUIGameSpectatorItemLineWarFare.GetTag(AIndex: Integer): Integer;
begin
  if AIndex = 0 then
    Result := -1
  else
    //Recruit is the last
    Result := Integer(BarracksResType[Length(BarracksResType) - AIndex + 1]); //opposite order, we draw items from the right
end;

function TKMGUIGameSpectatorItemLineWarFare.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  if aTag = -1 then
    Value := gHands[AHandIndex].Stats.GetUnitQty(utRecruit)
  else
    Value := gHands[AHandIndex].Stats.GetWareBalance(TKMWareType(ATag));

  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectatorItemLineCustomBuildings }
constructor TKMGUIGameSpectatorItemLineCustomBuildings.Create(aParent: TKMPanel; AHandIndex: Integer;
                                                              aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                                                              aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil);
begin
  inherited Create(aParent, AHandIndex, aOnJumpToPlayer, aSetViewportPos, aLinesAggregator);

  fHouseSketch := TKMHouseSketchEdit.Create;
end;

destructor TKMGUIGameSpectatorItemLineCustomBuildings.Destroy;
begin
  FreeAndNil(fHouseSketch);

  inherited;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Houses[TKMHouseType(ATag)].GUIIcon,
                                           gRes.Houses[TKMHouseType(ATag)].HouseName, FHandIndex,
                                           CheckHighlight, aOnItemClick);
  Result.Visible := False;
  ResetUIDs;
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := (GetValue(FHandIndex, aIndex) <> '') or
            (GetAdditionalValue(FHandIndex, aIndex) <> '');
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.GetTagCount: Integer;
begin
  Result := HOUSES_CNT - 1; //-1 for htSiegeWorkshop
end;

function TKMGUIGameSpectatorItemLineCustomBuildings.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(GUIHouseOrder[Length(GUIHouseOrder) - AIndex]); //opposite order, we draw items from the right
end;

procedure TKMGUIGameSpectatorItemLineCustomBuildings.ResetUIDs;
var
  HT: TKMHouseType;
begin
  for HT := Low(fLastHouseUIDs) to High(fLastHouseUIDs) do
    fLastHouseUIDs[HT] := 0;
end;


function TKMGUIGameSpectatorItemLineCustomBuildings.GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
var
  I: Integer;
  HT: TKMHouseType;
  HasDamagedHouses: Boolean;
  H: TKMHouse;
begin
  Result := KMPOINTF_INVALID_TILE;

  HT := TKMHouseType(ATag);

  HasDamagedHouses := False;
  for I := 0 to gHands[AHandIndex].Houses.Count - 1 do
    if gHands[AHandIndex].Houses[I].GetDamage > 0 then
    begin
      HasDamagedHouses := True;
      Break;
    end;

  //MainFunction - Left MB, Right MB
  //LMB - show only damaged houses or all houses
  //RMB - show all houses
  gHands[AHandIndex].GetNextHouseWSameType(HT, fLastHouseUIDs[HT], fHouseSketch, [hstHouse, hstHousePlan],
                                           GetVerifyHouseSketchFn(), HasDamagedHouses and aMainFunction);
  if not fHouseSketch.IsEmpty then
  begin
    gMySpectator.Highlight := fHouseSketch;
    H := gHands[AHandIndex].Houses.GetHouseByUID(fHouseSketch.UID);
    if H <> nil then
      gMySpectator.Selected := H;
    Result := KMPointF(fHouseSketch.Entrance); //get position on that house
    fLastHouseUIDs[HT] := fHouseSketch.UID;
  end;
end;

{ TKMGUIGameSpectatorItemLineBuild }
function TKMGUIGameSpectatorItemLineConstructing.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseWip(TKMHouseType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineConstructing.GetProgress(AHandIndex: Integer; ATag: Integer): Single;
var
  i: Integer;
  House, HouseProgress: TKMHouse;
  HouseType: TKMHouseType;
begin
  Result := inherited;
  if GetValue(AHandIndex, ATag) = '' then
    Exit;

  HouseType := TKMHouseType(ATag);
  HouseProgress := nil;
  for i := 0 to gHands[AHandIndex].Houses.Count - 1 do
  begin
    House := gHands[AHandIndex].Houses[i];
    if (House.HouseType = HouseType)
      and (House.BuildingState in [hbsWood, hbsStone])
      and (not Assigned(HouseProgress) or (House.BuildingProgress > HouseProgress.BuildingProgress)) then
      HouseProgress := House;
  end;

  if Assigned(HouseProgress) then
    Result := HouseProgress.BuildingProgress / HouseProgress.MaxHealth;
end;

function TKMGUIGameSpectatorItemLineConstructing.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := function(aSketch: TKMHouseSketch; aBoolParam: Boolean): Boolean
    begin
      Result := (aSketch <> nil)
                and (not (aSketch is TKMHouse) or not TKMHouse(aSketch).IsComplete);
    end;
end;

{ TKMGUIGameSpectatorItemLineBuildings }
function TKMGUIGameSpectatorItemLineHouses.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := inherited;
  Result.PercentBar.MainColor := icRed;
end;

function TKMGUIGameSpectatorItemLineHouses.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseQty(TKMHouseType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineHouses.GetAdditionalValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetHouseWip(TKMHouseType(ATag));
  Result := IfThen(Value > 0, '+' + IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineHouses.GetProgress(AHandIndex: Integer; ATag: Integer): Single;
var
  i: Integer;
  House, HouseHealth: TKMHouse;
  HouseType: TKMHouseType;
begin
  Result := inherited;
  if GetValue(AHandIndex, ATag) = '' then
    Exit;

  HouseType := TKMHouseType(ATag);
  HouseHealth := nil;
  for i := 0 to gHands[AHandIndex].Houses.Count - 1 do
  begin
    House := gHands[AHandIndex].Houses[i];
    if (House.HouseType = HouseType)
      and (House.GetDamage > 0)
      and (not Assigned(HouseHealth) or (House.GetDamage > HouseHealth.GetDamage)) then
      HouseHealth := House;
  end;

  if Assigned(HouseHealth) then
    Result := HouseHealth.GetHealth / HouseHealth.MaxHealth;
end;

function TKMGUIGameSpectatorItemLineHouses.GetVerifyHouseSketchFn: TAnonHouseSketchBoolFn;
begin
  Result := function(aSketch: TKMHouseSketch; aBoolParam: Boolean): Boolean
    begin
      //Show only damaged houses or all houses, depending on param
      //param - do we have damaged houses (on LMB) or RMB (all houses)
      Result := (aSketch <> nil)
                and (not (aSketch is TKMHouse)
                  or (TKMHouse(aSketch).GetDamage > 0)
                  or not aBoolParam); //Show
    end;
end;


{ TKMGUIGameSpectatorItemLinePopulation }
function TKMGUIGameSpectatorItemLinePopulation.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, FHandIndex,
                                           DontHighlight, aOnItemClick);
end;

function TKMGUIGameSpectatorItemLinePopulation.GetTagCount: Integer;
begin
  Result := CITIZENS_CNT;
end;

function TKMGUIGameSpectatorItemLinePopulation.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(School_Order[Length(School_Order) - AIndex - 1]); //opposite order, we draw items from the right
end;

function TKMGUIGameSpectatorItemLinePopulation.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineArmy }
function TKMGUIGameSpectatorItemLineArmy.CreateItem(AHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem;
begin
  Result := TKMGUIGameSpectatorItem.Create(Self, ATag,
                                           gRes.Units[TKMUnitType(ATag)].GUIIcon,
                                           gRes.Units[TKMUnitType(ATag)].GUIName, FHandIndex,
                                           CheckHighlight, aOnItemClick);
  ResetUIDs;
end;

function TKMGUIGameSpectatorItemLineArmy.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := gHands[FHandIndex].Stats.GetUnitQty(TKMUnitType(aIndex)) > 0;
end;

function TKMGUIGameSpectatorItemLineArmy.GetTagCount: Integer;
begin
  Result := WARRIORS_CNT;
end;

function TKMGUIGameSpectatorItemLineArmy.GetTag(AIndex: Integer): Integer;
begin
  Result := Integer(Soldiers_Order[Length(Soldiers_Order) - AIndex - 1]); //opposite order, we draw items from the right
end;

procedure TKMGUIGameSpectatorItemLineArmy.ResetUIDs;
var
  UT: TKMUnitType;
begin
  for UT := Low(fLastWarriorUIDs) to High(fLastWarriorUIDs) do
    fLastWarriorUIDs[UT] := 0;
end;

function TKMGUIGameSpectatorItemLineArmy.GetNextLoc(AHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
var
  NextGroup: TKMUnitGroup;
  UT: TKMUnitType;
begin
  Result := KMPOINTF_INVALID_TILE;

  UT := TKMUnitType(ATag);

  NextGroup := gHands[AHandIndex].GetNextGroupWSameType(UT, fLastWarriorUIDs[UT]);
  if NextGroup <> nil then
  begin
    gMySpectator.Selected := NextGroup;
    Result := NextGroup.FlagBearer.PositionF; //get position on that warrior
    fLastWarriorUIDs[UT] := NextGroup.UID;
  end;
end;


{ TKMGUIGameSpectatorItemLineArmyInstantenious }
function TKMGUIGameSpectatorItemLineArmyInstantenious.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

function TKMGUIGameSpectatorItemLineArmyInstantenious.CheckHighlight(aIndex: Integer): Boolean;
begin
  Result := True; //We always have soldiers to set viewport on
end;


{ TKMGUIGameSpectatorItemLineArmyTotal }
function TKMGUIGameSpectatorItemLineArmyTotal.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetWarriorsTotal(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;


{ TKMGUIGameSpectatorItemLineArmyKilling }
function TKMGUIGameSpectatorItemLineArmyKilling.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitKilledQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectatorItemLineArmyLost }
function TKMGUIGameSpectatorItemLineArmyLost.GetValue(AHandIndex: Integer; ATag: Integer): String;
var
  Value: Integer;
begin
  Value := gHands[AHandIndex].Stats.GetUnitLostQty(TKMUnitType(ATag));
  Result := IfThen(Value > 0, IntToStr(Value), '');
end;

{ TKMGUIGameSpectator }
constructor TKMGUIGameSpectator.Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
const
  DROPBOX_W = 270;
  LINES_CNT = 10;
begin
  inherited Create;

  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;

  FLastIndex := 0;

  SetLength(FLines, LINES_CNT);
  SetLength(FLinesAggregator, LINES_CNT);

  AddLineType(aParent, 0, nil);
  AddLineType(aParent, 1, TKMGUIGameSpectatorItemLineResources);
  AddLineType(aParent, 2, TKMGUIGameSpectatorItemLineWarFare);
  AddLineType(aParent, 3, TKMGUIGameSpectatorItemLineHouses);
  AddLineType(aParent, 4, TKMGUIGameSpectatorItemLineConstructing);
  AddLineType(aParent, 5, TKMGUIGameSpectatorItemLinePopulation);
  AddLineType(aParent, 6, TKMGUIGameSpectatorItemLineArmyInstantenious);
  AddLineType(aParent, 7, TKMGUIGameSpectatorItemLineArmyTotal);
  AddLineType(aParent, 8, TKMGUIGameSpectatorItemLineArmyKilling);
  AddLineType(aParent, 9, TKMGUIGameSpectatorItemLineArmyLost);

  //Create DropBox after pages, to show it above them
  FDropBoxPanel := TKMPanel.Create(aParent, aParent.Width - DROPBOX_W - 10, 0, DROPBOX_W + 10, 30);
  FDropBoxPanel.Anchors := [anTop, anRight];
  //FDropBoxPanel.Focusable := false;
  FDropBoxPanel.Show;
  FDropBox := TKMDropList.Create(FDropBoxPanel, 5, 5, DROPBOX_W, 20, fntMetal, '', bsGame, True, 0.85, TEXT_RENDER_LAYER);
  FDropBox.OnChange := ChangePage;


  FDropBox.Add(gResTexts[TX_WORD_NONE]);
  FDropBox.Add(gResTexts[TX_WORD_RESOURCES]);
  FDropBox.Add(gResTexts[TX_RESOURCES_WARFARE]);
  FDropBox.Add(gResTexts[TX_WORD_HOUSES]);
  FDropBox.Add(gResTexts[TX_WORD_CONSTRUCTING]);
  FDropBox.Add(gResTexts[TX_WORD_CITIZENS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_INSTANTANEOUS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_TOTAL_EQUIPPED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_DEFEATED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_LOST]);

  FDropBox.ItemIndex := 0;
end;

destructor TKMGUIGameSpectator.Destroy;
var
  I: Integer;
begin
  for I := Low(FLinesAggregator) to High(FLinesAggregator) do
    if FLinesAggregator[I] <> nil then
      FreeAndNil(FLinesAggregator[I]);

end;

procedure TKMGUIGameSpectator.AddLineType(aParent: TKMPanel; AIndex: Integer; ALineClass: TKMGUIGameSpectatorItemLineClass);
var
  I: Integer;
begin
  if ALineClass <> nil then
  begin
    FLinesAggregator[AIndex] := TKMGameSpectatorItemLinesAggregator.Create;
    for I := 0 to gHands.Count - 1 do
    begin
      FLines[AIndex, I] := ALineClass.Create(aParent, I, fOnJumpToPlayer, fSetViewportPos, FLinesAggregator[AIndex]);
      FLines[AIndex, I].Visible := False;
      FLinesAggregator[AIndex].SetCount(FLines[AIndex, I].GetTagCount);
    end;
  end;
end;

procedure TKMGUIGameSpectator.ChangePage(Sender: TObject);
var
  I, J: Integer;
  Teams: TKMByteSetArray;
  Position, TeamAddPos: Integer;
begin
  //Hide all lines
  for I := 0 to gHands.Count - 1 do
    if Assigned(FLines[FLastIndex, I]) then
      FLines[FLastIndex, I].Visible := False;

  FLastIndex := FDropBox.ItemIndex;

  Position := 32;
  Teams := gHands.Teams;

  TeamAddPos := GUI_SPEC_ITEM_TEAM;
  if Length(Teams) = gHands.Count then //FFA game
    TeamAddPos := GUI_SPEC_ITEM_SPRITE_V;

  for I := Low(Teams) to High(Teams) do
  begin
    for J in Teams[I] do
    begin
      if Assigned(FLines[FLastIndex, J]) then
      begin
        FLines[FLastIndex, J].Top := Position;
        FLines[FLastIndex, J].Show;
      end;
      Position := Position + GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_ITEM_SPRITE_V * 2 + GUI_SPEC_HEADER_HEIGHT;
    end;
    Position := Position + TeamAddPos;
  end;
  UpdateState(0); //Will update all data
end;

procedure TKMGUIGameSpectator.UpdateState(aTick: Cardinal);
var
  I, K: Integer;
begin
  //Updates could be done every 5 ticks
  if aTick mod 5 <> 0 then Exit;

  //Reset all aggregators first
  for I := Low(FLinesAggregator) to High(FLinesAggregator) do
    if FLinesAggregator[I] <> nil then
      FLinesAggregator[I].ResetItems;

  //Collect data from lines items - which to show and which not - into aggregator
  for I := Low(FLines) to High(FLines) do
    for K := 0 to Length(FLines[I]) - 1 do
      if FLines[I, K] <> nil then
        FLines[I, K].Update;

  //Set visibility for items, by aggregated data
  for I := Low(FLines) to High(FLines) do
    for K := 0 to Length(FLines[I]) - 1 do
      if FLines[I, K] <> nil then
        FLines[I, K].UpdateItemsVisibility;
end;

function TKMGUIGameSpectator.GetOpenedPage: Integer;
begin
  Result := FDropBox.ItemIndex;
end;

procedure TKMGUIGameSpectator.OpenPage(aIndex: Integer);
begin
  FDropBox.ItemIndex := aIndex;
  ChangePage(nil);
end;

procedure TKMGUIGameSpectator.CloseDropBox;
begin
  FDropBox.ItemIndex := 0;
  FDropBox.CloseList;
  ChangePage(nil);
end;


{ TKMGameSpectatorItemLinesAggregator }
procedure TKMGameSpectatorItemLinesAggregator.SetCount(aCount: Integer);
begin
  fCount := aCount;
  SetLength(fItemsVisibility, aCount);
end;

procedure TKMGameSpectatorItemLinesAggregator.ResetItems;
var
  I: Integer;
begin
  for I := 0 to fCount - 1 do
    fItemsVisibility[I] := False;
end;


end.
