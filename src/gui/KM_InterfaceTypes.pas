unit KM_InterfaceTypes;
{$I KaM_Remake.inc}
interface
uses
  Classes;

type
  TKMUIMode = (umSP, umMP, umReplay, umSpectate);
  TKMUIModeSet = set of TKMUIMode;

  TKMMenuPageType =  (
    gpMainMenu,
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
    gpError
  );

  TKMMenuChangeEventText = procedure (Dest: TKMMenuPageType; const aText: UnicodeString = '') of object;
  TKMToggleLocaleEvent = procedure (const aLocale: AnsiString; aBackToMenuPage: TKMMenuPageType) of object;

  TKMZoomBehaviour = (
    zbRestricted, // Limit the zoom to within the map boundaries (classic zoom behaviour)
    zbFull,       // Prevents the zoom from crossing both map boundaries
    zbLoose       // Limit the zoom to 1.1x the map width or height
  );

const
  // Options sliders
  OPT_SLIDER_MIN = 0;
  OPT_SLIDER_MAX = 20;

  CHAT_MENU_ALL = -1;
  CHAT_MENU_TEAM = -2;
  CHAT_MENU_SPECTATORS = -3;

  RESULTS_X_PADDING = 50;
  ITEM_NOT_LOADED = -100; // smth, but not -1, as -1 is used for ColumnBox.ItemIndex, when no item is selected

  RMB_ADD_ROWS_CNT = 5; // Number of rows to add / remove to group when click RMB on the button


implementation


end.

