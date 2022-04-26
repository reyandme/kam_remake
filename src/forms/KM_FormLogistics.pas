unit KM_FormLogistics;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF FPC} LResources, {$ENDIF}
  {$IFDEF MSWindows} Windows, Messages, {$ENDIF}
  {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
  {$IFDEF USE_VIRTUAL_TREEVIEW}VirtualTrees, {$ENDIF}
  SysUtils, Variants, Classes,
  Graphics, Controls, Forms, Dialogs, ComCtrls,
  StdCtrls, ExtCtrls, CheckLst, Spin, Clipbrd;

type
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  TKMColumnContentType = (cctText, cctNumber);

  TKMVSTColumn = record
    ID: Byte;
    Title: string;
    Alignment: TAlignment;
    Width: Word;
    Visible: Boolean;
    Position: Integer;
    ColumnType: TKMColumnContentType;
  end;

  TKMVSTKind = (vstkDelivery, vstkOffer, vstkDemand);

  TKMHandLogisticsVST = class (TVirtualStringTree)
  private
    function GetDefColumn(aIndex: Integer): TKMVSTColumn;
    function GetColumnsCnt: Integer;
  public
    Kind: TKMVSTKind;
    constructor Create(aOwner: TComponent; aKind: TKMVSTKind); reintroduce;
    property DefColumn[aIndex: Integer]: TKMVSTColumn read GetDefColumn;
    property ColumnsCnt: Integer read GetColumnsCnt;
  end;
  {$ENDIF}


  TFormLogistics = class(TForm)
    vstPageCtrl: TPageControl;
    tabSheetDeliveries: TTabSheet;
    tabSheetOffers: TTabSheet;
    tabSheetDemands: TTabSheet;
    gbFilter: TGroupBox;
    clbHandsFilter: TCheckListBox;
    Label1: TLabel;
    gbToFromID: TGroupBox;
    seToID: TSpinEdit;
    seFromID: TSpinEdit;
    cbToID: TCheckBox;
    cbFromID: TCheckBox;
    btnUncheckAll: TButton;
    btnCheckAll: TButton;
    panel1: TPanel;
    cbFormEnabled: TCheckBox;
    panel2: TPanel;
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    VSTDeliveries: TKMHandLogisticsVST;
    VSTOffers: TKMHandLogisticsVST;
    VSTDemands: TKMHandLogisticsVST;
    {$ENDIF}
    procedure FormCreate(Sender: TObject);
    procedure FormClose(Sender: TObject; var Action: TCloseAction);
    procedure vstPageCtrlChange(Sender: TObject);
    procedure FilterUpdated(Sender: TObject);
    procedure FormShow(Sender: TObject);
    procedure btnCheckAllClick(Sender: TObject);
    procedure btnUncheckAllClick(Sender: TObject);
    procedure cbFormEnabledClick(Sender: TObject);
  private
    {$IFDEF USE_VIRTUAL_TREEVIEW}
    fLastNodeHitInfo: THitInfo;

    procedure VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);

    procedure VSTDeliveriesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure VSTOffersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
    procedure VSTDemandsGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);

    procedure VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
    procedure VSTNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);

    procedure VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
    procedure VSTHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
    procedure VSTCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
    procedure VSTKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
    procedure VSTAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);

    procedure ApplyFilter;
    {$ENDIF}
    procedure UpdateAll;
  public
    procedure VSTUpdate;

    procedure UpdateView(aHandsCnt: Integer; aCheckAll: Boolean);

    {$IFDEF USE_VIRTUAL_TREEVIEW}
    procedure FilterNode(aVST: TKMHandLogisticsVST; aNode: PVirtualNode);
    {$ENDIF}

    function IsEnabled: Boolean;

    procedure Clear;
  end;


var
  FormLogistics: TFormLogistics;

implementation
uses
  Math, TypInfo,
  KM_GameApp,
  KM_HandEntity, KM_Hand, KM_HandLogistics, KM_HandsCollection, KM_HandTypes,
  KM_Resource, KM_ResWares, KM_ResUnits, KM_ResHouses, KM_ResTypes,
  KM_Defaults; // Make compiler happy, regarding inline methods

{$IFDEF USE_VIRTUAL_TREEVIEW}
const
  DELIVERIES_COL_COUNT = 10;
  OFFERS_COL_COUNT = 9;
  DEMANDS_COL_COUNT = 10;

type
  TKMDeliveriesColumnsArray = array [0..DELIVERIES_COL_COUNT-1] of TKMVSTColumn;
  TKMOffersColumnsArray     = array [0..OFFERS_COL_COUNT-1] of TKMVSTColumn;
  TKMDemandsColumnsArray    = array [0..DEMANDS_COL_COUNT-1] of TKMVSTColumn;


const
  DEF_SORT_COLUMN_ID = 1; //HandID by default


  DEF_DELIVERIES_COLUMNS: TKMDeliveriesColumnsArray = (
    (ID: 0;  Title: '#';          Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 1;  Title: 'Hand';       Alignment: taRightJustify;  Width: 50;  Visible: True; ColumnType: cctNumber),
    (ID: 2;  Title: 'iQ';         Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 3;  Title: 'Resource';   Alignment: taLeftJustify;   Width: 110; Visible: True; ColumnType: cctText),
    (ID: 4;  Title: 'From house'; Alignment: taLeftJustify;   Width: 130; Visible: True; ColumnType: cctText),
    (ID: 5;  Title: 'From ID';    Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 6;  Title: 'To';         Alignment: taLeftJustify;   Width: 130; Visible: True; ColumnType: cctText),
    (ID: 7;  Title: 'To ID';      Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 8;  Title: 'Serf';       Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 9;  Title: 'Stage';      Alignment: taLeftJustify;   Width: 50;  Visible: True; ColumnType: cctText)
  );

  DEF_OFFERS_COLUMNS: TKMOffersColumnsArray = (
    (ID: 0;  Title: '#';          Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 1;  Title: 'Hand';       Alignment: taRightJustify;  Width: 50;  Visible: True; ColumnType: cctNumber),
    (ID: 2;  Title: 'iO';         Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 3;  Title: 'Resource';   Alignment: taLeftJustify;   Width: 110; Visible: True; ColumnType: cctText),
    (ID: 4;  Title: 'From house'; Alignment: taLeftJustify;   Width: 130; Visible: True; ColumnType: cctText),
    (ID: 5;  Title: 'From ID';    Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 6;  Title: 'Count';      Alignment: taRightJustify;  Width: 70;  Visible: True; ColumnType: cctNumber),
    (ID: 7;  Title: 'Performed';  Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 8;  Title: 'Deleted';    Alignment: taLeftJustify;   Width: 70;  Visible: True; ColumnType: cctText)
  );

  DEF_DEMANDS_COLUMNS: TKMDemandsColumnsArray = (
    (ID: 0;  Title: '#';          Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 1;  Title: 'Hand';       Alignment: taRightJustify;  Width: 50;  Visible: True; ColumnType: cctNumber),
    (ID: 2;  Title: 'iD';         Alignment: taRightJustify;  Width: 40;  Visible: True; ColumnType: cctNumber),
    (ID: 3;  Title: 'Resource';   Alignment: taLeftJustify;   Width: 110; Visible: True; ColumnType: cctText),
    (ID: 4;  Title: 'To';         Alignment: taLeftJustify;   Width: 130; Visible: True; ColumnType: cctText),
    (ID: 5;  Title: 'To ID';      Alignment: taRightJustify;  Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 6;  Title: 'Type';       Alignment: taLeftJustify;   Width: 70;  Visible: True; ColumnType: cctText),
    (ID: 7;  Title: 'Importance'; Alignment: taLeftJustify;   Width: 70;  Visible: True; ColumnType: cctText),
    (ID: 8;  Title: 'Performed';  Alignment: taLeftJustify;   Width: 80;  Visible: True; ColumnType: cctNumber),
    (ID: 9;  Title: 'Deleted';    Alignment: taLeftJustify;   Width: 70;  Visible: True; ColumnType: cctText)
  );
{$ENDIF}


{$R *.dfm}


procedure TFormLogistics.FormClose(Sender: TObject; var Action: TCloseAction);
begin
  gMySpectator.ResetHighlightDebug;
end;


procedure TFormLogistics.FormCreate(Sender: TObject);
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  procedure InitVST(aVST: TKMHandLogisticsVST);
  var
    I: Integer;
    c: TVirtualTreeColumn;
  begin
    aVST.Header.Options := [hoColumnResize, hoDrag, hoShowHint, hoShowImages, hoShowSortGlyphs, hoVisible];
    aVST.TreeOptions.MiscOptions := [toAcceptOLEDrop, toFullRepaintOnResize, toGridExtensions, toInitOnSave, toToggleOnDblClick, toWheelPanning, toEditOnClick];
    aVST.TreeOptions.PaintOptions := [toHideFocusRect, toShowButtons, toShowDropmark, toShowTreeLines, toThemeAware, toUseBlendedImages];
    aVST.TreeOptions.SelectionOptions := [toExtendedFocus, toFullRowSelect];

    aVST.Align := alClient;
    aVST.EmptyListMessage := 'No data ...';
    aVST.DefaultNodeHeight := 20;
    aVST.NodeDataSize := SizeOf(TKMLogisticsIDs);

    aVST.OnGetText := VSTGetText;
    aVST.OnCompareNodes := VSTCompareNodes;
    aVST.OnFreeNode := VSTFreeNode;
    aVST.OnHeaderClick := VSTHeaderClick;
    aVST.OnKeyDown := VSTKeyDown;
    aVST.OnFocusChanged := VSTFocusChanged;
    aVST.OnAfterCellPaint := VSTAfterCellPaint;
    aVST.OnNodeClick := VSTNodeClick;

    aVST.Header.SortColumn := DEF_SORT_COLUMN_ID;

    for I := 0 to aVST.ColumnsCnt - 1 do
    begin
      c := aVST.Header.Columns.Add;
      c.Text := aVST.DefColumn[I].Title;
      c.Width := aVST.DefColumn[I].Width;
      c.Tag := aVST.DefColumn[I].ID;
      c.Alignment := aVST.DefColumn[I].Alignment;

      if aVST.DefColumn[I].Visible then
        c.Options := c.Options + [coVisible]
      else
        c.Options := c.Options - [coVisible];
    end;
  end;

  {$ENDIF}
begin
  // Form creation
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  VSTDeliveries := TKMHandLogisticsVST.Create(tabSheetDeliveries, vstkDelivery);
  VSTDeliveries.Parent := tabSheetDeliveries;

  VSTOffers := TKMHandLogisticsVST.Create(tabSheetOffers, vstkOffer);
  VSTOffers.Parent := tabSheetOffers;

  VSTDemands := TKMHandLogisticsVST.Create(tabSheetDemands, vstkDemand);
  VSTDemands.Parent := tabSheetDemands;

  InitVST(VSTDeliveries);
  InitVST(VSTOffers);
  InitVST(VSTDemands);
  {$ENDIF}
end;


procedure TFormLogistics.UpdateAll;
var
  I: Integer;
begin
  // Update all logistics tables
  Clear;

  UpdateView(gHands.Count, False);


  for I := 0 to gHands.Count - 1 do
    gHands[I].Deliveries.Queue.Form_UpdateAllNodes;
end;


procedure TFormLogistics.FormShow(Sender: TObject);
begin
  UpdateAll;
end;


function TFormLogistics.IsEnabled: Boolean;
begin
  Result := cbFormEnabled.Checked;
end;


procedure TFormLogistics.UpdateView(aHandsCnt: Integer; aCheckAll: Boolean);
var
  I: Integer;
begin
  clbHandsFilter.Items.Clear;
  for I := 0 to aHandsCnt - 1 do
    clbHandsFilter.Items.Add(IntToStr(I));

  if aCheckAll then
    clbHandsFilter.CheckAll(cbChecked, True, True);
end;


procedure TFormLogistics.VSTUpdate;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  procedure DoSort(aVST: TKMHandLogisticsVST);
  begin
    aVST.Sort(aVST.RootNode, aVST.Header.SortColumn, aVST.Header.SortDirection, True);
  end;
  {$ENDIF}

begin
  if not Visible then Exit;

  {$IFDEF USE_VIRTUAL_TREEVIEW}
  ApplyFilter;

  case vstPageCtrl.ActivePageIndex of
    0:  DoSort(VSTDeliveries);
    1:  DoSort(VSTOffers);
    2:  DoSort(VSTDemands);
  end;
  {$ENDIF}
end;


procedure TFormLogistics.btnCheckAllClick(Sender: TObject);
begin
  clbHandsFilter.CheckAll(cbChecked, True, True);
  VSTUpdate;
end;


procedure TFormLogistics.btnUncheckAllClick(Sender: TObject);
begin
  clbHandsFilter.CheckAll(cbUnchecked, True, True);
  VSTUpdate;
end;


procedure TFormLogistics.cbFormEnabledClick(Sender: TObject);
begin
  if cbFormEnabled.Checked then
    UpdateAll
  else
    Clear;

  vstPageCtrl.Enabled := cbFormEnabled.Checked;
  gbFilter.Enabled    := cbFormEnabled.Checked;
end;


procedure TFormLogistics.Clear;
{$IFDEF USE_VIRTUAL_TREEVIEW}
var
  I: Integer;
{$ENDIF}
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  // nil all nodes, since we are going to clear all VST's
  for I := 0 to gHands.Count - 1 do
    gHands[I].Deliveries.Queue.Form_NilAllNodes;

  VSTDeliveries.Clear;
  VSTOffers.Clear;
  VSTDemands.Clear;
  {$ENDIF}
end;


{$IFDEF USE_VIRTUAL_TREEVIEW}
procedure TFormLogistics.FilterNode(aVST: TKMHandLogisticsVST; aNode: PVirtualNode);
const
  DEL_FROM_ID_COL = 5;
  DEL_TO_ID_COL = 7;

  OFF_FROM_ID_COL = 5;

  DEM_TO_ID_COL = 5;

  function GetFromColumn(aKind: TKMVSTKind): Integer;
  begin
    case aKind of
      vstkDelivery: Result := DEL_FROM_ID_COL;
      vstkOffer:    Result := OFF_FROM_ID_COL;
      else          Result := 0;
    end;
  end;

  function GetToColumn(aKind: TKMVSTKind): Integer;
  begin
    case aKind of
      vstkDelivery: Result := DEL_TO_ID_COL;
      vstkDemand:   Result := DEM_TO_ID_COL;
      else          Result := 0;
    end;
  end;

var
  I: Integer;
  data: PKMLogisticsIDs;
  badHand, badToID, badFromID: Boolean;
  cellText: string;
begin
  data := aVST.GetNodeData(aNode);
  badHand := True;
  badToID := False;
  badFromID := False;

  try
    for I := 0 to clbHandsFilter.Items.Count - 1 do
      if (clbHandsFilter.State[I] = cbChecked) and (I = data.HandID) then
      begin
        badHand := False;
        Break;
      end;

    // Continue AFAP
    if badHand then Exit;

    if cbFromID.Enabled and cbFromID.Checked then
    begin
      VSTGetText(aVST, aNode, GetFromColumn(aVST.Kind), ttNormal, cellText);
      badFromID := StrToInt(cellText) <> seFromID.Value;
    end;

    // Continue AFAP
    if badFromID then Exit;

    if cbToID.Enabled and cbToID.Checked then
    begin
      VSTGetText(aVST, aNode, GetToColumn(aVST.Kind), ttNormal, cellText);
      badToID := StrToInt(cellText) <> seToID.Value;
    end;
  finally
    aVST.IsFiltered[aNode] := badHand or badToID or badFromID;
  end;
end;


procedure TFormLogistics.ApplyFilter;

  procedure FilterVST(aVST: TKMHandLogisticsVST);
  var
    C: PVirtualNode;
  begin
    for C in aVST.InitializedNodes(False) do
      FilterNode(aVST, C);
  end;

begin
  case vstPageCtrl.ActivePageIndex of
    0:  FilterVST(VSTDeliveries);
    1:  FilterVST(VSTOffers);
    2:  FilterVST(VSTDemands);
  end;
end;


procedure TFormLogistics.VSTFocusChanged(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex);
begin
  fLastNodeHitInfo.HitNode := Node;
  fLastNodeHitInfo.HitColumn := Column;
end;


procedure TFormLogistics.VSTNodeClick(Sender: TBaseVirtualTree; const HitInfo: THitInfo);
const
  OFF_COLOR = icYellow;
  DEM_COLOR = icRed;
  DEL_FROM_COLUMNS = [4..5];
  DEL_TO_COLUMNS = [6..7];
  DEL_SERF_COLUMN = 8;
var
  data: PKMLogisticsIDs;
  del: TKMDeliveries;
  offerEntity, demandEntity, serfEntity, selectEntity: TKMHandEntity;
begin
  Assert(Sender is TKMHandLogisticsVST);

  data := Sender.GetNodeData(HitInfo.HitNode);
  if not Assigned(data) then Exit;

  del := gHands[data.handID].Deliveries.Queue;

  case TKMHandLogisticsVST(Sender).Kind of
    vstkDelivery: begin
                    gMySpectator.ResetHighlightDebug;

                    offerEntity := nil;
                    demandEntity := nil;

                    if del.Delivery[data.ID].OfferID <> DELIVERY_NO_ID then
                      offerEntity := del.Offer[del.Delivery[data.ID].OfferWare, del.Delivery[data.ID].OfferID].Loc_House;

                    if del.Delivery[data.ID].DemandID <> DELIVERY_NO_ID then
                      demandEntity := del.Demand[del.Delivery[data.ID].DemandWare, del.Delivery[data.ID].DemandID].GetDemandEntity;

                    serfEntity := del.Delivery[data.ID].Serf;

                    // Check if click was on a specified column
                    if HitInfo.HitColumn in DEL_FROM_COLUMNS then
                      selectEntity := offerEntity
                    else
                    if HitInfo.HitColumn in DEL_TO_COLUMNS then
                      selectEntity := demandEntity
                    else
                    if HitInfo.HitColumn = DEL_SERF_COLUMN then
                      selectEntity := serfEntity
                    else
                    // otherwise circle through entities
                    if gMySpectator.Selected = nil then
                      selectEntity := serfEntity
                    else
                    if offerEntity = gMySpectator.Selected then
                      selectEntity := demandEntity
                    else
                    if demandEntity = gMySpectator.Selected then
                      selectEntity := serfEntity
                    else
                      selectEntity := offerEntity;

                    gGameApp.Game.GamePlayInterface.SelectEntity(selectEntity);

                    gMySpectator.HighlightDebug  := TKMHighlightEntity.New(offerEntity, OFF_COLOR);
                    gMySpectator.HighlightDebug2 := TKMHighlightEntity.New(demandEntity, DEM_COLOR);
                    gMySpectator.HighlightDebug3.SetEntity(serfEntity);
                    gMySpectator.HighlightRoute.SetEntity(serfEntity);
                  end;
    vstkOffer:    begin
                    gMySpectator.ResetHighlightDebug;
                    offerEntity := del.Offer[data.Ware, data.ID].Loc_House;
                    gGameApp.Game.GamePlayInterface.SelectEntity(offerEntity);
                    gMySpectator.HighlightDebug := TKMHighlightEntity.New(offerEntity, OFF_COLOR);
                  end;
    vstkDemand:   begin
                    gMySpectator.ResetHighlightDebug;
                    demandEntity := del.Demand[data.Ware, data.ID].GetDemandEntity;
                    gGameApp.Game.GamePlayInterface.SelectEntity(demandEntity);
                    gMySpectator.HighlightDebug := TKMHighlightEntity.New(demandEntity, DEM_COLOR);
                  end;
  end;
end;


procedure TFormLogistics.VSTKeyDown(Sender: TObject; var Key: Word; Shift: TShiftState);
begin
  //Copy selected cell text to clipboard
  if (ssCtrl in Shift) and (Key = Ord('C')) then
  begin
    if Assigned(fLastNodeHitInfo.HitNode) then
      ClipBoard.AsText := TVirtualStringTree(Sender).Text[fLastNodeHitInfo.HitNode, fLastNodeHitInfo.HitColumn];
  end;
end;


procedure TFormLogistics.VSTAfterCellPaint(Sender: TBaseVirtualTree; TargetCanvas: TCanvas; Node: PVirtualNode; Column: TColumnIndex; CellRect: TRect);
begin
  // Draw focus rect for the last selected cell
  if (fLastNodeHitInfo.HitNode = Node) and (fLastNodeHitInfo.HitColumn = Column) then
    TargetCanvas.DrawFocusRect(CellRect);
end;


procedure TFormLogistics.VSTCompareNodes(Sender: TBaseVirtualTree; Node1, Node2: PVirtualNode; Column: TColumnIndex; var Result: Integer);
var
  cellText1, cellText2 : string;
  columnType: TKMColumnContentType;
begin
  if Column = -1 then Exit;

  case TKMHandLogisticsVST(Sender).Kind of
    vstkDelivery: columnType := DEF_DELIVERIES_COLUMNS[Column].ColumnType;
    vstkOffer:    columnType := DEF_OFFERS_COLUMNS[Column].ColumnType;
    vstkDemand:   columnType := DEF_DEMANDS_COLUMNS[Column].ColumnType;
    else          columnType := cctText; //make compiler happy
  end;

  VSTGetText(Sender, Node1, Column, ttNormal, cellText1);
  VSTGetText(Sender, Node2, Column, ttNormal, cellText2);

  case columnType of
    cctText:    Result := CompareText(cellText1, cellText2);
    cctNumber:  Result := CompareValue(StrToInt(cellText1), StrToInt(cellText2));
  end;

end;


procedure TFormLogistics.VSTHeaderClick(Sender: TVTHeader; HitInfo: TVTHeaderHitInfo);
begin
  if HitInfo.Button <> mbLeft then Exit;

  if HitInfo.Column = Sender.SortColumn then
    Sender.SortDirection := TSortDirection(1 - Ord(Sender.SortDirection));

  Sender.SortColumn := HitInfo.Column;

  // Keep focused node in center
  Sender.Treeview.ScrollIntoView(Sender.Treeview.FocusedNode, True);
end;


{$Hints off}
procedure TFormLogistics.VSTFreeNode(Sender: TBaseVirtualTree; Node: PVirtualNode);
var
  data: PKMLogisticsIDs;
begin
//todo: [dcc32 Hint] KM_FormLogistics.pas(590): H2243 Expression needs no Initialize/Finalize
//todo: [dcc32 Hint] KM_FormLogistics.pas(589): H2077 Value assigned to 'data' never used
  data := Sender.GetNodeData(Node);
  Finalize(data^);
end;
{$Hints on}


procedure TFormLogistics.VSTGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex; TextType: TVSTTextType; var CellText: string);
begin
  Assert(Sender is TKMHandLogisticsVST);

  case TKMHandLogisticsVST(Sender).Kind of
    vstkDelivery: VSTDeliveriesGetText(Sender, Node, Column, TextType, CellText);
    vstkOffer:    VSTOffersGetText(Sender, Node, Column, TextType, CellText);
    vstkDemand:   VSTDemandsGetText(Sender, Node, Column, TextType, CellText);
  end;
end;


procedure TFormLogistics.VSTDeliveriesGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
                                              TextType: TVSTTextType; var CellText: string);
var
  handID, iQ, iO, iD: Integer;
  oWT, dWT: TKMWareType;
  data: PKMLogisticsIDs;
  del: TKMDeliveries;
begin
  data := Sender.GetNodeData(Node);
  handID := data.HandID;

  del := gHands[handID].Deliveries.Queue;

  iQ := data.ID;
  iO := del.Delivery[iQ].OfferID;
  iD := del.Delivery[iQ].DemandID;
  oWT := del.Delivery[iQ].OfferWare;
  dWT := del.Delivery[iQ].DemandWare;

  if (iQ = DELIVERY_NO_ID) or (iQ > del.DeliveryCount) then
  begin
    CellText := '-';
    Exit;
  end;

  case VSTDeliveries.Header.Columns[Column].Tag of
    0:  CellText := IntToStr(Node.Index);
    1:  CellText := IntToStr(handID);
    2:  CellText := IntToStr(iQ);
    3:  CellText := gResWares[del.DeliveryWare[iQ]].Title;
    4:  if (iO = DELIVERY_NO_ID) or (oWT = wtNone) or (del.Offer[oWT, iO].Loc_House = nil) then
          CellText := 'nil'
        else
          CellText := gResHouses[del.Offer[oWT, iO].Loc_House.HouseType].HouseName;

    5:  if (iO = DELIVERY_NO_ID) or (oWT = wtNone) or (del.Offer[oWT, iO].Loc_House = nil) then
          CellText := '-'
        else
          CellText := IntToStr(del.Offer[oWT, iO].Loc_House.UID);

    6:  if (id <> DELIVERY_NO_ID) and (dWT <> wtNone) then
        begin
          if del.Demand[dWT, iD].Loc_House <> nil then
            CellText := 'H: ' + gResHouses[del.Demand[dWT, iD].Loc_House.HouseType].HouseName
          else
          if del.Demand[dWT, iD].Loc_Unit <> nil then
            CellText := 'U: ' + gRes.Units[del.Demand[dWT, iD].Loc_Unit.UnitType].GUIName;
        end
        else
          CellText := 'nil';
    7:  if (iD <> DELIVERY_NO_ID) and (dWT <> wtNone) then
        begin
          if del.Demand[dWT, iD].Loc_House <> nil then
            CellText := IntToStr(del.Demand[dWT, iD].Loc_House.UID)
          else
          if del.Demand[dWT, iD].Loc_Unit <> nil then
            CellText := IntToStr(del.Demand[dWT, iD].Loc_Unit.UID);
        end
        else
          CellText := 'nil';
    8:  CellText := IntToStr(del.Delivery[iQ].Serf.UID);
    9:  CellText := IntToStr(del.Delivery[iQ].Serf.Task.Phase);
  end;
end;


procedure TFormLogistics.VSTOffersGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
                                          TextType: TVSTTextType; var CellText: string);
var
  handID, iO: Integer;
  oWT: TKMWareType;
  data: PKMLogisticsIDs;
begin
  data := Sender.GetNodeData(Node);
  handID := data.HandID;
  iO := data.ID;
  oWT := data.Ware;

  if (iO = DELIVERY_NO_ID) or (oWT = wtNone) or (iO >= gHands[handID].Deliveries.Queue.OfferCount[oWT]) then
  begin
    CellText := '-';
    Exit;
  end;

  with gHands[handID].Deliveries.Queue.Offer[oWT,iO] do
    case VSTOffers.Header.Columns[Column].Tag of
      0:  CellText := IntToStr(Node.Index);
      1:  CellText := IntToStr(handID);
      2:  CellText := IntToStr(iO);
      3:  CellText := gResWares[oWT].Title;
      4:  if Loc_House = nil then
            CellText := 'nil'
          else
            CellText := gResHouses[Loc_House.HouseType].HouseName;

      5:  if Loc_House = nil then
            CellText := '-'
          else
            CellText := IntToStr(Loc_House.UID);

      6:  CellText := IntToStr(Count);
      7:  CellText := IntToStr(BeingPerformed);
      8:  CellText := BoolToStr(IsDeleted, True);
    end;
end;


procedure TFormLogistics.VSTDemandsGetText(Sender: TBaseVirtualTree; Node: PVirtualNode; Column: TColumnIndex;
                                           TextType: TVSTTextType; var CellText: string);
var
  handID, iD: Integer;
  dWT: TKMWareType;
  data: PKMLogisticsIDs;
begin
  data := Sender.GetNodeData(Node);
  handID := data.HandID;
  iD := data.ID;
  dWT := data.Ware;

  if (iD = DELIVERY_NO_ID) or (dWT = wtNone) or (iD >= gHands[handID].Deliveries.Queue.DemandCount[dWT]) then
  begin
    CellText := '-';
    Exit;
  end;

  with gHands[handID].Deliveries.Queue.Demand[dWT,iD] do
    case VSTDemands.Header.Columns[Column].Tag of
      0:  CellText := IntToStr(Node.Index);
      1:  CellText := IntToStr(handID);
      2:  CellText := IntToStr(iD);
      3:  CellText := gResWares[dWT].Title;
      4:  if Loc_House <> nil then
            CellText := 'H: ' + gResHouses[Loc_House.HouseType].HouseName
          else
          if Loc_Unit <> nil then
            CellText := 'U: ' + gRes.Units[Loc_Unit.UnitType].GUIName
          else
            CellText := 'nil';

      5:  if Loc_House <> nil then
            CellText := IntToStr(Loc_House.UID)
          else
          if Loc_Unit <> nil then
            CellText := IntToStr(Loc_Unit.UID)
          else
            CellText := '-';

      6:  CellText := GetEnumName(TypeInfo(TKMDemandType), Integer(DemandType));
      7:  CellText := GetEnumName(TypeInfo(TKMDemandImportance), Integer(Importance));
      8:  CellText := IntToStr(BeingPerformed);
      9:  CellText := BoolToStr(IsDeleted, True);
    end;
end;
{$ENDIF}


procedure TFormLogistics.vstPageCtrlChange(Sender: TObject);
begin
  //todo: Replace ActivePageIndex (0,1,2) with TKMLogisticsPage(ActivePageIndex) (lpDeliveries, lpOffers, lpDemands)
  case vstPageCtrl.ActivePageIndex of
    0:  begin
          // Deliveries
          cbFromID.Enabled := True;
          seFromID.Enabled := True;
          cbToID.Enabled := True;
          seToID.Enabled := True;
        end;
    1:  begin
          // Offers
          cbFromID.Enabled := True;
          seFromID.Enabled := True;
          cbToID.Enabled := False;
          seToID.Enabled := False;
        end;
    2:  begin
          // Demands
          cbFromID.Enabled := False;
          seFromID.Enabled := False;
          cbToID.Enabled := True;
          seToID.Enabled := True;
        end;
  end;
  FilterUpdated(Sender);
end;


procedure TFormLogistics.FilterUpdated(Sender: TObject);
begin
  {$IFDEF USE_VIRTUAL_TREEVIEW}
  ApplyFilter;
  {$ENDIF}
end;


{$IFDEF USE_VIRTUAL_TREEVIEW}
{ TKMHandLogisticsVST }
constructor TKMHandLogisticsVST.Create(aOwner: TComponent; aKind: TKMVSTKind);
begin
  inherited Create(AOwner);

  Kind := aKind;
end;


function TKMHandLogisticsVST.GetColumnsCnt: Integer;
begin
  Result := 0;
  case Kind of
    vstkDelivery:  Result := DELIVERIES_COL_COUNT;
    vstkOffer:     Result := OFFERS_COL_COUNT;
    vstkDemand:    Result := DEMANDS_COL_COUNT;
  end;
end;


function TKMHandLogisticsVST.GetDefColumn(aIndex: Integer): TKMVSTColumn;
begin
  case Kind of
    vstkDelivery:  Result := DEF_DELIVERIES_COLUMNS[aIndex];
    vstkOffer:     Result := DEF_OFFERS_COLUMNS[aIndex];
    vstkDemand:    Result := DEF_DEMANDS_COLUMNS[aIndex];
  end;
end;
{$ENDIF}


end.

