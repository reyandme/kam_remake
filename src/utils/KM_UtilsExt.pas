unit KM_UtilsExt;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  Controls
  {$IFDEF MSWindows}
  , Windows
  {$ENDIF}
  {$IFDEF Unix}
  , unix, baseunix, UnixUtil
  {$ENDIF}
  ;

const
  K_THRESHOLD_DEFAULT = 10000;


  function GetShiftState(aButton: TMouseButton): TShiftState;
  function IsRMBInShiftState(aShift: TShiftState): Boolean;
  function GetMultiplicator(aButton: TMouseButton): Word; overload;
  function GetMultiplicator(aShift: TShiftState; const aMultiplier: Integer = 10): Word; overload;
  function IntToKStr(const aValue: Integer; aThreshold: Integer = K_THRESHOLD_DEFAULT): string;


implementation
uses
  SysUtils,
  KM_Defaults
  {$IFDEF FPC} , LCLIntF, LCLType {$ENDIF}
  ;
//  {$IFDEF FPC} FileUtil, {$ENDIF}
//  {$IFDEF WDC} IOUtils {$ENDIF};


const
  // Alt + LMB is considered as RMB
  // We can use it when hotkey is pressed (which is considered as LMB)
  RMB_ALTERNATIVE_SHIFT_STATE: TShiftState = [ssAlt, ssLeft];


function GetShiftState(aButton: TMouseButton): TShiftState;
begin
  Result := [];
  case aButton of
    mbLeft:   Include(Result, ssLeft);
    mbRight:  Include(Result, ssRight);
  end;

  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);

  if GetKeyState(VK_MENU) < 0 then
    Include(Result, ssAlt);

  if GetKeyState(VK_CONTROL) < 0 then
    Include(Result, ssCtrl);
end;


function IsRMBInShiftState(aShift: TShiftState): Boolean;
begin
  Result := (ssRight in aShift) or (RMB_ALTERNATIVE_SHIFT_STATE <= aShift);
end;


function GetMultiplicator(aButton: TMouseButton): Word;
begin
  Result := GetMultiplicator(GetShiftState(aButton));
end;


function GetMultiplicator(aShift: TShiftState; const aMultiplier: Integer = 10): Word;
begin
  Exclude(aShift, ssCtrl); //Ignore Ctrl
  // Consider Alt + LMB as a replacer for RMB
  if IsRMBInShiftState(aShift) then
    aShift := aShift + [ssRight] - [ssAlt, ssLeft];

  Result := Byte(aShift = [ssLeft])
          + Byte(aShift = [ssRight]) * aMultiplier
          + Byte(aShift = [ssShift,ssLeft]) * aMultiplier * aMultiplier
          + Byte(aShift = [ssShift,ssRight]) * aMultiplier * aMultiplier * aMultiplier;
end;


// 10123 -> '10k'
function IntToKStr(const aValue: Integer; aThreshold: Integer = K_THRESHOLD_DEFAULT): string;
begin
  if DBG_SHOW_EXACT_WARE_COUNT or (aValue < aThreshold) then
    Result := IntToStr(aValue)
  else
    Result := IntToStr(aValue div 1000) + 'k';
end;


end.
