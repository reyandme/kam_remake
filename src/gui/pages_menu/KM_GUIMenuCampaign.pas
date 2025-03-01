unit KM_GUIMenuCampaign;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, Math,
  KM_Controls, KM_ControlsBase, KM_ControlsDrop,
  KM_Pics, KM_MapTypes, KM_CampaignTypes, KM_GameTypes,
  KM_Campaigns, KM_InterfaceDefaults, KM_InterfaceTypes;


type
  TKMMenuCampaign = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText; //will be in ancestor class

    fCampaigns: TKMCampaignsCollection;

    fCampaignId: TKMCampaignId;
    fCampaign: TKMCampaign;
    fMapIndex: Byte; // Map index starts from 0
    fAnimNodeIndex : Byte;

    fDifficulty: TKMMissionDifficulty;

    procedure BackClick(Sender: TObject);
    procedure Scroll_Toggle(Sender: TObject);

    procedure SelectMap(aMapIndex: Byte);
    procedure Campaign_SelectMap(Sender: TObject);
    procedure UpdateDifficultyLevel;
    procedure StartClick(Sender: TObject);
    procedure Difficulty_Change(Sender: TObject);
    procedure AnimNodes(aTickCount: Cardinal);
    procedure PlayBriefingAudioTrack;
  protected
    Panel_Campaign: TKMPanel;
      Image_CampaignBG: TKMImage;
      Panel_Campaign_Flags: TKMPanel;
        Image_CampaignFlags: array[0..MAX_CAMP_MAPS - 1] of TKMImage;
        Label_CampaignFlags: array[0..MAX_CAMP_MAPS - 1] of TKMLabel;
        Image_CampaignSubNode: array[0..MAX_CAMP_NODES - 1] of TKMImage;
      Panel_CampScroll: TKMPanel;
        Image_Scroll, Image_ScrollClose: TKMImage;
        Label_CampaignTitle, Label_CampaignText: TKMLabel;
      Image_ScrollRestore: TKMImage;
      Label_Difficulty: TKMLabel;
      DropBox_Difficulty: TKMDropList;
      Button_CampaignStart, Button_CampaignBack: TKMButton;
  public
    OnNewCampaignMap: TKMNewCampaignMapEvent;

    constructor Create(aParent: TKMPanel; aCampaigns: TKMCampaignsCollection; aOnPageChange: TKMMenuChangeEventText);

    procedure MouseMove(Shift: TShiftState; X,Y: Integer);
    procedure Resize(X, Y: Word);
    procedure Show(aCampaign: TKMCampaignId);

    procedure RefreshCampaign;

    function Visible: Boolean;

    procedure UpdateState(aTickCount: Cardinal);
  end;


implementation
uses
  KM_Audio, KM_Music, KM_Sound, KM_Video,
  KM_GameSettings,
  KM_ResTexts, KM_ResFonts, KM_ResSound, KM_ResTypes,
  KM_RenderUI,
  KM_Defaults;

const
  FLAG_LABEL_OFFSET_X = 10;
  FLAG_LABEL_OFFSET_Y = 7;
  CAMP_NODE_ANIMATION_PERIOD = 5;
  IMG_SCROLL_MAX_HEIGHT = 430;

{ TKMGUIMainCampaign }
constructor TKMMenuCampaign.Create(aParent: TKMPanel; aCampaigns: TKMCampaignsCollection; aOnPageChange: TKMMenuChangeEventText);
var
  I: Integer;
begin
  inherited Create(gpCampaign);

  fCampaigns := aCampaigns;

  fDifficulty := mdNone;
  fMapIndex := 0;
  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  Panel_Campaign := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Campaign.AnchorsStretch;
    Image_CampaignBG := TKMImage.Create(Panel_Campaign, 0, 0, aParent.Width, aParent.Height,0,rxGuiMain);
    Image_CampaignBG.ImageStretch;

    Panel_Campaign_Flags := TKMPanel.Create(Panel_Campaign, 0, 0, aParent.Width, aParent.Height);
    Panel_Campaign_Flags.AnchorsStretch;
    for I := 0 to High(Image_CampaignFlags) do
    begin
      Image_CampaignFlags[I] := TKMImage.Create(Panel_Campaign_Flags, aParent.Width, aParent.Height, 23, 29, 10, rxGuiMain);
      Image_CampaignFlags[I].OnClick := Campaign_SelectMap;
      Image_CampaignFlags[I].Tag := I;

      Label_CampaignFlags[I] := TKMLabel.Create(Panel_Campaign_Flags, aParent.Width, aParent.Height, IntToStr(I+1), fntMini, taCenter);
      Label_CampaignFlags[I].FontColor := icLightGray2;
      Label_CampaignFlags[I].Hitable := False;
    end;
    for I := 0 to High(Image_CampaignSubNode) do
    begin
      Image_CampaignSubNode[I] := TKMImage.Create(Panel_Campaign_Flags, aParent.Width, aParent.Height, 0, 0, 16, rxGuiMain);
      Image_CampaignSubNode[I].ImageCenter; //Pivot at the center of the dot (width/height = 0)
    end;

  Panel_CampScroll := TKMPanel.Create(Panel_Campaign, 0, 0, 360, 430);
  Panel_CampScroll.Anchors := [anLeft,anBottom];

    Image_Scroll := TKMImage.Create(Panel_CampScroll, 0, 0, 360, IMG_SCROLL_MAX_HEIGHT, 410, rxGui);
    Image_Scroll.ClipToBounds := True;
    Image_Scroll.AnchorsStretch;
    Image_Scroll.ImageAnchors := [anLeft, anRight, anTop];

    Image_ScrollClose := TKMImage.Create(Panel_CampScroll, 360-60, 10, 32, 32, 52);
    Image_ScrollClose.Anchors := [anTop, anRight];
    Image_ScrollClose.OnClick := Scroll_Toggle;
    Image_ScrollClose.HighlightOnMouseOver := True;

    Label_CampaignTitle := TKMLabel.Create(Panel_CampScroll, 20, 46, 325, 20, NO_TEXT, fntOutline, taCenter);

    Label_CampaignText := TKMLabel.Create(Panel_CampScroll, 20, 70, 323, 290, NO_TEXT, fntAntiqua, taLeft);
    Label_CampaignText.WordWrap := True;

  Image_ScrollRestore := TKMImage.Create(Panel_Campaign, aParent.Width-20-30, Panel_Campaign.Height-50-53, 30, 48, 491);
  Image_ScrollRestore.Anchors := [anBottom, anRight];
  Image_ScrollRestore.OnClick := Scroll_Toggle;
  Image_ScrollRestore.HighlightOnMouseOver := True;

  Label_Difficulty := TKMLabel.Create(Panel_Campaign, aParent.Width-220-30, aParent.Height-78, gResTexts[TX_MISSION_DIFFICULTY_CAMPAIGN], fntOutline, taRight);
  Label_Difficulty.Anchors := [anLeft, anBottom];
  Label_Difficulty.Hide;
  DropBox_Difficulty := TKMDropList.Create(Panel_Campaign, aParent.Width-220-20, aParent.Height-80, 220, 20, fntMetal, gResTexts[TX_MISSION_DIFFICULTY], bsMenu);
  DropBox_Difficulty.Anchors := [anLeft, anBottom];
  DropBox_Difficulty.OnChange := Difficulty_Change;
  DropBox_Difficulty.Hide;

  Button_CampaignStart := TKMButton.Create(Panel_Campaign, aParent.Width-220-20, aParent.Height-50, 220, 30, gResTexts[TX_MENU_START_MISSION], bsMenu);
  Button_CampaignStart.Anchors := [anLeft,anBottom];
  Button_CampaignStart.OnClick := StartClick;

  Button_CampaignBack := TKMButton.Create(Panel_Campaign, 20, aParent.Height-50, 220, 30, gResTexts[TX_MENU_BACK], bsMenu);
  Button_CampaignBack.Anchors := [anLeft,anBottom];
  Button_CampaignBack.OnClick := BackClick;
end;


procedure TKMMenuCampaign.RefreshCampaign;
const
  MAP_PIC: array [Boolean] of Byte = (10, 11);
var
  I: Integer;
begin
  fCampaign := fCampaigns.CampaignById(fCampaignId);

  //Choose background
  Image_CampaignBG.RX := fCampaign.BackGroundPic.RX;
  Image_CampaignBG.TexID := fCampaign.BackGroundPic.ID;

  DropBox_Difficulty.Clear;

  //Setup sites
  for I := 0 to High(Image_CampaignFlags) do
  begin
    Image_CampaignFlags[I].Visible := I < fCampaign.MapCount;
    Image_CampaignFlags[I].TexID   := MAP_PIC[I <= fCampaign.UnlockedMap];
    Image_CampaignFlags[I].HighlightOnMouseOver := I <= fCampaign.UnlockedMap;
    Label_CampaignFlags[I].Visible := (I < fCampaign.MapCount) and (I <= fCampaign.UnlockedMap);
  end;

  //Place sites
  for I := 0 to fCampaign.MapCount - 1 do
  begin
    //Pivot flags around Y=bottom X=middle, that's where the flag pole is
    Image_CampaignFlags[I].Left := fCampaign.Maps[I].Flag.X - Round((Image_CampaignFlags[I].Width/2)*(1-Panel_Campaign_Flags.Scale));
    Image_CampaignFlags[I].Top  := fCampaign.Maps[I].Flag.Y - Round(Image_CampaignFlags[I].Height   *(1-Panel_Campaign_Flags.Scale));

    Label_CampaignFlags[I].AbsLeft := Image_CampaignFlags[I].AbsLeft + FLAG_LABEL_OFFSET_X;
    Label_CampaignFlags[I].AbsTop := Image_CampaignFlags[I].AbsTop + FLAG_LABEL_OFFSET_Y;
  end;

  //Select last map, no brifing will be played, since its set as
  SelectMap(fCampaign.UnlockedMap);
end;


procedure TKMMenuCampaign.UpdateDifficultyLevel;
var
  I: Integer;
  MD, oldMD, defMD: TKMMissionDifficulty;
  diffLevels: TKMMissionDifficultySet;
begin
  //Difficulty levels
  oldMD := mdNone;
  if fCampaign.MapsInfo[fMapIndex].TxtInfo.HasDifficultyLevels then
  begin
    diffLevels := fCampaign.MapsInfo[fMapIndex].TxtInfo.DifficultyLevels;

    if gGameSettings.CampaignLastDifficulty in diffLevels then
      oldMD := gGameSettings.CampaignLastDifficulty;

    DropBox_Difficulty.Clear;
    I := 0;

    //Set BestCompleteDifficulty as default
    if fCampaign.MapsProgressData[fMapIndex].Completed then
      defMD := fCampaign.MapsProgressData[fMapIndex].BestCompleteDifficulty
    else if oldMD <> mdNone then
      defMD := oldMD
    else
      defMD := mdNormal;

    for MD in diffLevels do
    begin
      DropBox_Difficulty.Add(gResTexts[DIFFICULTY_LEVELS_TX[MD]], Byte(MD));

      if MD = defMD then
        DropBox_Difficulty.ItemIndex := I;
      Inc(I);
    end;

    //Show DropList Up to fit 1024 height screen
    DropBox_Difficulty.DropUp := DropBox_Difficulty.Count > 3;

    if not DropBox_Difficulty.IsSelected then
      DropBox_Difficulty.ItemIndex := 0;

    DropBox_Difficulty.DoSetVisible;
    Label_Difficulty.DoSetVisible;
  end else begin
    Label_Difficulty.Hide;
    DropBox_Difficulty.Clear;
    DropBox_Difficulty.Hide;
  end;

  Difficulty_Change(nil);
end;


procedure TKMMenuCampaign.SelectMap(aMapIndex: Byte);
var
  I, panHeight: Integer;
  color: Cardinal;
begin
  fMapIndex := aMapIndex;

  UpdateDifficultyLevel;

  // Place highlight
  for I := 0 to High(Image_CampaignFlags) do
  begin
    Image_CampaignFlags[I].Highlight := (fMapIndex = I);
    color := icLightGray2;
    if I < fCampaign.MapCount then
      color := DIFFICULTY_LEVELS_COLOR[fCampaign.MapsProgressData[I].BestCompleteDifficulty];
    Label_CampaignFlags[I].FontColor := color;
  end;

  //Connect by sub-nodes
  fAnimNodeIndex := 0;

  for I := 0 to High(Image_CampaignSubNode) do
  begin
    Image_CampaignSubNode[I].Visible := False;
    Image_CampaignSubNode[I].Left := fCampaign.Maps[fMapIndex].Nodes[I].X;
    Image_CampaignSubNode[I].Top  := fCampaign.Maps[fMapIndex].Nodes[I].Y;
  end;

  Label_CampaignTitle.Caption := fCampaign.GetCampaignMissionTitle(fMapIndex);
  Label_CampaignText.Caption := fCampaign.GetMissionBriefing(fMapIndex);

  Panel_CampScroll.Left := IfThen(fCampaign.Maps[fMapIndex].TextPos = bcBottomRight, Panel_Campaign.Width - Panel_CampScroll.Width, 0);
  //Add offset from top and space on bottom to fit buttons
  panHeight := Label_CampaignText.Top + Label_CampaignText.TextSize.Y + 70
               + 25*Byte((DropBox_Difficulty.Count > 0) and (fCampaign.Maps[fMapIndex].TextPos = bcBottomRight));

  // Stretch image in case its too small for a briefing text
  // Stretched scroll does not look good, but its okay for now (only happens for a custom campaigns)
  // Todo: cut scroll image into 3 pieces (top / center / bottom) and render as many of central part as needed
  if panHeight > IMG_SCROLL_MAX_HEIGHT then
    Image_Scroll.ImageAnchors := Image_Scroll.ImageAnchors + [anBottom]
  else
    Image_Scroll.ImageAnchors := Image_Scroll.ImageAnchors - [anBottom];

  Panel_CampScroll.Height := panHeight;
  Panel_CampScroll.Top := Panel_Campaign.Height - Panel_CampScroll.Height;

  Image_ScrollRestore.Top := Panel_Campaign.Height - 50 - 53 - 32*Byte(DropBox_Difficulty.Count > 0);

  Image_ScrollRestore.Hide;
  Panel_CampScroll.Show;
end;


// Flag was clicked on the Map
procedure TKMMenuCampaign.Campaign_SelectMap(Sender: TObject);
begin
  if TKMControl(Sender).Tag > fCampaign.UnlockedMap then Exit; //Skip closed maps

  SelectMap(TKMControl(Sender).Tag);

  // Play briefing
  PlayBriefingAudioTrack;
end;

procedure TKMMenuCampaign.PlayBriefingAudioTrack;
begin
  gMusic.StopPlayingOtherFile; //Stop playing the previous briefing even if this one doesn't exist

  // For some reason fMapIndex could get incorrect value
  if not InRange(fMapIndex, 0, MAX_CAMP_MAPS - 1) then Exit;

  TKMAudio.PauseMusicToPlayFile(fCampaign.GetBriefingAudioFile(fMapIndex));
end;

procedure TKMMenuCampaign.StartClick(Sender: TObject);
begin
  gMusic.StopPlayingOtherFile;

  if Assigned(OnNewCampaignMap) then
    OnNewCampaignMap(fCampaignId, fMapIndex, fDifficulty);

  if fCampaign.MapsInfo[fMapIndex].TxtInfo.HasDifficultyLevels then
    gGameSettings.CampaignLastDifficulty := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag);
end;


procedure TKMMenuCampaign.Difficulty_Change(Sender: TObject);
begin
  if (DropBox_Difficulty.Count > 0) and DropBox_Difficulty.IsSelected then
    fDifficulty := TKMMissionDifficulty(DropBox_Difficulty.GetSelectedTag)
  else
    fDifficulty := mdNone;
end;


procedure TKMMenuCampaign.AnimNodes(aTickCount: Cardinal);
begin
  if not InRange(fAnimNodeIndex, 0, fCampaign.Maps[fMapIndex].NodeCount-1) then Exit;
  if (aTickCount mod CAMP_NODE_ANIMATION_PERIOD) <> 0 then Exit;
  if Image_CampaignSubNode[fAnimNodeIndex].Visible then Exit;
  Image_CampaignSubNode[fAnimNodeIndex].Visible := True;
  inc(fAnimNodeIndex);
end;


function TKMMenuCampaign.Visible: Boolean;
begin
  Result := Panel_Campaign.Visible;
end;


procedure TKMMenuCampaign.UpdateState(aTickCount: Cardinal);
begin
  if (fCampaign = nil) or not Visible then Exit;

  if fCampaign.Maps[fMapIndex].NodeCount > 0 then
    AnimNodes(aTickCount);
end;


procedure TKMMenuCampaign.Resize(X, Y: Word);
var
  I: Integer;
begin
  if (fCampaign = nil) or not Visible then Exit;

  //Special rules for resizing the campaigns panel
  Panel_Campaign_Flags.Scale := Min(768,Y) / 768;
  Panel_Campaign_Flags.Left := Round(1024*(1-Panel_Campaign_Flags.Scale) / 2);
  Image_CampaignBG.Left := Round(1024*(1-Panel_Campaign_Flags.Scale) / 2);
  Image_CampaignBG.Height := Min(768,Y);
  Image_CampaignBG.Width := Round(1024*Panel_Campaign_Flags.Scale);
  //Special rule to keep campaign flags pivoted at the right place (so the flagpole doesn't move when you resize)
  if fCampaign <> nil then
    for I := 0 to fCampaign.MapCount - 1 do
      with Image_CampaignFlags[I] do
      begin
        //Pivot flags around Y=bottom X=middle, that's where the flag pole is
        Left := fCampaign.Maps[I].Flag.X - Round((Width/2)*(1-Panel_Campaign_Flags.Scale));
        Top  := fCampaign.Maps[I].Flag.Y - Round(Height   *(1-Panel_Campaign_Flags.Scale));

        Label_CampaignFlags[I].AbsLeft := AbsLeft + FLAG_LABEL_OFFSET_X;
        Label_CampaignFlags[I].AbsTop := AbsTop + FLAG_LABEL_OFFSET_Y;
      end;
end;


//Mission description jumps around to allow to pick any of beaten maps
procedure TKMMenuCampaign.MouseMove(Shift: TShiftState; X,Y: Integer);
begin
  //
end;


procedure TKMMenuCampaign.Show(aCampaign: TKMCampaignId);
begin
  fCampaignId := aCampaign;
  RefreshCampaign;

  //Refresh;
  Panel_Campaign.Show;

  if not fCampaign.IntroVideoViewed then
  begin
    fCampaign.IntroVideoViewed := True;
    fCampaigns.SaveProgress;

    gVideoPlayer.AddCampaignVideo(fCampaign.Path, 'Logo');
    gVideoPlayer.AddCampaignVideo(fCampaign.Path, 'Intro');
    gVideoPlayer.SetCallback(PlayBriefingAudioTrack); // Start briefing audio after logo and intro videos
    gVideoPlayer.Play;
  end;

  // Start briefing audio immediately, if video was not started (disabled / no video file etc)
  if not gVideoPlayer.IsActive then
    PlayBriefingAudioTrack;
end;

procedure TKMMenuCampaign.BackClick(Sender: TObject);
begin
  gMusic.StopPlayingOtherFile; //Cancel briefing if it was playing

  fOnPageChange(gpCampSelect);
end;


procedure TKMMenuCampaign.Scroll_Toggle(Sender: TObject);
begin
  Panel_CampScroll.Visible := not Panel_CampScroll.Visible;
  Image_ScrollRestore.Visible := not Panel_CampScroll.Visible;
  if Panel_CampScroll.Visible then
    gSoundPlayer.Play(sfxMessageOpen)
  else
    gSoundPlayer.Play(sfxMessageClose);
end;


end.
