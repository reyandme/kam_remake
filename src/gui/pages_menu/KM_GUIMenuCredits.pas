unit KM_GUIMenuCredits;
{$I KaM_Remake.inc}
interface
uses
  {$IFDEF Unix} LCLType, {$ENDIF}
  {$IFDEF WDC} ShellAPI, Windows, {$ENDIF} // Required for OpenURL in Delphi
  {$IFDEF FPC} LCLIntf, {$ENDIF} // Required for OpenURL in Lazarus
  Classes, Forms, Controls,
  KM_Controls, KM_Defaults,
  KM_InterfaceDefaults, KM_InterfaceTypes;


type
  TKMMenuCredits = class(TKMMenuPageCommon)
  private
    fOnPageChange: TKMMenuChangeEventText;

    procedure LinkClick(Sender: TObject);
    procedure BackClick(Sender: TObject);
  protected
    Panel_Credits: TKMPanel;
    Label_Credits_KaM: TKMLabelScroll;
    Label_Credits_Remake: TKMLabelScroll;
    Button_CreditsHomepage: TKMButton;
    Button_CreditsFacebook: TKMButton;
    Button_CreditsBack: TKMButton;
  public
    OnToggleLocale: TKMToggleLocaleEvent;

    constructor Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
    procedure Show;
  end;


implementation
uses
  KM_ResCursors, KM_ResTexts, KM_RenderUI, KM_Resource, KM_ResFonts, KM_ResLocales, KM_GameSettings, KM_CommonUtils;


{ TKMGUIMainCredits }
constructor TKMMenuCredits.Create(aParent: TKMPanel; aOnPageChange: TKMMenuChangeEventText);
const
  OFFSET = 312;
begin
  inherited Create(gpCredits);

  fOnPageChange := aOnPageChange;
  OnEscKeyDown := BackClick;

  Panel_Credits := TKMPanel.Create(aParent, 0, 0, aParent.Width, aParent.Height);
  Panel_Credits.AnchorsStretch;

    TKMLabel.Create(Panel_Credits, aParent.Width div 2 - OFFSET, 70, gResTexts[TX_CREDITS],fntOutline,taCenter);
    Label_Credits_Remake := TKMLabelScroll.Create(Panel_Credits, aParent.Width div 2 - OFFSET, 110, 0, aParent.Height - 130,
      gResTexts[TX_CREDITS_PROGRAMMING] + '|Krom|Lewin||' +
      gResTexts[TX_CREDITS_ADDITIONAL_PROGRAMMING] + '|Alex|Rey|andreus|Danjb|ZblCoder||' +
      gResTexts[TX_CREDITS_ADDITIONAL_GRAPHICS] + '|StarGazer|Malin|H.A.H.||' +
      gResTexts[TX_CREDITS_ADDITIONAL_MUSIC] + '|Andre Sklenar - www.juicelab.cz||' +
      gResTexts[TX_CREDITS_ADDITIONAL_SOUNDS] + '|trb1914||' +
      gResTexts[TX_CREDITS_ADDITIONAL_TRANSLATIONS] + '|' + gResLocales.TranslatorCredits + '|' +
      gResTexts[TX_CREDITS_SPECIAL] + '|KaM Community members',
      fntGrey,
      taCenter);
    Label_Credits_Remake.Anchors := [anLeft, anTop, anBottom];

    TKMLabel.Create(Panel_Credits, aParent.Width div 2 + OFFSET, 70, gResTexts[TX_CREDITS_ORIGINAL], fntOutline, taCenter);
    Label_Credits_KaM := TKMLabelScroll.Create(Panel_Credits, aParent.Width div 2 + OFFSET, 110, 0, aParent.Height - 130, gResTexts[TX_CREDITS_TEXT], fntGrey, taCenter);
    Label_Credits_KaM.Anchors := [anLeft,anTop,anBottom];

    Button_CreditsHomepage := TKMButton.Create(Panel_Credits,400,610,224,30, '[$F8A070]www.kamremake.com[]', bsMenu);
    Button_CreditsHomepage.Anchors := [anLeft,anBottom];
    Button_CreditsHomepage.OnClick := LinkClick;

    Button_CreditsFacebook := TKMButton.Create(Panel_Credits,400,646,224,30, '[$F8A070]Facebook[]', bsMenu);
    Button_CreditsFacebook.Anchors := [anLeft,anBottom];
    Button_CreditsFacebook.OnClick := LinkClick;

    Button_CreditsBack := TKMButton.Create(Panel_Credits,400,700,224,30,gResTexts[TX_MENU_BACK],bsMenu);
    Button_CreditsBack.Anchors := [anLeft,anBottom];
    Button_CreditsBack.OnClick := BackClick;
end;


procedure TKMMenuCredits.LinkClick(Sender: TObject);

  //This can't be moved to e.g. KM_CommonUtils because the dedicated server needs that, and it must be Linux compatible
  procedure GoToURL(const aUrl: string);
  begin
    {$IFDEF WDC}
    ShellExecute(Application.Handle, 'open', PChar(aUrl), nil, nil, SW_SHOWNORMAL);
    {$ENDIF}
    {$IFDEF FPC}
    OpenURL(aUrl);
    {$ENDIF}
  end;

begin
  if Sender = Button_CreditsHomepage then GoToURL('http://www.kamremake.com/redirect.php?page=homepage&rev=' + UnicodeString(GAME_REVISION));
  if Sender = Button_CreditsFacebook then GoToURL('http://www.kamremake.com/redirect.php?page=facebook&rev=' + UnicodeString(GAME_REVISION));
end;


procedure TKMMenuCredits.Show;
begin
  // Load asian fonts, since there are some credits information on asian languages
  // No need to redraw all UI, as we do on the Options page, since there is no info rendered on the credits page yet
  if gRes.Fonts.LoadLevel <> fllFull then
  begin
    gRes.Cursors.Cursor := kmcAnimatedDirSelector;
    gRes.LoadLocaleFonts(gGameSettings.Locale, True);
    gRes.Cursors.Cursor := kmcDefault;
  end;

  //Set initial position
  Label_Credits_KaM.SmoothScrollToTop := TimeGet;
  Label_Credits_Remake.SmoothScrollToTop := TimeGet;

  Panel_Credits.Show;
end;


procedure TKMMenuCredits.BackClick(Sender: TObject);
begin
  fOnPageChange(gpMainMenu);
end;


end.
