unit KM_GUIMapEdTerrainSelection;
{$I KaM_Remake.inc}
interface
uses
   Math, SysUtils, KM_Utils,
   KM_Controls, KM_Defaults,
   KM_InterfaceDefaults,
   KM_GUIMapEdRMG;

type
  TKMMapEdTerrainSelection = class (TKMMapEdSubMenuPage)
  private
    fRMGPopUp: TKMMapEdRMG;
    procedure SelectionClick(Sender: TObject);
    procedure GenerateMapClick(Sender: TObject);
  protected
    Panel_Selection: TKMPanel;
      Button_SelectCopy: TKMButton;
      Button_SelectPaste: TKMButton;
      Button_SelectPasteApply: TKMButton;
      Button_SelectPasteCancel: TKMButton;
      Button_SelectFlipH, Button_SelectFlipV: TKMButton;
      Button_RMGRND: TKMButton;
  public
    constructor Create(aParent: TKMPanel);
    destructor Destroy; override;

    property GuiRMGPopUp: TKMMapEdRMG read fRMGPopUp write fRMGPopUp;
    procedure Show;
    function Visible: Boolean; override;
    procedure Hide;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResFonts, KM_ResTexts,
  KM_Game, KM_GameCursor, KM_RenderUI, KM_ResKeys,
  KM_TerrainSelection, KM_Terrain,
  KM_InterfaceGame;


{ TKMMapEdTerrainSelection }
constructor TKMMapEdTerrainSelection.Create(aParent: TKMPanel);
begin
  inherited Create;

  Panel_Selection := TKMPanel.Create(aParent, 0, 28, TB_MAP_ED_WIDTH, 400);

  TKMLabel.Create(Panel_Selection, 0, PAGE_TITLE_Y, TB_MAP_ED_WIDTH, 0, gResTexts[TX_MAPED_COPY_TITLE], fntOutline, taCenter);
  Button_SelectCopy := TKMButton.Create(Panel_Selection, 9, 30, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_COPY], bsGame);
  Button_SelectCopy.Hint := GetHintWHotKey(TX_MAPED_COPY_COPY_HINT, SC_MAPEDIT_SUB_MENU_ACTION_1);
  Button_SelectCopy.OnClick := SelectionClick;

  Button_SelectPaste := TKMButton.Create(Panel_Selection, 9, 60, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_PASTE], bsGame);
  Button_SelectPaste.Hint := GetHintWHotKey(TX_MAPED_COPY_PASTE_HINT, SC_MAPEDIT_SUB_MENU_ACTION_2);
  Button_SelectPaste.OnClick := SelectionClick;

  Button_SelectPasteApply := TKMButton.Create(Panel_Selection, 9, 90, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_PASTE_APPLY], bsGame);
  Button_SelectPasteApply.Hint := GetHintWHotKey(TX_MAPED_COPY_PASTE_HINT, SC_MAPEDIT_SUB_MENU_ACTION_3);
  Button_SelectPasteApply.OnClick := SelectionClick;

  Button_SelectPasteCancel := TKMButton.Create(Panel_Selection, 9, 120, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_PASTE_CANCEL], bsGame);
  Button_SelectPasteCancel.Hint := GetHintWHotKey(TX_MAPED_COPY_PASTE_HINT, SC_MAPEDIT_SUB_MENU_ACTION_4);
  Button_SelectPasteCancel.OnClick := SelectionClick;

  Button_SelectFlipH := TKMButton.Create(Panel_Selection, 9, 180, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_COPY_PASTE_HFLIP], bsGame);
  Button_SelectFlipH.Hint := GetHintWHotKey(TX_MAPED_COPY_PASTE_HFLIP_HINT, SC_MAPEDIT_SUB_MENU_ACTION_5);
  Button_SelectFlipH.OnClick := SelectionClick;

  Button_SelectFlipV := TKMButton.Create(Panel_Selection, 9, 210, TB_MAP_ED_WIDTH - 8, 20, gResTexts[TX_MAPED_COPY_PASTE_VFLIP], bsGame);
  Button_SelectFlipV.Hint := GetHintWHotKey(TX_MAPED_COPY_PASTE_VFLIP_HINT, SC_MAPEDIT_SUB_MENU_ACTION_6);
  Button_SelectFlipV.OnClick := SelectionClick;

  with TKMLabel.Create(Panel_Selection, 8, 250, TB_MAP_ED_WIDTH-16, 80, gResTexts[TX_MAPED_COPY_SELECT_HINT], fntGrey, taLeft) do
    AutoWrap := True;

  Button_RMGRND := TKMButton.Create(Panel_Selection, 9, 300, TB_MAP_ED_WIDTH - 9, 20, 'RMG Settings', bsGame); //Todo translate
  Button_RMGRND.Hint := GetHintWHotKey('RMG Settings', SC_MAPEDIT_SUB_MENU_ACTION_7); //Todo translate
  Button_RMGRND.OnClick := GenerateMapClick;

  fSubMenuActionsEvents[0] := SelectionClick;
  fSubMenuActionsEvents[1] := SelectionClick;
  fSubMenuActionsEvents[2] := SelectionClick;
  fSubMenuActionsEvents[3] := SelectionClick;
  fSubMenuActionsEvents[4] := SelectionClick;
  fSubMenuActionsEvents[5] := SelectionClick;
  fSubMenuActionsEvents[6] := GenerateMapClick;

  fSubMenuActionsCtrls[0] := Button_SelectCopy;
  fSubMenuActionsCtrls[1] := Button_SelectPaste;
  fSubMenuActionsCtrls[2] := Button_SelectPasteApply;
  fSubMenuActionsCtrls[3] := Button_SelectPasteCancel;
  fSubMenuActionsCtrls[4] := Button_SelectFlipH;
  fSubMenuActionsCtrls[5] := Button_SelectFlipV;
  fSubMenuActionsCtrls[6] := Button_RMGRND;
end;


destructor TKMMapEdTerrainSelection.Destroy;
begin
  fRMGPopUp.Free();
  inherited;
end;

procedure TKMMapEdTerrainSelection.GenerateMapClick(Sender: TObject);
begin
  fRMGPopUp.Show;
end;


procedure TKMMapEdTerrainSelection.SelectionClick(Sender: TObject);
begin
  gGameCursor.Mode := cmSelection;
  gGameCursor.Tag1 := 0;

  if Sender = Button_SelectCopy then
  begin
    //Copy selection into cursor
    gGame.MapEditor.Selection.Selection_Copy;
    Button_SelectPaste.Enabled := gGame.MapEditor.Selection.Selection_DataInBuffer;
  end
  else
  if Sender = Button_SelectPaste then
  begin
    //Paste selection
    gGame.MapEditor.Selection.Selection_PasteBegin;

    Button_SelectPasteApply.Enable;
    Button_SelectPasteCancel.Enable;
    Button_SelectCopy.Disable;
    Button_SelectPaste.Disable;
    Button_SelectFlipH.Disable;
    Button_SelectFlipV.Disable;
  end
  else
  if Sender = Button_SelectPasteApply then
  begin
    //Apply paste
    gGame.MapEditor.Selection.Selection_PasteApply;
    gGame.MapEditor.TerrainPainter.MakeCheckpoint;

    Button_SelectPasteApply.Disable;
    Button_SelectPasteCancel.Disable;
    Button_SelectCopy.Enable;
    Button_SelectPaste.Enable;
    Button_SelectFlipH.Enable;
    Button_SelectFlipV.Enable;
  end
  else
  if Sender = Button_SelectPasteCancel then
  begin
    //Cancel pasting
    gGame.MapEditor.Selection.Selection_PasteCancel;
    Button_SelectPasteApply.Disable;
    Button_SelectPasteCancel.Disable;
    Button_SelectCopy.Enable;
    Button_SelectPaste.Enable;
    Button_SelectFlipH.Enable;
    Button_SelectFlipV.Enable;
  end
  else
  if Sender = Button_SelectFlipH then
  begin
    //Flip selected
    gGame.MapEditor.Selection.Selection_Flip(faHorizontal);
    gGame.MapEditor.TerrainPainter.MakeCheckpoint;
  end
  else
  if Sender = Button_SelectFlipV then
  begin
    //Flip selected
    gGame.MapEditor.Selection.Selection_Flip(faVertical);
    gGame.MapEditor.TerrainPainter.MakeCheckpoint;
  end;
end;


procedure TKMMapEdTerrainSelection.Show;
begin
  gGameCursor.Mode := cmSelection;
  gGameCursor.Tag1 := 0;
  gGame.MapEditor.Selection.Selection_PasteCancel; //Could be leftover from last time we were visible

  Button_SelectPasteApply.Disable;
  Button_SelectPasteCancel.Disable;
  Button_SelectCopy.Enable;
  Button_SelectFlipH.Enable;
  Button_SelectFlipV.Enable;
  Button_SelectPaste.Enabled := gGame.MapEditor.Selection.Selection_DataInBuffer;

  Panel_Selection.Show;
end;


function TKMMapEdTerrainSelection.Visible: Boolean;
begin
  Result := Panel_Selection.Visible;
end;


procedure TKMMapEdTerrainSelection.Hide;
begin
  Panel_Selection.Hide;
end;


procedure TKMMapEdTerrainSelection.UpdateState;
begin
  Button_SelectPaste.Enabled := gGame.MapEditor.Selection.Selection_DataInBuffer;
end;


end.
