unit KM_GUIMapEdTerrainSelection;
{$I KaM_Remake.inc}
interface
uses
   {$IFDEF MSWindows} Windows, {$ENDIF}
   {$IFDEF Unix} LCLIntf, LCLType, {$ENDIF}
   Classes, Math, SysUtils, KM_Utils,
   KM_Controls, KM_ControlsBase,
   KM_Defaults,
   KM_InterfaceDefaults,
   KM_GUIMapEdRMG, KM_Pics, KM_TerrainTypes;

type
  TKMMapEdTerrainSelection = class(TKMMapEdSubMenuPage)
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
      Map_PasteType: array [TKMTerrainSelectionPasteType] of  TKMButtonFlat;
      Button_RMGRND: TKMButton;
      Button_SelectSetCoal: TKMButton;
  public
    constructor Create(aParent: TKMPanel);
    destructor Destroy; override;

    property GuiRMGPopUp: TKMMapEdRMG read fRMGPopUp write fRMGPopUp;
    procedure Show;
    function Visible: Boolean; override;
    procedure KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
    procedure Hide;
    procedure UpdateHotkeys;
    procedure UpdateState;
  end;


implementation
uses
  KM_ResFonts, KM_ResTexts,
  KM_Game, KM_Cursor, KM_RenderUI,
  KM_TerrainSelection, KM_MapEdTypes,
  KM_InterfaceGame,
  KM_ResTypes;


{ TKMMapEdTerrainSelection }
constructor TKMMapEdTerrainSelection.Create(aParent: TKMPanel);
const
  PAST_TYPE_RX_INDEX: array[TKMTerrainSelectionPasteType] of Integer = (383, 388, 385, 400);

  PAST_TYPE_HINT: array[TKMTerrainSelectionPasteType] of Integer = (TX_MAPED_COPY_PASTE_TERRAIN_HINT,
                                                                    TX_MAPED_COPY_PASTE_HEIGHTS_HINT,
                                                                    TX_MAPED_COPY_PASTE_OBJECTS_HINT,
                                                                    TX_MAPED_COPY_PASTE_OVERLAYS_HINT);
var
  PT: TKMTerrainSelectionPasteType;
begin
  inherited Create;

  Panel_Selection := TKMPanel.Create(aParent, 0, 28, aParent.Width, 400);

  with TKMLabel.Create(Panel_Selection, 0, TERRAIN_PAGE_TITLE_Y, Panel_Selection.Width, 0, gResTexts[TX_MAPED_COPY_TITLE], fntOutline, taCenter) do
    Anchors := [anLeft, anTop, anRight];
  Button_SelectCopy := TKMButton.Create(Panel_Selection, 9, 30, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_COPY], bsGame);
  Button_SelectCopy.Anchors := [anLeft, anTop, anRight];
  Button_SelectCopy.OnClick := SelectionClick;

  Button_SelectPaste := TKMButton.Create(Panel_Selection, 9, 60, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_PASTE], bsGame);
  Button_SelectPaste.Anchors := [anLeft, anTop, anRight];
  Button_SelectPaste.OnClick := SelectionClick;

  Button_SelectPasteApply := TKMButton.Create(Panel_Selection, 9, 90, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_PASTE_APPLY], bsGame);
  Button_SelectPasteApply.Anchors := [anLeft, anTop, anRight];
  Button_SelectPasteApply.OnClick := SelectionClick;

  Button_SelectPasteCancel := TKMButton.Create(Panel_Selection, 9, 120, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_PASTE_CANCEL], bsGame);
  Button_SelectPasteCancel.Anchors := [anLeft, anTop, anRight];
  Button_SelectPasteCancel.OnClick := SelectionClick;

  for PT := Low(TKMTerrainSelectionPasteType) to High(TKMTerrainSelectionPasteType) do
  begin
    Map_PasteType[PT] := TKMButtonFlat.Create(Panel_Selection, 17 + 50 * Ord(PT), 150, 34, 34, PAST_TYPE_RX_INDEX[PT], rxGui);
    Map_PasteType[PT].OnClick := SelectionClick;
    Map_PasteType[PT].Hint := gResTexts[PAST_TYPE_HINT[PT]];
    Map_PasteType[PT].Down := true;
  end;

  Button_SelectFlipH := TKMButton.Create(Panel_Selection, 9, 210, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_COPY_PASTE_HFLIP], bsGame);
  Button_SelectFlipH.Anchors := [anLeft, anTop, anRight];
  Button_SelectFlipH.OnClick := SelectionClick;

  Button_SelectFlipV := TKMButton.Create(Panel_Selection, 9, 240, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_COPY_PASTE_VFLIP], bsGame);
  Button_SelectFlipV.Anchors := [anLeft, anTop, anRight];
  Button_SelectFlipV.OnClick := SelectionClick;

  TKMLabel.Create(Panel_Selection, 9, 280, Panel_Selection.Width - 9, 80, gResTexts[TX_MAPED_COPY_SELECT_HINT], fntGrey, taLeft).WordWrap := True;

  Button_RMGRND := TKMButton.Create(Panel_Selection, 9, 330, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_RMG_BUTTON_TITLE], bsGame);
  Button_RMGRND.Anchors := [anLeft, anTop, anRight];
  Button_RMGRND.OnClick := GenerateMapClick;

  Button_SelectSetCoal := TKMButton.Create(Panel_Selection, 9, 360, Panel_Selection.Width - 9, 20, gResTexts[TX_MAPED_SELECTION_SMOOTH_COAL], bsGame);
  Button_SelectSetCoal.Anchors := [anLeft, anTop, anRight];
  Button_SelectSetCoal.OnClick := SelectionClick;
  Button_SelectSetCoal.Hint := gResTexts[TX_MAPED_SELECTION_SMOOTH_COAL_HINT];


  fSubMenuActionsEvents[0] := SelectionClick;
  fSubMenuActionsEvents[1] := SelectionClick;
  fSubMenuActionsEvents[2] := SelectionClick;
  fSubMenuActionsEvents[3] := SelectionClick;
  fSubMenuActionsEvents[4] := SelectionClick;
  fSubMenuActionsEvents[5] := SelectionClick;
  fSubMenuActionsEvents[6] := GenerateMapClick;

  fSubMenuActionsCtrls[0,0] := Button_SelectCopy;
  fSubMenuActionsCtrls[1,0] := Button_SelectPaste;
  fSubMenuActionsCtrls[2,0] := Button_SelectPasteApply;
  fSubMenuActionsCtrls[3,0] := Button_SelectPasteCancel;
  fSubMenuActionsCtrls[4,0] := Button_SelectFlipH;
  fSubMenuActionsCtrls[5,0] := Button_SelectFlipV;
  fSubMenuActionsCtrls[6,0] := Button_RMGRND;
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
var
  PT: TKMTerrainSelectionPasteType;
begin
  gCursor.Mode := cmSelection;
  gCursor.Tag1 := 0;

  for PT := Low(TKMTerrainSelectionPasteType) to High(TKMTerrainSelectionPasteType) do
    if Sender = Map_PasteType[PT] then
    begin
      Map_PasteType[PT].Down := not Map_PasteType[PT].Down;
      if Map_PasteType[PT].Down then
        gGame.MapEditor.Selection.IncludePasteType(PT)
      else
        gGame.MapEditor.Selection.ExcludePasteType(PT);

      Break;
    end;

  if Sender = Button_SelectCopy then
  begin
    //Copy selection into cursor
    gGame.MapEditor.Selection.CopyLandToBuffer;
    Button_SelectPaste.Enabled := gGame.MapEditor.Selection.HasDataInBuffer;
  end
  else
  if Sender = Button_SelectPaste then
  begin
    //Paste selection
    gGame.MapEditor.Selection.PasteBegin;

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
    gGame.MapEditor.Selection.PasteApply;
    gGame.MapEditor.History.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_PASTE]);

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
    gGame.MapEditor.Selection.PasteCancel;
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
    gGame.MapEditor.Selection.Flip(faHorizontal);
    gGame.MapEditor.History.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_COPY_PASTE_HFLIP]);
  end
  else
  if Sender = Button_SelectFlipV then
  begin
    //Flip selected
    gGame.MapEditor.Selection.Flip(faVertical);
    gGame.MapEditor.History.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_COPY_PASTE_VFLIP]);
  end
  else
  if Sender = Button_SelectSetCoal then
  begin
    gGame.MapEditor.Selection.SetNiceCoal;
    gGame.MapEditor.History.MakeCheckpoint(caTerrain, gResTexts[TX_MAPED_SELECTION_SMOOTH_COAL]);
  end;
end;


procedure TKMMapEdTerrainSelection.Show;
begin
  gCursor.Mode := cmSelection;
  gCursor.Tag1 := 0;
  gGame.MapEditor.Selection.Prepare; //Could be leftover from last time we were visible

  Button_SelectPasteApply.Disable;
  Button_SelectPasteCancel.Disable;
  Button_SelectCopy.Enable;
  Button_SelectFlipH.Enable;
  Button_SelectFlipV.Enable;
  Button_SelectPaste.Enabled := gGame.MapEditor.Selection.HasDataInBuffer;

  Panel_Selection.Show;
end;


function TKMMapEdTerrainSelection.Visible: Boolean;
begin
  Result := Panel_Selection.Visible;
end;


procedure TKMMapEdTerrainSelection.Hide;
begin
  if Panel_Selection.Visible then
    gGame.MapEditor.Selection.Cancel;
  Panel_Selection.Hide;
end;


procedure TKMMapEdTerrainSelection.UpdateHotkeys;
begin
  Button_SelectCopy.Hint        := GetHintWHotkey(TX_MAPED_COPY_COPY_HINT,        kfMapedSubMenuAction1);
  Button_SelectPaste.Hint       := GetHintWHotkey(TX_MAPED_COPY_PASTE_HINT,       kfMapedSubMenuAction2);
  Button_SelectPasteApply.Hint  := GetHintWHotkey(TX_MAPED_COPY_PASTE_HINT,       kfMapedSubMenuAction3);
  Button_SelectPasteCancel.Hint := GetHintWHotkey(TX_MAPED_COPY_PASTE_HINT,       kfMapedSubMenuAction4);
  Button_SelectFlipH.Hint       := GetHintWHotkey(TX_MAPED_COPY_PASTE_HFLIP_HINT, kfMapedSubMenuAction5);
  Button_SelectFlipV.Hint       := GetHintWHotkey(TX_MAPED_COPY_PASTE_VFLIP_HINT, kfMapedSubMenuAction6);
  Button_RMGRND.Hint            := GetHintWHotkey(TX_MAPED_RMG_BUTTON_HINT,       kfMapedSubMenuAction7);
end;


procedure TKMMapEdTerrainSelection.UpdateState;
begin
  Button_SelectPaste.Enabled := gGame.MapEditor.Selection.HasDataInBuffer;
end;


procedure TKMMapEdTerrainSelection.KeyDown(Key: Word; Shift: TShiftState; aIsFirst: Boolean; var aHandled: Boolean);
begin
  if aHandled or not aIsFirst then Exit;

  if (Key = VK_ESCAPE) and fRMGPopUp.Visible then
  begin
    fRMGPopUp.Hide;
    aHandled := True;
  end;
end;


end.
