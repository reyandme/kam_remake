unit KM_InterfaceMainMenu;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows} Windows, {$ENDIF}
  {$IFDEF Unix} LCLType, {$ENDIF}
  Classes, Controls, Math, SysUtils, KromUtils,
  KM_Controls, KM_Points, KM_Defaults, KM_Pics, KM_Networking, KM_ResFonts,
  KM_InterfaceDefaults,
  KM_GUIMenuCampaign,
  KM_GUIMenuCampaigns,
  KM_GUIMenuCredits,
  KM_GUIMenuError,
  KM_GUIMenuLoad,
  KM_GUIMenuLoading,
  KM_GUIMenuLobby,
  KM_GUIMenuMain,
  KM_GUIMenuMapEditor,
  KM_GUIMenuMultiplayer,
  KM_GUIMenuOptions,
  KM_GUIMenuReplays,
  KM_GUIMenuSingleMap,
  KM_GUIMenuSinglePlayer;


type
  TKMMainMenuInterface = class(TKMUserInterfaceCommon)
  private
    fMenuCampaign: TKMMenuCampaign;
    fMenuCampaigns: TKMMenuCampaigns;
    fMenuCredits: TKMMenuCredits;
    fMenuError: TKMMenuError;
    fMenuLoad: TKMMenuLoad;
    fMenuLoading: TKMMenuLoading;
    fMenuLobby: TKMMenuLobby;
    fMenuMain: TKMMenuMain;
    fMenuMapEditor: TKMMenuMapEditor;
    fMenuMultiplayer: TKMMenuMultiplayer;
    fMenuOptions: TKMMenuOptions;
    fMenuReplays: TKMMenuReplays;
    fMenuSingleMap: TKMMenuSingleMap;
    fMenuSinglePlayer: TKMMenuSinglePlayer;

    fMenuPage: TKMMenuPageCommon;
  protected
    Panel_Menu: TKMPanel;
    Panel_Background: TKMImage;
    Label_Version: TKMLabel;
    function GetHintPositionBase: TKMPoint; override;
    function GetHintFont: TKMFont; override;
  public
    constructor Create(X,Y: Word);
    destructor Destroy; override;

    property MenuPage: TKMMenuPageCommon read fMenuPage;
    procedure PageChange(Dest: TKMMenuPageType; const aText: UnicodeString = '');
    procedure AppendLoadingText(const aText: string);

    procedure ExportPages(const aPath: string); override;
    procedure ReturnToLobby(const aSaveName: UnicodeString);

    procedure KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean); override;
    procedure MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;
    procedure MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean); override;
    procedure MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer); override;

    procedure DebugControlsUpdated; override;
    procedure RefreshCampaigns;
    procedure Resize(X,Y: Word); override;
    procedure UpdateState(aTickCount: Cardinal); override;
  end;


implementation
uses
  KM_Main, KM_ResTexts, KM_Campaigns, KM_GameApp, KM_Log, KM_RenderUI;


{ TKMMainMenuInterface }
constructor TKMMainMenuInterface.Create(X,Y: Word);
var
  S: TKMShape;
begin
  inherited;
  Assert(gResTexts <> nil, 'fTextMain should be initialized before MainMenuInterface');

  //Fixed-size and centered Panel for menu
  Panel_Menu := TKMPanel.Create(Panel_Main, (X - MENU_DESIGN_X) div 2, (Y - MENU_DESIGN_Y) div 2, MENU_DESIGN_X, MENU_DESIGN_Y);
  Panel_Menu.AnchorsCenter;

  // Background is the same for all pages, except Results/Campaign, which will render ontop
  Panel_Background := TKMImage.Create(Panel_Menu, 0, 0, 1000, 1000, 17, rxGuiMain);
  Panel_Background.Tiled := True;
  TKMImage.Create(Panel_Menu, -18, -18, 1071, 822, 18, rxGuiMain).AnchorsCenter;

  fMenuMain          := TKMMenuMain.Create(Panel_Menu, PageChange);
  fMenuSinglePlayer  := TKMMenuSinglePlayer.Create(Panel_Menu, PageChange);
  fMenuCampaigns     := TKMMenuCampaigns.Create(Panel_Menu, PageChange);
  fMenuCampaign      := TKMMenuCampaign.Create(Panel_Menu, PageChange);
  fMenuSingleMap     := TKMMenuSingleMap.Create(Panel_Menu, PageChange);
  fMenuLoad          := TKMMenuLoad.Create(Panel_Menu, PageChange);
  fMenuMultiplayer   := TKMMenuMultiplayer.Create(Panel_Menu, PageChange);
  fMenuLobby         := TKMMenuLobby.Create(Panel_Menu, PageChange);
  fMenuMapEditor     := TKMMenuMapEditor.Create(Panel_Menu, PageChange);
  fMenuReplays       := TKMMenuReplays.Create(Panel_Menu, PageChange);
  fMenuOptions       := TKMMenuOptions.Create(Panel_Menu, PageChange);
  fMenuCredits       := TKMMenuCredits.Create(Panel_Menu, PageChange);
  fMenuError         := TKMMenuError.Create(Panel_Menu, PageChange);
  fMenuLoading       := TKMMenuLoading.Create(Panel_Menu, PageChange);

  //Show version info on every page
  Label_Version := TKMLabel.Create(Panel_Main, 8, 8, 0, 0, '', fntAntiqua, taLeft);

  if OVERLAY_RESOLUTIONS then
  begin
    S := TKMShape.Create(Panel_Menu, 0, 96, 1024, 576);
    S.LineColor := $FF00FFFF;
    S.LineWidth := 1;
    S.Hitable := False;
    S := TKMShape.Create(Panel_Menu, 0, 0, 1024, 768);
    S.LineColor := $FF00FF00;
    S.LineWidth := 1;
    S.Hitable := False;
  end;

  AfterCreateComplete;
  gLog.AddTime('Main menu init done');
end;


procedure TKMMainMenuInterface.DebugControlsUpdated;
begin
  if fMenuOptions.Visible then
    fMenuOptions.Refresh;
end;


destructor TKMMainMenuInterface.Destroy;
begin
  fMenuCampaign.Free;
  fMenuCampaigns.Free;
  fMenuCredits.Free;
  fMenuError.Free;
  fMenuLoad.Free;
  fMenuLoading.Free;
  fMenuLobby.Free;
  fMenuMain.Free;
  fMenuMapEditor.Free;
  fMenuMultiplayer.Free;
  fMenuOptions.Free;
  fMenuReplays.Free;
  fMenuSingleMap.Free;
  fMenuSinglePlayer.Free;

  inherited;
end;


function TKMMainMenuInterface.GetHintPositionBase: TKMPoint;
begin
  Result := KMPoint(Panel_Menu.Left - 5, Min(Panel_Menu.Bottom + 15, Panel_Main.Height));
end;


function TKMMainMenuInterface.GetHintFont: TKMFont;
begin
  Result := fntGrey;
end;


procedure TKMMainMenuInterface.RefreshCampaigns;
begin
  if fMenuPage.MenuType = gpCampSelect then
    fMenuCampaigns.RefreshList;

  if fMenuPage.MenuType = gpCampaign then
    fMenuCampaign.RefreshCampaign;
end;


//Keep Panel_Main centered
procedure TKMMainMenuInterface.Resize(X, Y: Word);
begin
  inherited;
  Panel_Menu.Height := Min(Panel_Main.Height, MENU_DESIGN_Y);
  Panel_Menu.Top := (Panel_Main.Height - Panel_Menu.Height) div 2;

  Panel_Background.Left := -Panel_Menu.Left;
  Panel_Background.Top := -Panel_Menu.Top;
  Panel_Background.Width := X;
  Panel_Background.Height := Y;

  //Needs to resize the map and move flag positions accordingly
  fMenuCampaign.Resize(X, Y);
  fMenuMultiplayer.Resize(X, Y);

  //Needs to swap map description / game settings on low resolution displays
  fMenuLobby.Lobby_Resize(Panel_Menu.Height);
end;


procedure TKMMainMenuInterface.AppendLoadingText(const aText: string);
begin
  fMenuLoading.AppendText(aText);
end;


procedure TKMMainMenuInterface.PageChange(Dest: TKMMenuPageType; const aText: UnicodeString = '');
var
  I: Integer;
  cmp: TKMCampaignId;
  Version: UnicodeString;
begin
  Version := UnicodeString(GAME_VERSION) + ' / ' + gGameApp.RenderVersion;

  if gMain <> nil then // could be nil if used from utils
    gMain.StatusBarText(SB_ID_KMR_VER,'KMR ' +  Version);

  //Hide all other pages
  for I := 0 to Panel_Menu.ChildCount - 1 do
    if Panel_Menu.Childs[I] is TKMPanel then
      Panel_Menu.Childs[I].Hide;

  Label_Version.Caption := '';

  case Dest of
    gpMainMenu:     begin
                      Label_Version.Caption := 'KaM Remake - ' + Version;
                      fMenuMain.Show;
                      fMenuPage := fMenuMain;
                    end;
    gpSingleplayer: begin
                      fMenuSinglePlayer.Show;
                      fMenuPage := fMenuSinglePlayer;
                    end;
    gpLoad:         begin
                      fMenuLoad.Show;
                      fMenuPage := fMenuLoad;
                    end;
    gpSingleMap:    begin
                      fMenuSingleMap.Show;
                      fMenuPage := fMenuSingleMap;
                    end;
    gpMultiplayer:  begin
                      fMenuMultiplayer.Show(aText);
                      fMenuPage := fMenuMultiplayer;
                    end;
    gpLobby:        begin
                      if aText = 'HOST' then
                        fMenuLobby.Show(lpkHost, gGameApp.Networking, Panel_Menu.Height)
                      else
                      if aText = 'JOIN' then
                        fMenuLobby.Show(lpkJoiner, gGameApp.Networking, Panel_Menu.Height)
                      else
                        raise Exception.Create('');
                      fMenuPage := fMenuLobby;
                    end;
    gpCampaign:     begin
                      cmp[0] := Ord(aText[1]);
                      cmp[1] := Ord(aText[2]);
                      cmp[2] := Ord(aText[3]);
                      fMenuCampaign.Show(cmp);
                      fMenuPage := fMenuCampaign;
                    end;
    gpCampSelect:   begin
                      fMenuCampaigns.Show;
                      fMenuPage := fMenuCampaigns;
                    end;
    gpCredits:      begin
                      fMenuCredits.Show;
                      fMenuPage := fMenuCredits;
                    end;
    gpOptions:      begin
                      fMenuOptions.Show;
                      fMenuPage := fMenuOptions;
                    end;
    gpMapEditor:    begin
                      fMenuMapEditor.Show;
                      fMenuPage := fMenuMapEditor;
                    end;
    gpReplays:      begin
                      fMenuReplays.Show;
                      fMenuPage := fMenuReplays;
                    end;
    gpError:        begin
                      fMenuError.Show(aText);
                      fMenuPage := fMenuError;
                    end;
    gpLoading:      begin
                      fMenuLoading.Show(aText);
                      fMenuPage := fMenuLoading;
                    end;
  end;
end;


procedure TKMMainMenuInterface.ExportPages(const aPath: string);
var
  path: string;
  I, K: Integer;
begin
  inherited;

  path := aPath + 'Menu' + PathDelim;
  ForceDirectories(path);

  for I := 0 to Panel_Menu.ChildCount - 1 do
    if (Panel_Menu.Childs[I] is TKMPanel)
    and (Panel_Menu.Childs[I].Width > 100) then
    begin
      //Hide all other panels
      for K := 0 to Panel_Menu.ChildCount - 1 do
        if Panel_Menu.Childs[K] is TKMPanel then
          Panel_Menu.Childs[K].Hide;

      Panel_Menu.Childs[I].Show;

      gGameApp.PrintScreen(path + 'Panel' + int2fix(I, 3) + '.jpg');
    end;
end;


procedure TKMMainMenuInterface.ReturnToLobby(const aSaveName: UnicodeString);
begin
  if gGameApp.Networking.IsHost then
    PageChange(gpLobby, 'HOST')
  else
    PageChange(gpLobby, 'JOIN');

  fMenuLobby.ReturnToLobby(aSaveName);
end;


procedure TKMMainMenuInterface.KeyDown(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := True; // assume we handle all keys here

  if fMyControls.KeyDown(Key, Shift) then Exit; //Handled by Controls

  if (fMenuPage <> nil) then
    fMenuPage.MenuKeyDown(Key, Shift);
end;


procedure TKMMainMenuInterface.KeyUp(Key: Word; Shift: TShiftState; var aHandled: Boolean);
begin
  aHandled := True; // assume we handle all keys here

  if fMyControls.KeyUp(Key, Shift) then Exit; //Handled by Controls
end;


procedure TKMMainMenuInterface.MouseDown(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  fMyControls.MouseDown(X, Y, Shift, Button);
end;


//Do something related to mouse movement in menu
procedure TKMMainMenuInterface.MouseMove(Shift: TShiftState; X,Y: Integer; var aHandled: Boolean);
begin
  aHandled := True; // assume we always handle mouse move

  fMyControls.MouseMove(X, Y, Shift);

  fMenuCampaign.MouseMove(Shift, X, Y);
end;


procedure TKMMainMenuInterface.MouseUp(Button: TMouseButton; Shift: TShiftState; X,Y: Integer);
begin
  fMyControls.MouseUp(X, Y, Shift, Button);
  Exit; //We could have caused gGameApp reinit (i.e. resolution change), so exit at once
end;


//Should update anything we want to be updated, obviously
procedure TKMMainMenuInterface.UpdateState(aTickCount: Cardinal);
begin
  inherited;
  fMenuLobby.UpdateState;
  fMenuMapEditor.UpdateState;
  fMenuLoad.UpdateState;
  fMenuReplays.UpdateState;
  fMenuSingleMap.UpdateState;
  fMenuCampaign.UpdateState(aTickCount);
end;


end.
