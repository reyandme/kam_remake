unit KromShellUtils;
{$I KaM_Remake.inc}
interface
uses
  Classes,
  {$IFDEF MSWindows}Windows, MMSystem, {$ENDIF}
  {$IFDEF Unix}LCLType, {$ENDIF}
  {$IFDEF FPC}LCLIntf, UTF8Process, LazHelpHTML, {$ENDIF}
  {$IFDEF WDC}ShellApi, {$ENDIF}
	Forms, Dialogs, Controls;

	function RunOpenDialog(Sender: TOpenDialog; const aName, aPath, aFilter: string): Boolean;
  function RunSaveDialog(Sender: TSaveDialog; aFileName, aFilePath, aFilter: string; const aFileExt: string = ''): Boolean;
	procedure DoClientAreaResize(aForm: TForm);
	function BrowseURL(const aURL: string) : Boolean;
  procedure MailTo(const aAddress, aSubject, aBody:string);
  function IsUnderWine: Boolean;


implementation
uses
  KromUtils
  {$IFDEF Unix}
  , dynlibs
  {$ENDIF}
  ;


function RunOpenDialog(Sender: TOpenDialog; const aName, aPath, aFilter: string): Boolean;
begin
  Sender.FileName := aName;
  Sender.InitialDir := aPath;
  Sender.Filter := aFilter;
  Result := Sender.Execute; // Returns "False" if user pressed "Cancel"
  //Result := Result and FileExists(Sender.FileName); //Already should be enabled in OpenDialog options
end;


function RunSaveDialog(Sender: TSaveDialog; aFileName, aFilePath, aFilter: string; const aFileExt: string = ''): Boolean;
begin
  Sender.FileName   := aFileName;
  Sender.InitialDir := aFilePath;
  Sender.Filter     := aFilter;
  Result            := Sender.Execute; //Returns "False" if user pressed "Cancel"
  if not Result then exit;
  Sender.FileName   := AssureFileExt(Sender.FileName, aFileExt);
end;


procedure DoClientAreaResize(aForm:TForm);
const
  DESIGN_HEIGHT = 18;
var
  heightDif: Integer;
  I: Integer;
begin
  heightDif := GetSystemMetrics(SM_CYCAPTION) - DESIGN_HEIGHT;

  for I := 0 to aForm.ControlCount - 1 do
    if (akBottom in aForm.Controls[I].Anchors)
    and (akTop in aForm.Controls[I].Anchors) then
      aForm.Controls[I].Height := aForm.Controls[I].Height - heightDif
    else
    if (akBottom in aForm.Controls[I].Anchors) then
      aForm.Controls[I].Top := aForm.Controls[I].Top - heightDif;

  aForm.ClientHeight := aForm.ClientHeight + heightDif;
end;


function BrowseURL(const aURL: string): Boolean;
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
    if ShellExecute(Application.Handle, 'open', PChar(aURL), nil, nil, SW_SHOWNORMAL) > 32 then
      Result := True;
  {$ENDIF}

  {$IFDEF FPC}
  v:=THTMLBrowserHelpViewer.Create(nil);
  try
    v.FindDefaultBrowser(BrowserPath,BrowserParams);

    p:=System.Pos('%s', BrowserParams);
    System.Delete(BrowserParams,p,2);
    System.Insert(aURL,BrowserParams,p);

    // start browser
    BrowserProcess:=TProcessUTF8.Create(nil);
    try
      BrowserProcess.CommandLine := BrowserPath + ' ' + BrowserParams;
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


procedure MailTo(const aAddress, aSubject, aBody: string);
begin
  BrowseURL('mailto:' + aAddress + '?subject=' + aSubject + '&body=' + aBody);
end;


function IsUnderWine: Boolean;
{$IFNDEF WDC64}
var
  H: Cardinal;
{$ENDIF}
begin
  {$IFDEF WDC64}
  Result := False;
  {$ELSE}
  Result := False;
  H := LoadLibrary('ntdll.dll');
  if
  {$IFNDEF Unix}
  H > HINSTANCE_ERROR
  {$ELSE}
  H <> NilHandle
  {$ENDIF}
  then
  begin
    Result := Assigned(GetProcAddress(H, 'wine_get_version'));
    FreeLibrary(H);
  end;
  {$ENDIF}
end;


end.
