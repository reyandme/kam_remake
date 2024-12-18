unit KM_WorkerThreadUtils;
{$I KaM_Remake.inc}
interface
uses
  Classes
  {$IF DEFINED(WDC) OR (FPC_FULLVERSION >= 30200)}, KM_CommonClasses, KM_WorkerThread {$ENDIF};

  {$IF DEFINED(WDC) OR (FPC_FULLVERSION >= 30200)}
  procedure AsyncSaveToFileAndFree(var aStream: TKMemoryStream; const aFileName: string; aWorkerThread: TKMWorkerThread);
  procedure AsyncSaveToFileCompressedAndFree(var aStream: TKMemoryStream; const aFileName: string; const aMarker: string; aWorkerThread: TKMWorkerThread);
  procedure AsyncSaveStreamsToFileAndFree(var aMainStream, aSubStream1, aSubStream2: TKMemoryStream; const aFileName: string;
                                                const aMarker1, aMarker2: string; aWorkerThread: TKMWorkerThread);
  {$ENDIF}

implementation


{$IF DEFINED(WDC) OR (FPC_FULLVERSION >= 30200)}
procedure AsyncSaveToFileAndFree(var aStream: TKMemoryStream; const aFileName: string; aWorkerThread: TKMWorkerThread);
var
  localStream: TKMemoryStream;
begin
  localStream := aStream;
  aStream := nil; //So caller doesn't use it by mistake

  {$IFDEF WDC}
    aWorkerThread.QueueWork(procedure
    begin
      try
        localStream.SaveToFile(aFileName);
      finally
        localStream.Free;
      end;
    end, 'SaveToFile');
  {$ELSE}
    try
      LocalStream.SaveToFile(aFileName);
    finally
      LocalStream.Free;
    end;
  {$ENDIF}
end;


procedure AsyncSaveToFileCompressedAndFree(var aStream: TKMemoryStream; const aFileName: string; const aMarker: string;
                                                                aWorkerThread: TKMWorkerThread);
var
  localStream: TKMemoryStream;
begin
  localStream := aStream;
  aStream := nil; //So caller doesn't use it by mistake

  {$IFDEF WDC}
    aWorkerThread.QueueWork(procedure
    begin
      try
        localStream.SaveToFileCompressed(aFileName, aMarker);
      finally
        localStream.Free;
      end;
    end, 'SaveToFileCompressed ' + aMarker);
  {$ELSE}
    try
      LocalStream.SaveToFileCompressed(aFileName, aMarker);
    finally
      LocalStream.Free;
    end;
  {$ENDIF}
end;


procedure AsyncSaveStreamsToFileAndFree(var aMainStream, aSubStream1, aSubStream2: TKMemoryStream; const aFileName: string;
                                                             const aMarker1, aMarker2: string; aWorkerThread: TKMWorkerThread);
var
  localSubStream1, localSubStream2, localMainStream: TKMemoryStream;
begin
  localMainStream := aMainStream;
  localSubStream1 := aSubStream1;
  localSubStream2 := aSubStream2;
  aMainStream := nil; //So caller doesn't use it by mistake
  aSubStream1 := nil; //So caller doesn't use it by mistake
  aSubStream2 := nil; //So caller doesn't use it by mistake

  {$IFDEF WDC}
    aWorkerThread.QueueWork(procedure
    begin
      try
        localMainStream.AppendStream(localSubStream1, aMarker1);
        localMainStream.AppendStream(localSubStream2, aMarker2);
        localMainStream.SaveToFile(aFileName);
      finally
        localSubStream1.Free;
        localSubStream2.Free;
        localMainStream.Free;
      end;
    end, 'SaveStreamsToFile ' + aMarker1 + ' ' + aMarker2);
  {$ELSE}
    try
      mainStream.AppendStream(localStream1, aMarker1);
      mainStream.AppendStream(localStream2, aMarker2);
      mainStream.SaveToFile(aFileName);
    finally
      localStream1.Free;
      localStream2.Free;
      mainStream.Free;
    end;
  {$ENDIF}
end;
{$ENDIF}

end.

