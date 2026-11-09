unit KM_ResKeys;
{$I KaM_Remake.inc}
interface
uses
  KM_ResTypes;


type
  TKMResKeys = class
  private
    fKeys: array[TKMKeyFunction] of Integer;
    procedure DoSetKey(aFunc: TKMKeyFunction; const aKey: Integer);
    function GetKey(aFunc: TKMKeyFunction): Integer;
  public
    constructor Create;

    function GetKeyName(aKey: Word): string;
    function GetKeyNameById(aKeyFunc: TKMKeyFunction): string;
    function GetKeyFunctionForKey(aKey: Word; aAreaSet: TKMKeyFuncAreaSet): TKMKeyFunction;

    property Key[aFunc: TKMKeyFunction]: Integer read GetKey write DoSetKey; default;

    function AllowKeySet(aKey: Word): Boolean;

    procedure SetKey(aKeyFunc: TKMKeyFunction; aKey: Word);
    procedure ResetKeymap;

    procedure Load;
    procedure Save;
  end;

var
  // All Keys accessible from everywhere
  gResKeys: TKMResKeys;


implementation
uses
  Math,
  KM_KeysSettings,
  KM_ResKeyFuncs,
  KM_ResTexts;


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
    72, 83, 76, 0, 88,                     // Army commands (Halt/Split/Link/Food/Storm) (H/S/L/F/X)
    187, 189, 190, 188,                     // Army commands (Increase form./Decrease form./Turn clockwise/Turn counterclockwise) (=/-/./,)
    //House keys
    65, 83, 68,                             // School/Barracks/TH commands (prev unit / equip unit / next unit)

    // Spectate/Replay view Keys
    0,                                      // Open/Close spectator statistics panel
    78,                                     // Play next tick in replay
    49, 50, 51, 52, 53, 54, 55, 56, 57, 48, 189, 61, // Switch between players while spectating/viewing replay (1-8)

    // Map Editor Keys
    13,                                     // Map Editor Extra's menu (Return)
    83,                                     // Map Editor Save map (S, but Ctrl+S is actually used)
    112, 113, 114, 115, 116,                // Map Editor menus (F1-F5)
    49, 50, 51, 52, 53, 54,                 // Map Editor sub-menus (1-6)
    81, 87, 69, 82, 84, 89, 85,             // Map Editor sub-menu actions (Q, W, E, R, T, Y, U)
    32,                                     // Map Editor show objects palette (Space)
    119,                                    // Map Editor show tiles palette (F8)
    46,                                     // Map Editor universal erasor (Delete)
    45,                                     // Map Editor paint bucket (Insert)
    72,                                     // Map Editor history (H)
    0,                                      // Map Editor Flat terrain
    0                                       // Map Editor Tiles grid
  );


{ TKMResKeys }
constructor TKMResKeys.Create;
begin
  inherited;

  ResetKeymap;
end;


function TKMResKeys.GetKey(aFunc: TKMKeyFunction): Integer;
begin
  Result := fKeys[aFunc];
end;


procedure TKMResKeys.DoSetKey(aFunc: TKMKeyFunction; const aKey: Integer);
begin
  if (aKey = -1) or not InRange(aKey, 0, 255) then Exit;

  fKeys[aFunc] := aKey;
end;


procedure TKMResKeys.ResetKeymap;
var
  KF: TKMKeyFunction;
begin
  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
    fKeys[KF] := DEF_KEYS[KF];
end;


function TKMResKeys.AllowKeySet(aKey: Word): Boolean;
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
      if fKeys[KF] = aKey then
        case gResKeyFuncs[KF].Area of
          faCommon:     fKeys[KF] := 0;
          faGame:       if (gResKeyFuncs[aKeyFunc].Area in [faGame, faUnit, faHouse, faCommon]) then
                          fKeys[KF] := 0;
          faUnit:       if (gResKeyFuncs[aKeyFunc].Area in [faUnit, faGame, faCommon]) then
                          fKeys[KF] := 0;
          faHouse:      if (gResKeyFuncs[aKeyFunc].Area in [faHouse, faGame, faCommon]) then
                          fKeys[KF] := 0;
          faSpecReplay: if (gResKeyFuncs[aKeyFunc].Area in [faSpecReplay, faCommon]) then
                          fKeys[KF] := 0;
          faMapEdit:    if (gResKeyFuncs[aKeyFunc].Area in [faMapEdit, faCommon]) then
                          fKeys[KF] := 0;
        end;

  fKeys[aKeyFunc] := aKey;
end;


function TKMResKeys.GetKeyFunctionForKey(aKey: Word; aAreaSet: TKMKeyFuncAreaSet): TKMKeyFunction;
var
  KF: TKMKeyFunction;
begin
  Result := kfNone;

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
    if (fKeys[KF] = aKey) and (gResKeyFuncs[KF].Area in aAreaSet) then
      Exit(KF);
end;



function TKMResKeys.GetKeyNameById(aKeyFunc: TKMKeyFunction): string;
begin
  Result := GetKeyName(fKeys[aKeyFunc]);
end;


function TKMResKeys.GetKeyName(aKey: Word): string;
begin
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
end;


procedure TKMResKeys.Load;
begin
  gKeySettings.LoadFromXML;
end;


procedure TKMResKeys.Save;
begin
  gKeySettings.SaveToXML;
end;


end.

