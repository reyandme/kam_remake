unit iaWin.NameDelphiThreads;
{$I KaM_Remake.inc}

interface
uses
  {$IFDEF FPC} Windows; {$ENDIF}
  {$IFDEF WDC} WinAPI.Windows; {$ENDIF}

  procedure NameDelphiThreads(const pMainThreadId:THandle);


// taken from https://github.com/ideasawakened/iaLib
// article: https://www.ideasawakened.com/post/name-your-threads-even-the-ones-auto-created-by-delphi
implementation
uses
  {$IFDEF FPC} SysUtils, Classes, JwaTlHelp32; {$ENDIF} // jwawinbase, jwawinnt ?
  {$IFDEF WDC} System.SysUtils, System.Classes, WinAPI.TlHelp32; {$ENDIF}



// If we want to nam all thread we can do that with delay via anonymous thread, f.e.
//TThread.CreateAnonymousThread(
//    procedure
//    var
//      vSnapshot:THandle;
//      vProcessId:THandle;
//      vTE32:TThreadEntry32;
//      i:Integer;
//    begin
//      Sleep(4000);
//      .... // Rest code
// example from: https://en.delphipraxis.net/topic/2677-do-you-name-your-threads-for-debugging/
procedure NameDelphiThreads(const pMainThreadId:THandle);
var
  vSnapshot:THandle;
  vProcessId:THandle;
  vTE32:TThreadEntry32;
//  i:Integer;
begin
  vProcessId := GetCurrentProcessId();

  vSnapshot := CreateToolhelp32Snapshot(TH32CS_SNAPTHREAD, vProcessId);
  if vSnapshot <> INVALID_HANDLE_VALUE then
  begin
    try
      vTE32.dwSize := SizeOf(vTE32); //If you do not initialize dwSize, Thread32First fails.
      if Thread32First(vSnapshot, vTE32) then
      begin
//        i := 1;
        repeat
          if vTE32.th32OwnerProcessID = vProcessId then
          begin
            if vTE32.th32ThreadID = pMainThreadId then
            begin
              TThread.NameThreadForDebugging('DelphiCreated_Main', pMainThreadId);
            end
            else
            begin
              // skip naming for now, since we will change madExcept thread debug name
//              TThread.NameThreadForDebugging('DelphiCreated_' + AnsiString(IntToStr(i)), vTE32.th32ThreadID);
//              Inc(i);
            end;
          end;
        until not Thread32Next(vSnapshot, vTE32);
      end;
    finally
      CloseHandle(vSnapshot);
    end;
  end;
end;

{$IFDEF DEBUG}
initialization
  NameDelphiThreads(GetCurrentThreadId);
{$ENDIF}

end.
