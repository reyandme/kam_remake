unit KM_ScriptPreProcessor;
{$I KaM_Remake.inc}
{$WARN IMPLICIT_STRING_CAST OFF}
interface
uses
  uPSPreProcessor, uPSUtils,
  KM_ScriptFilesCollection, KM_ScriptErrorHandler,
  KM_ScriptValidatorResult,
  KM_CommonTypes;

type
  // Script preprocessor preprocess script files before compilation
  // This class is our interface to PS script PreProcessor
  // and handler of our custom preprocessor directives
  TKMScriptPreProcessor = class
  private
    fSilent: Boolean;
    fDestroyErrorHandler: Boolean;
    fScriptFilesInfo: TKMScriptFilesCollection;
    fErrorHandler: TKMScriptErrorHandler;
    fValidationIssues: TKMScriptValidatorResult;

    fCustomScriptParams: TKMCustomScriptParamDataArray;
    fPSPreProcessor: TPSPreProcessor;

    function IsCampaignMissionScript: Boolean;

    function GetCustomScriptParamData(aParam: TKMCustomScriptParam): TKMCustomScriptParamData;

    procedure AfterPreProcess;
    procedure BeforePreProcess(const aMainFileName: UnicodeString; const aMainFileText: AnsiString);

    function ScriptOnNeedFile(Sender: TPSPreProcessor; const aCallingFileName: tbtunicodestring;
                              var aFileName: tbtunicodestring; var aOutput: tbtstring): Boolean;
    procedure ScriptOnProcessDirective(Sender: TPSPreProcessor; Parser: TPSPascalPreProcessorParser; const Active: Boolean;
                                        const DirectiveName, DirectiveParam: tbtString; var aContinue: Boolean);
  protected
    property ErrorHandler: TKMScriptErrorHandler read fErrorHandler;

    function AllowGameUpdate: Boolean; virtual;
    function TryLoadCustomEventDirectives(const aDirectiveName, aDirectiveParam: string; aParser: TPSPascalPreProcessorParser): Boolean; virtual;
    function TryLoadCustomConsoleCommands(const aDirectiveName, aDirectiveParam: string; aParser: TPSPascalPreProcessorParser): Boolean; virtual;
  public
    constructor Create(aSilent: Boolean); overload;
    constructor Create(aOnScriptError: TUnicodeStringEvent; aErrorHandler: TKMScriptErrorHandler; aSilent: Boolean); overload;
    destructor Destroy; override;

    property PSPreProcessor: TPSPreProcessor read fPSPreProcessor;

    property CustomScriptParams[aParam: TKMCustomScriptParam]: TKMCustomScriptParamData read GetCustomScriptParamData;
    property ScriptFilesInfo: TKMScriptFilesCollection read fScriptFilesInfo;
    property ValidationIssues: TKMScriptValidatorResult read fValidationIssues write fValidationIssues;

    function ScriptMightChangeAfterPreProcessing: Boolean;
    function PreProcessFile(const aFileName: UnicodeString): Boolean; overload;
    function PreProcessFile(const aFileName: UnicodeString; var aScriptCode: AnsiString): Boolean; overload;
  end;


implementation
uses
  SysUtils, Classes, TypInfo, Math,
  KromUtils,
  KM_GameParams,
  KM_Resource, KM_ResUnits, KM_ResTypes,
  KM_ScriptingTypes,
  KM_CampaignTypes,
  KM_CommonUtils,
  KM_Log, KM_FileIO,
  KM_Defaults;


{ TKMScriptingPreProcessor }
constructor TKMScriptPreProcessor.Create(aSilent: Boolean);
begin
  Create(TUnicodeStringEvent(nil), TKMScriptErrorHandler.Create(nil), aSilent);
  fDestroyErrorHandler := True;
end;


constructor TKMScriptPreProcessor.Create(aOnScriptError: TUnicodeStringEvent; aErrorHandler: TKMScriptErrorHandler; aSilent: Boolean);
begin
  inherited Create;

  fSilent := aSilent;
  fPSPreProcessor := TPSPreProcessor.Create;
  fPSPreProcessor.OnNeedFile := ScriptOnNeedFile;
  fPSPreProcessor.OnProcessDirective := ScriptOnProcessDirective;

  fScriptFilesInfo := TKMScriptFilesCollection.Create;

  fErrorHandler := aErrorHandler;
  fDestroyErrorHandler := False;
end;


destructor TKMScriptPreProcessor.Destroy;
begin
  FreeAndNil(fScriptFilesInfo);
  //Error Handler could be destroyed already
  if fDestroyErrorHandler then
    FreeAndNil(fErrorHandler);

  FreeAndNil(fPSPreProcessor);
  inherited;
end;


procedure TKMScriptPreProcessor.BeforePreProcess(const aMainFileName: UnicodeString; const aMainFileText: AnsiString);
var
  CSP: TKMCustomScriptParam;
begin
  fScriptFilesInfo.MainFilePath := ExtractFilePath(aMainFileName);
  fScriptFilesInfo.SetMainFileInfo(aMainFileName, aMainFileText);

  //Reset custom script parameters
  for CSP := Low(TKMCustomScriptParam) to High(TKMCustomScriptParam) do
  begin
    fCustomScriptParams[CSP].Added := False;
    fCustomScriptParams[CSP].Data := '';
  end;
end;


function TKMScriptPreProcessor.GetCustomScriptParamData(aParam: TKMCustomScriptParam): TKMCustomScriptParamData;
begin
  Result := fCustomScriptParams[aParam];
end;


procedure TKMScriptPreProcessor.AfterPreProcess;
begin
  fScriptFilesInfo.StripIncludedCnt;
end;


function TKMScriptPreProcessor.ScriptMightChangeAfterPreProcessing: Boolean;
begin
  Result := (fScriptFilesInfo.IncludedCount <> 0) or fScriptFilesInfo.HasDefDirectives;
end;


// Check if main script file is a campaign mission
function TKMScriptPreProcessor.IsCampaignMissionScript: Boolean;
begin
  if gGameParams <> nil then
    Exit(gGameParams.IsCampaign)
  else
    // We could run pre processor from script validator, f.e., so we will have no gGameParams initialized

    // fScriptFilesInfo.MainFilePath could have absolute or relative path
    // ScriptValidator ExeDir could lead to some different folder
    Result :=  (Pos(ExeDir + CAMPAIGNS_FOLDER_NAME, fScriptFilesInfo.MainFilePath) = 1)
            or (Pos(CAMPAIGNS_FOLDER_NAME, fScriptFilesInfo.MainFilePath) = 1)
            // Use PathDelims for script validator, to avoid abusing maps with names like 'Better_then_any_Campaigns_map' which contains 'Campaigns' string
            or (Pos(PathDelim + CAMPAIGNS_FOLDER_NAME + PathDelim, fScriptFilesInfo.MainFilePath) > 0);
end;


function TKMScriptPreProcessor.PreProcessFile(const aFileName: UnicodeString): Boolean;
var
  scriptCode: AnsiString;
begin
  Result := PreProcessFile(aFileName, scriptCode);
end;


function TKMScriptPreProcessor.PreProcessFile(const aFileName: UnicodeString; var aScriptCode: AnsiString): Boolean;
var
  mainScriptCode: AnsiString;
  errorStr: string;
begin
  Result := False;
  fErrorHandler.ScriptLogFile := ChangeFileExt(aFileName, SCRIPT_LOG_EXT);

  if not FileExists(aFileName) then
  begin
    gLog.AddNoTime(aFileName + ' was not found. It is okay for mission to have no dynamic scripts.');
    Exit(False);
  end;

  mainScriptCode := ReadTextA(aFileName);

  fPSPreProcessor.MainFileName := aFileName;
  fPSPreProcessor.MainFile := mainScriptCode;
  BeforePreProcess(aFileName, mainScriptCode);
  try
    fPSPreProcessor.PreProcess(fPSPreProcessor.MainFileName, aScriptCode);
    AfterPreProcess;
    Result := True; // If PreProcess has been done succesfully
  except
    on E: Exception do
    begin
      if fSilent then Exit; // Silently exit
      
      errorStr := 'Script preprocessing errors:' + EolW + E.Message;
      fErrorHandler.HandleScriptErrorString(sePreprocessorError, errorStr);
      if fValidationIssues <> nil then
        fValidationIssues.AddError(0, 0, '', errorStr);
    end;
  end;
end;


function TKMScriptPreProcessor.AllowGameUpdate: Boolean;
begin
  Result := False;
end;


// Returns True if we will handle directive
function TKMScriptPreProcessor.TryLoadCustomEventDirectives(const aDirectiveName, aDirectiveParam: string; aParser: TPSPascalPreProcessorParser): Boolean;
const
  CUSTOM_EVENT_DIRECTIVE = 'EVENT';
begin
  Result := UpperCase(aDirectiveName) = UpperCase(CUSTOM_EVENT_DIRECTIVE);
end;


// Returns True if we will handle directive
function TKMScriptPreProcessor.TryLoadCustomConsoleCommands(const aDirectiveName, aDirectiveParam: string; aParser: TPSPascalPreProcessorParser): Boolean;
const
  CUSTOM_CONSOLE_COMMAND_DIRECTIVE = 'COMMAND';
  CUSTOM_CONSOLE_COMMAND_DIRECTIVE_SHORT = 'CMD';
begin
  Result := (UpperCase(aDirectiveName) = UpperCase(CUSTOM_CONSOLE_COMMAND_DIRECTIVE))
         or (UpperCase(aDirectiveName) = UpperCase(CUSTOM_CONSOLE_COMMAND_DIRECTIVE_SHORT));
end;


procedure TKMScriptPreProcessor.ScriptOnProcessDirective(Sender: TPSPreProcessor; Parser: TPSPascalPreProcessorParser; const Active: Boolean;
                                                            const DirectiveName, DirectiveParam: tbtString; var aContinue: Boolean);
const
  CUSTOM_TH_TROOP_COST_DIRECTIVE = 'CUSTOM_TH_TROOP_COST';
  CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE = 'CUSTOM_MARKET_GOLD_PRICE_X';

  procedure LoadCustomTHTroopCost;
  var
    I, troopCost: Integer;
    errorStr: UnicodeString;
    directiveParamSL: TStringList;
    hasError: Boolean;
    thTroopCost: array[Low(TH_TROOP_COST)..High(TH_TROOP_COST)] of Integer;
  begin
    if UpperCase(DirectiveName) = UpperCase(CUSTOM_TH_TROOP_COST_DIRECTIVE) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      try
        directiveParamSL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ',', directiveParamSL);

          hasError := False;
          if directiveParamSL.Count <> Length(thTroopCost) then
          begin
            hasError := True;
            fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has wrong number of parameters: expected %d, actual: %d. At [%d:%d]' + sLineBreak,
                                                [CUSTOM_TH_TROOP_COST_DIRECTIVE, Length(thTroopCost), directiveParamSL.Count,
                                                 Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_TH_TROOP_COST_DIRECTIVE,
                                         Format('Wrong number of parameters: expected %d, actual: %d',
                                                [Length(thTroopCost), directiveParamSL.Count]));
          end;

          for I := Low(thTroopCost) to High(thTroopCost) do
            if TryStrToInt(directiveParamSL[I], troopCost) then
              thTroopCost[I] := EnsureRange(troopCost, 1, 255)
            else begin
              hasError := True;
              fErrorHandler.AppendErrorStr(Format('Directive ''%s'' wrong parameter: [%s] is not a number. At [%d:%d]' + sLineBreak,
                                                  [CUSTOM_TH_TROOP_COST_DIRECTIVE, directiveParamSL[I], Parser.Row, Parser.Col]));
              if fValidationIssues <> nil then
                fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_TH_TROOP_COST_DIRECTIVE,
                                           Format('Wrong directive parameter: [%s] is not a number', [directiveParamSL[I]]));
            end;

          if not hasError then
          begin
            fCustomScriptParams[cspTHTroopCosts].Added := True;
            fCustomScriptParams[cspTHTroopCosts].Data := DirectiveParam;
          end else
            Exit;

          //Do not do anything for while in MapEd
          //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
          //gGame could be nil here, but that does not change final CRC, so we can Exit
          if not AllowGameUpdate then Exit;

          //Update actual troop cost
          for I := Low(TH_TROOP_COST) to High(TH_TROOP_COST) do
            TH_TROOP_COST[I] := thTroopCost[I];

        finally
          directiveParamSL.Free;
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading directive ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading directive');
          end;
      end;
    end;
  end;

  procedure LoadCustomMarketGoldPrice;
  var
    errorStr: UnicodeString;
    directiveParamSL: TStringList;
    hasError: Boolean;
    goldOrePriceX, goldPriceX: Single;
  begin
    if UpperCase(DirectiveName) = UpperCase(CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE) then
    begin
      aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

      try
        directiveParamSL := TStringList.Create;
        try
          StringSplit(DirectiveParam, ',', directiveParamSL);

          if directiveParamSL.Count <> 2 then
          begin
            fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has wrong number of parameters: expected 2, actual: %d. At [%d:%d]' + sLineBreak,
                                                [CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE, directiveParamSL.Count, Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE,
                                         'Wrong number of parameters: expected 2, actual: ' + IntToStr(directiveParamSL.Count));
          end;

          hasError := False;
          if TryStrToFloat(directiveParamSL[0], goldOrePriceX, gFormatSettingsDotSeparator)
          and TryStrToFloat(directiveParamSL[1], goldPriceX, gFormatSettingsDotSeparator) then
          begin
            goldOrePriceX := EnsureRange(goldOrePriceX, 0.1, 10);
            goldPriceX := EnsureRange(goldPriceX, 0.1, 10);
          end else
          begin
            hasError := True;
            fErrorHandler.AppendErrorStr(Format('Directive ''%s'' has not a number parameter: [%s]. At [%d:%d]' + sLineBreak,
                                                [CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE, DirectiveParam, Parser.Row, Parser.Col]));
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, CUSTOM_MARKET_GOLD_PRICE_DIRECTIVE,
                                         'Wrong directive parameters type, Integer required');
          end;

          if not hasError then
          begin
            fCustomScriptParams[cspMarketGoldPrice].Added := True;
            fCustomScriptParams[cspMarketGoldPrice].Data :=
              Format('%s: x%s %s: x%s', [gRes.Wares[wtGoldOre].Title, FormatFloat('#0.#', goldOrePriceX),
                                         gRes.Wares[wtGold].Title,    FormatFloat('#0.#', goldPriceX)]);
          end else
            Exit;

          //Do not do anything for while in MapEd
          //But we have to allow to preprocess file, as preprocessed file used for CRC calc in MapEd aswell
          //gGame could be nil here, but that does not change final CRC, so we can Exit
          if not AllowGameUpdate then Exit;

          // Update actual market prices
          gRes.Wares[wtGoldOre].MarketPriceMultiplier := goldOrePriceX;
          gRes.Wares[wtGold].MarketPriceMultiplier := goldPriceX;

        finally
          directiveParamSL.Free;
        end;
      except
        on E: Exception do
          begin
            errorStr := Format('Error loading directive ''%s'' at [%d:%d]', [Parser.Token, Parser.Row, Parser.Col]);
            fErrorHandler.AppendErrorStr(errorStr, errorStr + ' Exception: ' + E.Message
              {$IFDEF WDC} + sLineBreak + E.StackTrace {$ENDIF});
            if fValidationIssues <> nil then
              fValidationIssues.AddError(Parser.Row, Parser.Col, Parser.Token, 'Error loading directive');
          end;
      end;
    end;
  end;

begin
  // Most of the scripts do not have directives.
  // save in fHasDefDirectives, when script do have IFDEF or IFNDEF directive, which might change script code after pre-processing
  if not fScriptFilesInfo.HasDefDirectives
    and Active
    and ((DirectiveName = 'IFDEF')
      or (DirectiveName = 'IFNDEF')
      or (DirectiveName = 'ELSE')
      or (DirectiveName = 'DEFINE')
      or (DirectiveName = 'UNDEF')) then
    fScriptFilesInfo.HasDefDirectives := True;

  if TryLoadCustomEventDirectives(DirectiveName, DirectiveParam, Parser) then
    aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

  if TryLoadCustomConsoleCommands(DirectiveName, DirectiveParam, Parser) then
    aContinue := False; //Custom directive should not be proccesed any further by pascal script preprocessor, as it will cause an error

  LoadCustomTHTroopCost;
  LoadCustomMarketGoldPrice;
end;


function TKMScriptPreProcessor.ScriptOnNeedFile(Sender: TPSPreProcessor; const aCallingFileName: tbtunicodestring;
                                                var aFileName: tbtunicodestring; var aOutput: tbtstring): Boolean;
var
  path, fileName, fileExt, errorStr: string;
  inclFile: string;
  includedScriptFileInfo: TKMScriptFileInfo;
  isCmpScript: Boolean;
begin
  Result := False;

  // Always should check main script folder first, instead of using aCallingFileName, since it could be invoked from included script
  // We want to always allow to overwrite included file from main script folder
  //
  // So f.e. main.script includes A.script in the Campaign's Scripts folder
  // A.script includes B.script, which is also in the Campaign's Scripts folder
  // But if main script folder contains other B.script, then it should be used instead of Scripts/B.script
  path := fScriptFilesInfo.MainFilePath;

  inclFile := Trim(aFileName);

  fileName := path + inclFile;

  isCmpScript := IsCampaignMissionScript;

  fileExt := ExtractFileExt(fileName);
  // Check included file extension
  if fileExt <> EXT_FILE_SCRIPT_DOT then
  begin
    errorStr := Format('Error including ''%s'' from ''%s'':|wrong extension: ''%s''',
                       [inclFile, ExtractFileName(aCallingFileName), fileExt]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  // Do not allow to include campaigndata.script, since we can include scripts from the root folder now
  if inclFile = CAMPAIGN_DATA_SCRIPT_FILENAME + EXT_FILE_SCRIPT_DOT then
  begin
    errorStr := Format('Error including ''%s'' from ''%s'':|filename ''%s'' is reserved for campaign data',
                       [inclFile, ExtractFileName(aCallingFileName), CAMPAIGN_DATA_SCRIPT_FILENAME + EXT_FILE_SCRIPT_DOT]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  // Check if file has some path in it
  if ExtractFilePath(fileName) <> fScriptFilesInfo.MainFilePath then
  begin
    if isCmpScript then
      errorStr := Format('Error including ''%s'' from ''%s'':|included script files should be in the same folder as main script file ' +
                         'or in the campaign folder: ''%s''',
                         [fileName, ExtractFileName(aCallingFileName), CAMPAIGN_SCRIPTS_FOLDER_NAME])
    else
      errorStr := Format('Error including ''%s'' from ''%s'':|included script files should be in the same folder as main script file',
                         [fileName, ExtractFileName(aCallingFileName)]);
    fErrorHandler.AppendErrorStr(errorStr, errorStr);
    raise Exception.Create(errorStr); // We should raise Exception here, to stop Including process by PascalScript
  end;

  aFileName := fileName;

  // If file not found in the main script folder and main script is from campaign mission (checked via folder path),
  // then we should try to find this script in the 'Scripts' folder inside campaign main folder
  if isCmpScript and not FileExists(aFileName) then
  begin
    fileName := path + '..' + PathDelim + CAMPAIGN_SCRIPTS_FOLDER_NAME + PathDelim + inclFile;

    // If not found, then set aFileName to an initial name
    if FileExists(fileName) then
      aFileName := fileName;
  end;

  if FileExists(aFileName) then
  begin
    aOutput := ReadTextA(aFileName);

    includedScriptFileInfo.FullFilePath := aFileName;
    includedScriptFileInfo.FileName := ExtractFileName(aFileName);
    includedScriptFileInfo.FileText := aOutput;

    fScriptFilesInfo.AddIncludeInfo(includedScriptFileInfo);

    Result := True;
  end;
end;


end.
