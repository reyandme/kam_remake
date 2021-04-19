unit KM_KeysSettings;
{$I KaM_Remake.inc}
interface
uses
  KM_GameAppSettings;

type
  // Hotkey Settings
  TKMKeysSettings = class(TKMGameAppSettingsPart)
  public
    constructor Create;
    destructor Destroy; override;

    procedure LoadFromXML; override;
    procedure SaveToXML; override;
  end;

var
  gKeySettings: TKMKeysSettings;


implementation
uses
  KM_ResTexts,
  KM_ResKeys,
  KM_ResTypes,

  KM_XmlHelper,
  KM_IoXML;


{ TKMKeysSettings }
constructor TKMKeysSettings.Create;
begin
  inherited;

  gKeySettings := Self;
end;


destructor TKMKeysSettings.Destroy;
begin
  inherited;

  gKeySettings := nil;
end;


procedure TKMKeysSettings.LoadFromXML;
var
  KF: TKMKeyFunction;
  nHotkeys, nKey: TXMLNode;
  keyFuncName: string;
  keySpec: TKMKeySpec;
begin
  if Self = nil then Exit;
  inherited;

  nHotkeys := Root.AddOrFindChild('Hotkeys');

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
  begin
    keyFuncName := TKMResKeys.GetKeyFunctionStr(KF);
    if nHotkeys.HasChild(keyFuncName) then
    begin
      nKey := nHotkeys.AddOrFindChild(keyFuncName);
      if nKey.HasAttribute('Key') then
      begin
        keySpec := gResKeys[KF];
        keySpec.Key := nKey.Attributes['Key'].AsInteger;
        gResKeys[KF] := keySpec;
      end;
    end;
  end;
end;

procedure TKMKeysSettings.SaveToXML;
var
  KF: TKMKeyFunction;
  nHotkeys, nKey: TXMLNode;
begin
  if Self = nil then Exit;
  inherited;

  nHotkeys := Root.AddOrFindChild('Hotkeys');

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
  begin
    nKey := nHotkeys.AddOrFindChild(TKMResKeys.GetKeyFunctionStr(KF));
    nKey.Attributes['Key'] := gResKeys[KF].Key;
    nKey.Attributes['KeyDesc'] := gResKeys.GetKeyName(gResKeys[KF].Key);
    nKey.Attributes['FuncDesc'] := gResTexts[gResKeys[KF].TextId];
  end;
end;


end.

