unit KM_RenderQuery;
{$I KaM_Remake.inc}
interface
uses
//  {$IFDEF ANDROID}
//    Androidapi.Gles2,
//  {$ENDIF}
//  {$IFDEF DESKTOP}
    dglOpenGL;//,
//  {$ENDIF}
  //KM_RenderTypes;


type
  TKMQueryBuffer = (qbFront, qbBack);

  TKMRenderQuery = class
  private
    // To avoid stalling, one frame we query A and read from B, next frame query B and read from A
    fQueryBufferA: TKMQueryBuffer;
    fQueryBufferB: TKMQueryBuffer;
    fQueryID: array of array [TKMQueryBuffer] of record
      TimeStart, TimeEnd: Cardinal;
    end;
  public
    constructor Create;

    function QueriesGen: Integer;
    procedure QueriesDelete(var aQueryId: Integer);
    procedure QueriesSwapBuffers;
    procedure QueriesBegin(aQueryId: Integer);
    procedure QueriesEnd(aQueryId: Integer);
    function QueriesTime(aQueryId: Integer): UInt64;
  end;


implementation


{ TKMRenderQuery }
constructor TKMRenderQuery.Create;
begin
  inherited;

  fQueryBufferA := qbBack;
  fQueryBufferB := qbFront;
end;


// call this function when initializating the OpenGL settings
function TKMRenderQuery.QueriesGen: Integer;
var
  I: Integer;
begin
  SetLength(fQueryID, Length(fQueryID) + 1);

  I := High(fQueryID);

  glGenQueries(1, @fQueryID[I, qbFront].TimeStart);
  glGenQueries(1, @fQueryID[I, qbFront].TimeEnd);
  glGenQueries(1, @fQueryID[I, qbBack].TimeStart);
  glGenQueries(1, @fQueryID[I, qbBack].TimeEnd);

  // dummy query to prevent OpenGL errors from popping out
  glQueryCounter(fQueryID[I, qbFront].TimeStart, GL_TIMESTAMP);
  glQueryCounter(fQueryID[I, qbFront].TimeEnd, GL_TIMESTAMP);
  glQueryCounter(fQueryID[I, qbBack].TimeStart, GL_TIMESTAMP);
  glQueryCounter(fQueryID[I, qbBack].TimeEnd, GL_TIMESTAMP);

  Result := I;
end;


procedure TKMRenderQuery.QueriesDelete(var aQueryId: Integer);
begin
  glDeleteQueries(1, @fQueryID[aQueryId, fQueryBufferA].TimeStart);
  glDeleteQueries(1, @fQueryID[aQueryId, fQueryBufferA].TimeEnd);
  glDeleteQueries(1, @fQueryID[aQueryId, fQueryBufferB].TimeStart);
  glDeleteQueries(1, @fQueryID[aQueryId, fQueryBufferB].TimeEnd);

  aQueryId := -1;
end;


// aux function to keep the code simpler
procedure TKMRenderQuery.QueriesSwapBuffers;
begin
  if fQueryBufferA = qbFront then
  begin
    fQueryBufferA := qbBack;
    fQueryBufferB := qbFront;
  end else
  begin
    fQueryBufferA := qbFront;
    fQueryBufferB := qbBack;
  end;
end;


procedure TKMRenderQuery.QueriesBegin(aQueryId: Integer);
begin
  //glBeginQuery(GL_TIME_ELAPSED, fQueryID[fQueryBufferBack][0]);
  glQueryCounter(fQueryID[aQueryId, fQueryBufferA].TimeStart, GL_TIMESTAMP);
end;


procedure TKMRenderQuery.QueriesEnd(aQueryId: Integer);
begin
  //glEndQuery(GL_TIME_ELAPSED);
  glQueryCounter(fQueryID[aQueryId, fQueryBufferA].TimeEnd, GL_TIMESTAMP);
end;


// Gets time from previous frame
// (to avoid stalling GPU, since query times are known only after rendering is done, which is async)
// Since previous frame is done, we dont need to explicitly wait for queries to complete
function TKMRenderQuery.QueriesTime(aQueryId: Integer): UInt64;
var
  t1, t2: UInt64;
begin
  glGetQueryObjectui64v(fQueryID[aQueryId, fQueryBufferB].TimeStart, GL_QUERY_RESULT, @t1);
  glGetQueryObjectui64v(fQueryID[aQueryId, fQueryBufferB].TimeEnd, GL_QUERY_RESULT, @t2);

  if t2 > t1 then
    Result := t2 - t1
  else
    Result := 0; //Sometimes we can get overflow....
end;


end.
