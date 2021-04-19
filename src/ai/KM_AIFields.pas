unit KM_AIFields;
{$I KaM_Remake.inc}
interface
uses
  KM_NavMesh, KM_AIInfluences, KM_Eye, KM_Supervisor,
  KM_CommonClasses, KM_Points, KM_GameTypes;


type
  //Master class for Influence maps, NavMeshe and other terrain representations
  //that are helpful in decision making by Mayour/General
  TKMAIFields = class
  private
    fNavMesh: TKMNavMesh;
    fInfluences: TKMInfluences;
    fEye: TKMEye;
    fSupervisor: TKMSupervisor;

    fCanHaveAAI: Boolean; // Flag, if game can have AdvancedAI
  public
    constructor Create();
    destructor Destroy(); override;

    property NavMesh: TKMNavMesh read fNavMesh;
    property Influences: TKMInfluences read fInfluences;
    property Eye: TKMEye read fEye write fEye;
    property Supervisor: TKMSupervisor read fSupervisor write fSupervisor;

    procedure AfterMissionInit(aCanHaveAAI: Boolean);

    procedure Save(SaveStream: TKMemoryStream);
    procedure Load(LoadStream: TKMemoryStream);
    procedure UpdateState(aTick: Cardinal);
    procedure Paint(const aRect: TKMRect);
  end;


var
  gAIFields: TKMAIFields;


implementation
uses
  SysUtils,
  KM_Defaults,
  KM_DevPerfLog, KM_DevPerfLogTypes;

const
  AIFIELDS_MARKER = 'AIFields';


{ TKMAIFields }
constructor TKMAIFields.Create();
begin
  inherited;

  fNavMesh := TKMNavMesh.Create();
  fInfluences := TKMInfluences.Create(fNavMesh);
  fEye := TKMEye.Create();
  fSupervisor := TKMSupervisor.Create();
end;


destructor TKMAIFields.Destroy();
begin
  FreeAndNil(fNavMesh);
  FreeAndNil(fInfluences);
  FreeAndNil(fEye);
  FreeAndNil(fSupervisor);
  inherited;
end;


procedure TKMAIFields.AfterMissionInit(aCanHaveAAI: Boolean);
begin
  fCanHaveAAI := aCanHaveAAI;

  if not AI_GEN_NAVMESH then
    Exit;

  fNavMesh.AfterMissionInit();
  fInfluences.AfterMissionInit();
  if fCanHaveAAI then
  begin
    fSupervisor.AfterMissionInit();
    // fEye.AfterMissionInit(); Eye is updated from HandsCollection (so mines are already visible for game with random map and automatic selection of storehouse)
  end;
end;


procedure TKMAIFields.Save(SaveStream: TKMemoryStream);
begin
  SaveStream.PlaceMarker(AIFIELDS_MARKER);

  SaveStream.Write(fCanHaveAAI);
  fNavMesh.Save(SaveStream);
  fInfluences.Save(SaveStream);

  if fCanHaveAAI then
  begin
    fEye.Save(SaveStream);
    fSupervisor.Save(SaveStream);
  end;
end;


procedure TKMAIFields.Load(LoadStream: TKMemoryStream);
begin
  LoadStream.CheckMarker(AIFIELDS_MARKER);

  LoadStream.Read(fCanHaveAAI);
  fNavMesh.Load(LoadStream);
  fInfluences.Load(LoadStream);

  if fCanHaveAAI then
  begin
    fEye.Load(LoadStream);
    fSupervisor.Load(LoadStream);
  end;
end;


procedure TKMAIFields.UpdateState(aTick: Cardinal);
begin
  {$IFDEF PERFLOG}
  gPerfLogs.SectionEnter(psAIFields);
  {$ENDIF}
  try
    fNavMesh.UpdateState(aTick);
    fInfluences.UpdateState(aTick);

    if fCanHaveAAI then
    begin
      fEye.UpdateState(aTick);
      fSupervisor.UpdateState(aTick);
    end;
  finally
    {$IFDEF PERFLOG}
    gPerfLogs.SectionLeave(psAIFields);
    {$ENDIF}
  end;
end;


//Render debug symbols
procedure TKMAIFields.Paint(const aRect: TKMRect);
begin
  if AI_GEN_INFLUENCE_MAPS then
    fInfluences.Paint(aRect);

  if AI_GEN_NAVMESH then
    fNavMesh.Paint(aRect);

  if fCanHaveAAI then
  begin
    fEye.Paint(aRect);
    fSupervisor.Paint(aRect);
  end;
end;


end.
