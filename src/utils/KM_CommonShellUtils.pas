unit KM_CommonShellUtils;
{$I KaM_Remake.inc}
interface

  function ShellOpenFile(const aURL: string): Boolean;
  function ShellOpenFolder(const aURL: string; aSelectFile: Boolean): Boolean;

  {$IFNDEF Unix}
  function GetMemUsed: NativeUInt;
  function GetCommittedStackSize: NativeUInt;
  {$ENDIF}

implementation
uses
  {$IFDEF MSWindows}Windows, {$ENDIF}
  Forms
  {$IFDEF WDC}, ShellApi, PsAPI {$ENDIF}
  {$IFDEF Unix}
  {$IFDEF FPC}, LCLIntF {$ENDIF}
  {$ELSE}
  {$IFDEF FPC}, JwaPsApi {$ENDIF}
  {$ENDIF}
  ;


function ShellOpenFile(const aURL: string): Boolean;
begin
  if aURL = '' then Exit(False);

  {$IFDEF WDC}
  Result := ShellExecute(Application.Handle, 'open', PChar(aURL), nil, nil, SW_SHOWNORMAL) > 32;
  {$ENDIF}

  {$IFDEF FPC}
  Result := OpenDocument(aURL);
  {$ENDIF}
end;


function ShellOpenFolder(const aURL: string; aSelectFile: Boolean): Boolean;
{$IFDEF WDC}
  var
  url: string;
{$ENDIF}
begin
  if aURL = '' then Exit(False);

  {$IFDEF WDC}
  url := '"' + aURL + '"';
  if aSelectFile then
    url := '/select, ' + url;

  Result := ShellExecute(Application.Handle, 'open', 'explorer.exe', PChar(url),  nil, SW_SHOWNORMAL) > 32;
  {$ENDIF}

  {$IFDEF FPC}
  Result := OpenDocument(aURL);
  {$ENDIF}
end;


{$IFNDEF Unix}
function GetMemUsed: NativeUInt;
var
  pmc: PPROCESS_MEMORY_COUNTERS;
  cb: Integer;
begin
  cb := SizeOf(_PROCESS_MEMORY_COUNTERS);
  GetMem(pmc, cb);
  pmc^.cb := cb;
  if GetProcessMemoryInfo(GetCurrentProcess(), pmc, cb) then
    Result := pmc^.WorkingSetSize
  else
    Result := 0;

  FreeMem(pmc);
end;


function GetCommittedStackSize: NativeUInt;
//NB: Win32 uses FS, Win64 uses GS as base for Thread Information Block.
asm
 {$IFDEF WIN32}
  mov eax, [fs:04h] // TIB: base of the stack
  mov edx, [fs:08h] // TIB: lowest committed stack page
  sub eax, edx      // compute difference in EAX (=Result)
 {$ENDIF}
 {$IFDEF WIN64}
  mov rax, abs [gs:08h] // TIB: base of the stack
  mov rdx, abs [gs:10h] // TIB: lowest committed stack page
  sub rax, rdx          // compute difference in RAX (=Result)
 {$ENDIF}
end;
{$ENDIF}


end.
