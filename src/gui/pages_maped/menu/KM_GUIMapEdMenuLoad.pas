unit KM_GUIMapEdMenuLoad;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils, Math,
   KM_Controls, KM_Maps;

type
  TKMMapEdMenuLoad = class
  private
    fOnDone: TNotifyEvent;

    fMaps: TKMapsCollection;
    fMapsMP: TKMapsCollection;
    fMapsDL: TKMapsCollection;
    fMapsCM: TKMapsCollection;

    procedure Menu_LoadClick(Sender: TObject);
    procedure Menu_LoadChange(Sender: TObject);
    procedure Menu_LoadUpdate;
    procedure Menu_LoadUpdateDone(Sender: TObject);
  protected
    Panel_Load: TKMPanel;
    Radio_Load_MapType: TKMRadioGroup;
    DropBox_Campaigns: TKMDropList;
    ListBox_Load: TKMListBox;
    Button_LoadLoad: TKMButton;
    Button_LoadCancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
    destructor Destroy; override;

    procedure SetLoadMode(aMultiplayer:boolean);
    procedure Show;
    procedure Hide;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, KM_Game, KM_GameApp, KM_RenderUI, KM_ResFonts, KM_InterfaceGame,
  KM_InterfaceMapEditor, KM_Defaults, KM_Campaigns;


{ TKMMapEdMenuLoad }
constructor TKMMapEdMenuLoad.Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
var
  I: Integer;
begin
  inherited Create;

  fOnDone := aOnDone;

  fMaps := TKMapsCollection.Create(mfSP);
  fMapsMP := TKMapsCollection.Create(mfMP);
  fMapsDL := TKMapsCollection.Create(mfDL);
  fMapsCM := TKMapsCollection.Create(mfCM);

  Panel_Load := TKMPanel.Create(aParent,0,45,aParent.Width,aParent.Height - 45);
  Panel_Load.Anchors := [anLeft, anTop, anBottom];

  with TKMLabel.Create(Panel_Load, 9, PAGE_TITLE_Y, Panel_Load.Width - 9, 30, gResTexts[TX_MAPED_LOAD_TITLE], fntOutline, taLeft) do
    Anchors := [anLeft, anTop, anRight];

  with TKMBevel.Create(Panel_Load, 9, 30, TB_MAP_ED_WIDTH - 9, 82) do
    Anchors := [anLeft, anTop, anRight];

  Radio_Load_MapType := TKMRadioGroup.Create(Panel_Load,9,32,Panel_Load.Width - 9,80,fntGrey);
  Radio_Load_MapType.Anchors := [anLeft, anTop, anRight];
  Radio_Load_MapType.ItemIndex := 0;
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Load_MapType.Add(gResTexts[TX_MENU_CAMPAIGNS]);
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_DLMAPS]);
  Radio_Load_MapType.OnChange := Menu_LoadChange;

  DropBox_Campaigns := TKMDropList.Create(Panel_Load, 9, 120, Panel_Load.Width - 9, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
  DropBox_Campaigns.Anchors := [anLeft, anBottom];
  DropBox_Campaigns.OnChange := Menu_LoadChange;
  DropBox_Campaigns.Clear;
  for I := 0 to gGameApp.Campaigns.Count - 1 do
    DropBox_Campaigns.Add(gGameApp.Campaigns[I].GetCampaignTitle);
  DropBox_Campaigns.Hide;

  ListBox_Load := TKMListBox.Create(Panel_Load, 9, 145, Panel_Load.Width - 9, 175, fntGrey, bsGame);
  ListBox_Load.Anchors := [anLeft, anTop, anRight];
  ListBox_Load.ItemHeight := 18;
  ListBox_Load.AutoHideScrollBar := True;
  ListBox_Load.SearchEnabled := True;
  ListBox_Load.OnDoubleClick := Menu_LoadClick;

  Button_LoadLoad     := TKMButton.Create(Panel_Load,9,335,Panel_Load.Width - 9,30,gResTexts[TX_MAPED_LOAD],bsGame);
  Button_LoadLoad.Anchors := [anLeft, anTop, anRight];
  Button_LoadCancel   := TKMButton.Create(Panel_Load,9,370,Panel_Load.Width - 9,30,gResTexts[TX_MAPED_LOAD_CANCEL],bsGame);
  Button_LoadCancel.Anchors := [anLeft, anTop, anRight];
  Button_LoadLoad.OnClick     := Menu_LoadClick;
  Button_LoadCancel.OnClick   := Menu_LoadClick;
end;


destructor TKMMapEdMenuLoad.Destroy;
begin
  fMaps.Free;
  fMapsMP.Free;
  fMapsDL.Free;
  fMapsCM.Free;
  inherited;
end;


//Mission loading dialog
procedure TKMMapEdMenuLoad.Menu_LoadClick(Sender: TObject);
var
  MapName: string;
  IsMulti: Boolean;
  Maps: TKMapsCollection;
  Map: TKMapInfo;
  Campaign: TKMCampaign;
begin
  if (Sender = Button_LoadLoad) or (Sender = ListBox_Load) then
  begin
    if ListBox_Load.ItemIndex = -1 then
      Exit;

    case Radio_Load_MapType.ItemIndex of
      0: Maps := fMaps;
      1: Maps := fMapsMP;
      2: Maps := fMapsCM;
      3: Maps := fMapsDL
      else Exit;
    end;

    IsMulti := Radio_Load_MapType.ItemIndex <> 0;
    Map := Maps[ListBox_Load.ItemTags[ListBox_Load.ItemIndex]];
    gGameApp.NewMapEditor(Map.FullPath('.dat'), 0, 0, Map.CRC, Map.MapAndDatCRC);

    //Keep MP/SP selected in the map editor interface
    //(if mission failed to load we would have fGame = nil)
    if (gGame <> nil) and (gGame.ActiveInterface is TKMapEdInterface) then
      TKMapEdInterface(gGame.ActiveInterface).SetLoadMode(IsMulti);
  end
  else
  if Sender = Button_LoadCancel then
    fOnDone(Self);
end;


procedure TKMMapEdMenuLoad.Menu_LoadChange(Sender: TObject);
begin
  Menu_LoadUpdate;
end;


procedure TKMMapEdMenuLoad.Menu_LoadUpdate;
var
  I: Integer;
begin
  fMaps.TerminateScan;
  fMapsMP.TerminateScan;
  fMapsDL.TerminateScan;
  fMapsCM.TerminateScan;

  ListBox_Load.Clear;
  ListBox_Load.ItemIndex := -1;

  DropBox_Campaigns.Visible := Radio_Load_MapType.ItemIndex = 2;
  ListBox_Load.Top := IfThen(DropBox_Campaigns.Visible, 145, 120);
  ListBox_Load.Height := IfThen(DropBox_Campaigns.Visible, 180, 205);

  //DropBox_Campaigns.ItemIndex := gGameApp.GameSettings.MenuMapEdCMIndex;

  case Radio_Load_MapType.ItemIndex of
    0: fMaps.Refresh(Menu_LoadUpdateDone);
    1: fMapsMP.Refresh(Menu_LoadUpdateDone);
    2: fMapsCM.Refresh(Menu_LoadUpdateDone);
    3: fMapsDL.Refresh(Menu_LoadUpdateDone);
    else Exit;
  end;
end;


procedure TKMMapEdMenuLoad.Menu_LoadUpdateDone(Sender: TObject);
var
  I: Integer;
  PrevMap: string;
  PrevTop: Integer;
  M: TKMapsCollection;
  Campaign: TKMCampaign;
begin
  case Radio_Load_MapType.ItemIndex of
    0: M := fMaps;
    1: M := fMapsMP;
    2: M := fMapsCM;
    3: M := fMapsDL
    else Exit;
  end;

  //Remember previous map
  if ListBox_Load.ItemIndex <> -1 then
    PrevMap := M.Maps[ListBox_Load.ItemIndex].FileName
  else
    PrevMap := '';
  PrevTop := ListBox_Load.TopIndex;

  Campaign := nil;
  if (Radio_Load_MapType.ItemIndex = 2) and (DropBox_Campaigns.ItemIndex >= 0) then
    Campaign := gGameApp.Campaigns[DropBox_Campaigns.ItemIndex];

  ListBox_Load.Clear;

  M.Lock;
  try
    for I := 0 to M.Count - 1 do
    begin
      if (Radio_Load_MapType.ItemIndex = 2) and (not Assigned(Campaign) or not CompareCampaignId(M.Maps[I].CampaignId, Campaign.CampaignId)) then
        Continue;

      ListBox_Load.Add(M.Maps[I].FileName, I);
      if M.Maps[I].FileName = PrevMap then
        ListBox_Load.ItemIndex := ListBox_Load.Count - 1;
    end;
  finally
    M.Unlock;
  end;

  ListBox_Load.TopIndex := PrevTop;
end;


procedure TKMMapEdMenuLoad.Hide;
begin
  fMaps.TerminateScan;
  fMapsMP.TerminateScan;
  fMapsDL.TerminateScan;
  fMapsCM.TerminateScan;
  Panel_Load.Hide;
end;


procedure TKMMapEdMenuLoad.Show;
begin
  Menu_LoadUpdate;
  Panel_Load.Show;
end;


procedure TKMMapEdMenuLoad.UpdateState;
begin
  if fMaps <> nil then fMaps.UpdateState;
  if fMapsMP <> nil then fMapsMP.UpdateState;
  if fMapsDL <> nil then fMapsDL.UpdateState;
  if fMapsCM <> nil then fMapsCM.UpdateState;
end;


procedure TKMMapEdMenuLoad.SetLoadMode(aMultiplayer: Boolean);
begin
  if aMultiplayer then
    Radio_Load_MapType.ItemIndex := 1
  else
    Radio_Load_MapType.ItemIndex := 0;
end;


end.
