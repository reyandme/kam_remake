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
  DEF_K_LIMIT = 10000;


  function GetShiftState(aButton: TMouseButton): TShiftState;
  function GetMultiplicator(aButton: TMouseButton): Word; overload;
  function GetMultiplicator(aShift: TShiftState; const aMultiplier: Integer = 10): Word; overload;
  function IntToKStr(const aValue: Integer; aLimit: Integer = DEF_K_LIMIT): String;


implementation
uses
  SysUtils,
  KM_Defaults;
//  {$IFDEF FPC} FileUtil, {$ENDIF}
//  {$IFDEF WDC} IOUtils {$ENDIF};   const

function GetShiftState(aButton: TMouseButton): TShiftState;
begin
  Result := [];
  case aButton of
    mbLeft:   Include(Result, ssLeft);
    mbRight:  Include(Result, ssRight);
  end;

  if GetKeyState(VK_SHIFT) < 0 then
    Include(Result, ssShift);
end;


function GetMultiplicator(aButton: TMouseButton): Word;
begin
  Result := GetMultiplicator(GetShiftState(aButton));
end;


function GetMultiplicator(aShift: TShiftState; const aMultiplier: Integer = 10): Word;
begin
  Exclude(aShift, ssCtrl); //Ignore Ctrl
  Result := Byte(aShift = [ssLeft])
          + Byte(aShift = [ssRight]) * aMultiplier
          + Byte(aShift = [ssShift,ssLeft]) * aMultiplier * aMultiplier
          + Byte(aShift = [ssShift,ssRight]) * aMultiplier * aMultiplier * aMultiplier;
end;


// 10123 -> '10k'
function IntToKStr(const aValue: Integer; aLimit: Integer = DEF_K_LIMIT): String;
begin
  if SHOW_RES_CNT_K_FOR_10000 and (aValue >= aLimit) then
    Result := IntToStr(aValue div 1000) + 'k'
  else
    Result := IntToStr(aValue);
end;


end.
