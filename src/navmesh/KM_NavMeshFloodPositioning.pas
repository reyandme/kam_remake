{
NavMesh - positioning in walkable tiles
@author: Martin Toupal
@e-mail: poznamenany@gmail.com
}
unit KM_NavMeshFloodPositioning;
{$I KaM_Remake.inc}
interface
uses
   Math, KM_CommonTypes,
   KM_Points, KM_NavMeshFloodFill;


type
  // This class finds walkable positions for small groups of soldiers (3x3) around initial points
  // It uses only NavMesh -> it does not check passability so selected position may be inaccessible (by house / other unit)
  TNavMeshFloodPositioning = class(TNavMeshFloodFill)
  private
    fCount: Word;
    fSqrMinSpacing: Single;
  protected
    fPointArray: TKMPointArray;

    function CanBeExpanded(const aIdx: Word): Boolean; override;
    procedure MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint); override;
  public
    function FindPositions(aCount,aMinSpacing: Word; var aInitIdxArray: TKMWordArray; out aPointArray: TKMPointArray): Boolean;
  end;


implementation
uses
  KM_AIFields;


{ TNavMeshFloodPositioning }
function TNavMeshFloodPositioning.CanBeExpanded(const aIdx: Word): Boolean;
begin
  Result := fCount < Length(fPointArray);
end;


procedure TNavMeshFloodPositioning.MarkAsVisited(const aIdx, aDistance: Word; const aPoint: TKMPoint);
var
  Check: Boolean;
  K, L: Integer;
begin
  inherited MarkAsVisited(aIdx, aDistance, aPoint);

  // Add new positions (1 polygon (triangle) in NavMesh can give 3 new positions which are given by center points of it's 3 border lines)
  if CanBeExpanded(aIdx) then
    with gAIFields.NavMesh.Polygons[aIdx] do
      for K := 0 to NearbyCount - 1 do
      begin
        Check := True;
        for L := 0 to fCount - 1 do // Does we already have this position?
          if (KMDistanceSqr(NearbyPoints[K], fPointArray[L]) < fSqrMinSpacing) then
          begin
            Check := False;
            break;
          end;
        if Check then // Add position
        begin
          fPointArray[fCount] := NearbyPoints[K];
          fCount := fCount + 1;
          if not CanBeExpanded(aIdx) then
            Exit;
        end;
      end;
end;


function TNavMeshFloodPositioning.FindPositions(aCount,aMinSpacing: Word; var aInitIdxArray: TKMWordArray; out aPointArray: TKMPointArray): Boolean;
begin
  fSqrMinSpacing := sqr(aMinSpacing);
  SetLength(fPointArray, aCount);
  fCount := 0;

  FillPolygons(High(aInitIdxArray), aInitIdxArray);

  aPointArray := fPointArray;
  Result := (fCount = aCount);
end;


end.
