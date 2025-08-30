unit KM_GUIGameSpectator;
{$I KaM_Remake.inc}
interface
uses
  Classes, Math, StrUtils, SysUtils,
  KM_Controls, KM_ControlsBase, KM_ControlsDrop, KM_ControlsScroll, KM_ControlsProgressBar,
  KM_Defaults,
  KM_CommonTypes, KM_Points;


type
  // Type of things shown in spectator statistics
  TKMHandStatType = (
    slNone, slResources, slWarfare, slHouses, slConstructions, slSLR,
    slWorkers, slArmy, slArmyTotal, slArmyKilling, slArmyLost
  );

  // We render everything in 3 layers to minimize switching of texture bindings
  TKMSpecPaintLayer = (
    plNone,  // Without textures (Bevels, ProgressBars)
    plImage, // Sprites (houses and flags)
    plText   // Labels
  );

  TKMGUIGameSpectatorItem = class(TKMPanel)
  private
    fHandID: Integer;
    fImageID: Word;
    fValue: String;
    fAdditionalValue: String;
    fProgress: Single;
    fItemTag: Integer;
    fOnItemClick: TIntBoolEvent;
    fDoHighlight: TBoolIntFuncSimple;
    procedure ItemClicked(Sender: TObject; Shift: TShiftState);
  protected
    Bevel: TKMBevel;
    Image: TKMImage;
    PercentBar: TKMPercentBar;
    Label_Text: TKMLabel;
    Label_AddText: TKMLabel;
  public
    constructor Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String; AHandID: Integer;
                       aProgressColor: Cardinal; aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntBoolEvent);
    property ItemTag: Integer read fItemTag;
    property Value: String read fValue write fValue;
    property AdditionalValue: String read fAdditionalValue write fAdditionalValue;
    property Progress: Single read fProgress write fProgress;
    procedure CreateChilds;
    procedure Paint; override;
    procedure PaintLayer(aPaintLayer: TKMSpecPaintLayer);
  end;

  TKMGameSpectatorItemLinesAggregator = class
  private
    fItemsVisibility: array of Boolean;
    fCount: Integer;
    procedure ResetItems;
    procedure SetCount(aCount: Integer);
  end;

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
    Image_Flag: TKMImage;
    Label_Text: TKMLabel;

    function CreateItem(aHandIndex: Integer; ATag: Integer; aOnItemClick: TIntBoolEvent): TKMGUIGameSpectatorItem; virtual; abstract;
    function GetTagCount: Integer; virtual; abstract;
    function GetTag(AIndex: Integer): Integer; virtual; abstract;
    function GetValue(aHandIndex: Integer; ATag: Integer): String; virtual; abstract;
    function GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String; virtual;
    function GetProgress(aHandIndex: Integer; ATag: Integer): Single; virtual;
    function GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF; virtual;
    property SetViewportPos: TPointFEvent read FSetViewportPos;
    function DontHighlight(aIndex: Integer): Boolean;
    function DoHighlight(aIndex: Integer): Boolean;
  public
    constructor Create(aParent: TKMPanel; aHandIndex: Integer; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                       aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil); virtual;
    procedure Paint; override;
    procedure PaintLayer(aPaintLayer: TKMSpecPaintLayer);
    property HandIndex: Integer read FHandIndex;
  end;


  TKMGUIGameSpectator = class(TKMPanel)
  private
    FDropBox: TKMDropList;
    fScrollPanel: TKMScrollPanel;
    fItemsPanel: TKMPanel; // Panel for all of the ItemLines. We use it to do handle MouseWheel event
    FLastIndex: TKMHandStatType;

    FOnJumpToPlayer: TIntegerEvent;
    FSetViewportPos: TPointFEvent;

    FLinesAggregator: array [TKMHandStatType] of TKMGameSpectatorItemLinesAggregator;
    FLines: array [TKMHandStatType] of array [0..MAX_HANDS - 1] of TKMGUIGameSpectatorItemLine;

    procedure AddLineType(aParent: TKMPanel; aLineType: TKMHandStatType; aLineClass: TKMGUIGameSpectatorItemLineClass);
    procedure ChangePage(Sender: TObject);
  public
    constructor Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
    destructor Destroy; override;

    function GetOpenedPage: Integer;
    procedure OpenPage(aIndex: Integer);
    procedure CloseDropBox;

    property DropBox: TKMDropList read FDropBox;

    procedure Resize;

    procedure UpdateState(aTick: Cardinal); override;
    procedure Paint; override;
  end;


implementation
uses
  KM_GameParams, KM_RenderUI, KM_ResFonts, KM_Resource, KM_ResTexts,
  KM_ControlsTypes, KM_GUIGameSpectatorItemLines, KM_HandsCollection,
  KM_ResTypes;

const
  GUI_SPEC_ITEM_WIDTH = 28;
  GUI_SPEC_ITEM_HEIGHT = 36;
  GUI_SPEC_ITEM_SRLITE_H = 4;
  GUI_SPEC_ITEM_SPRITE_V = 4;
  GUI_SPEC_ITEM_TEAM = 14;
  GUI_SPEC_HEADER_HEIGHT = 14;
  GUI_SPEC_HEADER_FLAG = 1164;
  GUI_SPEC_HEADER_FLAG_FRAME = 5;


{ TKMGUIGameSpectatorItem }
constructor TKMGUIGameSpectatorItem.Create(aParent: TKMPanel; ATag: Integer; AImageID: Word; const AHint: String;
                                           AHandID: Integer; aProgressColor: Cardinal; aDoHighlight: TBoolIntFuncSimple; aOnItemClick: TIntBoolEvent);
begin
  inherited Create(aParent, 0, 0, GUI_SPEC_ITEM_WIDTH, GUI_SPEC_ITEM_HEIGHT);

  fItemTag := ATag;
  Hint := AHint;
  fHandID := AHandID;
  fImageID := AImageID;
  fValue := '';
  fAdditionalValue := '';
  fProgress := -1;
  fDoHighlight := aDoHighlight;
  fOnItemClick := aOnItemClick;
  CreateChilds;
  PercentBar.MainColor := aProgressColor;
end;


procedure TKMGUIGameSpectatorItem.ItemClicked(Sender: TObject; Shift: TShiftState);
begin
  if Assigned(fOnItemClick) then
    fOnItemClick(fItemTag, ssLeft in Shift);
end;


procedure TKMGUIGameSpectatorItem.CreateChilds;
begin
  Bevel := TKMBevel.Create(Self, 0, 0, Width, Height);
  Bevel.AnchorsStretch;
  Bevel.OnClickShift := ItemClicked;
  Image := TKMImage.Create(Self, 2, 0, Width - 4, Height - 4, fImageID, rxGui);
  if fHandID < gHands.Count then
    Image.FlagColor := gHands[fHandID].FlagColor;
  Image.ImageCenter;
  Image.Anchors := [anRight, anTop];
  Image.OnClickShift := ItemClicked;
  PercentBar := TKMPercentBar.Create(Self, 0, Height - 6, Width, 6, fntMini);
  PercentBar.AnchorsStretch;
  Label_Text := TKMLabel.Create(Self, Width div 2, Height - 16, fValue, fntGrey, taCenter);
  Label_Text.Anchors := [anRight, anTop];
  Label_AddText := TKMLabel.Create(Self, Width - 2, -2, fValue, fntGrey, taRight);
  Label_AddText.Anchors := [anRight, anTop];
end;


procedure TKMGUIGameSpectatorItem.Paint;
begin
  // We paint everything ourselves in layers
end;


procedure TKMGUIGameSpectatorItem.PaintLayer(aPaintLayer: TKMSpecPaintLayer);
begin
  if aPaintLayer = plNone then
  begin
    Image.Lightness := CTRL_HIGHLIGHT_COEF_DEF * Byte(((csOver in Image.State) or (csOver in Bevel.State)) and fDoHighlight(fItemTag));

    PercentBar.Visible := (fProgress >= 0);
    PercentBar.Position := fProgress;

    Label_Text.Caption := fValue;
    Label_AddText.Caption := fAdditionalValue;
  end;

  case aPaintLayer of
    plNone:   begin
                Bevel.Paint;
                if PercentBar.IsSetVisible then
                  PercentBar.Paint;
              end;
    plImage:  Image.Paint;
    plText:   begin
                Label_Text.Paint;
                Label_AddText.Paint;
              end;
  end;
end;


{ TKMGUIGameSpectatorItemLine }
constructor TKMGUIGameSpectatorItemLine.Create(aParent: TKMPanel; aHandIndex: Integer;
                                               aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent;
                                               aLinesAggregator: TKMGameSpectatorItemLinesAggregator = nil);
var
  I: Integer;
begin
  inherited Create(aParent, aParent.Width, aHandIndex * (GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_ITEM_SPRITE_V), 0, GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_HEADER_HEIGHT + GUI_SPEC_ITEM_SPRITE_V);
  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;
  fLinesAggregator := aLinesAggregator;
  Anchors := [anTop, anRight];
  Focusable := False;
  FHandIndex := aHandIndex;
  SetLength(fItems, GetTagCount);
  CreateChilds;
  for I := 0 to GetTagCount - 1 do
    fItems[I] := CreateItem(aHandIndex, GetTag(I), LineItemClicked);
end;


procedure TKMGUIGameSpectatorItemLine.LineClicked(Sender: TObject);
begin
  if Assigned(fOnJumpToPlayer) then
    fOnJumpToPlayer(FHandIndex);
end;


procedure TKMGUIGameSpectatorItemLine.LineItemClicked(aItemTag: Integer; aMainFunction: Boolean);
var
  loc: TKMPointF;
begin
  if Assigned(FSetViewportPos) then
  begin
    loc := GetNextLoc(FHandIndex, aItemTag, aMainFunction);
    if loc <> KMPOINTF_INVALID_TILE then
      FSetViewportPos(loc);
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
  I, position, count, oldW: Integer;
begin
  if not Visible then
    Exit;

  count := 0;
  for I := 0 to GetTagCount - 1 do
    if fLinesAggregator.FItemsVisibility[I] then
      Inc(count);

  oldW := Width;
  Width := Max(count * (GUI_SPEC_ITEM_WIDTH + GUI_SPEC_ITEM_SRLITE_H) + GUI_SPEC_ITEM_SRLITE_H,
               gRes.Fonts[fntGrey].GetTextSize(gHands[FHandIndex].OwnerName(not gGameParams.IsSingleplayer)).X + 32 + 4);
  // Update Left line position according to the new Width
  Left := Left - (Width - oldW);

  position := Width - GUI_SPEC_ITEM_SRLITE_H - GUI_SPEC_ITEM_WIDTH;
  for I := 0 to GetTagCount - 1 do
    if fLinesAggregator.FItemsVisibility[I] then
    begin
      fItems[I].Top := GUI_SPEC_HEADER_HEIGHT;
      fItems[I].Left := position;
      Dec(position, GUI_SPEC_ITEM_WIDTH + GUI_SPEC_ITEM_SRLITE_H);
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
    fItems[I].Visible := (fItems[I].Value <> '')
                          or (fItems[I].AdditionalValue <> '')
                          or (fItems[I].Progress >= 0);
    if fItems[I].Visible then
      fLinesAggregator.FItemsVisibility[I] := True;
  end;
end;


function TKMGUIGameSpectatorItemLine.GetAdditionalValue(aHandIndex: Integer; ATag: Integer): String;
begin
  Result := '';
end;


function TKMGUIGameSpectatorItemLine.GetNextLoc(aHandIndex: Integer; ATag: Integer; aMainFunction: Boolean): TKMPointF;
begin
  Result := KMPOINTF_INVALID_TILE;
end;


function TKMGUIGameSpectatorItemLine.GetProgress(aHandIndex: Integer; ATag: Integer): Single;
begin
  Result := -1;
end;


procedure TKMGUIGameSpectatorItemLine.CreateChilds;
begin
  Bevel := TKMBevel.Create(Self, 0, 0, Width, Height);
  Bevel.AnchorsStretch;
  Bevel.OnClick := LineClicked;
  Bevel.BackAlpha := 0.2;
  Bevel.EdgeAlpha := 0.5;
  Image_Flag := TKMImage.Create(Self, Width - 32, 0, 32, GUI_SPEC_HEADER_HEIGHT, 0, rxHouses);
  if FHandIndex < gHands.Count then
    Image_Flag.FlagColor := gHands[FHandIndex].FlagColor;
  Image_Flag.ImageCenter;
  Image_Flag.Anchors := [anTop, anRight];
  Image_Flag.OnClick := LineClicked;
  Label_Text := TKMLabel.Create(Self, Width - 32, 0, '', fntGrey, taRight);
  Label_Text.Anchors := [anRight];
end;


procedure TKMGUIGameSpectatorItemLine.Paint;
begin
  // We paint everything ourselves in layers
end;


procedure TKMGUIGameSpectatorItemLine.PaintLayer(aPaintLayer: TKMSpecPaintLayer);
var
  I: Integer;
begin
  if aPaintLayer = plNone then
  begin
    Image_Flag.TexId := GUI_SPEC_HEADER_FLAG + gGameParams.Tick mod GUI_SPEC_HEADER_FLAG_FRAME;
    Label_Text.Caption := gHands[FHandIndex].OwnerName(not gGameParams.IsSingleplayer);
  end;

  case aPaintLayer of
    plNone:   Bevel.Paint;
    plImage:  Image_Flag.Paint;
    plText:   Label_Text.Paint;
  end;

  // Paint all the items in layers too
  for I := 0 to ChildCount - 1 do
    if Childs[I].IsSetVisible then
      if Childs[I] is TKMGUIGameSpectatorItem then
        TKMGUIGameSpectatorItem(Childs[I]).PaintLayer(aPaintLayer);
end;


{ TKMGUIGameSpectator }
constructor TKMGUIGameSpectator.Create(aParent: TKMPanel; aOnJumpToPlayer: TIntegerEvent; aSetViewportPos: TPointFEvent);
const
  DROPBOX_W = 270;
  DROPBOX_H = 20;
  SCR_PANEL_PAD_H = 30;
begin
  inherited Create(aParent, 0, 0, aParent.Width, aParent.Height);
  AnchorsStretch;
  Hitable := False;

  fOnJumpToPlayer := aOnJumpToPlayer;
  fSetViewportPos := aSetViewportPos;

  FScrollPanel := TKMScrollPanel.Create(Self, 0, SCR_PANEL_PAD_H, Self.Width - 5, Self.Height - SCR_PANEL_PAD_H, [saVertical], bsGame, ssGame);
  FScrollPanel.Hitable := False;
  FScrollPanel.AnchorsStretch;
  FScrollPanel.Padding.SetBottom(5);
  FScrollPanel.ScrollV_PadLeft := -20;
  FScrollPanel.Hide;

  fItemsPanel := TKMPanel.Create(FScrollPanel, FScrollPanel.Width - 100, 0, 100, FScrollPanel.Height);
  fItemsPanel.Anchors := [anTop, anRight, anBottom];

  AddLineType(fItemsPanel, slNone, nil);
  AddLineType(fItemsPanel, slResources, TKMGUIGameSpectatorItemLineResources);
  AddLineType(fItemsPanel, slWarfare, TKMGUIGameSpectatorItemLineWarFare);
  AddLineType(fItemsPanel, slHouses, TKMGUIGameSpectatorItemLineHouses);
  AddLineType(fItemsPanel, slConstructions, TKMGUIGameSpectatorItemLineConstructing);
  AddLineType(fItemsPanel, slSLR, TKMGUIGameSpectatorItemLinePopulationSLR);
  AddLineType(fItemsPanel, slWorkers, TKMGUIGameSpectatorItemLinePopulationHouseWorkers);
  AddLineType(fItemsPanel, slArmy, TKMGUIGameSpectatorItemLineArmyInstantenious);
  AddLineType(fItemsPanel, slArmyTotal, TKMGUIGameSpectatorItemLineArmyTotal);
  AddLineType(fItemsPanel, slArmyKilling, TKMGUIGameSpectatorItemLineArmyKilling);
  AddLineType(fItemsPanel, slArmyLost, TKMGUIGameSpectatorItemLineArmyLost);

  // Create DropBox after pages, to show it above them
  FDropBox := TKMDropList.Create(Self, Self.Width - DROPBOX_W - 5, 5, DROPBOX_W, DROPBOX_H, fntMetal, '', bsGame, True, 0.85);
  FDropBox.Anchors := [anTop, anRight];
  FDropBox.OnChange := ChangePage;
  FDropBox.DropCount := Ord(High(TKMHandStatType)) + 1;

  FDropBox.Add(gResTexts[TX_WORD_NONE]);
  FDropBox.Add(gResTexts[TX_WORD_RESOURCES]);
  FDropBox.Add(gResTexts[TX_RESOURCES_WARFARE]);
  FDropBox.Add(gResTexts[TX_WORD_HOUSES]);
  FDropBox.Add(gResTexts[TX_WORD_CONSTRUCTING]);
  FDropBox.Add(gResTexts[TX_SPECTATOR_PANEL_CITIZENS_SLR]);
  FDropBox.Add(gResTexts[TX_SPECTATOR_PANEL_CITIZENS_HOUSE_WORKERS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_INSTANTANEOUS]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_TOTAL_EQUIPPED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_DEFEATED]);
  FDropBox.Add(gResTexts[TX_WORD_ARMY] + ' - ' + gResTexts[TX_RESULTS_ARMY_LOST]);

  FDropBox.ItemIndex := 0;

  Assert(FDropBox.Count = FDropBox.DropCount);
end;


destructor TKMGUIGameSpectator.Destroy;
var
  I: TKMHandStatType;
begin
  for I := Low(TKMHandStatType) to High(TKMHandStatType) do
    FreeAndNil(FLinesAggregator[I]);

  inherited;
end;


procedure TKMGUIGameSpectator.Paint;
var
  L: TKMSpecPaintLayer;
  I: Integer;
begin
  // No inherited. We paint everything as we see fit (in layers)

  // Paint DropBox and its button
  for I := 0 to ChildCount - 1 do
    if Childs[I].IsSetVisible then
      if not (Childs[I] is TKMGUIGameSpectatorItemLine) then
        TKMGUIGameSpectatorItemLine(Childs[I]).Paint;

  // Do clip manually, since we are painting in layers
  fScrollPanel.ClipY;

  // Paint everything in layers
  for L := Low(TKMSpecPaintLayer) to High(TKMSpecPaintLayer) do
  for I := 0 to fItemsPanel.ChildCount - 1 do
    if fItemsPanel.Childs[I].IsSetVisible then
      if fItemsPanel.Childs[I] is TKMGUIGameSpectatorItemLine then
        TKMGUIGameSpectatorItemLine(fItemsPanel.Childs[I]).PaintLayer(L);

  fScrollPanel.UnClipY;
end;


procedure TKMGUIGameSpectator.AddLineType(aParent: TKMPanel; aLineType: TKMHandStatType; aLineClass: TKMGUIGameSpectatorItemLineClass);
var
  I: Integer;
begin
  if aLineClass = nil then Exit;

  FLinesAggregator[aLineType] := TKMGameSpectatorItemLinesAggregator.Create;
  for I := 0 to gHands.Count - 1 do
  begin
    FLines[aLineType, I] := aLineClass.Create(aParent, I, fOnJumpToPlayer, fSetViewportPos, FLinesAggregator[aLineType]);
    FLines[aLineType, I].Visible := False;
    FLinesAggregator[aLineType].SetCount(FLines[aLineType, I].GetTagCount);
  end;
end;


procedure TKMGUIGameSpectator.ChangePage(Sender: TObject);
var
  I, J: Integer;
  teams: TKMByteSetArray;
  top, teamAddPos: Integer;
begin
  // Hide all lines
  for I := 0 to gHands.Count - 1 do
    if Assigned(FLines[FLastIndex, I]) then
      FLines[FLastIndex, I].Visible := False;

  fItemsPanel.Hide;
  FLastIndex := TKMHandStatType(FDropBox.ItemIndex);

  if FLastIndex = slNone then Exit;

  top := 0;
  teams := gHands.Teams;

  teamAddPos := GUI_SPEC_ITEM_TEAM;
  if Length(teams) = gHands.Count then //FFA game
    teamAddPos := GUI_SPEC_ITEM_SPRITE_V;

  for I := Low(teams) to High(teams) do
  begin
    for J in teams[I] do
    begin
      if Assigned(FLines[FLastIndex, J]) then
      begin
        FLines[FLastIndex, J].Top := top;
        FLines[FLastIndex, J].Show;
        fItemsPanel.Show;
      end;
      top := top + GUI_SPEC_ITEM_HEIGHT + GUI_SPEC_ITEM_SPRITE_V * 2 + GUI_SPEC_HEADER_HEIGHT;
    end;
    top := top + teamAddPos;
  end;

  UpdateState(0); //Will update all data
end;


procedure TKMGUIGameSpectator.Resize;
begin
  // Update all data and according line positions
  UpdateState(0);
end;


procedure TKMGUIGameSpectator.UpdateState(aTick: Cardinal);
var
  I: TKMHandStatType;
  K: Integer;
  maxW, maxH: Integer;
begin
  inherited;

  //Updates could be done every 10 ticks
  if aTick mod 10 <> 0 then Exit;

  //Reset all aggregators first
  for I := Low(TKMHandStatType) to High(TKMHandStatType) do
    if FLinesAggregator[I] <> nil then
      FLinesAggregator[I].ResetItems;

  //Collect data from lines items - which to show and which not - into aggregator
  for I := Low(TKMHandStatType) to High(TKMHandStatType) do
    for K := 0 to Length(FLines[I]) - 1 do
      if FLines[I, K] <> nil then
        FLines[I, K].Update;

  maxW := 0;
  maxH := 0;

  //Set visibility for items, by aggregated data
  for I := Low(TKMHandStatType) to High(TKMHandStatType) do
    for K := 0 to Length(FLines[I]) - 1 do
      if FLines[I, K] <> nil then
      begin
        FLines[I, K].UpdateItemsVisibility;
        if FLines[I, K].Visible then
        begin
          // Calc sizes for an ItemsPanels
          maxW := Max(maxW, FLines[I, K].Width);
          maxH := Max(maxH, FLines[I, K].Bottom);
        end;
      end;

  // Set Items panel sizes
  fItemsPanel.Width := maxW;
  fItemsPanel.Height := maxH;

  // Update ScrollPanel scrolls, to make sure its rendered to set Left position properly
  fScrollPanel.UpdateScrolls;
  fItemsPanel.Left := fScrollPanel.Width - maxW - Byte(fScrollPanel.ScrollV.Visible)*25;
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
