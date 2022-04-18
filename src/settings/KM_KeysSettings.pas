unit KM_KeysSettings;
{$I KaM_Remake.inc}
interface
uses
  KM_IoXML,
  KM_GameAppSettingsPart;

type
  // Hotkey settings loader/saver
  TKMKeysSettings = class(TKMGameAppSettingsPart)
  private
    fHotkeysNode: TKMXmlNode;
  public
    procedure LoadFromXML; override;
    procedure SaveToXML; override;

    procedure UpdateResKeys;
  end;

var
  gKeySettings: TKMKeysSettings;


implementation
uses
  KM_ResTexts,
  KM_ResKeys,
  KM_ResKeyFuncs,
  KM_ResTypes;


{ TKMKeysSettings }
procedure TKMKeysSettings.UpdateResKeys;
var
  KF: TKMKeyFunction;
  nKey: TKMXmlNode;
  keyFuncName: string;
begin
  if gResKeys = nil then Exit;

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
  begin
    keyFuncName := GetKeyFunctionStr(KF);
    if fHotkeysNode.HasChild(keyFuncName) then
    begin
      nKey := fHotkeysNode.AddOrFindChild(keyFuncName);
      if nKey.HasAttribute('Key') then
        gResKeys[KF] := nKey.Attributes['Key'].AsInteger;
    end;
  end;
end;


procedure TKMKeysSettings.LoadFromXML;
begin
  if Self = nil then Exit;
  inherited;

  fHotkeysNode := Root.AddOrFindChild('Hotkeys');

  UpdateResKeys;
end;


procedure TKMKeysSettings.SaveToXML;
var
  KF: TKMKeyFunction;
  nHotkeys, nKey: TKMXmlNode;
begin
  if Self = nil then Exit;
  inherited;

  nHotkeys := Root.AddOrFindChild('Hotkeys');

  // Those are already nil on game exit (gGameApp is destroyed already)
  if (gResKeys = nil)
  or (gResKeyFuncs = nil)
  or (gResTexts = nil) then
    Exit;

  // Clear old data before filling in
  nHotkeys.Clear;

  for KF := KEY_FUNC_LOW to High(TKMKeyFunction) do
  begin
    nKey := nHotkeys.AddOrFindChild(GetKeyFunctionStr(KF));
    nKey.Attributes['Key'] := gResKeys[KF];

    // These are just comments
    nKey.Attributes['KeyDesc'] := gResKeys.GetKeyName(gResKeys[KF]);
    nKey.Attributes['FuncDesc'] := gResTexts[gResKeyFuncs[KF].TextId];
  end;
end;


end.

