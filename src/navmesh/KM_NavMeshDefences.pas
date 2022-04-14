{
NavMesh - generator of defence positions
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshDefences;
{$I KaM_Remake.inc}
interface
uses
  Math, KM_Defaults, KM_CommonTypes, KM_Points,
  KM_NavMeshFloodFill;

type
  TDefenceInfo = record
    Influence, EnemyInfluence, AllyInfluence: Byte;
    Distance: Word;
    PointInDir: TKMPoint;
  end;
  TDefInfoArray = array of TDefenceInfo;

  // Defence lines for watchtowers
  TKMDefenceLine = record
    Polygon: Word;
    Nodes: array[0..1] of Word;
  end;
  TKMDefenceLines = record
    Mark: Byte;
    Count,PolyCnt: Word;
    Lines: array of TKMDefenceLine;
  end;
  TKMDefLinesArray = array of TKMDefenceLines;
  {$IFDEF DEBUG_NavMeshDefences}
  TKMDefLinesDebugInfo = record
    Count: Word;
    DefLines: array of record
      Price: Single;
      DefArr: TKMDefenceLines;
    end;
  end;
  {$ENDIF}

  // Defence position for army defence
  TKMDefencePosition = record
    Line: Byte;
    Polygon, Weight: Word;
    DirPoint: TKMPointDir;
  end;
  TKMDefencePosArr = array of TKMDefencePosition;
  PDefencePosition = ^TKMDefencePosition;

  TKMTeamDefPos = array of record
    Polygons: Word;
    Owners: TKMHandIDArray;
    DefPosArr: TKMDefencePosArr;
  end;

  TForwardFF = class;
  TBackwardFF = class;
  TFilterFF = class;

  TForwardFF = class(TNavMeshFloodFill)
  private
  protected
    fOwner: TKMHandID;
    fFirstLine: Word;
    fPolygonCnt: Integer;
    fDefInfo: TDefInfoArray;
    fBackwardFF: TBackwardFF;
    fBestDefLines: TKMDefenceLines;
    {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter: Integer;
    fDebugDefPolyCnt: Integer;
    {$ENDIF}

    procedure MakeNewQueue(); override;
    function IsVisited(const aIdx: Word): Boolean; override;
    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx: Word; const aDistance: Cardinal; const aPoint: TKMPoint); override;
    function ForwardFF(): Boolean;
  public
    constructor Create(aSorted: Boolean = False); reintroduce;
    destructor Destroy(); override;

    property FirstLine: Word read fFirstLine;
    property BestDefLines: TKMDefenceLines read fBestDefLines;

    function FindDefenceLines(aOwner: TKMHandID; var aDefLines: TKMDefenceLines): Boolean;
    function FindDefensivePolygons(aOwner: TKMHandID; var aDefPosArr: TKMDefencePosArr): Boolean;
    function FindTeamDefences(var aOwners: TKMHandIDArray; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos; aDefLinesRequired: Boolean = False): Boolean;

    procedure Paint();
  end;


  TBackwardFF = class(TNavMeshFloodFill)
  protected
    fDefLinesRequired: Boolean;
    fOwner: TKMHandID;
    fPolygonCnt: Integer;
    fBestEvaluation: Single;
    fStartPolygons: TKMWordArray;
    fDefInfo: TDefInfoArray;
    fBestDefLines: TKMDefenceLines;
    fDefPosArr: TKMDefencePosArr;
    fFilterFF: TFilterFF;
    {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter: Integer;
    fDebugDefPolyCnt: Integer;
    fDebugDefLines: TKMDefLinesDebugInfo;
    {$ENDIF}

    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure BackwardFlood(aOwners: TKMHandIDArray);
    procedure EvaluateDefence(const aIdx: Word);
    function FindDefencePos(aBaseCnt: Word): Boolean;
  public
    constructor Create(aSorted: Boolean = False); reintroduce;
    destructor Destroy(); override;

    procedure UpdatePointers(var aDefInfo: TDefInfoArray; var aQueueArray: TPolygonsQueueArr);
    procedure NewQueue(aVisitedIdx: Byte);
    procedure AddPolygon(aIdx: Word);
    function FindDefenceLines(aOwner: TKMHandID; aPolygonCnt: Integer): TKMDefenceLines;
    function FindDefensivePolygons(aOwner: TKMHandID; aPolygonCnt: Integer; var aFirstLine: Word; var aBestDefLines: TKMDefenceLines; aDefLinesRequired: Boolean): TKMDefencePosArr;
    procedure FindTeamDefences(var aOwners: TKMHandIDArray; aPolygonCnt: Integer; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos; aDefLinesRequired: Boolean = False);

    procedure Paint(var aOwners: TKMHandIDArray; aPolygonCnt: Integer; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos);
  end;


  TFilterFF = class(TNavMeshFloodFill)
  private
    fPolyCnt: Word;
    fBestDefLines, fAllDefLines: TKMDefenceLines;
  protected
    procedure InitQueue(aMaxIdx: Integer; aInitIdxArray: TKMWordArray); reintroduce;
    function IsVisited(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx: Word; const aDistance: Cardinal; const aPoint: TKMPoint); override;
    function CheckStartPolygons(var aStartPolygons: TKMWordArray): boolean;
  public
    property BestDefLines: TKMDefenceLines read fBestDefLines;

    function IsPolyInsideDef(aIdx: Word): Boolean;
    procedure FilterDefenceLine(var aAllDefLines, aBestDefLines: TKMDefenceLines);
    procedure FilterTeamDefLine(aClean: Boolean; aOwner: TKMHandID; var aAllDefLines: TKMDefenceLines; var aSeparatedDefLines: TKMDefLinesArray; var aPLDefAreas: TKMByteArray);

    procedure Paint();
  end;


const
  OWNER_INFLUENCE_LIMIT = 240; // From this influence limit will be counted distance, it is also the closest line of possible defence
  MAX_ENEMY_INFLUENCE = 200; // Maximal enemy influence in FordwardFF (forward flood fill will not scan futher)
  ALLY_INFLUENCE_LIMIT = 240; // If ally influence will be greater than this constant, then will be applied penalization ALLY_INFLUENCE_PENALIZATION in weight function of actual defensive line
  ENEMY_INFLUENCE_LIMIT = 1; // If enemy influence will be greater than this constant, then will be applied penalization ENEMY_INFLUENCE_PENALIZATION in weight function of actual defensive line

  // Weights of defensive line calculation
  MIN_OPTIMAL_INFLUENCE = 50; // Minimal optimal influence (maximal is given by ALLY_INFLUENCE_LIMIT)
  POLYGON_CNT_PENALIZATION = 5; // Polygon count penalization (more polygons = worse defensive line)
  OPTIMAL_INFLUENCE_ADD = 1; // Improve criterium of actual defence line in case that influence is in <MIN_OPTIMAL_INFLUENCE, ALLY_INFLUENCE_LIMIT>
  ENEMY_INFLUENCE_PENALIZATION = 10; // Enemy penalization (dont place defences inside of enemy city)
  MAXIMAL_DEFENCE_DISTANCE = 75; // Maximal defence distance (maximal distance is also affected by MAX_ENEMY_INFLUENCE)
  MIN_DEFENCE_CNT = 1; // Minimal count of defence polygons before penalization

implementation
uses
  SysUtils, KM_Hand, KM_HandsCollection,
  {$IF Defined(DEBUG_NavMeshDefences) or Defined(DEBUG_BattleLines)}
  DateUtils,
  {$ENDIF}
  KM_AIFields, KM_AIInfluences, KM_NavMesh, KM_RenderAux;


{ TForwardFF }
constructor TForwardFF.Create(aSorted: Boolean = False);
begin
  inherited Create(aSorted);
  fBackwardFF := TBackwardFF.Create(aSorted);
  {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter := 0;
    fDebugDefPolyCnt := 0;
  {$ENDIF}
end;


destructor TForwardFF.Destroy();
begin
  fBackwardFF.Free;
  inherited Destroy;
end;


// Prepare new Queue
procedure TForwardFF.MakeNewQueue();
begin
  fPolygonCnt := 0;
  // Check length
  if (Length(fQueueArray) < gAIFields.NavMesh.PolygonsCnt) then
  begin
    SetLength(fQueueArray, gAIFields.NavMesh.PolygonsCnt);
    SetLength(fDefInfo, gAIFields.NavMesh.PolygonsCnt);
    fBackwardFF.UpdatePointers(fDefInfo, fQueueArray);
  end;
  // There is 1 FF forward, 1 FF backward and X FF for positioning in 1 cycle; filter have its own array
  ClearVisitIdx();
  // Init also backward FF
  fBackwardFF.NewQueue(fVisitedIdx+1);
  {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter := 0;
    if (fDebugDefPolyCnt = 0) then
      fDebugDefPolyCnt := gAIFields.NavMesh.PolygonsCnt;
  {$ENDIF}
end;


function TForwardFF.IsVisited(const aIdx: Word): Boolean;
begin
  Result := (fQueueArray[aIdx].Visited >= fVisitedIdx); // Arrays are common for TForwardFF and TBackwardFF so >= must be here
end;


function TForwardFF.CanBeExpanded(const aIdx: Word): Boolean;
{$IFDEF DEBUG_NavMeshDefences}
  var
    Idx,K: Integer;
{$ENDIF}
begin
  // This is border condition for final line of forward flood fill (polygons with 3 nearby polygons can create defensive lines)
  Result := (gAIFields.NavMesh.Polygons[aIdx].NearbyCount <> 3) OR (fDefInfo[aIdx].EnemyInfluence < MAX_ENEMY_INFLUENCE);
  if not Result then
    fBackwardFF.AddPolygon(aIdx);
  {$IFDEF DEBUG_NavMeshDefences}
    Inc(fDebugCounter);
    if OVERLAY_DEFENCES_A AND (fDebugCounter = Round(DateUtils.MilliSecondsBetween(Now, 0) * 0.01) mod fDebugDefPolyCnt) then
    begin
      gAIFields.NavMesh.DrawPolygon(aIdx, Min(250,75), tcBlue, -1, IntToStr(aIdx));
      Idx := fStartQueue;
      for K := 0 to fQueueCnt - 1 do
      begin
        gAIFields.NavMesh.DrawPolygon(Idx, Min(250,K + 75), tcBlue, -1, IntToStr(K));
        Idx := fQueueArray[Idx].Next;
      end;
    end;
  {$ENDIF}
end;


procedure TForwardFF.MarkAsVisited(const aIdx: Word; const aDistance: Cardinal; const aPoint: TKMPoint);
var
  Distance: Cardinal;
begin
  Inc(fPolygonCnt);
  // Get owner influence and distance from influence
  fDefInfo[aIdx].Influence := gAIFields.Influences.OwnPoly[fOwner, aIdx];
  fDefInfo[aIdx].AllyInfluence := gAIFields.Influences.GetBestAllianceOwnership(fOwner, aIdx, atAlly);
  fDefInfo[aIdx].EnemyInfluence := gAIFields.Influences.GetBestAllianceOwnership(fOwner, aIdx, atEnemy);
  Distance := aDistance + fDefInfo[aIdx].EnemyInfluence shr 2;
  if (fDefInfo[aIdx].Influence > OWNER_INFLUENCE_LIMIT) OR (fDefInfo[aIdx].AllyInfluence > OWNER_INFLUENCE_LIMIT) then
    Distance := 0;
  inherited MarkAsVisited(aIdx, Distance, aPoint);
  // For special polygons calculate also ene influence
  //if (gAIFields.NavMesh.Polygons[aIdx].NearbyCount = 3) then
end;


// Forward flood fill -> from polygons in the owner's city make flood fill to polygons in hostile influence area
// ForwardFF will find enemies, compute distance and detect empty areas which does not requires defences
function TForwardFF.ForwardFF(): Boolean;
var
  PL: TKMHandID;
  I, Cnt: Integer;
  CityCenterPoints: TKMPointArray;
  StartPolygons: TKMWordArray;
begin
  // Get center points of all allied cities
  Cnt := 0;
  for PL := 0 to gHands.Count - 1 do
    if (gHands[fOwner].Alliances[PL] = atAlly) then
    begin
      gAIFields.Eye.OwnerUpdate(PL);
      CityCenterPoints := gAIFields.Eye.GetCityCenterPoints(True);
      // Transform it to polygons
      SetLength(StartPolygons, Cnt + Length(CityCenterPoints));
      for I := 0 to Length(CityCenterPoints) - 1 do
      begin
        StartPolygons[Cnt] := gAIFields.NavMesh.KMPoint2Polygon[ CityCenterPoints[I] ];
        Cnt := Cnt + 1;
      end;
    end;
  // Update owner
  gAIFields.Eye.OwnerUpdate(fOwner);

  // Flood fill
  Result := FillPolygons(Length(StartPolygons), StartPolygons);
end;


// Find best defensive lines (for watchtowers)
function TForwardFF.FindDefenceLines(aOwner: TKMHandID; var aDefLines: TKMDefenceLines): Boolean;
begin
  fOwner := aOwner;
  fFirstLine := 0;

  gAIFields.Eye.OwnerUpdate(aOwner); // Make sure that Eye is set to the right Owner (Old AI does not shift it)

  Result := ForwardFF();
  if Result then
    aDefLines := fBackwardFF.FindDefenceLines(aOwner, fPolygonCnt);
end;


// Find best defensive polygons (for defensive positions)
function TForwardFF.FindDefensivePolygons(aOwner: TKMHandID; var aDefPosArr: TKMDefencePosArr): Boolean;
begin
  fOwner := aOwner;
  fFirstLine := 0;
  fBestDefLines.Mark := 0;
  fBestDefLines.Count := 0;
  fBestDefLines.PolyCnt := 0;

  gAIFields.Eye.OwnerUpdate(aOwner); // Make sure that Eye is set to the right Owner (Old AI does not shift it)

  Result := ForwardFF();
  if Result then
    aDefPosArr := fBackwardFF.FindDefensivePolygons(aOwner, fPolygonCnt, fFirstLine, fBestDefLines, False);
end;


function TForwardFF.FindTeamDefences(var aOwners: TKMHandIDArray; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos; aDefLinesRequired: Boolean = False): Boolean;
begin
  fOwner := aOwners[0];

  gAIFields.Eye.OwnerUpdate(fOwner); // Make sure that Eye is set to the right Owner (Old AI does not shift it)

  Result := ForwardFF();
  if Result then
    fBackwardFF.FindTeamDefences(aOwners, fPolygonCnt, aDefPosReq, aTeamDefPos, aDefLinesRequired);
end;


procedure TForwardFF.Paint();
var
  K: Integer;
  PL: TKMHandID;
  Owners: TKMHandIDArray;
  DefPosReq: TKMWordArray;
  TeamDefPos: TKMTeamDefPos;
begin
  //{
  // Get players in alliance
  for PL := 0 to gHands.Count - 1 do
    if gHands[PL].Enabled AND (gHands[ gMySpectator.HandID ].Alliances[PL] = atAlly) then
    begin
      SetLength(Owners, Length(Owners) + 1);
      Owners[ High(Owners) ] := PL;
      // Make first index spec. handID so it have different color
      if (gMySpectator.HandID = Owners[ High(Owners) ]) then
      begin
        Owners[ High(Owners) ] := Owners[0];
        Owners[0] := gMySpectator.HandID;
      end;
    end;
  // Copy dummy defense requirements
  SetLength(DefPosReq, Length(Owners));
  for K := Low(DefPosReq) to High(DefPosReq) do
    DefPosReq[K] := 10;
  // Find defences for debug
  fOwner := Owners[0];
  fFirstLine := 0;
  gAIFields.Eye.OwnerUpdate(fOwner); // Make sure that Eye is set to the right Owner (Old AI does not shift it)
  ForwardFF();
  //{
  if not OVERLAY_DEFENCES_A then
    for K := Low(fDefInfo) to High(fDefInfo) do
      with fDefInfo[K] do
      begin
        if (fDefInfo[K].Influence      > 0) then gAIFields.NavMesh.DrawPolygon(K, fDefInfo[K].Influence     , tcGreen );
        if (fDefInfo[K].AllyInfluence  > 0) then gAIFields.NavMesh.DrawPolygon(K, fDefInfo[K].AllyInfluence , tcBlue  );
        if (fDefInfo[K].EnemyInfluence > 0) then gAIFields.NavMesh.DrawPolygon(K, fDefInfo[K].EnemyInfluence, tcRed   );
      end;

  //}
  fBackwardFF.Paint(Owners, fPolygonCnt, DefPosReq, TeamDefPos);

  {$IFDEF DEBUG_NavMeshDefences}
    fDebugDefPolyCnt := fDebugCounter;
  {$ENDIF}
end;


{ TBackwardFF }
constructor TBackwardFF.Create(aSorted: Boolean = False);
begin
  inherited Create(aSorted);
  fFilterFF := TFilterFF.Create(False);
  {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter := 0;
    fDebugDefPolyCnt := 0;
  {$ENDIF}
end;


destructor TBackwardFF.Destroy();
begin
  fFilterFF.Free;
  inherited Destroy;
end;


procedure TBackwardFF.UpdatePointers(var aDefInfo: TDefInfoArray; var aQueueArray: TPolygonsQueueArr);
begin
  fDefInfo := aDefInfo;
  fQueueArray := aQueueArray;
end;


procedure TBackwardFF.NewQueue(aVisitedIdx: Byte);
begin
  fQueueCnt := 0;
  fVisitedIdx := aVisitedIdx;
  fBestEvaluation := 1000000000;
end;


procedure TBackwardFF.AddPolygon(aIdx: Word);
begin
  fQueueArray[aIdx].Visited := fVisitedIdx; // Polygon is marked from ForwardFF
  fDefInfo[aIdx].Distance := fQueueArray[aIdx].Distance; // Save distance for future calculation of defensive lines
  fQueueArray[aIdx].Distance := High(Word) - fQueueArray[aIdx].Distance; // NavMesh Flood fill class can sort only in increased order -> distances must be inverted when we want to start with the farthest
  InsertAndSort(aIdx);
end;


// Evaluation of actual defensive line
procedure TBackwardFF.EvaluateDefence(const aIdx: Word);
  // Get second defensive polygon (2 neighboring polygons in NavMesh have common 1 line)
  function GetSecondDefencePolygon(const aDefIdx: Word): Word;
  var
    I, NearbyIdx, VisitedCnt, VisitedIdx, UnVisitedIdx: Word;
  begin
    Result := aDefIdx;
    // Find un/visited surrounding polygons (in case that there are 2 visited polygons defece line will be with unvisited and vice versa)
    VisitedCnt := 0;
    VisitedIdx := 0; // For compiler
    UnVisitedIdx := 0; // For compiler
    for I := 0 to gAIFields.NavMesh.Polygons[aDefIdx].NearbyCount-1 do
    begin
      NearbyIdx := gAIFields.NavMesh.Polygons[aDefIdx].Nearby[I];
      if IsVisited(NearbyIdx) then
      begin
        VisitedCnt := VisitedCnt + 1;
        VisitedIdx := NearbyIdx;
      end
      else
        UnVisitedIdx := NearbyIdx;
    end;
    if (VisitedCnt = 1) then
      Result := VisitedIdx
    else if (VisitedCnt <> 3) then
      Result := UnVisitedIdx;
  end;
  // Add new defensive polygon and find defensive line
  procedure AddDefence(aDefIdx1: Word);
  var
    SecondIndice: Boolean;
    I,K, DefIdx2: Integer;
  begin
    fBestDefLines.Lines[ fBestDefLines.Count ].Polygon := aDefIdx1;
    // For defensive position we dont need proper defensive lines only border polygon for position flood fill
    if fDefLinesRequired then
    begin
      DefIdx2 := GetSecondDefencePolygon(aDefIdx1);
      // Find common defensive line of 2 polygons
      SecondIndice := False;
      for I := 0 to 2 do
        for K := 0 to 2 do
          if (gAIFields.NavMesh.Polygons[aDefIdx1].Indices[I] = gAIFields.NavMesh.Polygons[DefIdx2].Indices[K]) then
          begin
            fBestDefLines.Lines[ fBestDefLines.Count ].Nodes[ Byte(SecondIndice) ] := gAIFields.NavMesh.Polygons[aDefIdx1].Indices[I];
            SecondIndice := True; // It will also switch index from 0 to 1
            Break;
          end;
      if SecondIndice then // Make sure that this node exist
        Inc(fBestDefLines.Count);
    end
    else
      Inc(fBestDefLines.Count);
  end;
var
  K, QueueIdx: Integer;
  Evaluation: Single;
begin
  if (fPolygonCnt < 10) then
    Exit;
  for K := Low(fStartPolygons) to High(fStartPolygons) do
    if IsVisited(fStartPolygons[K]) then
      Exit;
  // Calculate evaluation of actual defensive position
  Evaluation := fQueueCnt * POLYGON_CNT_PENALIZATION;
  QueueIdx := aIdx;
  for K := 0 to fQueueCnt do // aIdx is already taken from Queue so it must be from 0 to fQueueCnt!
  begin
    Evaluation := + Evaluation
                  //+ fDefInfo[QueueIdx].Distance // Consideration of distance does more damage than benefit
                  - Byte(    ((fDefInfo[QueueIdx].AllyInfluence > MIN_OPTIMAL_INFLUENCE) AND (fDefInfo[QueueIdx].AllyInfluence < ALLY_INFLUENCE_LIMIT))
                          OR ((fDefInfo[QueueIdx].Influence     > MIN_OPTIMAL_INFLUENCE) AND (fDefInfo[QueueIdx].Influence     < ALLY_INFLUENCE_LIMIT))
                        ) * OPTIMAL_INFLUENCE_ADD
                  + Byte(fDefInfo[QueueIdx].EnemyInfluence > ENEMY_INFLUENCE_LIMIT) * ENEMY_INFLUENCE_PENALIZATION
                  + Byte(fQueueCnt < MIN_DEFENCE_CNT) * (MIN_DEFENCE_CNT - fQueueCnt) * 100;
    QueueIdx := fQueueArray[QueueIdx].Next;
  end;
  // If is evaluation better save polygons
  if (Evaluation < fBestEvaluation) then
  begin
    fBestEvaluation := Evaluation;
    fBestDefLines.Count := 0; // Set defences count to 0 (it will be incremented later)
    if (fQueueCnt >= Length(fBestDefLines.Lines)) then
      SetLength(fBestDefLines.Lines, fQueueCnt + 32);
    // Copy defensive polygons
    QueueIdx := aIdx;
    for K := 0 to fQueueCnt do // aIdx is already taken from Queue so it must be from 0 to fQueueCnt!
    begin
      AddDefence(QueueIdx);
      QueueIdx := fQueueArray[QueueIdx].Next;
    end;
    {$IFDEF DEBUG_NavMeshDefences}
      with fDebugDefLines do
        if (Count >= Length(DefLines)) then
          SetLength(DefLines, Count + 20);
      with fDebugDefLines.DefLines[ fDebugDefLines.Count ] do
      begin
        Price := Evaluation;
        DefArr.Count := fBestDefLines.Count;
        SetLength(DefArr.Lines, DefArr.Count);
        Move(fBestDefLines.Lines[0], DefArr.Lines[0], SizeOf(DefArr.Lines[0]) * DefArr.Count);
      end;
      Inc(fDebugDefLines.Count);
    {$ENDIF}
  end;
end;


function TBackwardFF.CanBeExpanded(const aIdx: Word): Boolean;
{$IFDEF DEBUG_NavMeshDefences}
var
  K, Idx: Integer;
{$ENDIF}
begin
  Dec(fPolygonCnt);

  Result := (fDefInfo[aIdx].Distance > 0);

  if Result AND (fDefInfo[aIdx].Distance < MAXIMAL_DEFENCE_DISTANCE) then
    EvaluateDefence(aIdx);

  {$IFDEF DEBUG_NavMeshDefences}
    Inc(fDebugCounter);
    if OVERLAY_DEFENCES_A AND (fDebugCounter = Round(DateUtils.MilliSecondsBetween(Now, 0) * 0.01) mod fDebugDefPolyCnt) then
    begin
      gAIFields.NavMesh.DrawPolygon(aIdx, Min(250,75), tcRed, 1, IntToStr(aIdx));
      Idx := fStartQueue;
      for K := 0 to fQueueCnt-1 do
      begin
        gAIFields.NavMesh.DrawPolygon(Idx, Min(250,K + 75), tcRed, 1, IntToStr(K));
        Idx := fQueueArray[Idx].Next;
      end;
    end;
  {$ENDIF}
end;


// Backward flood fill -> flood fill from enemy influence area to owner city
// BackwardFF will find the best possible defences
procedure TBackwardFF.BackwardFlood(aOwners: TKMHandIDArray);
  // Save init polygons so they are always inside of defence line
  procedure MarkInitPolygons();
  var
    K: Integer;
    SP: TKMWordArray;
  begin
    SetLength(fStartPolygons,0);
    for K := Low(aOwners) to High(aOwners) do
    begin
      gAIFields.Eye.OwnerUpdate(aOwners[K]);
      SP := gAIFields.Eye.GetCityCenterPolygons(True);
      if (Length(SP) > 0) then
      begin
        SetLength(fStartPolygons, Length(fStartPolygons) + Length(SP));
        Move(SP[0], fStartPolygons[Length(fStartPolygons)-Length(SP)], SizeOf(SP[0])*Length(SP));
      end;
    end;
    gAIFields.Eye.OwnerUpdate(fOwner); // Make sure that Eye is set to the right Owner (Old AI does not shift it)
  end;
  // Prepare init polygons for backward flood fill (polygons near enemy)
  procedure CreateBorders();
  var
    I, K, QueueIdx, NearbyIdx: Integer;
  begin
    QueueIdx := fStartQueue;
    for I := 1 to fQueueCnt do // Enemy polygons are prepared in Queue
    begin
      for K := 0 to gAIFields.NavMesh.Polygons[QueueIdx].NearbyCount-1 do
      begin
        NearbyIdx := gAIFields.NavMesh.Polygons[QueueIdx].Nearby[K];
        if (fQueueArray[NearbyIdx].Visited < fVisitedIdx-1) then // This polygon was not visited in forward cycle -> it will not be visited in backward
          fQueueArray[NearbyIdx].Visited := fVisitedIdx;
      end;
      QueueIdx := fQueueArray[QueueIdx].Next;
    end;
  end;
  // Find nearby unvisited polygons and expand polygon
  procedure ExpandPolygon(aIdx: Word);
  var
    I, NearbyIdx: Integer;
  begin
    for I := 0 to gAIFields.NavMesh.Polygons[aIdx].NearbyCount-1 do
    begin
      NearbyIdx := gAIFields.NavMesh.Polygons[aIdx].Nearby[I];
      if not IsVisited(NearbyIdx) then
      begin
        fQueueArray[NearbyIdx].Visited := fVisitedIdx; // Mark as visited
        fDefInfo[NearbyIdx].Distance := fQueueArray[NearbyIdx].Distance; // Save distance for future calculation
        if (gAIFields.NavMesh.Polygons[NearbyIdx].NearbyCount = 3) then // Defences are created only from polygons with 3 surrounding polygons
        begin
          fQueueArray[NearbyIdx].Distance := High(Word) - fQueueArray[NearbyIdx].Distance; // Invert distance (only polygons which will be inserted)
          InsertAndSort(NearbyIdx); // Insert ONLY polygons with 3 nearby polygons because it is possible to create defence line from them and also it save performance
        end
        else
          ExpandPolygon(NearbyIdx);
      end;
    end;
  end;
var
  Idx: Word;
begin
  {$IFDEF DEBUG_NavMeshDefences}
    fDebugCounter := 0;
    if (fDebugDefPolyCnt = 0) then
      fDebugDefPolyCnt := gAIFields.NavMesh.PolygonsCnt;
  {$ENDIF}
  MarkInitPolygons();
  fBestDefLines.Count := 0;
  CreateBorders();
  while RemoveFromQueue(Idx) do
    if CanBeExpanded(Idx) then
      ExpandPolygon(Idx);
end;


// Flood fill for detection of defensive positions
function TBackwardFF.FindDefencePos(aBaseCnt: Word): Boolean;
const
  INIT_WEIGHT = MAX_MAP_SIZE*MAX_MAP_SIZE div 6;
  SQR_MIN_DEF_POINT_DISTANCE = 3*3;
var
  Check: Boolean;
  Idx, NearbyIdx, Cnt, ScannedCnt, NextLine, ActLineIdx: Word;
  I, K: Integer;
  Direction: TKMDirection;
begin
  Result := False;

  // Check and determine counts
  if (fBestDefLines.Count = 0) then
    Exit;
  aBaseCnt := Max(aBaseCnt,fBestDefLines.Count);

  // Prepare defensive FF - add all polygon is BestDefLines to queue
  NewQueue(fVisitedIdx + 1);
  for I := 0 to fBestDefLines.Count - 1 do
  begin
    Idx := fBestDefLines.Lines[I].Polygon;
    MarkAsVisited(Idx, fDefInfo[ Idx ].Distance, gAIFields.NavMesh.Polygons[Idx].CenterPoint);
    InsertInQueue( Idx );
    // Direction of groups in defence position may be tricky so it is computed for all children at once as a average point of surrounding polygons
    fDefInfo[Idx].PointInDir := gAIFields.NavMesh.Polygons[Idx].CenterPoint;
    Cnt := 1;
    // Mark every polygon before def line as visited so FF will not make defences here
    for K := 0 to gAIFields.NavMesh.Polygons[Idx].NearbyCount-1 do
    begin
      NearbyIdx := gAIFields.NavMesh.Polygons[Idx].Nearby[K];
      //if (fDefInfo[ NearbyIdx ].Distance > fDefInfo[ Idx ].Distance) then // Sometimes distances does not match with polygons inside of def line
      if not fFilterFF.IsPolyInsideDef(NearbyIdx) then
      begin
        Cnt := Cnt + 1;
        fDefInfo[Idx].PointInDir := KMPointAdd(fDefInfo[Idx].PointInDir, gAIFields.NavMesh.Polygons[NearbyIdx].CenterPoint);
        MarkAsVisited(NearbyIdx, fDefInfo[ NearbyIdx ].Distance, gAIFields.NavMesh.Polygons[Idx].NearbyPoints[K]);
      end
    end;
    // Average sum of points for direction
    fDefInfo[Idx].PointInDir.X := Round( fDefInfo[Idx].PointInDir.X / Cnt );
    fDefInfo[Idx].PointInDir.Y := Round( fDefInfo[Idx].PointInDir.Y / Cnt );
  end;

  // Execute FF
  SetLength(fDefPosArr, aBaseCnt);
  Cnt := 0;
  ScannedCnt := 0;
  NextLine := fQueueCnt;
  ActLineIdx := 0;
  while RemoveFromQueue(Idx) AND (Cnt < aBaseCnt) do
  begin
    Inc(ScannedCnt);
    if (ScannedCnt > NextLine) then
    begin
      Inc(NextLine, fQueueCnt);
      Inc(ActLineIdx);
    end;
    // Add only defence points with specicific distance
    Check := True;
    for I := 0 to Cnt - 1 do
      if (KMDistanceSqr(fQueueArray[Idx].DistPoint, fDefPosArr[I].DirPoint.Loc) < SQR_MIN_DEF_POINT_DISTANCE) then
      begin
        Check := False;
        Break;
      end;
    if Check then
    begin
      with fDefPosArr[Cnt] do
      begin
        Line := ActLineIdx;
        Polygon := Idx;
        Direction := KMGetDirection( fQueueArray[Idx].DistPoint, fDefInfo[Idx].PointInDir );
        DirPoint := KMPointDir( fQueueArray[Idx].DistPoint, Direction );
        Weight := Max( 0, (High(Word) shr 1) // Init value
                           + (fDefInfo[Idx].Influence shl 1) // Increase weight of owner's city
                           - (ActLineIdx * 100) // Penalize back lines
                           - fDefInfo[Idx].AllyInfluence // Penalize allied influence
                           + fDefInfo[Idx].EnemyInfluence // Add more soldiers closer to enemy influence
                     );
      end;
      if (Direction <> dirNA) then
        Cnt := Cnt + 1;
    end;
    // Expand polygon
    for I := 0 to gAIFields.NavMesh.Polygons[Idx].NearbyCount-1 do
    begin
      NearbyIdx := gAIFields.NavMesh.Polygons[Idx].Nearby[I];
      if not IsVisited(NearbyIdx) then
      begin
        MarkAsVisited(NearbyIdx, fDefInfo[ NearbyIdx ].Distance, gAIFields.NavMesh.Polygons[Idx].NearbyPoints[I]);
        InsertInQueue(NearbyIdx);
        fDefInfo[NearbyIdx].PointInDir := fDefInfo[Idx].PointInDir;
      end;
    end;
  end;

  SetLength(fDefPosArr, Cnt);
  Result := True;
end;


function TBackwardFF.FindDefenceLines(aOwner: TKMHandID; aPolygonCnt: Integer): TKMDefenceLines;
begin
  fOwner := aOwner;
  fPolygonCnt := aPolygonCnt;
  fDefLinesRequired := True;
  BackwardFlood([aOwner]);
  fFilterFF.FilterDefenceLine(fBestDefLines, Result);
end;


// Defense detection for Krom's AI
function TBackwardFF.FindDefensivePolygons(aOwner: TKMHandID; aPolygonCnt: Integer; var aFirstLine: Word; var aBestDefLines: TKMDefenceLines; aDefLinesRequired: Boolean): TKMDefencePosArr;
const
  MIN_DEF_POINTS_CNT = 9;
  MULTIPLICATION = 3;
begin
  // Initialization
  fOwner := aOwner;
  fPolygonCnt := aPolygonCnt;
  fDefLinesRequired := aDefLinesRequired;
  // Find best defence line
  BackwardFlood([aOwner]);
  // Filter defence line in walkable area around players city
  fFilterFF.FilterDefenceLine(fBestDefLines, aBestDefLines);
  fBestDefLines := aBestDefLines;
  aFirstLine := fBestDefLines.Count;
  // Get more defensive points around defensive line
  if FindDefencePos( Max(MIN_DEF_POINTS_CNT, aFirstLine * MULTIPLICATION) ) then
    Result := fDefPosArr
  else
    SetLength(Result,0);
end;


// Defense detection for new AI (once per a team)
procedure TBackwardFF.FindTeamDefences(var aOwners: TKMHandIDArray; aPolygonCnt: Integer; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos; aDefLinesRequired: Boolean = False);
var
  SeparatedDefLines: TKMDefLinesArray;
  DefLinesReq: TKMWordArray;
  procedure AddDefRequirements(aIdx: Integer; var aPLsDefAreas: TKMByteArray);
  var
    K, Cnt, PolySum: Integer;
  begin
    // Check length
    Cnt := Length(DefLinesReq);
    if (Length(SeparatedDefLines) > Cnt) then
    begin
      SetLength(DefLinesReq, Length(SeparatedDefLines));
      FillChar(DefLinesReq[Cnt], SizeOf(DefLinesReq[Cnt]) * (Length(DefLinesReq) - Cnt), #0);
    end;
    // Compute sum of polygons
    PolySum := 1;
    for K := 0 to Length(aPLsDefAreas) - 1 do
      if (aPLsDefAreas[K] < length(SeparatedDefLines) ) then
        Inc(PolySum, SeparatedDefLines[ aPLsDefAreas[K] ].PolyCnt)
      else // AI cannot walk to the defense position
        exit;
    // Distribute requirements
    for K := 0 to Length(aPLsDefAreas) - 1 do
      Inc(  DefLinesReq[ aPLsDefAreas[K] ], Round( SeparatedDefLines[ aPLsDefAreas[K] ].PolyCnt / PolySum * aDefPosReq[aIdx] )  );
  end;
  function GetOwners(DefLineIdx: Integer; var aPLsDefAreas: TKMByte2Array): TKMHandIDArray;
  var
    IdxPL,K,Cnt: Integer;
  begin
    SetLength(Result, Length(aOwners));
    Cnt := 0;
    for IdxPL := 0 to Length(aPLsDefAreas) - 1 do
      for K := 0 to Length(aPLsDefAreas[IdxPL]) - 1 do
        if (aPLsDefAreas[IdxPL,K] = DefLineIdx) then
        begin
          Result[Cnt] := aOwners[IdxPL];
          Inc(Cnt);
          Break;
        end;
    SetLength(Result, Cnt);
  end;
var
  I: Integer;
  PLsDefAreas: TKMByte2Array;
begin
  fOwner := aOwners[0];
  fPolygonCnt := aPolygonCnt;
  fDefLinesRequired := aDefLinesRequired;
  BackwardFlood(aOwners); // Find best defence line
  if (fBestDefLines.Count = 0) then
    Exit;
  // Find defence positions of each player
  SetLength(PLsDefAreas,Length(aOwners));
  for I := 0 to Length(aOwners)-1 do
  begin
    // Get defence lines in player's influence area
    fFilterFF.FilterTeamDefLine((I = 0), aOwners[I], fBestDefLines, SeparatedDefLines, PLsDefAreas[I]);
    // Divide required defence positions into defence lines
    AddDefRequirements(I, PLsDefAreas[I]);
  end;
  // Find defences
  SetLength(aTeamDefPos, Length(SeparatedDefLines));
  for I := 0 to Length(SeparatedDefLines)-1 do
  begin
    fBestDefLines := SeparatedDefLines[I];
    FindDefencePos(DefLinesReq[I]);
    with aTeamDefPos[I] do
    begin
      Polygons := SeparatedDefLines[I].PolyCnt;
      Owners := GetOwners(I,PLsDefAreas);
      DefPosArr := fDefPosArr;
    end;
  end;
end;


procedure TBackwardFF.Paint(var aOwners: TKMHandIDArray; aPolygonCnt: Integer; var aDefPosReq: TKMWordArray; var aTeamDefPos: TKMTeamDefPos);
{$IFDEF DEBUG_NavMeshDefences}
var
  Opacity: Byte;
  K,L: Integer;
  MinPrc, MaxPrc: Single;
  P1,P2: TKMPoint;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshDefences}
    FindTeamDefences(aOwners, aPolygonCnt, aDefPosReq, aTeamDefPos);
    MinPrc := +1E10;
    MaxPrc := -1E10;
    for K := 0 to fDebugDefLines.Count - 1 do
      with fDebugDefLines.DefLines[K] do
      begin
        if (MinPrc > Price) then MinPrc := Price;
        if (MaxPrc < Price) then MaxPrc := Price;
      end;
    for K := 0 to fDebugDefLines.Count - 1 do
      with fDebugDefLines.DefLines[K] do
        for L := 0 to DefArr.Count - 1 do
        begin
          Opacity := Round(255 - (Price - MinPrc) / MaxPrc * 254);
          P1 := gAIFields.NavMesh.Nodes[ DefArr.Lines[L].Nodes[0] ];
          P2 := gAIFields.NavMesh.Nodes[ DefArr.Lines[L].Nodes[1] ];
          gRenderAux.LineOnTerrain(P1, P2, (Opacity shl 24) OR tcRed);
        end;
    fDebugDefPolyCnt := fDebugCounter;
  {$ENDIF}

  fFilterFF.Paint();
end;


{ TFilterFF }
function TFilterFF.IsPolyInsideDef(aIdx: Word): Boolean;
begin
  Result := (fQueueArray[aIdx].Visited > 0) AND (fQueueArray[aIdx].Visited < $FF);
end;


function TFilterFF.IsVisited(const aIdx: Word): Boolean;
var
  I: Integer;
begin
  if (fQueueArray[aIdx].Visited = $FF) then
  begin
    for I := 0 to fAllDefLines.Count - 1 do
      if (fAllDefLines.Lines[I].Polygon = aIdx) then
      begin
        fBestDefLines.Lines[ fBestDefLines.Count ] := fAllDefLines.Lines[I]; // Length was already checked
        fBestDefLines.Count := fBestDefLines.Count + 1;
        Break;
      end;
    fQueueArray[aIdx].Visited := fVisitedIdx; // Border can be visited multiple times so mark it as visited
  end;
  Result := (fQueueArray[aIdx].Visited > 0); // Visited Array is always filled with zeros
end;

procedure TFilterFF.MarkAsVisited(const aIdx: Word; const aDistance: Cardinal; const aPoint: TKMPoint);
begin
  Inc(fPolyCnt);
  inherited MarkAsVisited(aIdx, aDistance, aPoint);
end;


procedure TFilterFF.InitQueue(aMaxIdx: Integer; aInitIdxArray: TKMWordArray);
var
  I: Integer;
begin
  fPolyCnt := 0;
  fVisitedIdx := $FE; // Force parent procedure to clear array
  inherited InitQueue(aMaxIdx, aInitIdxArray); // Init queue
  // Mark exist defence lines as a visited (faster than check each node whether is part of defensive line)
  for I := 0 to fAllDefLines.Count - 1 do
    fQueueArray[ fAllDefLines.Lines[I].Polygon ].Visited := $FF;
  fVisitedIdx := 1;
end;


// Check if start polygon is on the defence line
function TFilterFF.CheckStartPolygons(var aStartPolygons: TKMWordArray): boolean;
var
  K,L,M, cnt, borderCnt: Integer;
begin
  cnt := Length(aStartPolygons);
  for K := cnt-1 downto 0 do
  begin
    borderCnt := 0;
    for L := 0 to fAllDefLines.Count-1 do
      // Remove border start polygons
      if (aStartPolygons[K] = fAllDefLines.Lines[L].Polygon) then
      begin
        Dec(cnt);
        aStartPolygons[K] := aStartPolygons[cnt];
        Break;
      end
      // Remove surrounded start polygons
      else
        for M := 0 to gAIFields.NavMesh.Polygons[ aStartPolygons[K] ].NearbyCount - 1 do
          Inc(borderCnt, Byte(fAllDefLines.Lines[L].Polygon = gAIFields.NavMesh.Polygons[ aStartPolygons[K] ].Nearby[M]));
    if (borderCnt = gAIFields.NavMesh.Polygons[ aStartPolygons[K] ].NearbyCount) then
    begin
      Dec(cnt);
      aStartPolygons[K] := aStartPolygons[cnt];
    end
  end;
  SetLength(aStartPolygons, cnt);
  Result := cnt > 0;
end;


procedure TFilterFF.FilterDefenceLine(var aAllDefLines, aBestDefLines: TKMDefenceLines);
var
  StartPolygons: TKMWordArray;
begin
  fAllDefLines := aAllDefLines;
  fBestDefLines.Count := 0;
  if (Length(fBestDefLines.Lines) < fAllDefLines.Count) then
    SetLength(fBestDefLines.Lines, fAllDefLines.Count);

  StartPolygons := gAIFields.Eye.GetCityCenterPolygons(True);
  if not CheckStartPolygons(StartPolygons) then
    Exit;

  InitQueue(Length(StartPolygons)-1, StartPolygons);
  Flood();
  aBestDefLines.Count := fBestDefLines.Count;
  SetLength(aBestDefLines.Lines, fBestDefLines.Count);
  if (fBestDefLines.Count > 0) then
    Move(fBestDefLines.Lines[0], aBestDefLines.Lines[0], Sizeof(fBestDefLines.Lines[0])*fBestDefLines.Count);
end;


procedure TFilterFF.FilterTeamDefLine(aClean: Boolean; aOwner: TKMHandID; var aAllDefLines: TKMDefenceLines;
                                      var aSeparatedDefLines: TKMDefLinesArray; var aPLDefAreas: TKMByteArray);
  procedure AddPLDefArea(aVisitMark: Integer);
  begin
    SetLength(aPLDefAreas, Length(aPLDefAreas) + 1);
    aPLDefAreas[ High(aPLDefAreas) ] := aVisitMark-1; // Visit mark is +1 in comparison with visit indexes
  end;
var
  I,K, VisitMark: Integer;
  StartPolygons,StartPolygon: TKMWordArray;
begin
  fAllDefLines := aAllDefLines;
  fBestDefLines.Count := 0;
  if (Length(fBestDefLines.Lines) < fAllDefLines.Count) then
    SetLength(fBestDefLines.Lines, fAllDefLines.Count);
  // Get city center polygons
  gAIFields.Eye.OwnerUpdate(aOwner);
  StartPolygons := gAIFields.Eye.GetCityCenterPolygons(True);
  if not CheckStartPolygons(StartPolygons) then
  begin
    if aClean then
    begin
      InitQueue(-1, []);
      fVisitedIdx := fVisitedIdx - 1;
    end;
    Exit;
  end;
  // Check if city is already in known defence area
  SetLength(StartPolygon,1);
  SetLength(aPLDefAreas,0);
  // Scan area around all StartPolygons of 1 player; visited polygons will have value fVisitedIdx
  for I := 0 to Length(StartPolygons) - 1 do
  begin
    StartPolygon[0] := StartPolygons[I];
    if (aClean OR (Length(fQueueArray) <= 0)) AND (I = 0) then // First start polygon of first player
      InitQueue(0, StartPolygon)
    else
    begin
      VisitMark := fQueueArray[ StartPolygon[0] ].Visited;
      if (VisitMark > 0) AND (VisitMark < $FF) then // Defence area is known
      begin
        for K := Low(aPLDefAreas) to High(aPLDefAreas) do
          if (aPLDefAreas[K] = VisitMark-1) then // fVisitedIdx starts with number 1, first player in array have 0 => decrease it
            Continue;
        AddPLDefArea(VisitMark);
        Continue;
      end;
      inherited InitQueue(0, StartPolygon); // Fill new defence area
    end;
    // Save new defence area
    fPolyCnt := 0;
    Flood();
    if (fBestDefLines.Count > 0) then
    begin
      AddPLDefArea(fVisitedIdx);
      SetLength(aSeparatedDefLines, Length(aSeparatedDefLines) + 1); // in 99% only one iteration (= 1 city)
      with aSeparatedDefLines[ High(aSeparatedDefLines) ] do
      begin
        Count := fBestDefLines.Count;
        Mark := fVisitedIdx;
        PolyCnt := fPolyCnt;
        SetLength(Lines, fBestDefLines.Count);
        Move(fBestDefLines.Lines[0], Lines[0], Sizeof(fBestDefLines.Lines[0])*fBestDefLines.Count);
      end;
    end;
  end;
end;


procedure TFilterFF.Paint();
{$IFDEF DEBUG_NavMeshDefences}
const
  RAD = 0.25;
var
  K: Integer;
{$ENDIF}
begin
  {$IFDEF DEBUG_NavMeshDefences}
    for K := Low(fQueueArray) to High(fQueueArray) do
      with gAIFields.NavMesh.Polygons[K].CenterPoint do
        case fQueueArray[K].Visited of
         1: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcRed,  ($09000000) OR tcRed);
         2: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcBlack,($09000000) OR tcBlack);
         3: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcWhite,($09000000) OR tcWhite);
         4: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcGreen,($09000000) OR tcGreen);
         5: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcBlue, ($09000000) OR tcBlue);
         6: gRenderAux.CircleOnTerrain(X, Y-1, RAD, ($FF000000) OR tcBlue, ($09000000) OR tcBlue);
        end;
  {$ENDIF}
end;


end.
