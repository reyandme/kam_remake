unit KM_CampaignClasses;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses;

type
  //Unique campaign identification, stored as 3 ANSI letters (TSK, TPR, etc)
  //3 bytes are used to avoid string types issues
  TKMCampaignId = class
  private
    fID: AnsiString;
    function GetID: AnsiString;
    procedure SetID(aID: AnsiString);
  public
    constructor Create(aID: AnsiString);
    constructor Load(aLoadStream: TKMemoryStream);
    procedure Save(aSaveStream: TKMemoryStream);

    property ID: AnsiString read GetID write SetID;

    class function isIdValid(aID: AnsiString): Boolean;
  end;

const
  CAMPAIGN_ID_LENGTH = 3;


implementation
uses
  SysUtils;


{ TKMCampaignId }
constructor TKMCampaignId.Create(aID: AnsiString);
begin
  inherited Create;

  if not isIdValid(aID) then
    raise Exception.Create('Wrong campaign ID: ' + string(aID));

  fID := aID;
end;


constructor TKMCampaignId.Load(aLoadStream: TKMemoryStream);
begin
  inherited Create;

  aLoadStream.ReadA(fID);
end;


function TKMCampaignId.GetID: AnsiString;
begin
  if Self = nil then Exit('');

  Result := fID;
end;


procedure TKMCampaignId.Save(aSaveStream: TKMemoryStream);
begin
  if Self = nil then Exit;

  aSaveStream.WriteA(fID);
end;


procedure TKMCampaignId.SetID(aID: AnsiString);
begin
  if not isIdValid(aID) then
    raise Exception.Create('Wrong campaign ID: ' + string(aID));

  fID := aID;
end;


class function TKMCampaignId.isIdValid(aID: AnsiString): Boolean;
begin
  Result := length(aID) = CAMPAIGN_ID_LENGTH;
end;


end.