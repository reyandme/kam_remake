unit KM_ResKeys;
{$I KaM_Remake.inc}
interface
uses
  Classes, SysUtils, StrUtils, Math, Generics.Collections,
  {$IFDEF WDC} UITypes, {$ENDIF}
  KM_ResTexts,
  KM_ResTypes,
  KM_KeysSettings;

const
  KEY_FUNC_LOW = Succ(kfNone); // 1st key function

type
  TKMKeySpec = record
  private
    fKey: Integer;    // Key assigned to this function
    procedure SetKey(const aKey: Integer);
  public
    TextId: Word;     // Text description of the function
    Area: TKMKeyFuncArea; // Area of effect for the function (common, game, maped)
    IsChangableByPlayer: Boolean; // Hide debug key and its function from UI
    property Key: Integer read fKey write SetKey;
  end;

  TKMResKeys = class
  private
    fFuncs: array [TKMKeyFunction] of TKMKeySpec;
    function GetFunc(aKeyFunc: TKMKeyFunction): TKMKeySpec;
    procedure SetFunc(aKeyFunc: TKMKeyFunction; const aFuncInfo: TKMKeySpec);
  public
    constructor Create;
    function GetKeyName(aKey: Word; aUseDefaultLocale: Boolean = False): string;
    function GetKeyNameById(aKeyFunc: TKMKeyFunction): string;
    function GetKeyFunctionForKey(aKey: Word; aAreaSet: TKMKeyFuncAreaSet): TKMKeyFunction;
    function GetKeyFunctionName(aKeyFunc: TKMKeyFunction): string;
    function AllowKeySet(aArea: TKMKeyFuncArea; aKey: Word): Boolean;
    procedure SetKey(aKeyFunc: TKMKeyFunction; aKey: Word);
    function Count: Integer;
    property Funcs[aKeyFunc: TKMKeyFunction]: TKMKeySpec read GetFunc write SetFunc; default;
    procedure Load;
    procedure Save;
    procedure ResetKeymap;

//    class function GetKeyFunction(aKeyFunStr: string): TKMKeyFunction;
    class function GetKeyDescription(aKey: Word; aShift: TShiftState): string;
    class function GetMouseBtnDescription(X, Y: Integer; aButton: TMouseButton; aShift: TShiftState): string;

    class function GetKeyFunctionStr(aKeyFun: TKMKeyFunction): string;
  end;

var
  // All Keys accessible from everywhere
  gResKeys: TKMResKeys;

implementation
uses
  TypInfo,{, RTTI}
  KM_Utils;

const
  // Default keys
  DEF_KEYS: array [TKMKeyFunction] of Byte = (
    //Common Keys
    0,
    37, 39, 38, 40,                         // Scroll Left, Right, Up, Down (Arrow keys)
    4,                                      // Map drag scroll (Middle mouse btn)
    34, 33, 8,                              // Zoom In/Out/Reset (Page Down, Page Up, Backspace)
    27,                                     // Close opened menu (Esc)
    177, 176,                               // Music controls (Media previous track, Media next track)
    178, 179, 175, 174, 0,                  // Music disable / shuffle / volume up / down / mute
    107, 109, 0,                            // Sound volume up / down /mute
    173,                                    // Mute music and sound
    122,                                    // Debug Window hotkey (F11)

    // These keys are not changable by Player in Options menu
    77, 86, 69, 67,                         // Debug hotkeys (Show Map/Victory/Defeat/Add Scout) (M, V, E, C)

    // Game Keys
    112, 113, 114, 115,                     // Game menus (F1-F4)
    116, 117, 118, 119,                     // Speed ups (x1/x3/x6/x10) (F5-F8)
    66, 80, 84,                             // Beacon/Pause/Show team in MP (B, P, T)
    32, 46, 13,                             // Center to alert/Delete message/Show chat (Space, Delete, Return)
    9,                                      // Select next building/unit/group with same type (Tab)
    0,                                      // Player color mode
    81, 87, 69, 82,                         // Plan road/corn/wine/erase plan(building) (R, C, W, D)
    49, 50, 51, 52, 53, 54, 55, 56, 57, 48, // Dynamic selection groups 1-10 (1-9, 0)
    0, 0, 0, 0, 0, 0, 0, 0, 0, 0,           // Dynamic selection groups 11-20 (no defaults)
    //Unit keys
    72, 83, 76, 70, 88,                     // Army commands (Halt/Split/Link/Food/Storm) (H/S/L/F/X)
    187, 189, 190, 188,                     // Army commands (Increase form./Decrease form./Turn clockwise/Turn counterclockwise) (=/-/./,)
    //House keys
    65, 83, 68,                             // School/Barracks/TH commands (prev unit / equip unit / next unit)

    // Spectate/Replay view Keys
    0,                                      // Open/Close spectator statistics panel
    78,                                     // Play next tick in replay
    49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 189, 61, // Switch between players while spectating/viewing replay (1-8)

    // Map Editor Keys
    13,                                     // Map Editor Extra's menu (Return)
    112, 113, 114, 115, 116,                // Map Editor menus (F1-F5)
    49, 50, 51, 52, 53, 54,                 // Map Editor sub-menus (1-6)
    81, 87, 69, 82, 84, 89, 85,             // Map Editor sub-menu actions (Q, W, E, R, T, Y, U)
    32,                                     // Map Editor show objects palette (Space)
    119,                                    // Map Editor show tiles palette (F8)
    46,                                     // Map Editor universal erasor (Delete)
    45,                                     // Map Editor paint bucket (Insert)
    72                                      // Map Editor history (H)
  );

  // Function text values
  KEY_FUNC_TX: array [TKMKeyFunction] of Word = (
    //Common Keys
    0,
    TX_KEY_FUNC_SCROLL_LEFT, TX_KEY_FUNC_SCROLL_RIGHT, TX_KEY_FUNC_SCROLL_UP, TX_KEY_FUNC_SCROLL_DOWN,    // Scroll Left, Right, Up, Down
    TX_KEY_FUNC_MAP_DRAG_SCROLL,                                                                          // Map drag scroll
    TX_KEY_FUNC_ZOOM_IN, TX_KEY_FUNC_ZOOM_OUT, TX_KEY_FUNC_ZOOM_RESET,                                    // Zoom In/Out/Reset
    TX_KEY_FUNC_CLOSE_MENU,                                                                               // Close opened menu
    TX_KEY_FUNC_MUSIC_PREV_TRACK, TX_KEY_FUNC_MUSIC_NEXT_TRACK,                                           // Music track prev / next
    TX_KEY_FUNC_MUSIC_DISABLE, TX_KEY_FUNC_MUSIC_SHUFFLE,                                                 // Music disable / shuffle
    TX_KEY_FUNC_MUSIC_VOLUME_UP, TX_KEY_FUNC_MUSIC_VOLUME_DOWN, TX_KEY_FUNC_MUSIC_MUTE,                   // Music volume up / down / mute
    TX_KEY_FUNC_SOUND_VOLUME_UP, TX_KEY_FUNC_SOUND_VOLUME_DOWN, TX_KEY_FUNC_SOUND_MUTE,                   // Sound volume up / down / mute
    TX_KEY_FUNC_MUTE_ALL,                                                                                 // Mute music and sound

    TX_KEY_FUNC_DBG_WINDOW,                                                                               // Debug window

    // These keys are not changable by Player in Options menu
    TX_KEY_FUNC_DBG_MAP, TX_KEY_FUNC_DBG_VICTORY, TX_KEY_FUNC_DBG_DEFEAT, TX_KEY_FUNC_DBG_SCOUT,          // Debug (Show Map, Victory, Defeat, Add Scout)

    // Game Keys
    TX_KEY_FUNC_MENU_BUILD, TX_KEY_FUNC_MENU_RATIO, TX_KEY_FUNC_MENU_STATS, TX_KEY_FUNC_MENU_MAIN,        // Game menus
    TX_KEY_FUNC_GAME_SPEED_1,TX_KEY_FUNC_GAME_SPEED_2,TX_KEY_FUNC_GAME_SPEED_3,TX_KEY_FUNC_GAME_SPEED_4,  // Speed ups
    TX_KEY_FUNC_BEACON, TX_KEY_FUNC_PAUSE, TX_KEY_FUNC_SHOW_TEAMS,                                        // Beacon/Pause/Show team in MP
    TX_KEY_FUNC_CENTER_ALERT, TX_KEY_FUNC_DELETE_MSG, TX_KEY_FUNC_SHOW_GAME_CHAT,                         // Center to alert/Delete message/Show chat
    TX_KEY_FUNC_SEL_NXT_BLD_UNIT_SAME_TYPE,                                                               // Select next building/unit/group with same type
    TX_KEY_FUNC_PLAYER_COLOR_MODE,                                                                        // Player color mode
    TX_KEY_FUNC_PLAN_ROAD, TX_KEY_FUNC_PLAN_FIELD, TX_KEY_FUNC_PLAN_WINE, TX_KEY_FUNC_ERASE_PLAN,         // Plan road/corn/wine/erase plan(building)
    TX_KEY_FUNC_SELECT_1, TX_KEY_FUNC_SELECT_2, TX_KEY_FUNC_SELECT_3, TX_KEY_FUNC_SELECT_4, TX_KEY_FUNC_SELECT_5,   // Dynamic selection groups 1-5
    TX_KEY_FUNC_SELECT_6, TX_KEY_FUNC_SELECT_7, TX_KEY_FUNC_SELECT_8, TX_KEY_FUNC_SELECT_9, TX_KEY_FUNC_SELECT_10,  // Dynamic selection groups 6-10
    TX_KEY_FUNC_SELECT_11,TX_KEY_FUNC_SELECT_12,TX_KEY_FUNC_SELECT_13,TX_KEY_FUNC_SELECT_14,TX_KEY_FUNC_SELECT_15,  // Dynamic selection groups 11-15
    TX_KEY_FUNC_SELECT_16,TX_KEY_FUNC_SELECT_17,TX_KEY_FUNC_SELECT_18,TX_KEY_FUNC_SELECT_19,TX_KEY_FUNC_SELECT_20,  // Dynamic selection groups 16-20
    //Unit keys
    TX_KEY_FUNC_HALT, TX_KEY_FUNC_SPLIT, TX_KEY_FUNC_LINKUP, TX_KEY_FUNC_FOOD, TX_KEY_FUNC_STORM,         // Army commands
    TX_KEY_FUNC_FORM_INCREASE, TX_KEY_FUNC_FORM_DECREASE, TX_KEY_FUNC_TURN_CW, TX_KEY_FUNC_TURN_CCW,      // Army commands
    //House keys
    TX_KEY_FUNC_TRAIN_PREV, TX_KEY_FUNC_TRAIN_EQUIP, TX_KEY_FUNC_TRAIN_NEXT,                              // School/Barracks/TH commands

    // Spectate MP game/Replay view Keys
    TX_KEY_FUNC_SPECPANEL_DROPBOX_OPEN_CLOSE,
    TX_KEY_FUNC_REPLAY_PLAY_NEXT_TICK,
    TX_KEY_FUNC_SPECTATE_PLAYER_1, TX_KEY_FUNC_SPECTATE_PLAYER_2, TX_KEY_FUNC_SPECTATE_PLAYER_3, TX_KEY_FUNC_SPECTATE_PLAYER_4,    // Spectator/Replay player switch
    TX_KEY_FUNC_SPECTATE_PLAYER_5, TX_KEY_FUNC_SPECTATE_PLAYER_6, TX_KEY_FUNC_SPECTATE_PLAYER_7, TX_KEY_FUNC_SPECTATE_PLAYER_8,    // Spectator/Replay player switch
    TX_KEY_FUNC_SPECTATE_PLAYER_9, TX_KEY_FUNC_SPECTATE_PLAYER_10, TX_KEY_FUNC_SPECTATE_PLAYER_11, TX_KEY_FUNC_SPECTATE_PLAYER_12, // Spectator/Replay player switch

    // Map Editor Keys
    TX_KEY_FUNC_MAPEDIT_EXTRA,                                                                            // Map Editor Extra's menu
    TX_KEY_FUNC_MAPEDIT_TERAIN_EDIT, TX_KEY_FUNC_MAPEDIT_VILLAGE_PLAN,                                    // Map Editor menus
    TX_KEY_FUNC_MAPEDIT_VISUAL_SCRIPT, TX_KEY_FUNC_MAPEDIT_GLOBAL_SCRIPT, TX_KEY_FUNC_MAPEDIT_MENU_MAIN,  // Map Editor menus
    TX_KEY_FUNC_MAPEDIT_SUBMENU_1, TX_KEY_FUNC_MAPEDIT_SUBMENU_2, TX_KEY_FUNC_MAPEDIT_SUBMENU_3,          // Map Editor sub-menus
    TX_KEY_FUNC_MAPEDIT_SUBMENU_4, TX_KEY_FUNC_MAPEDIT_SUBMENU_5, TX_KEY_FUNC_MAPEDIT_SUBMENU_6,          // Map Editor sub-menus
    TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_1, TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_2,   // Map Editor sub-menu actions
    TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_3, TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_4,   // Map Editor sub-menu actions
    TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_5, TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_6,   // Map Editor sub-menu actions
    TX_KEY_FUNC_MAPEDIT_SUBMENU_ACTION_7,                                         // Map Editor sub-menu actions
    TX_KEY_FUNC_MAPEDIT_OBJ_PALETTE,                                              // Map Editor show objects palette
    TX_KEY_FUNC_MAPEDIT_TILES_PALETTE,                                            // Map Editor show tiles palette
    TX_KEY_FUNC_MAPEDIT_UNIV_ERASOR,                                              // Map Editor universal erasor
    TX_KEY_FUNC_MAPEDIT_PAINT_BUCKET,                                             // Map Editor paint bucket
    TX_KEY_FUNC_MAPEDIT_HISTORY                                                   // Map Editor history
  );

{ TKMResKeys }
constructor TKMResKeys.Create;
var
  KF: TKMKeyFunction;
begin
  inherited;

  ResetKeymap;

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
  begin
    fFuncs[KF].TextId := KEY_FUNC_TX[KF];

    case KF of
      kfScrollLeft..kfDebugAddscout:    fFuncs[KF].Area := faCommon;
      kfMenuBuild..kfSelect20:          fFuncs[KF].Area := faGame;
      kfArmyHalt..kfArmyRotateCcw:      fFuncs[KF].Area := faUnit;
      kfTrainGotoPrev..kfTrainGotoNext: fFuncs[KF].Area := faHouse;
      kfSpecpanelSelectDropbox..kfSpectatePlayer12: fFuncs[KF].Area := faSpecReplay;
      else    fFuncs[KF].Area := faMapEdit;
    end;

    fFuncs[KF].IsChangableByPlayer := (KF in [kfDebugRevealmap..kfDebugAddscout]);
  end;
end;


function TKMResKeys.Count: Integer;
begin
  Result := Integer(High(TKMKeyFunction));
end;


function TKMResKeys.GetFunc(aKeyFunc: TKMKeyFunction): TKMKeySpec;
begin
  Result := fFuncs[aKeyFunc];
end;


procedure TKMResKeys.SetFunc(aKeyFunc: TKMKeyFunction; const aFuncInfo :TKMKeySpec);
begin
  fFuncs[aKeyFunc] := aFuncInfo;
end;


procedure TKMResKeys.ResetKeymap;
var
  KF: TKMKeyFunction;
begin
  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
    fFuncs[KF].Key := DEF_KEYS[KF];
end;


function TKMResKeys.GetKeyFunctionName(aKeyFunc: TKMKeyFunction): string;
begin
  Result := gResTexts[KEY_FUNC_TX[aKeyFunc]];
end;


function TKMResKeys.GetKeyNameById(aKeyFunc: TKMKeyFunction): string;
begin
  Result := GetKeyName(fFuncs[aKeyFunc].Key);
end;


procedure TKMResKeys.Load;
begin
  gKeySettings.LoadFromXML;
end;


procedure TKMResKeys.Save;
begin
  gKeySettings.SaveToXML;
end;


function TKMResKeys.GetKeyFunctionForKey(aKey: Word; aAreaSet: TKMKeyFuncAreaSet): TKMKeyFunction;
var
  KF: TKMKeyFunction;
begin
  Result := kfNone;

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
    if (fFuncs[KF].Key = aKey) and (fFuncs[KF].Area in aAreaSet) then
      Exit(KF);
end;


function TKMResKeys.AllowKeySet(aArea: TKMKeyFuncArea; aKey: Word): Boolean;
begin
  // False if Key equals to Shift or Ctrl, which are used in game for specific bindings
  Result := not (aKey in [16, 17]);
end;


procedure TKMResKeys.SetKey(aKeyFunc: TKMKeyFunction; aKey: Word);
var
  KF: TKMKeyFunction;
begin
  // Reset previous key binding if Key areas overlap
  if aKey <> 0 then
    for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
      if fFuncs[KF].Key = aKey then
        case fFuncs[KF].Area of
          faCommon:     fFuncs[KF].Key := 0;
          faGame:       if (fFuncs[aKeyFunc].Area in [faGame, faUnit, faHouse, faCommon]) then
                          fFuncs[KF].Key := 0;
          faUnit:       if (fFuncs[aKeyFunc].Area in [faUnit, faGame, faCommon]) then
                          fFuncs[KF].Key := 0;
          faHouse:      if (fFuncs[aKeyFunc].Area in [faHouse, faGame, faCommon]) then
                          fFuncs[KF].Key := 0;
          faSpecReplay: if (fFuncs[aKeyFunc].Area in [faSpecReplay, faCommon]) then
                          fFuncs[KF].Key := 0;
          faMapEdit:    if (fFuncs[aKeyFunc].Area in [faMapEdit, faCommon]) then
                          fFuncs[KF].Key := 0;
        end;

  fFuncs[aKeyFunc].Key := aKey;
end;


function TKMResKeys.GetKeyName(aKey: Word; aUseDefaultLocale: Boolean = False): string;
begin
  if aUseDefaultLocale then
    gResTexts.ForceDefaultLocale := True;

  try
    // All the special keys (not characters and not numbers) need a localized name
    case aKey of
      0:  Result := '';
      1:  Result :=  gResTexts[TX_KEY_LMB];
      2:  Result :=  gResTexts[TX_KEY_RMB];
      3:  Result :=  gResTexts[TX_KEY_BREAK];
      4:  Result :=  gResTexts[TX_KEY_MMB];
      5:  Result :=  gResTexts[TX_KEY_MOUSE_FORWARD];
      6:  Result :=  gResTexts[TX_KEY_MOUSE_BACKWARD];
      8:  Result :=  gResTexts[TX_KEY_BACKSPACE];
      9:  Result :=  gResTexts[TX_KEY_TAB];
      12: Result :=  gResTexts[TX_KEY_CLEAR];
      13: Result :=  gResTexts[TX_KEY_ENTER];
      16: Result :=  gResTexts[TX_KEY_SHIFT];
      17: Result :=  gResTexts[TX_KEY_CTRL];
      18: Result :=  gResTexts[TX_KEY_ALT];
      19: Result :=  gResTexts[TX_KEY_PAUSE];
      20: Result :=  gResTexts[TX_KEY_CAPS];
      27: Result :=  gResTexts[TX_KEY_ESC];
      32: Result :=  gResTexts[TX_KEY_SPACE];
      33: Result :=  gResTexts[TX_KEY_PG_UP];
      34: Result :=  gResTexts[TX_KEY_PG_DOWN];
      35: Result :=  gResTexts[TX_KEY_END];
      36: Result :=  gResTexts[TX_KEY_HOME];
      37: Result :=  gResTexts[TX_KEY_ARROW_LEFT];
      38: Result :=  gResTexts[TX_KEY_ARROW_UP];
      39: Result :=  gResTexts[TX_KEY_ARROW_RIGHT];
      40: Result :=  gResTexts[TX_KEY_ARROW_DOWN];
      41: Result :=  gResTexts[TX_KEY_SELECT];
      42: Result :=  gResTexts[TX_KEY_PRINT];
      43: Result :=  gResTexts[TX_KEY_EXECUTE];
      44: Result :=  gResTexts[TX_KEY_PRINT_SCREEN];
      45: Result :=  gResTexts[TX_KEY_INSERT];
      46: Result :=  gResTexts[TX_KEY_DELETE];
      47: Result :=  gResTexts[TX_KEY_HELP];
      // NumPad keys
      96: Result :=  gResTexts[TX_KEY_NUM_0];
      97: Result :=  gResTexts[TX_KEY_NUM_1];
      98: Result :=  gResTexts[TX_KEY_NUM_2];
      99: Result :=  gResTexts[TX_KEY_NUM_3];
      100: Result := gResTexts[TX_KEY_NUM_4];
      101: Result := gResTexts[TX_KEY_NUM_5];
      102: Result := gResTexts[TX_KEY_NUM_6];
      103: Result := gResTexts[TX_KEY_NUM_7];
      104: Result := gResTexts[TX_KEY_NUM_8];
      105: Result := gResTexts[TX_KEY_NUM_9];
      106: Result := gResTexts[TX_KEY_NUM_MULTIPLY];
      107: Result := gResTexts[TX_KEY_NUM_PLUS];
      108: Result := gResTexts[TX_KEY_SEPARATOR];
      109: Result := gResTexts[TX_KEY_NUM_MINUS];
      110: Result := gResTexts[TX_KEY_NUM_DOT];
      111: Result := gResTexts[TX_KEY_NUM_DIVIDE];
      // F keys
      112: Result := 'F1';
      113: Result := 'F2';
      114: Result := 'F3';
      115: Result := 'F4';
      116: Result := 'F5';
      117: Result := 'F6';
      118: Result := 'F7';
      119: Result := 'F8';
      120: Result := 'F9';
      121: Result := 'F10';
      122: Result := 'F11';
      123: Result := 'F12';
      // F13..F24 are the special function keys, enabled by default in the EFI(UEFI) BIOS
      //  This is especially the case with Windows 8/8.1 laptops.
      //  Most manufacturers don't give the option to change it in the BIOS, hence we name them here anyways.
      124: Result := 'F13';
      125: Result := 'F14';
      126: Result := 'F15';
      127: Result := 'F16';
      128: Result := 'F17';
      129: Result := 'F18';
      130: Result := 'F19';
      131: Result := 'F20';
      132: Result := 'F21';
      133: Result := 'F22';
      134: Result := 'F23';
      135: Result := 'F24';
      144: Result := gResTexts[TX_KEY_NUM_LOCK];
      145: Result := gResTexts[TX_KEY_SCROLL_LOCK];
      160: Result := gResTexts[TX_KEY_LEFT_SHIFT];
      161: Result := gResTexts[TX_KEY_RIGHT_SHIFT];
      162: Result := gResTexts[TX_KEY_LEFT_CTRL];
      163: Result := gResTexts[TX_KEY_RIGHT_CTRL];
      164: Result := gResTexts[TX_KEY_LEFT_ALT];
      165: Result := gResTexts[TX_KEY_RIGHT_ALT];
      // Media keys (additional keys on some keyboards)
      166: Result := gResTexts[TX_KEY_BROWSER_BACK];
      167: Result := gResTexts[TX_KEY_BROWSER_FORWARD];
      168: Result := gResTexts[TX_KEY_BROWSER_REFRESH];
      169: Result := gResTexts[TX_KEY_BROWSER_STOP];
      170: Result := gResTexts[TX_KEY_BROWSER_SEARCH];
      171: Result := gResTexts[TX_KEY_BROWSER_FAVORITES];
      172: Result := gResTexts[TX_KEY_BROWSER_HOME];
      173: Result := gResTexts[TX_KEY_VOLUME_MUTE];
      174: Result := gResTexts[TX_KEY_VOLUME_DOWN];
      175: Result := gResTexts[TX_KEY_VOLUME_UP];
      176: Result := gResTexts[TX_KEY_MEDIA_NEXT_TRACK];
      177: Result := gResTexts[TX_KEY_MEDIA_PREV_TRACK];
      178: Result := gResTexts[TX_KEY_MEDIA_STOP];
      179: Result := gResTexts[TX_KEY_MEDIA_PLAY_PAUSE];
      180: Result := gResTexts[TX_KEY_LAUNCH_MAIL];
      181: Result := gResTexts[TX_KEY_LAUNCH_MEDIA_SELECT];
      182: Result := gResTexts[TX_KEY_LAUNCH_APP1];
      183: Result := gResTexts[TX_KEY_LAUNCH_APP2];
      186: Result := ';';
      187: Result := '=';
      188: Result := ',';
      189: Result := '-';
      190: Result := '.';
      191: Result := '/';
      192: Result := '`';
      219: Result := '[';
      220: Result := '\';
      221: Result := ']';
      222: Result := '''';
      250: Result := gResTexts[TX_KEY_PLAY];
      251: Result := gResTexts[TX_KEY_ZOOM];
    else
      Result := Char(aKey);
    end;
  finally
    if aUseDefaultLocale then
      gResTexts.ForceDefaultLocale := False;
  end;
end;


//class function TKMResKeys.GetKeyFunction(aKeyFunStr: string): TKMKeyFunction;
//begin
//  Result := TRttiEnumerationType.GetValue<TKMKeyFunction>(aKeyFunStr);
//end;


class function TKMResKeys.GetKeyDescription(aKey: Word; aShift: TShiftState): string;
var
  keyName: string;
begin
  if gResKeys <> nil then
    keyName := gResKeys.GetKeyName(aKey, True) // Use default locale
  else
    keyName := '';

  Result := Format('Key: %d [%s] Shift: [%s]', [aKey, keyName, ShiftStateToString(aShift)]);
end;


class function TKMResKeys.GetMouseBtnDescription(X, Y: Integer; aButton: TMouseButton; aShift: TShiftState): string;
begin
  Result := Format('at (%d;%d) Btn %s Shift: [%s]',
                   [X, Y, GetEnumName(TypeInfo(TMouseButton), Integer(aButton)), ShiftStateToString(aShift)]);
end;


class function TKMResKeys.GetKeyFunctionStr(aKeyFun: TKMKeyFunction): string;
begin
//  Result := TRttiEnumerationType.GetName(aKeyFun);
  Result := GetEnumName(TypeInfo(TKMKeyFunction), Integer(aKeyFun));
end;


{ TKMKeySpec }
procedure TKMKeySpec.SetKey(const aKey: Integer);
begin
  if (aKey = -1) or not InRange(aKey, 0, 255) then Exit;

  fKey := aKey;
end;


end.
