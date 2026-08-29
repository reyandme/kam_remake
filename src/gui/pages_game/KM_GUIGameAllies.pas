unit KM_GUIGameAllies;
{$I KaM_Remake.inc}
interface
uses
  KM_Controls, KM_ControlsBase, KM_ControlsDrop,
  KM_Defaults;

type
  TKMGUIGameAllies = class
  private
    fLineIdToNetPlayerId: array [0..MAX_LOBBY_SLOTS - 1] of Integer;
    fLineCount: Integer;

    procedure Allies_Mute(Sender: TObject);
    procedure AlliesTeamChange(Sender: TObject);
    procedure Update_Image_AlliesMute(aImage: TKMImage);
    procedure Allies_UpdateRoomMapping;
  protected
    Panel_Allies: TKMPanel;
      Label_PeacetimeRemaining: TKMLabel;
      Image_AlliesHostStar: TKMImage;
      Image_AlliesMute: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Image_AlliesWinLoss: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Image_AlliesFlag: array [0..MAX_LOBBY_SLOTS-1] of TKMImage;
      Label_AlliesPlayer: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      DropBox_AlliesTeam: array [0..MAX_LOBBY_SLOTS-1] of TKMDropList;
      Label_AlliesTeam: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesPing: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesPingFpsSlash: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Label_AlliesFPS: array [0..MAX_LOBBY_SLOTS-1] of TKMLabel;
      Image_AlliesClose: TKMImage;
  public
    constructor Create(aParent: TKMPanel);

    procedure AlliesOnPlayerSetup;
    procedure AlliesOnPingInfo;
    procedure Allies_Close(Sender: TObject);

    procedure Show;
    procedure Hide;
    function Visible: Boolean;
    procedure UpdateState;
  end;


implementation
uses
  SysUtils,
  KM_CommonTypes, KM_CommonUtils, KM_NetTypes, KM_Utils, KM_Log,
  KM_Game, KM_HandsCollection, KM_GameInputProcess, KM_Networking,
  KM_RenderUI, KM_Sound,
  KM_ResFonts, KM_ResLocales, KM_ResSound, KM_ResTexts, KM_ResTypes;

const
  ALLIES_ROWS = 7;
  PANEL_ALLIES_WIDTH = 840;
  PANEL_ALLIES_HEIGHT = 240;

{ TKMGUIGameAllies }
constructor TKMGUIGameAllies.Create(aParent: TKMPanel);
const
  LINE_W = 395;
var
  I, K: Integer;
begin
  inherited Create;

  Panel_Allies := TKMPanel.Create(aParent, TOOLBAR_WIDTH, aParent.Height - PANEL_ALLIES_HEIGHT, PANEL_ALLIES_WIDTH, PANEL_ALLIES_HEIGHT);
  Panel_Allies.Anchors := [anLeft, anBottom];
  Panel_Allies.Hide;

    TKMImage.Create(Panel_Allies,0,0,PANEL_ALLIES_WIDTH,190,409).ImageAnchors := [anLeft, anRight, anTop];

    Label_PeacetimeRemaining := TKMLabel.Create(Panel_Allies,400,15,'',fntOutline,taCenter);
    Image_AlliesHostStar := TKMImage.Create(Panel_Allies, 50, 82, 20, 20, 77, rxGuiMain);
    Image_AlliesHostStar.Hint := gResTexts[TX_PLAYER_HOST];
    Image_AlliesHostStar.Hide;

    for I := 0 to MAX_LOBBY_SLOTS - 1 do
    begin
      var dx := (I div ALLIES_ROWS) * LINE_W;
      var dy := (I mod ALLIES_ROWS) * 20;

      if (I mod ALLIES_ROWS) = 0 then // Header for each column
      begin
        TKMLabel.Create(Panel_Allies, 80  + dx, 60, 140, 20, gResTexts[TX_LOBBY_HEADER_PLAYERS], fntOutline, taLeft);
        TKMLabel.Create(Panel_Allies, 230 + dx, 60, 140, 20, gResTexts[TX_LOBBY_HEADER_TEAM], fntOutline, taLeft);
        TKMLabel.Create(Panel_Allies, 360 + dx, 60, gResTexts[TX_LOBBY_HEADER_PINGFPS], fntOutline, taCenter);
      end;

      Image_AlliesWinLoss[I] := TKMImage.Create(Panel_Allies, 42 + dx, 81 + dy, 16, 16, 0, rxGuiMain);
      Image_AlliesWinLoss[I].Hide;

      Image_AlliesMute[I] := TKMImage.Create(Panel_Allies, 45 + 15 + dx, 82 + dy, 11, 11, 0, rxGuiMain);
      Image_AlliesMute[I].OnClick := Allies_Mute;
      Image_AlliesMute[I].Tag := I;
      Image_AlliesMute[I].HighlightOnMouseOver := True;
      Image_AlliesMute[I].Hide;

      Image_AlliesFlag[I] := TKMImage.Create(Panel_Allies,     15 + 60 + dx, 82 + dy, 16,  11,  0, rxGuiMain);
      Label_AlliesPlayer[I] := TKMLabel.Create(Panel_Allies,   15 + 80 + dx, 80 + dy, 140, 20, '', fntGrey, taLeft);
      Label_AlliesTeam[I]   := TKMLabel.Create(Panel_Allies,   15 + 230 + dx, 80 + dy, 120, 20, '', fntGrey, taLeft);
      DropBox_AlliesTeam[I] := TKMDropList.Create(Panel_Allies,15 + 230 + dx, 80 + dy, 120, 20, fntGrey, '', bsGame);
      DropBox_AlliesTeam[I].Hide; // Use label for demos until we fix exploits
      DropBox_AlliesTeam[I].Add('-');
      for K := 1 to MAX_TEAMS do
        DropBox_AlliesTeam[I].Add(IntToStr(K));
      DropBox_AlliesTeam[I].OnChange := AlliesTeamChange;
      DropBox_AlliesTeam[I].DropUp := True; // Doesn't fit if it drops down
      Label_AlliesPing[I] :=          TKMLabel.Create(Panel_Allies, 15 + 347 + dx, 80 + dy, '', fntGrey, taRight);
      Label_AlliesPingFpsSlash[I] :=  TKMLabel.Create(Panel_Allies, 15 + 354 + dx, 80 + dy, '', fntGrey, taCenter);
      Label_AlliesFPS[I] :=           TKMLabel.Create(Panel_Allies, 15 + 361 + dx, 80 + dy, '', fntGrey, taLeft);
    end;

    Image_AlliesClose := TKMImage.Create(Panel_Allies, PANEL_ALLIES_WIDTH - 98, 24, 32, 32, 52, rxGui);
    Image_AlliesClose.Hint := gResTexts[TX_MSG_CLOSE_HINT];
    Image_AlliesClose.OnClick := Allies_Close;
    Image_AlliesClose.HighlightOnMouseOver := True;
end;


procedure TKMGUIGameAllies.Allies_Close(Sender: TObject);
begin
  if Visible then gSoundPlayer.Play(sfxnMPChatClose);
  Hide;
end;


procedure TKMGUIGameAllies.Allies_Mute(Sender: TObject);
begin
  var img := TKMImage(Sender);

  if gLog.IsDebugLogEnabled then
    gLog.LogDebug(Format('TKMGUIGameAllies.Allies_Mute: Image.tag = %d NetPlayerIndex = %d',
                         [img.Tag, fLineIdToNetPlayerId[img.Tag]]));

  gNetworking.ToggleMuted(fLineIdToNetPlayerId[img.Tag]);
  Update_Image_AlliesMute(img);
end;


procedure TKMGUIGameAllies.Update_Image_AlliesMute(aImage: TKMImage);
begin
  if gNetworking.IsMuted(fLineIdToNetPlayerId[aImage.Tag]) then
  begin
    aImage.Hint := gResTexts[TX_UNMUTE_PLAYER];
    aImage.TexID := 84;
  end else
  begin
    aImage.Hint := gResTexts[TX_MUTE_PLAYER];
    aImage.TexID := 83;
  end;
end;


procedure TKMGUIGameAllies.Allies_UpdateRoomMapping;
var
  I, J, K: Integer;
  teams: TKMByteSetArray;
  handIdToRoomId: array [0..MAX_HANDS - 1] of Integer;
begin
  // First empty everything
  fLineCount := 0;

  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    fLineIdToNetPlayerId[I] := -1;

  for I := 0 to MAX_HANDS - 1 do
    handIdToRoomId[I] := -1;

  for I := 1 to gNetworking.Room.Count do
    if not gNetworking.Room[I].IsSpectator then
        handIdToRoomId[gNetworking.Room[I].HandIndex] := I;

  teams := gHands.Teams;

  K := 0;
  for J := Low(teams) to High(teams) do
    for I in teams[J] do
      if handIdToRoomId[I] <> -1 then //handIdToRoomId could -1, if we play in the save, where 1 player left
      begin
        fLineIdToNetPlayerId[K] := handIdToRoomId[I];
        Inc(K);
      end;

  // Spectators
  for I := 1 to gNetworking.Room.Count do
    if gNetworking.Room[I].IsSpectator then
    begin
      fLineIdToNetPlayerId[K] := I;
      Inc(K);
    end;

  fLineCount := K;
end;


procedure TKMGUIGameAllies.AlliesOnPlayerSetup;
var
  I, K, netI: Integer;
  localeID: Integer;
begin
  Allies_UpdateRoomMapping;

  Image_AlliesHostStar.Hide;

  //Hide extra player lines
  for I := fLineCount to MAX_LOBBY_SLOTS - 1 do
  begin
    Label_AlliesPlayer[I].Hide;
    DropBox_AlliesTeam[I].Hide;
    Label_AlliesTeam[I].Hide;
  end;

  I := 0;
  for K := 0 to fLineCount - 1 do
  begin
    netI := fLineIdToNetPlayerId[K];

    if netI = -1 then Continue; //In case we have AI players at hand, without NetI

    // Show players locale flag
    if gNetworking.Room[netI].IsComputer then
      Image_AlliesFlag[I].TexID := GetAIPlayerIcon(gNetworking.Room[netI].PlayerNetType)
    else
    begin
      localeID := gResLocales.IndexByCode(gNetworking.Room[netI].LangCode);
      if localeID <> -1 then
        Image_AlliesFlag[I].TexID := gResLocales[localeID].FlagSpriteID
      else
        Image_AlliesFlag[I].TexID := 0;
    end;
    if gNetworking.HostSlotIndex = netI then
    begin
      Image_AlliesHostStar.Visible := True;
      Image_AlliesHostStar.Left := 190 + (I div ALLIES_ROWS)*380;
      Image_AlliesHostStar.Top := 80 + (I mod ALLIES_ROWS)*20;
    end;

    if gNetworking.Room[netI].IsHuman then
      Label_AlliesPlayer[I].Caption := gNetworking.Room[netI].NicknameU
    else
      Label_AlliesPlayer[I].Caption := gHands[gNetworking.Room[netI].HandIndex].OwnerName;

    if (gNetworking.MySlotIndex <> netI)                // If not my player
      and gNetworking.Room[netI].IsHuman then // and is not Computer
    begin
      Update_Image_AlliesMute(Image_AlliesMute[I]);
      Image_AlliesMute[I].DoSetVisible; //Do not use .Show here, because we do not want change Parent.Visible status from here
    end;

    if gNetworking.Room[netI].IsSpectator then
    begin
      Label_AlliesPlayer[I].FontColor := gNetworking.Room[netI].FlagColorDef;
      DropBox_AlliesTeam[I].ItemIndex := 0;
      Label_AlliesTeam[I].Caption := gResTexts[TX_LOBBY_SPECTATOR];
    end
    else
    begin
      Label_AlliesPlayer[I].FontColor := gHands[gNetworking.Room[netI].HandIndex].FlagColor;
      DropBox_AlliesTeam[I].ItemIndex := gNetworking.Room[netI].Team;
      if gNetworking.Room[netI].Team = 0 then
        Label_AlliesTeam[I].Caption := '-'
      else
        Label_AlliesTeam[I].Caption := IntToStr(gNetworking.Room[netI].Team);

      case gHands[gNetworking.Room[netI].HandIndex].AI.WonOrLost of
        wolNone: Image_AlliesWinLoss[I].Hide;
        wolWon:  begin
                    Image_AlliesWinLoss[I].TexID := 8;
                    Image_AlliesWinLoss[I].Hint := gResTexts[TX_PLAYER_WON];
                    Image_AlliesWinLoss[I].DoSetVisible;
                  end;
        wolLost: begin
                    Image_AlliesWinLoss[I].TexID := 87;
                    Image_AlliesWinLoss[I].Hint := gResTexts[TX_PLAYER_LOST];
                    Image_AlliesWinLoss[I].DoSetVisible;
                  end;
      end;
    end;
    // Strikethrough for disconnected players
    Image_AlliesMute[I].Enabled := not gNetworking.Room[netI].Dropped;
    if gNetworking.Room[netI].Dropped then
      Image_AlliesMute[I].Hint := '';
    Image_AlliesFlag[I].Enabled := not gNetworking.Room[netI].Dropped;
    Label_AlliesPlayer[I].Strikethrough := gNetworking.Room[netI].Dropped;
    // Do not strike through '-' symbol, when player has no team
    Label_AlliesTeam[I].Strikethrough := gNetworking.Room[netI].Dropped
                                         and (gNetworking.Room[netI].Team <> 0);
    Label_AlliesPing[I].Strikethrough := gNetworking.Room[netI].Dropped;
    Label_AlliesFPS[I].Strikethrough := gNetworking.Room[netI].Dropped;
    DropBox_AlliesTeam[I].Enabled := (netI = gNetworking.MySlotIndex);
    DropBox_AlliesTeam[I].Hide; // Use label for demos until we fix exploits

    Inc(I);
  end;
end;


procedure TKMGUIGameAllies.AlliesOnPingInfo;
var
  I, K, slotIndex: Integer;
begin
  Allies_UpdateRoomMapping;

  I := 0;
  for K := 0 to fLineCount - 1 do
  begin
    slotIndex := fLineIdToNetPlayerId[K];

    if slotIndex = -1 then Continue; //In case we have AI players at hand, without slotIndex

    if (I < gNetworking.Room.Count) and gNetworking.Room[slotIndex].IsHuman then
    begin
      var ping := gNetworking.Room[slotIndex].GetInstantPing;
      var fps := gNetworking.Room[slotIndex].FPS;
      Label_AlliesPing[I].Caption := WrapColor(IntToStr(ping), GetPingColor(ping));
      Label_AlliesPingFpsSlash[I].Caption := '/';
      Label_AlliesFPS[I].Caption := WrapColor(IntToStr(fps), GetFPSColor(fps));
    end else
    begin
      Label_AlliesPing[I].Caption := '';
      Label_AlliesPingFpsSlash[I].Caption := '';
      Label_AlliesFPS[I].Caption := '';
    end;
    Inc(I);
  end;
end;


procedure TKMGUIGameAllies.AlliesTeamChange(Sender: TObject);
var
  I: Integer;
begin
  for I := 0 to MAX_LOBBY_SLOTS - 1 do
    if (Sender = DropBox_AlliesTeam[I]) and DropBox_AlliesTeam[I].Enabled then
      gGame.GameInputProcess.CmdGame(gicGameTeamChange, I+1, DropBox_AlliesTeam[I].ItemIndex);
end;


procedure TKMGUIGameAllies.Show;
begin
  Panel_Allies.Show;
end;


procedure TKMGUIGameAllies.Hide;
begin
  Panel_Allies.Hide;
end;


function TKMGUIGameAllies.Visible: Boolean;
begin
  Result := Panel_Allies.Visible;
end;


procedure TKMGUIGameAllies.UpdateState;
begin
  // Update peacetime counter
  if gGame.Options.Peacetime <> 0 then
    Label_PeacetimeRemaining.Caption := Format(gResTexts[TX_MP_PEACETIME_REMAINING],
                                               [TimeToString(gGame.GetPeacetimeRemaining)])
  else
    Label_PeacetimeRemaining.Caption := '';
end;


end.
