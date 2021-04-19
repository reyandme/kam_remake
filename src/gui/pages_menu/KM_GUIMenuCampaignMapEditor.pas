unit KM_GUIMenuCampaignMapEditor;
{$I KaM_Remake.inc}
interface
uses
  Classes, Controls, SysUtils, Math, KM_Maps,
  KM_Controls, KM_Pics, KM_MapTypes, KM_CampaignTypes,
  KM_Campaigns, KM_InterfaceDefaults, KM_InterfaceTypes, KM_GameSettings;

type
  TKMMenuCampaignMapEditor = class (TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class

    fCampaign: TKMCampaign;

    fScrollVisible: Boolean;
    fScrollPanelPosition: Boolean;

    fPopUpMenuObject: TObject;
    fPopUpMenuPositionX: Integer;
    fPopUpMenuPositionY: Integer;

    procedure BackClick(Sender: TObject);
    procedure ScrollPositionClick(Sender: TObject);
    procedure ScrollToggle(Sender: TObject);

    procedure SelectMission(Sender: TObject);
    procedure SelectNode(Sender: TObject);
    procedure MoveMap(Sender: TObject);
    procedure MoveNode(Sender: TObject);

    procedure PopUpMenuContextPopup(Sender: TObject; X, Y: Integer; var Handled: Boolean);
    procedure PopUpMenuMapClick(Sender: TObject);

    procedure PopUpMenuFlagClick(Sender: TObject);
    procedure PopUpMenuSubNodeClick(Sender: TObject);

    procedure UpdateMaps;
    procedure UpdateNodes;
    procedure UpdateState;
  protected
    Panel_Campaign: TKMPanel;
      Label_Test: TKMLabel;

      Image_CampaignBG: TKMImage;
      PopUpMenu_Map, PopUpMenu_Flag, PopUpMenu_SubNode: TKMPopUpMenu;
      Panel_Campaign_Map: TKMPanel;
        Image_CampaignFlags: array[0..MAX_CAMP_MAPS - 1] of TKMImage;
        Label_CampaignFlags: array[0..MAX_CAMP_MAPS - 1] of TKMLabel;
        Image_CampaignSubNode: array[0..MAX_CAMP_NODES - 1] of TKMImage;
        Label_CampaignSubNode: array[0..MAX_CAMP_NODES - 1] of TKMLabel;

      Panel_CampScroll: TKMPanel;
        Image_ScrollTop, Image_Scroll, Image_ScrollClose: TKMImage;
        ListBox_Missions, ListBox_Nodes: TKMListBox;

      Label_Missions: TKMLabel;
      DropBox_Missions: TKMDropList;

      Image_ScrollRestore: TKMImage;
      Button_ScrollPosition, Button_CampaignBack: TKMButton;
  public
    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);

    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure Resize(X, Y: Word);
    procedure Show(aCampaign: TKMCampaignId);

    procedure RefreshCampaign;
  end;


implementation

uses
  KM_GameApp, KM_ResTexts, KM_RenderUI, KM_ResFonts, KM_Sound, KM_ResSound, KM_Defaults, KM_Video;

const
  FLAG_LABEL_OFFSET_X = 10;
  FLAG_LABEL_OFFSET_Y = 7;

  NODE_LABEL_OFFSET_X = 7;
  NODE_LABEL_OFFSET_Y = 2;

{ TKMMenuCampaignMapEditor }



{ TKMGUIMainCampaign }
constructor TKMMenuCampaignMapEditor.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
var
  I: Integer;
begin
  inherited Create(gpCampaign);

  fScrollPanelPosition := True;
  fScrollVisible := True;
  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  Panel_Campaign := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Campaign.AnchorsStretch;

  PopUpMenu_Map := TKMPopUpMenu.Create(aParent, 200);
  PopUpMenu_Map.AddItem('Add flag', 0);
  PopUpMenu_Map.AddItem('Add node', 1);
  PopUpMenu_Map.OnClick := PopUpMenuMapClick;

  PopUpMenu_Flag := TKMPopUpMenu.Create(aParent, 200);
  PopUpMenu_Flag.AddItem('Delete', 0);
  PopUpMenu_Flag.OnClick := PopUpMenuFlagClick;

  PopUpMenu_SubNode := TKMPopUpMenu.Create(aParent, 200);
  PopUpMenu_SubNode.AddItem('Delete', 0);
  PopUpMenu_SubNode.OnClick := PopUpMenuSubNodeClick;

    Panel_Campaign_Map := TKMPanel.Create(Panel_Campaign, 0, 0, aParent.Width, aParent.Height);
    Panel_Campaign_Map.AnchorsStretch;

    Image_CampaignBG := TKMImage.Create(Panel_Campaign_Map, 0, 0, aParent.Width, aParent.Height,0,rxGuiMain);
    Image_CampaignBG.ImageStretch;
    Image_CampaignBG.PopUpMenu := PopUpMenu_Map;
    Image_CampaignBG.OnContextPopup := PopUpMenuContextPopup;

    Label_Test := TKMLabel.Create(Panel_Campaign_Map, aParent.Width, aParent.Height, 'ddd', fntMini, taLeft);
    Label_Test.FontColor := icLightGray2;
    Label_Test.Hitable := False;

    for I := 0 to High(Image_CampaignFlags) do
    begin
      Image_CampaignFlags[I] := TKMImage.Create(Panel_Campaign_Map, aParent.Width, aParent.Height, 23, 29, 10, rxGuiMain);
      Image_CampaignFlags[I].HighlightOnMouseOver := True;
      Image_CampaignFlags[I].DragAndDrop := True;
      Image_CampaignFlags[I].OnMoveDragAndDrop := MoveMap;
      Image_CampaignFlags[I].DragAndDropRegionEnabled := True;
      Image_CampaignFlags[I].DragAndDropRegion := Rect(Panel_Campaign_Map.AbsLeft + 32, Panel_Campaign_Map.AbsTop + 32,
                                                       Panel_Campaign_Map.AbsRight - 32, Panel_Campaign_Map.AbsBottom - 64);
      Image_CampaignFlags[I].OnClick := SelectMission;
      Image_CampaignFlags[I].Tag := I;
      Image_CampaignFlags[I].PopUpMenu := PopUpMenu_Flag;
      Image_CampaignFlags[I].OnContextPopup := PopUpMenuContextPopup;

      Label_CampaignFlags[I] := TKMLabel.Create(Panel_Campaign_Map, aParent.Width, aParent.Height, IntToStr(I+1), fntMini, taCenter);
      Label_CampaignFlags[I].FontColor := icLightGray2;
      Label_CampaignFlags[I].Hitable := False;
    end;

    for I := 0 to High(Image_CampaignSubNode) do
    begin
      Image_CampaignSubNode[I] := TKMImage.Create(Panel_Campaign_Map, aParent.Width, aParent.Height, 16, 16, 16, rxGuiMain);
      Image_CampaignSubNode[I].HighlightOnMouseOver := True;
      Image_CampaignSubNode[I].ImageCenter;
      Image_CampaignSubNode[I].DragAndDrop := True;
      Image_CampaignSubNode[I].OnMoveDragAndDrop := MoveNode;
      Image_CampaignSubNode[I].DragAndDropRegionEnabled := True;
      Image_CampaignSubNode[I].DragAndDropRegion := Rect(Panel_Campaign_Map.AbsLeft + 16, Panel_Campaign_Map.AbsTop + 16,
                                                         Panel_Campaign_Map.AbsRight - 16, Panel_Campaign_Map.AbsBottom - 64);
      Image_CampaignSubNode[I].OnClick := SelectNode;
      Image_CampaignSubNode[I].Tag := I;
      Image_CampaignSubNode[I].PopUpMenu := PopUpMenu_SubNode;
      Image_CampaignSubNode[I].OnContextPopup := PopUpMenuContextPopup;

      Label_CampaignSubNode[I] := TKMLabel.Create(Panel_Campaign_Map, aParent.Width, aParent.Height, IntToStr(I+1), fntMini, taCenter);
      Label_CampaignSubNode[I].FontColor := icLightGray2;
      Label_CampaignSubNode[I].Hitable := False;
    end;

  Panel_CampScroll := TKMPanel.Create(Panel_Campaign, 0, Panel_Campaign.Height - 320, 360, 320);
  Panel_CampScroll.Anchors := [anLeft,anBottom];
    Image_Scroll := TKMImage.Create(Panel_CampScroll, 0, 0, 360, 320, 410, rxGui);
    Image_Scroll.ClipToBounds := True;
    Image_Scroll.AnchorsStretch;
    Image_Scroll.ImageAnchors := [anLeft, anRight, anTop];

    Image_ScrollClose := TKMImage.Create(Panel_CampScroll, 360-60, 10, 32, 32, 52);
    Image_ScrollClose.Anchors := [anTop, anRight];
    Image_ScrollClose.OnClick := ScrollToggle;
    Image_ScrollClose.HighlightOnMouseOver := True;

    ListBox_Missions := TKMListBox.Create(Panel_CampScroll, 20, 60, 260, 200, fntMetal,  bsMenu);
    ListBox_Missions.OnChange := SelectMission;

    ListBox_Nodes := TKMListBox.Create(Panel_CampScroll, 300, 60, 40, 200, fntMetal,  bsMenu);
    ListBox_Nodes.OnChange := SelectNode;

    //Panel_CampScroll.Hide;

  Image_ScrollRestore := TKMImage.Create(Panel_Campaign, aParent.Width-20-30, Panel_Campaign.Height-50-83, 30, 48, 491);
  Image_ScrollRestore.Anchors := [anBottom, anRight];
  Image_ScrollRestore.OnClick := ScrollToggle;
  Image_ScrollRestore.HighlightOnMouseOver := True;

  Image_ScrollRestore.Hide;

  Label_Missions := TKMLabel.Create(Panel_Campaign, aParent.Width-220-30, aParent.Height-78, 'Missions', fntOutline, taRight);
  //Label_Missions.Anchors := [anLeft, anBottom];
  Label_Missions.Hide;

  DropBox_Missions := TKMDropList.Create(Panel_Campaign, aParent.Width-220-20, aParent.Height-80, 220, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
  //DropBox_Missions.Anchors := [anLeft, anBottom];
  DropBox_Missions.OnChange := SelectMission;
  DropBox_Missions.DropUp := True;
  DropBox_Missions.DropCount := 20;
  DropBox_Missions.Hide;

  Button_ScrollPosition := TKMButton.Create(Panel_Campaign, aParent.Width-220-20, aParent.Height-50, 220, 30, 'Scroll position', bsMenu);
  Button_ScrollPosition.Anchors := [anLeft,anBottom];
  Button_ScrollPosition.OnClick := ScrollPositionClick;

  Button_CampaignBack := TKMButton.Create(Panel_Campaign, 20, aParent.Height-50, 220, 30, gResTexts[TX_MENU_BACK], bsMenu);
  Button_CampaignBack.Anchors := [anLeft,anBottom];
  Button_CampaignBack.OnClick := BackClick;
end;


procedure TKMMenuCampaignMapEditor.RefreshCampaign;
const
  MapPic: array [Boolean] of Byte = (10, 11);
var
  I: Integer;
begin
  Image_CampaignBG.RX := fCampaign.BackGroundPic.RX;
  Image_CampaignBG.TexID := fCampaign.BackGroundPic.ID;

  for I := 0 to High(Image_CampaignFlags) do
  begin
    Image_CampaignFlags[I].Visible := I < fCampaign.Missions.Count;
    Image_CampaignFlags[I].TexID   := MapPic[I <= ListBox_Missions.ItemIndex];
    Label_CampaignFlags[I].Visible := (I < fCampaign.Missions.Count) and (I <= ListBox_Missions.ItemIndex);
  end;

  for I := 0 to fCampaign.Missions.Count - 1 do
  begin
    Image_CampaignFlags[I].Left := fCampaign.Missions[I].Flag.X - Round((Image_CampaignFlags[I].Width/2)*(1-Panel_Campaign_Map.Scale));
    Image_CampaignFlags[I].Top  := fCampaign.Missions[I].Flag.Y - Round(Image_CampaignFlags[I].Height   *(1-Panel_Campaign_Map.Scale));
    Label_CampaignFlags[I].AbsLeft := Image_CampaignFlags[I].AbsLeft + FLAG_LABEL_OFFSET_X;
    Label_CampaignFlags[I].AbsTop := Image_CampaignFlags[I].AbsTop + FLAG_LABEL_OFFSET_Y;
  end;
end;

procedure TKMMenuCampaignMapEditor.UpdateMaps;
var
  I: Integer;
begin
  for I := 0 to High(Image_CampaignFlags) do
  begin
    Image_CampaignFlags[I].Highlight := I = ListBox_Missions.ItemIndex;
    Label_CampaignFlags[I].FontColor := icLightGray2;
  end;

  ListBox_Nodes.Clear;
  for I := 0 to High(Image_CampaignSubNode) do
  begin
    Image_CampaignSubNode[I].Visible := (ListBox_Missions.ItemIndex >= 0) and (I < fCampaign.Missions[ListBox_Missions.ItemIndex].NodeCount);
    Label_CampaignSubNode[I].Visible := Image_CampaignSubNode[I].Visible;
    if Image_CampaignSubNode[I].Visible then
    begin
      ListBox_Nodes.Add((I + 1).ToString);
      Image_CampaignSubNode[I].Highlight := False;
      Image_CampaignSubNode[I].Left := fCampaign.Missions[ListBox_Missions.ItemIndex].Nodes[I].X - 8;
      Image_CampaignSubNode[I].Top  := fCampaign.Missions[ListBox_Missions.ItemIndex].Nodes[I].Y - 8;
      Label_CampaignSubNode[I].AbsLeft := Image_CampaignSubNode[I].AbsLeft + NODE_LABEL_OFFSET_X;
      Label_CampaignSubNode[I].AbsTop := Image_CampaignSubNode[I].AbsTop + NODE_LABEL_OFFSET_Y;
    end;
  end;

  RefreshCampaign;
end;

procedure TKMMenuCampaignMapEditor.UpdateNodes;
var
  I: Integer;
begin
  for I := 0 to High(Image_CampaignSubNode) do
    Image_CampaignSubNode[I].Highlight := I = ListBox_Nodes.ItemIndex;
end;

procedure TKMMenuCampaignMapEditor.PopUpMenuContextPopup(Sender: TObject; X, Y: Integer; var Handled: Boolean);
begin
  fPopUpMenuObject := Sender;
  fPopUpMenuPositionX := X - TKMImage(Sender).AbsLeft;
  fPopUpMenuPositionY := Y - TKMImage(Sender).AbsTop;
end;

procedure TKMMenuCampaignMapEditor.PopUpMenuMapClick(Sender: TObject);
var
  Mission: TKMCampaignMission;
  Index: Integer;
begin
  case PopUpMenu_Map.ItemIndex of
    0: begin
      Mission := TKMCampaignMission.Create;
      Mission.Flag.X := fPopUpMenuPositionX - 8;
      Mission.Flag.Y := fPopUpMenuPositionY - 25;
      Index := fCampaign.Missions.Add(Mission);
      ListBox_Missions.Add(fCampaign.GetCampaignMissionTitle(Index));
      DropBox_Missions.Add(fCampaign.GetCampaignMissionTitle(Index));
      ListBox_Missions.ItemIndex := Index;
      DropBox_Missions.ItemIndex := Index;
      UpdateMaps;
    end;
    1: begin
      Mission := fCampaign.Missions[ListBox_Missions.ItemIndex];
      Index := Mission.NodeCount;
      Inc(Mission.NodeCount);
      Mission.Nodes[Index].X := fPopUpMenuPositionX + 3;
      Mission.Nodes[Index].Y := fPopUpMenuPositionY + 2;
      UpdateMaps;
      ListBox_Nodes.ItemIndex := Index;
    end;
  end;
end;

procedure TKMMenuCampaignMapEditor.PopUpMenuFlagClick(Sender: TObject);
var
  Mission: TKMCampaignMission;
  Index: Integer;
begin
  Mission := fCampaign.Missions[ListBox_Missions.ItemIndex];
  Index := (fPopUpMenuObject as TKMImage).Tag;
  case PopUpMenu_Flag.ItemIndex of
    0: begin
      fCampaign.DeleteMission(Index);
      UpdateMaps;
    end;
  end;
end;

procedure TKMMenuCampaignMapEditor.PopUpMenuSubNodeClick(Sender: TObject);
var
  Mission: TKMCampaignMission;
  Index: Integer;
begin
  Mission := fCampaign.Missions[ListBox_Missions.ItemIndex];
  Index := (fPopUpMenuObject as TKMImage).Tag;
  case PopUpMenu_SubNode.ItemIndex of
    0: begin
      Mission.DeleteNode(Index);
      UpdateMaps;
    end;
  end;
end;

procedure TKMMenuCampaignMapEditor.SelectMission(Sender: TObject);
begin
  if Sender is TKMImage then
  begin
    ListBox_Missions.ItemIndex := TKMImage(Sender).Tag;
    DropBox_Missions.ItemIndex := ListBox_Missions.ItemIndex;
  end;

  if Sender is TKMListBox then
    DropBox_Missions.ItemIndex := ListBox_Missions.ItemIndex;

  if Sender is TKMDropList then
    ListBox_Missions.ItemIndex := DropBox_Missions.ItemIndex;

  UpdateMaps;
end;

procedure TKMMenuCampaignMapEditor.SelectNode(Sender: TObject);
begin
  if Sender is TKMImage then
    ListBox_Nodes.ItemIndex := TKMImage(Sender).Tag;
  UpdateNodes;
end;

procedure TKMMenuCampaignMapEditor.Resize(X, Y: Word);
var
  I: Integer;
begin
  Panel_Campaign_Map.Scale := Min(768,Y) / 768;
  Panel_Campaign_Map.Left := Round(1024*(1-Panel_Campaign_Map.Scale) / 2);
  Image_CampaignBG.Left := Round(1024*(1-Panel_Campaign_Map.Scale) / 2);
  Image_CampaignBG.Height := Min(768,Y);
  Image_CampaignBG.Width := Round(1024*Panel_Campaign_Map.Scale);
  if fCampaign <> nil then
    for I := 0 to fCampaign.Missions.Count - 1 do
      with Image_CampaignFlags[I] do
      begin
        Left := fCampaign.Missions[I].Flag.X - Round((Width/2)*(1-Panel_Campaign_Map.Scale));
        Top  := fCampaign.Missions[I].Flag.Y - Round(Height   *(1-Panel_Campaign_Map.Scale));

        Label_CampaignFlags[I].AbsLeft := AbsLeft + FLAG_LABEL_OFFSET_X;
        Label_CampaignFlags[I].AbsTop := AbsTop + FLAG_LABEL_OFFSET_Y;
      end;
end;

procedure TKMMenuCampaignMapEditor.MoveMap(Sender: TObject);
var
  MapIndex: Integer;
begin
  MapIndex := TKMControl(Sender).Tag;
  fCampaign.Missions[MapIndex].Flag.X := Image_CampaignFlags[MapIndex].Left + Round((Image_CampaignFlags[MapIndex].Width/2)*(1-Panel_Campaign_Map.Scale));
  fCampaign.Missions[MapIndex].Flag.Y := Image_CampaignFlags[MapIndex].Top + Round(Image_CampaignFlags[MapIndex].Height   *(1-Panel_Campaign_Map.Scale));

  Label_CampaignFlags[MapIndex].AbsLeft := Image_CampaignFlags[MapIndex].AbsLeft + FLAG_LABEL_OFFSET_X;
  Label_CampaignFlags[MapIndex].AbsTop := Image_CampaignFlags[MapIndex].AbsTop + FLAG_LABEL_OFFSET_Y;
end;

procedure TKMMenuCampaignMapEditor.MoveNode(Sender: TObject);
var
  NodeIndex: Integer;
begin
  NodeIndex := TKMControl(Sender).Tag;
  fCampaign.Missions[ListBox_Missions.ItemIndex].Nodes[NodeIndex].X := Image_CampaignSubNode[NodeIndex].Left + 8;
  fCampaign.Missions[ListBox_Missions.ItemIndex].Nodes[NodeIndex].Y := Image_CampaignSubNode[NodeIndex].Top + 8;

  Label_CampaignSubNode[NodeIndex].AbsLeft := Image_CampaignSubNode[NodeIndex].AbsLeft + NODE_LABEL_OFFSET_X;
  Label_CampaignSubNode[NodeIndex].AbsTop := Image_CampaignSubNode[NodeIndex].AbsTop + NODE_LABEL_OFFSET_Y;
end;


procedure TKMMenuCampaignMapEditor.MouseMove(Shift: TShiftState; X,Y: Integer);
begin
  //
end;


procedure TKMMenuCampaignMapEditor.Show(aCampaign: TKMCampaignId);
var
  I: Integer;
begin
  fCampaign := gGameApp.Campaigns.CampaignById(aCampaign);

  ListBox_Missions.Clear;
  DropBox_Missions.Clear;
  for I := 0 to fCampaign.Missions.Count - 1 do
  begin
    ListBox_Missions.Add(fCampaign.GetCampaignMissionTitle(I));
    DropBox_Missions.Add(fCampaign.GetCampaignMissionTitle(I));
  end;

  Panel_Campaign.Show;
  ListBox_Missions.ItemIndex := 0;
  UpdateMaps();
  UpdateState;
end;

procedure TKMMenuCampaignMapEditor.BackClick(Sender: TObject);
begin
  fOnPageChange(gpMapEditor);
end;

procedure TKMMenuCampaignMapEditor.ScrollPositionClick(Sender: TObject);
begin
  fScrollPanelPosition := not fScrollPanelPosition;
  UpdateState;
  gSoundPlayer.Play(sfxMessageOpen);
end;

procedure TKMMenuCampaignMapEditor.UpdateState;
begin
  Panel_CampScroll.Left := IfThen(fScrollPanelPosition, Panel_Campaign.Width - Panel_CampScroll.Width, 0);
  //Image_ScrollRestore.Left := IfThen(fScrollPanelPosition, Panel_Campaign.Width - 50, 20);
  Panel_CampScroll.Visible := fScrollVisible;
  Image_ScrollRestore.Visible := not fScrollVisible;
  Label_Missions.Visible := not fScrollVisible or not fScrollPanelPosition;
  DropBox_Missions.Visible := not fScrollVisible or not  fScrollPanelPosition;
  Button_ScrollPosition.Enabled := fScrollVisible;
end;


procedure TKMMenuCampaignMapEditor.ScrollToggle(Sender: TObject);
begin
  fScrollVisible := not fScrollVisible;
  UpdateState;
  if Panel_CampScroll.Visible then
    gSoundPlayer.Play(sfxMessageOpen)
  else
    gSoundPlayer.Play(sfxMessageClose);
end;


end.

