unit KromShellUtils;
{$I ..\..\KaM_Remake.inc}
interface
uses
  {$IFDEF MSWindows}Windows, MMSystem, {$ENDIF}
  {$IFDEF Unix}LCLType, {$ENDIF}
  {$IFDEF FPC}LCLIntf, UTF8Process, LazHelpHTML, {$ENDIF}
  {$IFDEF WDC}ShellApi, {$ENDIF}
	Forms, Classes, Dialogs, Controls;
	
	function RunOpenDialog(Sender:TOpenDialog; const Name,Path,Filter:string):boolean;
  function RunSaveDialog(Sender:TSaveDialog; FileName, FilePath, Filter:string; const FileExt:string = ''):boolean;
	procedure DoClientAreaResize(aForm:TForm);
	function BrowseURL(const URL: string) : Boolean;
  function OpenPDF(const URL: string): Boolean;
  procedure MailTo(const Address,Subject,Body:string);
  procedure OpenMySite(const ToolName: string; const Address: string = 'http://krom.reveur.de');


implementation
uses
  KromUtils;


function RunOpenDialog(Sender: TOpenDialog; const Name, Path, Filter: string): boolean;
begin
  Sender.FileName := Name;
  Sender.InitialDir := Path;
  Sender.Filter := Filter;
  Result := Sender.Execute; // Returns "false" if user pressed "Cancel"
  //Result := Result and FileExists(Sender.FileName); //Already should be enabled in OpenDialog options
end;


function RunSaveDialog(Sender:TSaveDialog; FileName, FilePath, Filter:string; const FileExt:string = ''):boolean;
begin
  Sender.FileName   := FileName;
  Sender.InitialDir := FilePath;
  Sender.Filter     := Filter;
  Result            := Sender.Execute; //Returns "false" if user pressed "Cancel"
  if not Result then exit;
  Sender.FileName   := AssureFileExt(Sender.FileName, FileExt);
end;


procedure DoClientAreaResize(aForm:TForm);
const DesignHeight = 18;
var
  HeightDif:integer;
  i:integer;
begin
  HeightDif := GetSystemMetrics(SM_CYCAPTION) - DesignHeight;

  for i:=0 to aForm.ControlCount-1 do
    if (akBottom in aForm.Controls[i].Anchors) and
       (akTop in aForm.Controls[i].Anchors) then
      aForm.Controls[i].Height := aForm.Controls[i].Height - HeightDif
    else
    if (akBottom in aForm.Controls[i].Anchors) then
      aForm.Controls[i].Top := aForm.Controls[i].Top - HeightDif;

  aForm.ClientHeight := aForm.ClientHeight + HeightDif;
end;


function OpenPDF(const URL: string): Boolean;
begin
  {$IFDEF WDC}
  Result := ShellExecute(Application.Handle, 'open', PChar(URL),nil,nil, SW_SHOWNORMAL) > 32;
  {$ENDIF}

  {$IFDEF FPC}
  Result := OpenDocument(URL);
  {$ENDIF}
end;


function BrowseURL(const URL: string): Boolean;
{$IFDEF FPC}
var
  v: THTMLBrowserHelpViewer;
  BrowserPath, BrowserParams: string;
  p: LongInt;
  BrowserProcess: TProcessUTF8;
{$ENDIF}
begin
  //We need some result incase it's neither WDC nor FPC
  Result := False;

  {$IFDEF WDC}
    //ShellExecute returns a value greater than 32 if successful, or an error value that is less than or equal to 32 otherwise
    if ShellExecute(Application.Handle, 'open', PChar(URL),nil,nil, SW_SHOWNORMAL) > 32 then
      Result := True;
  {$ENDIF}

  {$IFDEF FPC}
  v:=THTMLBrowserHelpViewer.Create(nil);
  try
    v.FindDefaultBrowser(BrowserPath,BrowserParams);

    p:=System.Pos('%s', BrowserParams);
    System.Delete(BrowserParams,p,2);
    System.Insert(URL,BrowserParams,p);

    // start browser
    BrowserProcess:=TProcessUTF8.Create(nil);
    try
      BrowserProcess.CommandLine:=BrowserPath+' '+BrowserParams;
      BrowserProcess.Execute;
      Result := True;
    finally
      BrowserProcess.Free;
    end;
  finally
    v.Free;
  end;
  {$ENDIF}
end;


procedure MailTo(const Address,Subject,Body:string);
begin
  BrowseURL('mailto:'+Address+'?subject='+Subject+'&body='+Body);
end;


procedure OpenMySite(const ToolName: string; const Address: string = 'http://krom.reveur.de');
begin
  BrowseURL(Address+'/index_r.php?t='+ToolName); //Maybe add tool version later..
end;


end.
