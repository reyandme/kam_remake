unit KM_GUIMapEdMenuLoad;
{$I KaM_Remake.inc}
interface
uses
   Classes, SysUtils,
   KM_Controls, KM_ControlsBase, KM_ControlsList, KM_ControlsSwitch,
   KM_Maps;

type
  TKMMapEdMenuLoad = class
  private
    fOnDone: TNotifyEvent;

    fMaps: TKMapsCollection;
    fMapsMP: TKMapsCollection;
    fMapsDL: TKMapsCollection;

    procedure Menu_LoadClick(Sender: TObject);
    procedure Menu_LoadChange(Sender: TObject);
    procedure Menu_LoadUpdate;
    procedure Menu_LoadUpdateDone(Sender: TObject);
  protected
    Panel_Load: TKMPanel;
    Radio_Load_MapType: TKMRadioGroup;
    ListBox_Load: TKMListBox;
    Button_LoadLoad: TKMButton;
    Button_LoadCancel: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
    destructor Destroy; override;

    procedure SetLoadMode(aMultiplayer: Boolean);
    procedure Show;
    procedure Hide;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResTexts, KM_Game, KM_GameApp, KM_RenderUI, KM_ResFonts, KM_InterfaceGame,
  KM_InterfaceMapEditor, KM_Defaults, KM_MapTypes, KM_CommonTypes;


{ TKMMapEdMenuLoad }
constructor TKMMapEdMenuLoad.Create(aParent: TKMPanel; aOnDone: TNotifyEvent);
begin
  inherited Create;

  fOnDone := aOnDone;

  fMaps := TKMapsCollection.Create(mkSP);
  fMapsMP := TKMapsCollection.Create(mkMP);
  fMapsDL := TKMapsCollection.Create(mkDL);

  Panel_Load := TKMPanel.Create(aParent,0,45,aParent.Width,aParent.Height - 45);
  Panel_Load.Anchors := [anLeft, anTop, anBottom];

  TKMLabel.Create(Panel_Load, 9, PAGE_TITLE_Y, Panel_Load.Width - 9, 30, gResTexts[TX_MAPED_LOAD_TITLE], fntOutline, taLeft).Anchors := [anLeft, anTop, anRight];
  TKMBevel.Create(Panel_Load, 9, 30, TB_MAP_ED_WIDTH - 9, 57).Anchors := [anLeft, anTop, anRight];
  Radio_Load_MapType := TKMRadioGroup.Create(Panel_Load,9,32,Panel_Load.Width - 9,54,fntGrey);
  Radio_Load_MapType.Anchors := [anLeft, anTop, anRight];
  Radio_Load_MapType.ItemIndex := 0;
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_SPMAPS]);
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_MPMAPS_SHORT]);
  Radio_Load_MapType.Add(gResTexts[TX_MENU_MAPED_DLMAPS]);
  Radio_Load_MapType.OnChange := Menu_LoadChange;
  ListBox_Load := TKMListBox.Create(Panel_Load, 9, 104, Panel_Load.Width - 9, 205, fntGrey, bsGame);
  ListBox_Load.Anchors := [anLeft, anTop, anRight];
  ListBox_Load.ItemHeight := 18;
  ListBox_Load.AutoHideScrollBar := True;
  ListBox_Load.ShowHintWhenShort := True;
  ListBox_Load.HintBackColor := TKMColor4f.New(87, 72, 37);
  ListBox_Load.SearchEnabled := True;
  ListBox_Load.OnDoubleClick := Menu_LoadClick;
  Button_LoadLoad     := TKMButton.Create(Panel_Load,9,318,Panel_Load.Width - 9,30,gResTexts[TX_MAPED_LOAD],bsGame);
  Button_LoadLoad.Anchors := [anLeft, anTop, anRight];
  Button_LoadCancel   := TKMButton.Create(Panel_Load,9,354,Panel_Load.Width - 9,30,gResTexts[TX_MAPED_LOAD_CANCEL],bsGame);
  Button_LoadCancel.Anchors := [anLeft, anTop, anRight];
  Button_LoadLoad.OnClick     := Menu_LoadClick;
  Button_LoadCancel.OnClick   := Menu_LoadClick;
end;


destructor TKMMapEdMenuLoad.Destroy;
begin
  fMaps.Free;
  fMapsMP.Free;
  fMapsDL.Free;

  inherited;
end;


//Mission loading dialog
procedure TKMMapEdMenuLoad.Menu_LoadClick(Sender: TObject);
var
  mapName: string;
  isMulti: Boolean;
begin
  if (Sender = Button_LoadLoad) or (Sender = ListBox_Load) then
  begin
    if ListBox_Load.ItemIndex = -1 then Exit;

    mapName := ListBox_Load.Item[ListBox_Load.ItemIndex];
    isMulti := Radio_Load_MapType.ItemIndex <> 0;
    gGameApp.NewMapEditor(TKMapsCollection.FullPath(mapName, '.dat', TKMMapKind(Radio_Load_MapType.ItemIndex + 1)), isMulti);
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
begin
  fMaps.TerminateScan;
  fMapsMP.TerminateScan;
  fMapsDL.TerminateScan;

  ListBox_Load.Clear;
  ListBox_Load.ItemIndex := -1;

  case Radio_Load_MapType.ItemIndex of
    0: fMaps.Refresh(Menu_LoadUpdateDone);
    1: fMapsMP.Refresh(Menu_LoadUpdateDone);
    2: fMapsDL.Refresh(Menu_LoadUpdateDone);
  else
    Exit;
  end;
end;


procedure TKMMapEdMenuLoad.Menu_LoadUpdateDone(Sender: TObject);
var
  I: Integer;
  prevMap: string;
  prevTop: Integer;
  M: TKMapsCollection;
begin
  case Radio_Load_MapType.ItemIndex of
    0: M := fMaps;
    1: M := fMapsMP;
    2: M := fMapsDL;
  else
    Exit;
  end;

  //Remember previous map
  if ListBox_Load.ItemIndex <> -1 then
    prevMap := M.Maps[ListBox_Load.ItemIndex].Name
  else
    prevMap := '';
  prevTop := ListBox_Load.TopIndex;

  ListBox_Load.Clear;

  M.Lock;
  try
    for I := 0 to M.Count - 1 do
    begin
      ListBox_Load.Add(M.Maps[I].Name);
      if M.Maps[I].Name = prevMap then
        ListBox_Load.ItemIndex := I;
    end;
  finally
    M.Unlock;
  end;

  ListBox_Load.TopIndex := prevTop;
end;


procedure TKMMapEdMenuLoad.Hide;
begin
  fMaps.TerminateScan;
  fMapsMP.TerminateScan;
  fMapsDL.TerminateScan;
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
end;


procedure TKMMapEdMenuLoad.SetLoadMode(aMultiplayer: Boolean);
begin
  if aMultiplayer then
    Radio_Load_MapType.ItemIndex := 1
  else
    Radio_Load_MapType.ItemIndex := 0;
end;


end.
