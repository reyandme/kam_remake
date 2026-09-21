unit KM_MessageLog;
{$I KaM_Remake.inc}
interface
uses
  KM_CommonClasses, KM_GameTypes, KM_Points;


type
  //Individual message
  TKMLogMessage = class
  private
    fKind: TKMMessageKind;
    fEntityUID: Integer;
    fLoc: TKMPoint;
    fTextID: Integer;
    fIsReadGIP: Boolean; //This is synced through GIP

    // Runtime (not saved)
    fIsReadLocal: Boolean; //This is used locally so it responds instantly
  public
    constructor Create(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer);
    constructor Load(LoadStream: TKMemoryStream);
    procedure Save(SaveStream: TKMemoryStream);

    function IsGoto: Boolean;
    function IsRead: Boolean;
    function Text: UnicodeString;
    property Loc: TKMPoint read fLoc;
    property EntityUID: Integer read fEntityUID;
    property Kind: TKMMessageKind read fKind;

    property IsReadGIP: Boolean write fIsReadGIP;
    property IsReadLocal: Boolean write fIsReadLocal;
  end;

  TKMMessageLog = class
  private
    fCountLog: Integer;
    fListLog: array of TKMLogMessage;

    fReadAtCountGIP: Integer; // Last time player opened log when log count was equal to

    // Runtime (not saved)
    fReadAtCountLocal: Integer;

    function GetMessageLog(aIndex: Integer): TKMLogMessage;
    function GetReadAtCount: Integer;
  public
    destructor Destroy; override;

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);

    property CountLog: Integer read fCountLog;
    property ReadAtCountGIP: Integer read fReadAtCountGIP write fReadAtCountGIP;
    property ReadAtCountLocal: Integer read fReadAtCountLocal write fReadAtCountLocal;
    property ReadAtCount: Integer read GetReadAtCount;
    property MessagesLog[aIndex: Integer]: TKMLogMessage read GetMessageLog; default;

    function HasNewMessages: Boolean;

    procedure Add(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer);
  end;


implementation
uses
  SysUtils, Math,
  KM_ResTexts,
  KM_HandEntity;


{ TKMLogMessage }
constructor TKMLogMessage.Create(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer);
begin
  inherited Create;

  fKind := aKind;
  fLoc := aLoc;
  fEntityUID := aEntityUID;
  fTextID := aTextID;
end;


constructor TKMLogMessage.Load(LoadStream: TKMemoryStream);
begin
  inherited Create;

  LoadStream.CheckMarker('LogMessage');
  LoadStream.Read(fEntityUID);
  LoadStream.Read(fLoc);
  LoadStream.Read(fTextID);
  LoadStream.Read(fKind, SizeOf(TKMMessageKind));
  LoadStream.Read(fIsReadGIP);
end;


procedure TKMLogMessage.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker('LogMessage');
  SaveStream.Write(fEntityUID);
  SaveStream.Write(fLoc);
  SaveStream.Write(fTextID);
  SaveStream.Write(fKind, SizeOf(TKMMessageKind));
  SaveStream.Write(fIsReadGIP);
end;


//Check wherever message has a GoTo option
function TKMLogMessage.IsGoto: Boolean;
begin
  Result := fKind in [mkHouse, mkGroup];
end;


function TKMLogMessage.IsRead: Boolean;
begin
  Result := fIsReadLocal or fIsReadGIP;
end;


function TKMLogMessage.Text: UnicodeString;
begin
  Result := gResTexts[fTextID];
end;


{ TKMMessageLog }
destructor TKMMessageLog.Destroy;
var
  I: Integer;
begin
  for I := 0 to fCountLog - 1 do
    FreeAndNil(fListLog[I]);

  inherited;
end;


function TKMMessageLog.GetMessageLog(aIndex: Integer): TKMLogMessage;
begin
  Assert(InRange(aIndex, 0, fCountLog - 1));
  Result := fListLog[aIndex];
end;


function TKMMessageLog.GetReadAtCount: Integer;
begin
  Result := Max(fReadAtCountGIP, fReadAtCountLocal);
end;


function TKMMessageLog.HasNewMessages: Boolean;
begin
  Result := ReadAtCount < fCountLog;
end;


procedure TKMMessageLog.Add(aKind: TKMMessageKind; aTextID: Integer; const aLoc: TKMPoint; aEntityUID: Integer);
begin
  SetLength(fListLog, fCountLog + 1);
  fListLog[fCountLog] := TKMLogMessage.Create(aKind, aTextID, aLoc, aEntityUID);
  Inc(fCountLog);
end;


procedure TKMMessageLog.Save(SaveStream: TKMemoryStream);
var
  I: Integer;
begin
  SaveStream.PlaceMarker('MessageLog');
  SaveStream.Write(fCountLog);
  SaveStream.Write(fReadAtCountGIP);
  for I := 0 to fCountLog - 1 do
    MessagesLog[I].Save(SaveStream);
end;


procedure TKMMessageLog.Load(LoadStream: TKMemoryStream);
var
  I: Integer;
begin
  LoadStream.CheckMarker('MessageLog');
  LoadStream.Read(fCountLog);
  LoadStream.Read(fReadAtCountGIP);
  SetLength(fListLog, fCountLog);

  for I := 0 to fCountLog - 1 do
    fListLog[I] := TKMLogMessage.Load(LoadStream);
end;


end.
