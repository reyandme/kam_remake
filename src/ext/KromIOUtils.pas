unit KromIOUtils;
interface
uses
  ShellAPI, SysUtils;

function CopyDir(const aFromDir, aToDir: string): Boolean;
function DelDir(aDir: string): Boolean;
function ReturnSize(aSize: Int64): string;

implementation


function CopyDir(const aFromDir, aToDir: string): Boolean;
var
  fos: TSHFileOpStruct;
begin
  fos := default(TSHFileOpStruct);
  fos.wFunc  := FO_COPY;
  fos.fFlags := FOF_FILESONLY;
  fos.pFrom  := PChar(aFromDir + #0);
  fos.pTo    := PChar(aToDir);
  Result := ShFileOperation(fos) = 0;
end;


function DelDir(aDir: string): Boolean;
var
  fos: TSHFileOpStruct;
begin
  fos := default(TSHFileOpStruct);
  fos.wFunc  := FO_DELETE;
  fos.fFlags := FOF_SILENT or FOF_NOCONFIRMATION;
  fos.pFrom  := PChar(aDir + #0);
  Result := ShFileOperation(fos) = 0;
end;


function ReturnSize(aSize: Int64): string;
begin
  if aSize < 2048 then
    Result := IntToStr(aSize) + 'b'
  else
  if aSize < 2048*1000 then
    Result := IntToStr(aSize shr 10) + 'Kb'
  else
  if aSize < 2048*1000000 then
    Result := IntToStr(aSize shr 20) + 'Mb'
  else
    Result := IntToStr(aSize shr 30) + 'Gb';
end;


end.
 
