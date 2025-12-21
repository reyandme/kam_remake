unit KM_RenderDebug;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults, KM_Points, KM_CommonTypes, KM_CommonClasses, Generics.Collections,
  KM_MarchingSquares, KM_AIDefensePos;

type
  TKMRenderDebug = class
  private
    fClipRect: TKMRect;
    fAreaTilesLand: TBoolean2Array;
    fAreaData: IKMData2D<Boolean>;
    fMarchingSquares: TKMMarchingSquares;
    fBorderPoints: TList<TKMPointList>;
    procedure ResetAreaData;
    function IsAreaInClip(aLoc: TKMPoint; aRadius: Integer): Boolean;
    procedure CollectAreaTiles(var aPoints: TBoolean2Array; const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single;
                               aDistanceFunc: TCoordDistanceFn);
  public
    constructor Create;
    destructor Destroy; override;

    procedure ReInit;

    property ClipRect: TKMRect read fClipRect write fClipRect;

    procedure PaintMiningRadius;
    procedure PaintDefences;

    procedure RenderTiledArea(const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single; aDistanceFunc: TCoordDistanceFn;
                                    aFillColor, aLineColor: Cardinal);
  end;


  TKMAreaData = class(TInterfacedObject, IKMData2D<Boolean>)
  private
    fAreaPoints: TBoolean2Array;
    function GetData(X, Y: Integer): Boolean;
  public
    procedure SetDataArray(var aAreaPoints: TBoolean2Array);
  end;


implementation
uses
  Math, SysUtils,
  KM_Game, KM_RenderAux,
  KM_Resource, KM_Terrain, KM_Houses, KM_HouseWoodcutters, KM_ResUnits,
  KM_HandsCollection, KM_Hand, KM_CommonUtils,
  KM_ResTypes, KM_DevPerfLog, KM_DevPerfLogTypes;


{ TKMRenderDebug }
constructor TKMRenderDebug.Create;
begin
  inherited;

  fAreaData := TKMAreaData.Create;
  fBorderPoints := TObjectList<TKMPointList>.Create; // Object list will take care of Freeing added objects
  fMarchingSquares := TKMMarchingSquares.Create;
end;


destructor TKMRenderDebug.Destroy;
begin
  fMarchingSquares.Free;
  fBorderPoints.Clear;
  fBorderPoints.Free;
  fAreaData := nil; //Interfaced object will be freed automatically

  inherited;
end;


procedure TKMRenderDebug.ReInit;
begin
  if Self = nil then Exit;

  SetLength(fAreaTilesLand, gTerrain.MapY, gTerrain.MapX);
end;


// Render quads over tiles
procedure TKMRenderDebug.RenderTiledArea(const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single; aDistanceFunc: TCoordDistanceFn;
                                               aFillColor, aLineColor: Cardinal);
var
  I, K: Integer;
begin
  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionEnter(psRenderDebug);
  {$ENDIF}
  try
    if not IsAreaInClip(aLoc, Ceil(aMaxRadius)) then
      Exit;

    ResetAreaData;

    for I := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
      for K := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
        if InRange(aDistanceFunc(K, I), aMinRadius, aMaxRadius) and gTerrain.TileInMapCoords(aLoc.X+K, aLoc.Y+I) then
        begin
          fAreaTilesLand[aLoc.Y+I - 1, aLoc.X+K - 1] := True; // fDefLand is 0-based
          gRenderAux.QuadI(aLoc.X+K, aLoc.Y+I, aFillColor);
        end;

    if not fMarchingSquares.IdentifyPerimeters(fBorderPoints) then
      Exit;

    for K := 0 to fBorderPoints.Count - 1 do
      gRenderAux.LineOnTerrain(fBorderPoints[K], aLineColor);
  finally
    {$IFDEF DBG_PERFLOG}
    gPerfLogs.SectionLeave(psRenderDebug);
    {$ENDIF}
  end;
end;


procedure TKMRenderDebug.CollectAreaTiles(var aPoints: TBoolean2Array; const aLoc: TKMPoint; aMinRadius, aMaxRadius: Single;
                                          aDistanceFunc: TCoordDistanceFn);
var
  I, K: Integer;
begin
  for I := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
    for K := -Round(aMaxRadius) - 1 to Round(aMaxRadius) do
      if InRange(aDistanceFunc(K, I), aMinRadius, aMaxRadius) and gTerrain.TileInMapCoords(aLoc.X+K, aLoc.Y+I) then
        aPoints[aLoc.Y+I - 1, aLoc.X+K - 1] := True;
end;


procedure TKMRenderDebug.ResetAreaData;
var
  I: Integer;
begin
  //Dynamic 2d array should be cleared row by row
  for I := 0 to gTerrain.MapY - 1 do
    FillChar(fAreaTilesLand[I,0], SizeOf(fAreaTilesLand[I,0]) * Length(fAreaTilesLand[I]), #0);

  TKMAreaData(fAreaData).SetDataArray(fAreaTilesLand);
  fMarchingSquares.SetData(fAreaData as IKMData2D<Boolean>, gTerrain.MapX + 1, gTerrain.MapY + 1);
  fBorderPoints.Clear;
end;


function TKMRenderDebug.IsAreaInClip(aLoc: TKMPoint; aRadius: Integer): Boolean;
begin
  // Rough filter for distant locs
  Result := KMRectArea(KMRectIntersect(fClipRect, KMRect(aLoc.X - aRadius,
                                                         aLoc.Y - aRadius,
                                                         aLoc.X + aRadius,
                                                         aLoc.Y + aRadius))) > 0;
end;


procedure TKMRenderDebug.PaintDefences;
var
  I, J, K: Integer;
  DP: TAIDefencePosition;
  fillColor, lineColor: Cardinal;
begin
  if SKIP_RENDER or (gGame = nil) then Exit;

  Assert(Length(fAreaTilesLand) > 0, 'TKMRenderDebug was not initialized');

  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionEnter(psRenderDebug);
  {$ENDIF}

  //Draw tiles and shared borders first for all players
  for I := 0 to gHands.Count - 1 do
  begin
    ResetAreaData; //Reset data for every hand

    if I = gMySpectator.SelectedHandID then
    begin
      fillColor := gHands[I].FlagColor and $60FFFFFF;
      lineColor := icCyan;
    end
    else
    begin
      fillColor := gHands[I].FlagColor and $20FFFFFF;
      lineColor := gHands[I].FlagColor;
    end;

    for K := 0 to gHands[I].AI.General.DefencePositions.Count - 1 do
    begin
      DP := gHands[I].AI.General.DefencePositions[K];

      if not IsAreaInClip(DP.Position.Loc, DP.Radius) then
        Continue;

      CollectAreaTiles(fAreaTilesLand, DP.Position.Loc, 0, DP.Radius, KMLengthDiag);
    end;

    //Draw quads
    gRenderAux.SetColor(fillColor); //Setting color initially will be much faster, than calling it on every cell
    for J := 0 to gTerrain.MapY - 1 do
      for K := 0 to gTerrain.MapX - 1 do
        if fAreaTilesLand[J, K] then
          gRenderAux.QuadI(K + 1, J + 1); //gTerrain is 1-based...

    if not fMarchingSquares.IdentifyPerimeters(fBorderPoints) then
      Continue;

    for K := 0 to fBorderPoints.Count - 1 do
      gRenderAux.LineOnTerrain(fBorderPoints[K], lineColor);
  end;

  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionLeave(psRenderDebug);
  {$ENDIF}
end;


procedure TKMRenderDebug.PaintMiningRadius;
const
  GOLD_ORE_COLOR = icYellow;
  IRON_ORE_COLOR = icSteelBlue;
  COAL_ORE_COLOR = icGray;
  WOODCUTTER_COLOR = icDeepGreen;
  QUARRY_COLOR = icBlack;
  FISHERHUT_COLOR = icBlue;
  FARM_COLOR = icYellow;
  WINEYARD_COLOR = icLightCyan;
  SELECTED_ORE_COLOR = icLight2Red;

  procedure AddOrePoints(aOreP, aAllOreP: TKMPointListArray);
  var
    I,J,K: Integer;
    Skip: Boolean;
  begin
    for I := 0 to Length(aOreP) - 1 do
    begin
      for J := 0 to aOreP[I].Count - 1 do
      begin
        Skip := False;
        //Skip if we already have this point in upper layer
        for K := 0 to I do
          if aAllOreP[K].Contains(aOreP[I][J]) then
          begin
            Skip := True;
            Break;
          end;
        if not Skip then
        begin
          aAllOreP[I].Add(aOreP[I][J]); //Couild be Add actually, as we checked Contains already
          //Remove added points from lowered layers
          for K := I + 1 to 2 do
            aAllOreP[K].Remove(aOreP[I][J]);
        end;
      end;
    end;
  end;

  procedure PaintOrePoints(aOreP: TKMPointListArray; Color: Cardinal; aHighlight: Boolean = False);
  var
    I, K, L: Integer;
    lineColor, fillColor: Cardinal;
    coef: Single;
  begin
    coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      coef := 0.3;
    end;

    ResetAreaData;
    lineColor := Color;
    for I := 1 to Length(aOreP) - 1 do
    begin
      Color := Color and $40FFFFFF; //Add some transparency
      Color := MultiplyBrightnessByFactor(Color, coef);
      for K := Length(aOreP) - 1 downto 0 do
        for L := 0 to aOreP[K].Count - 1 do
        begin
          fillColor := Color;
          if K = 1 then
            fillColor := MultiplyBrightnessByFactor(Color, 4);
          if K = 2 then
            fillColor := MultiplyBrightnessByFactor(Color, 7);
          gRenderAux.Quad(aOreP[K][L].X, aOreP[K][L].Y, fillColor);

          fAreaTilesLand[aOreP[K][L].Y - 1, aOreP[K][L].X - 1] := True;
        end;
    end;

    if not fMarchingSquares.IdentifyPerimeters(fBorderPoints) then
      Exit;

    for I := 0 to fBorderPoints.Count - 1 do
      gRenderAux.LineOnTerrain(fBorderPoints[I], lineColor);
  end;

  procedure PaintMiningPoints(aPoints: TKMPointList; Color: Cardinal; aHighlight: Boolean = False; aDeepCl: Boolean = False;
                              aVertexes: Boolean = False);
  var
    I: Integer;
    coef: Single;
    lineColor: Cardinal;
    inset: Single;
  begin
    coef := 0.15;
    if aHighlight then
    begin
      Color := SELECTED_ORE_COLOR;
      coef := 0.3;
    end;

    inset := 0;
    if aVertexes then
      inset := -0.5;

    lineColor := Color;

    if aDeepCl then
      Color := Color and $80FFFFFF //Add some transparency
    else
      Color := Color and $40FFFFFF; //Add more transparency
    Color := MultiplyBrightnessByFactor(Color, coef);

    ResetAreaData;

    gRenderAux.SetColor(Color);
    for I := 0 to aPoints.Count - 1 do
    begin
      gRenderAux.Quad(aPoints[I].X + inset, aPoints[I].Y + inset);
      if aVertexes then
        gRenderAux.CircleOnTerrain(aPoints[I].X - 1, aPoints[I].Y - 1, 0.15, Color);

      fAreaTilesLand[aPoints[I].Y - 1, aPoints[I].X - 1] := True;
    end;

    if not fMarchingSquares.IdentifyPerimeters(fBorderPoints) then
      Exit;

    for I := 0 to fBorderPoints.Count - 1 do
      gRenderAux.LineOnTerrain(fBorderPoints[I], lineColor, inset);
  end;

var
  I, J, K: Integer;
  H: TKMHouse;
  ironOreP, goldOreP, coalOreP, oreP, selectedOreP: TKMPointListArray;
  woodcutterPts, quarryPts, fisherHutPts, farmPts, wineyardPts: TKMPointList;
  houseDirPts: TKMPointDirList;
  housePts, selectedPts: TKMPointList;
begin
  if gGame = nil then Exit;

  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionEnter(psRenderDebug);
  {$ENDIF}

  SetLength(oreP, 3);
  SetLength(ironOreP, 3);
  SetLength(goldOreP, 3);
  SetLength(coalOreP, 3);
  SetLength(selectedOreP, 3);

  for I := 0 to Length(oreP) - 1 do
  begin
    oreP[I] := TKMPointList.Create;
    ironOreP[I] := TKMPointList.Create;
    goldOreP[I] := TKMPointList.Create;
    coalOreP[I] := TKMPointList.Create;
    selectedOreP[I] := TKMPointList.Create;
  end;

  woodcutterPts := TKMPointList.Create;
  quarryPts := TKMPointList.Create;
  fisherHutPts := TKMPointList.Create;
  farmPts := TKMPointList.Create;
  wineyardPts := TKMPointList.Create;
  housePts := TKMPointList.Create;
  houseDirPts := TKMPointDirList.Create;
  selectedPts := TKMPointList.Create;

  for I := 0 to gHands.Count - 1 do
  begin
    for J := 0 to gHands[I].Houses.Count - 1 do
    begin
      housePts.Clear;
      houseDirPts.Clear;
      H := gHands[I].Houses[J];
      case H.HouseType of
        htIronMine:   begin
                        if not IsAreaInClip(H.PointBelowEntrance, 11) then
                          Continue;

                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtIronOre, oreP);
                        AddOrePoints(oreP, ironOreP);
                      end;
        htGoldMine:   begin
                        if not IsAreaInClip(H.PointBelowEntrance, 11) then
                          Continue;

                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtGoldOre, oreP);
                        AddOrePoints(oreP, goldOreP);
                      end;
        htCoalMine:   begin
                        if not IsAreaInClip(H.PointBelowEntrance, 5) then
                          Continue;

                        gTerrain.FindOrePointsByDistance(H.PointBelowEntrance, wtCoal, oreP);
                        AddOrePoints(oreP, coalOreP);
                      end;
        htWoodcutters:begin
                        if not IsAreaInClip(TKMHouseWoodcutters(H).FlagPoint, gRes.Units[utWoodcutter].MiningRange) then
                          Continue;

                        gTerrain.FindPossibleTreePoints(TKMHouseWoodcutters(H).FlagPoint,
                                                        gRes.Units[utWoodcutter].MiningRange,
                                                        housePts);
                        woodcutterPts.AddList(housePts);
                      end;
        htQuarry:      begin
                        if not IsAreaInClip(H.PointBelowEntrance, gRes.Units[utStonemason].MiningRange) then
                          Continue;

                        gTerrain.FindStoneLocs(H.PointBelowEntrance,
                                               gRes.Units[utStonemason].MiningRange,
                                               KMPOINT_ZERO, True, housePts);
                        quarryPts.AddList(housePts);
                      end;
        htFishermans:  begin
                        if not IsAreaInClip(H.PointBelowEntrance, gRes.Units[utFisher].MiningRange) then
                          Continue;

                        gTerrain.FindFishWaterLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFisher].MiningRange,
                                                   KMPOINT_ZERO, True, houseDirPts);
                        houseDirPts.ToPointList(housePts, True);
                        fisherHutPts.AddList(housePts);
                      end;
        htFarm:       begin
                        if not IsAreaInClip(H.PointBelowEntrance, gRes.Units[utFarmer].MiningRange) then
                          Continue;

                        gTerrain.FindCornFieldLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFarmer].MiningRange,
                                                   housePts);
                        farmPts.AddList(housePts);
                      end;
        htVineyard:   begin
                        if not IsAreaInClip(H.PointBelowEntrance, gRes.Units[utFarmer].MiningRange) then
                          Continue;

                        gTerrain.FindWineFieldLocs(H.PointBelowEntrance,
                                                   gRes.Units[utFarmer].MiningRange,
                                                   housePts);
                        wineyardPts.AddList(housePts);
                      end;
        else Continue;
      end;

      if gMySpectator.Selected = H then
      begin
        if H.HouseType in [htIronMine, htGoldMine, htCoalMine] then
        begin
          for K := 0 to Length(oreP) - 1 do
            selectedOreP[K].AddList(oreP[K]);
        end
        else
          selectedPts.AddList(housePts);
      end;

      for K := 0 to Length(oreP) - 1 do
        oreP[K].Clear;
    end;
  end;

  PaintOrePoints(ironOreP, IRON_ORE_COLOR);
  PaintOrePoints(goldOreP, GOLD_ORE_COLOR);
  PaintOrePoints(coalOreP, COAL_ORE_COLOR);
  PaintOrePoints(selectedOreP, 0, True);

  PaintMiningPoints(woodcutterPts, WOODCUTTER_COLOR, False, False, True);
  PaintMiningPoints(quarryPts, QUARRY_COLOR);
  PaintMiningPoints(fisherHutPts, FISHERHUT_COLOR);
  PaintMiningPoints(farmPts, FARM_COLOR, False, True);
  PaintMiningPoints(wineyardPts, WINEYARD_COLOR);
  // Show selected points as vertexes if woodcutter house is selected
  PaintMiningPoints(selectedPts, 0, True, False, (gMySpectator.Selected is TKMHouse) and (TKMHouse(gMySpectator.Selected).HouseType = htWoodcutters));


  {$IFDEF DBG_PERFLOG}
  gPerfLogs.SectionLeave(psRenderDebug);
  {$ENDIF}

  for I := 0 to Length(oreP) - 1 do
  begin
    oreP[I].Free;
    ironOreP[I].Free;
    goldOreP[I].Free;
    coalOreP[I].Free;
    selectedOreP[I].Free;
  end;
  woodcutterPts.Free;
  quarryPts.Free;
  fisherHutPts.Free;
  farmPts.Free;
  wineyardPts.Free;
  housePts.Free;
  houseDirPts.Free;
  selectedPts.Free;
end;


{ TKMAreaData }
function TKMAreaData.GetData(X, Y: Integer): Boolean;
begin
  Result :=     InRange(Y, Low(fAreaPoints), High(fAreaPoints))
            and InRange(X, Low(fAreaPoints[Y]), High(fAreaPoints[Y]))
            and fAreaPoints[Y, X];
end;


procedure TKMAreaData.SetDataArray(var aAreaPoints: TBoolean2Array);
begin
  fAreaPoints := aAreaPoints;
end;


end.
