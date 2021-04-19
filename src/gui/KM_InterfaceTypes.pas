unit KM_InterfaceTypes;
{$I KaM_Remake.inc}
interface

type
  TUIMode = (umSP, umMP, umReplay, umSpectate);
  TUIModeSet = set of TUIMode;

  TKMMenuPageType =  (gpMainMenu,
                        gpSinglePlayer,
                          gpCampaign,
                          gpCampSelect,
                          gpSingleMap,
                          gpLoad,
                        gpMultiplayer,
                          gpLobby,
                        gpReplays,
                        gpMapEditor,
                        gpOptions,
                        gpCredits,
                      gpLoading,
                      gpError);
  TGUIEvent = procedure (Sender: TObject; Dest: TKMMenuPageType) of object;
  TKMMenuChangeEventText = procedure (Dest: TKMMenuPageType; const aText: UnicodeString = '') of object;
  TKMToggleLocaleEvent = procedure (const aLocale: AnsiString; aBackToMenuPage: TKMMenuPageType) of object;

const
  //Options sliders
  OPT_SLIDER_MIN = 0;
  OPT_SLIDER_MAX = 20;
  MAX_SAVENAME_LENGTH = 50;

  CHAT_MENU_ALL = -1;
  CHAT_MENU_TEAM = -2;
  CHAT_MENU_SPECTATORS = -3;

  RESULTS_X_PADDING = 50;
  ITEM_NOT_LOADED = -100; // smth, but not -1, as -1 is used for ColumnBox.ItemIndex, when no item is selected


implementation


end.

