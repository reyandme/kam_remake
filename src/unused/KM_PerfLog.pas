unit KM_PerfLog;
{$I KaM_Remake.inc}
interface
uses
  Generics.Collections;


type
  TKMPerfSection = (pskTick,
                      pskHungarian, pskAIFields, pskFOW,
                      pskHands, pskPathfinding, pskTerrain, psGIP, pskScripting,
                    pskRender,
                      psFOWCheck, psFOWCheck3, psFOWCheck5,
                      psRenderTer,
                      psRenderTerBase, pskUpdateVBO, psDoTiles, psDoWater, psDoTilesLayers, psDoOverlays, psDoLighting, psDoShadows,
                      psRenderFences, psRenderPlans,
                      psRenderOther, psRenderList, psRenderHands, psRenderFOW
                    );

const
  //Unicode for TStringList population
  SectionName: array [TKMPerfSection] of UnicodeString = ('Tick', 'Hungur', 'AIFields', 'FOW',
    'Hands', 'PFinding', 'Terrain', 'GIP', 'Script',
    'Render',
    'FOWChecks', 'FOWCheck3', 'FOWCheck5',
    'RenderTer', 'RenTerBase',
    'UpdateVBO', 'DoTiles', 'DoWater', 'DoLayers', 'DoOverlays', 'DoLight', 'DoShadows',
    'RenFences', 'RenPlans',
    'RenderOth', 'RendList', 'RendHands', 'RenderFOW'
    );

const
  SKIP_SECTION: set of TKMPerfSection = [pskHungarian, pskAIFields, pskFOW, psFOWCheck, psFOWCheck3, psFOWCheck5,
                                       psRenderOther, psRenderList, psRenderHands, psRenderFOW,
                                       pskHands, pskPathfinding, pskTerrain, psGIP, pskScripting];

type
  //Log how much time each section takes and write results to a log file

  TKMPerfSectionData = record
    Section: TKMPerfSection;
    Time: Int64;
  end;

  TKMPerfLog = class
  private
    fTick: Cardinal;
    fRenderCounter: Cardinal;
    fCount: array [TKMPerfSection] of Integer;
    fTimeEnter: array [TKMPerfSection] of Int64;
//    fTimes: array [TPerfSection] of array of Int64;
    fTickTimes: TDictionary<Cardinal, TDictionary<TKMPerfSection, Int64>>;
//    fRenderTimes: TDictionary<Cardinal, TDictionary<TKMPerfSection, Int64>>;
  public
    constructor Create;
    destructor Destroy; override;
    procedure Clear;
    procedure StartTick(aTick: Cardinal);
    procedure EndTick;
    procedure StartRender;//(aCounter: Cardinal);
    procedure EndRender;
    procedure EnterSection(aSection: TKMPerfSection);
    procedure LeaveSection(aSection: TKMPerfSection);
    procedure SaveToFile(const aFilename: UnicodeString);
  end;


implementation
uses
  Classes, SysUtils, KM_CommonUtils;


const
  SECT_W = 12;


//  LIMITS: array[TPerfSection] of Integer = (30000, 5000, 5000, 5000, 5000, 5000, 5000, 5000);


{ TKMPerfLog }
constructor TKMPerfLog.Create;
var
  K: TKMPerfSection;
begin
  inherited;

  for K := Low(TKMPerfSection) to High(TKMPerfSection) do
    fTimeEnter[K] := 0;

  fTickTimes := TDictionary<Cardinal, TDictionary<TKMPerfSection, Int64>>.Create;

  fRenderCounter := 0;
end;


destructor TKMPerfLog.Destroy;
var
  SectDict: TDictionary<TKMPerfSection, Int64>;
begin
  for SectDict in fTickTimes.Values do
    SectDict.Free;

  fTickTimes.Clear;
  fTickTimes.Free;

  inherited;
end;


procedure TKMPerfLog.Clear;
var
  I: TKMPerfSection;
begin
  for I := Low(TKMPerfSection) to High(TKMPerfSection) do
    fCount[I] := 0;
end;


procedure TKMPerfLog.StartTick(aTick: Cardinal);
var
  K: TKMPerfSection;
  SectDict: TDictionary<TKMPerfSection, Int64>;
begin
  Assert(not fTickTimes.ContainsKey(aTick), 'Tick is already started');

  fTick := aTick;

  SectDict := TDictionary<TKMPerfSection, Int64>.Create;
  fTickTimes.Add(fTick, SectDict);

  EnterSection(pskTick);

  //Init all sections
  for K := Low(TKMPerfSection) to High(TKMPerfSection) do
  begin
    if K = pskTick then
      Continue;

    EnterSection(K);
    LeaveSection(K);
  end;
end;


procedure TKMPerfLog.EndTick;
begin
  LeaveSection(pskTick);
end;


procedure TKMPerfLog.StartRender;//(aCounter: Cardinal);
var
  K: TKMPerfSection;
  SectDict: TDictionary<TKMPerfSection, Int64>;
begin
  Inc(fRenderCounter);
//  Assert(not fRenderTimes.ContainsKey(fRenderCounter), 'Tick is already started');

  SectDict := TDictionary<TKMPerfSection, Int64>.Create;
  fTickTimes.Add(fRenderCounter, SectDict);

  EnterSection(pskRender);

  //Init all sections
  for K := Low(TKMPerfSection) to High(TKMPerfSection) do
  begin
    if K in [pskTick, pskRender] then
      Continue;

    EnterSection(K);
    LeaveSection(K);
  end;
end;


procedure TKMPerfLog.EndRender;
begin
  LeaveSection(pskRender);
end;


procedure TKMPerfLog.EnterSection(aSection: TKMPerfSection);
begin
  Assert(fTimeEnter[aSection] = 0, 'Entering not left section');
  fTimeEnter[aSection] := TimeGetUsec;
end;


procedure TKMPerfLog.LeaveSection(aSection: TKMPerfSection);
var
  T, OldT: Int64;
  SectDict: TDictionary<TKMPerfSection, Int64>;
//  SectData: TKMPerfSectionData;
begin
  T := TimeGetUsec - fTimeEnter[aSection]; //Measure it ASAP
//  if fCount[aSection] >= Length(fTimes[aSection]) then
//    SetLength(fTimes[aSection], fCount[aSection] + 1024);
//
//  fTimes[aSection, fCount[aSection]] := T;
//  Assert(fTickTimes.ContainsKey(fTick), 'Leave unopened section at tick' + IntToStr(fTick));

  if fTickTimes.TryGetValue(fTick, SectDict) then
//    raise Exception.CreateFmt('Leave unopened section at tick %d', [fTick])
//  else
  begin
//    SectData.Section := aSection;
//    SectData.Time := T;
    if SectDict.TryGetValue(aSection, OldT) then
      SectDict.Items[aSection] := OldT + T
    else
      SectDict.Add(aSection, T);
  end;

//  Inc(fCount[aSection]);

  fTimeEnter[aSection] := 0;
end;


procedure TKMPerfLog.SaveToFile(const aFilename: UnicodeString);
var
  I: Integer;
  K: TKMPerfSection;
  S: TStringList;
  TickKey: Cardinal;
  SectKey: TKMPerfSection;
  Str: String;
  SectDict: TDictionary<TKMPerfSection, Int64>;

  FastTick: Boolean;

  SectsArray: TArray<TKMPerfSection>;
  TicksArray: TArray<Cardinal>;

  Total: array[TKMPerfSection] of Int64;
begin
  ForceDirectories(ExtractFilePath(aFilename));

  S := TStringList.Create;

  TicksArray := fTickTimes.Keys.ToArray;
  TArray.Sort<Cardinal>(TicksArray);

//  Str := 'Tick   '; //7
  Str := '       ';
  for K := Low(TKMPerfSection) to High(TKMPerfSection) do
  begin
    if K in SKIP_SECTION then
      Continue;

    Total[K] := 0;
    Str := Str + Format('%' + IntToStr(SECT_W) + 's', [SectionName[K]]);
  end;
  S.Append(Str);


  I := 0;
  for TickKey in TicksArray do
  begin
    Inc(I);
    SectDict := fTickTimes.Items[TickKey];

    SectsArray := SectDict.Keys.ToArray;
    TArray.Sort<TKMPerfSection>(SectsArray);

    FastTick := False;
    Str := Format('%6d:', [TickKey]);
    for SectKey in SectsArray do
    begin
      if SectKey in SKIP_SECTION then
        Continue;
//      if (SectKey = psTick) and (SectDict.Items[SectKey] < 5000) then //Skip ticks with low execution time
//      begin
//        FastTick := True;
//        Break;
//      end;

      Str := Str + Format('%' + IntToStr(SECT_W) + 'd', [SectDict.Items[SectKey]]);

      if I < Length(TicksArray) then
        Total[SectKey] := Total[SectKey] + SectDict.Items[SectKey];
    end;

    if not FastTick then
      S.Append(Str);
  end;

  S.Append('AVERAGE');
  Str := '';
  for K := Low(TKMPerfSection) to High(TKMPerfSection) do
  begin
    if K in SKIP_SECTION then
      Continue;

    Str := Str + Format('%' + IntToStr(SECT_W) + 'd', [Round(Total[K] / Length(TicksArray))]);
  end;
  S.Append(Str);

//  for K := Low(TPerfSection) to High(TPerfSection) do
//  begin
//    //Section name
//    S.Append(SectionName[K]);
//    S.Append(StringOfChar('-', 60));
//
//    //Times
//    for I := 0 to fCount[K] - 1 do
//    if fTimes[K,I] > LIMITS[K] then //Dont bother saving 95% of data
//      S.Append(Format('%d'#9'%d', [I, fTimes[K,I]]));
//
//    //Footer
//    S.Append('');
//    S.Append('');
//  end;

  S.SaveToFile(aFilename);
  S.Free;
end;


end.
