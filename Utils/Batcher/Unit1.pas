unit Unit1;
{$I ..\..\KaM_Remake.inc}
interface
uses
  Windows, Classes, Controls, Forms, Math, StdCtrls, SysUtils, StrUtils, IOUtils, System.RegularExpressions,
  KM_Defaults, KM_CommonClasses, KM_CommonTypes, KM_Points, KromUtils,
  KM_GameApp, KM_Log, KM_HandsCollection, KM_MissionScript,
  KM_Maps, KM_MissionScript_Info, KM_Terrain, KM_CommonUtils;

type
  TKMCommandInfo = record
    Parsed: Boolean;
    StartPos: Integer;
    EndPos: Integer;
  end;  

  TKMMissionColorInfoArray = array of record
    CurrPlayer: TKMCommandInfo;
    SetMapColor: TKMCommandInfo;
    SetRgbColor: TKMCommandInfo;
  end;

  TForm1 = class(TForm)
    Button3: TButton;
    Button1: TButton;
    Button2: TButton;
    Memo1: TMemo;
    Button4: TButton;
    btnUnXorAll: TButton;
    btnXorAll: TButton;
    Button7: TButton;
    Button8: TButton;
    Button5: TButton;
    Button6: TButton;
    Button9: TButton;
    btnCheckColor: TButton;
    btnSetDefColor: TButton;
    btnRemoveNewRemap: TButton;
    btnDeleteUnusedSetMapColor: TButton;
    Button10: TButton;
    Button11: TButton;
    Button12: TButton;
    Button13: TButton;
    Button14: TButton;
    procedure Button3Click(Sender: TObject);
    procedure Button1Click(Sender: TObject);
    procedure Button2Click(Sender: TObject);
    procedure Button4Click(Sender: TObject);
    procedure btnXorAllClick(Sender: TObject);
    procedure Button7Click(Sender: TObject);
    procedure Button8Click(Sender: TObject);
    procedure Button5Click(Sender: TObject);
    procedure Button6Click(Sender: TObject);
    procedure Button9Click(Sender: TObject);
    procedure btnCheckColorClick(Sender: TObject);
    procedure btnRemoveNewRemapClick(Sender: TObject);
    procedure btnDeleteUnusedSetMapColorClick(Sender: TObject);
    procedure Button10Click(Sender: TObject);
    procedure Button11Click(Sender: TObject);
    procedure Button12Click(Sender: TObject);
    procedure Button13Click(Sender: TObject);
    procedure Button14Click(Sender: TObject);
  private
    function ValidateUnitName(aValue: String): Boolean;
    procedure AddAIPlayersToMPMaps(aAICommandTxt: String);
    procedure AddMissingAIPlayers;
    procedure AddAdvancedAIPlayersToMPMaps;
    procedure ResetCommands(var aCommands: TKMMissionColorInfoArray);
    procedure GetColorCommandsInfo(aTxt: AnsiString; var aColorInfoArray: TKMMissionColorInfoArray);
    function XorUnXor(UnXor: Boolean; F: TMemoryStream): Boolean;
    function CheckNoColorCommandsForAllMaps(var NoColorsMaps: TStringList; aSetMissingColor: Boolean): Integer;
    procedure SetUp(aNeedGame: Boolean);
    procedure TearDown;
    procedure ControlsEnable(aFlag: Boolean);
  end;

var
  Form1: TForm1;

implementation
uses
  KM_Campaigns, KM_Game, KM_Hand, KM_MissionScript_Standard;

{$R *.dfm}

const
  KAM_ORIGINAL_TEAM_COLORS: array [0..MAX_HANDS-1] of Cardinal = (
    $0707FF, //Red
    $E3BB5B, //Cyan
    $27A700, //Green
    $FF67FF, //Magenta
    $07FFFF, //Yellow
    $577B7B, //Grey
    $000000, //Black
    $000000, //Black
    $2383FB, //Orange
    $FF0707, //Blue
    $0BE73F, //Light green
    $FFFFFF  //White
  );

type
  TKMMissionParserPatcher = class(TKMMissionParserCommon)
  protected
    function ProcessCommand(CommandType: TKMCommandType; P: array of Integer; TextParam: AnsiString = ''): Boolean;
  public
    function ReadMissionFileWOChanges(const aFileName: string): AnsiString;
    procedure SaveToFile(aTxt: AnsiString; const aFileName: string; aDoXor: Boolean = True);
  end;

  TKMMissionParserColorCheck = class(TKMMissionParserPatcher)
  public
    procedure SetDefaultColorsForMission(var aTxt: AnsiString; aCommands: TKMMissionColorInfoArray);
    function GetPlayersWithoutColorStr(aCommands: TKMMissionColorInfoArray): String;
    function GetPlayersWithoutColorArr(aCommands: TKMMissionColorInfoArray): TIntegerArray;
    function IsValid(aCommands: TKMMissionColorInfoArray): Boolean;
  end;


{ TMissionParserPatcher }
function TKMMissionParserPatcher.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; TextParam: AnsiString = ''): Boolean;
begin
  // Do nothing here and make compiler happy
  Result := True;
end;

// Read mission file as it is, without any changes
// We don't use TMissionParserCommon.ReadMissionFile, becasue it cuts spaces and does other things
function TKMMissionParserPatcher.ReadMissionFileWOChanges(const aFileName: string): AnsiString;
var
  I, Num: Cardinal;
  F: TMemoryStream;
begin
  Result := '';

  if not FileExists(aFileName) then Exit;

  //Load and decode .DAT file into FileText
  F := TMemoryStream.Create;
  try
    F.LoadFromFile(aFileName);

    if F.Size = 0 then Exit;

    // Detect whether mission is encoded so we can support decoded/encoded .DAT files
    // We can't test 1st char, it can be any. Instead see how often common chracters meet
    Num := 0;
    for I := 0 to F.Size - 1 do               //tab, eol, 0..9, space, !
      if PByte(Cardinal(F.Memory)+I)^ in [9,10,13,ord('0')..ord('9'),$20,$21] then
        Inc(Num);

    // Usually 30-50% is numerals/spaces, tested on typical KaM maps, take half of that as margin
    if (Num / F.Size < 0.20) then
    for I := 0 to F.Size - 1 do
      PByte(Cardinal(F.Memory)+I)^ := PByte(Cardinal(F.Memory)+I)^ xor 239;

    SetString(Result, PAnsiChar(F.Memory), F.Size div SizeOf(AnsiChar));
  finally
    F.Free;
  end;
end;


procedure TKMMissionParserPatcher.SaveToFile(aTxt: AnsiString; const aFileName: string; aDoXor: Boolean = True);
var
  I: Integer;
  F: TMemoryStream;
begin
  F := TMemoryStream.Create;
  try
    F.Write(Pointer(aTxt)^, Length(aTxt) * SizeOf(AnsiChar));

    if aDoXor then
      for I := 0 to F.Size - 1 do
        PByte(Cardinal(F.Memory)+I)^ := PByte(Cardinal(F.Memory)+I)^ xor 239;

    F.SaveToFile(aFileName);
  finally
    F.Free;
  end;
end;


procedure TForm1.ControlsEnable(aFlag: Boolean);
var
  I: Integer;
begin
  for I := 0 to ControlCount - 1 do
    if Controls[I] is TButton then
      Controls[I].Enabled := aFlag;
end;


procedure TForm1.SetUp(aNeedGame: Boolean);
begin
  ControlsEnable(False);
  Memo1.Clear;

  SKIP_RENDER := True;
  SKIP_SOUND := True;
  ExeDir := ExtractFilePath(ParamStr(0)) + '..\..\';
  gLog := TKMLog.Create(ExtractFilePath(ParamStr(0)) + 'temp.log');
  gGameApp := TKMGameApp.Create(nil, 1024, 768, False, nil, nil, nil, True);
  gGameApp.GameSettings.Autosave := False;
end;


procedure TForm1.TearDown;
begin
  FreeThenNil(gGameApp);
  FreeAndNil(gLog);

  ControlsEnable(True);
end;


//Rename marketplace sprites from rxRemake scheme to rxHouses library
procedure TForm1.Button1Click(Sender: TObject);
var
  SearchRec: TSearchRec;
  NewName: string;
  B: Boolean;
begin
  FindFirst('..\..\SpriteResource\9\9*.png', faAnyFile, SearchRec);
  repeat
    NewName := SearchRec.Name;
    NewName := StringReplace(NewName, '9_00', '2_17', [rfReplaceAll, rfIgnoreCase]);
    NewName := StringReplace(NewName, '9_01', '2_18', [rfReplaceAll, rfIgnoreCase]);
    NewName := StringReplace(NewName, '9_02', '2_19', [rfReplaceAll, rfIgnoreCase]);
    NewName := StringReplace(NewName, '9_03', '2_20', [rfReplaceAll, rfIgnoreCase]);
    B := RenameFile(ExtractFilePath(ParamStr(0)) + '..\..\SpriteResource\9\' + SearchRec.Name,
                    ExtractFilePath(ParamStr(0)) + '..\..\SpriteResource\9\' + NewName);
    Assert(B);
  until (FindNext(SearchRec) <> 0);
  FindClose(SearchRec);
end;


// Export message goals into EVT files to allow to rig them easily
procedure TForm1.Button3Click(Sender: TObject);
const
  TPR_CAMPAIGN: TKMCampaignId = (Byte('T'), Byte('P'), Byte('R'));
var
  I: Integer;
begin
  SetUp(True);

  for I := 0 to gGameApp.Campaigns.CampaignById(TPR_CAMPAIGN).MapCount - 1 do
  begin
    gGameApp.NewCampaignMap(gGameApp.Campaigns.CampaignById(TPR_CAMPAIGN), I);

    gHands[0].AI.Goals.ExportMessages(ExtractFilePath(ParamStr(0)) + Format('TPR%.2d.evt', [I+1]));

    gGameApp.StopGame(grSilent);
  end;

  TearDown;
end;


procedure TForm1.Button2Click(Sender: TObject);
var
  I,J,K: Integer;
  PathToMaps: TStringList;
  MapInfo: TKMapInfo;
  WinCond, DefeatCond: array [TKMGoalCondition] of Word;
  GC: TKMGoalCondition;
  MapFolderType: TKMapFolder;
begin
  SetUp(True);

  FillChar(WinCond, SizeOf(WinCond), #0);
  FillChar(DefeatCond, SizeOf(WinCond), #0);

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    for I := 0 to PathToMaps.Count - 1 do
    begin
      if Pos('MapsMP', PathToMaps[I]) > 0 then
        MapFolderType := mfMP
      else
        MapFolderType := mfSP;

      MapInfo := TKMapInfo.Create(TruncateExt(ExtractFileName(PathToMaps[I])), False, MapFolderType);
      MapInfo.LoadExtra;
      for J := 0 to MapInfo.LocCount - 1 do
      begin
        for K := 0 to MapInfo.GoalsVictoryCount[J] - 1 do
          Inc(WinCond[MapInfo.GoalsVictory[J,K].Cond]);
        for K := 0 to MapInfo.GoalsSurviveCount[J] - 1 do
          Inc(DefeatCond[MapInfo.GoalsSurvive[J,K].Cond]);
      end;
    end;

    //Report results
    Memo1.Lines.Append(IntToStr(PathToMaps.Count) + ' maps');
    Memo1.Lines.Append('Win / Def');
    for GC := Low(TKMGoalCondition) to High(TKMGoalCondition) do
      Memo1.Lines.Append(Format('%3d / %3d ' + GoalConditionStr[GC], [WinCond[GC], DefeatCond[GC]]));
  finally
    PathToMaps.Free;
  end;

  TearDown;
end;


procedure TForm1.Button4Click(Sender: TObject);
var
  I: Integer;
  PathToMaps: TStringList;
  GoalLoc, GoalEnd: Integer;
  Txt, GoalTxt: AnsiString;
  L,R: AnsiString;
  MP: TKMMissionParserPatcher;
  Args: TStringList;
  GoalLog: TStringList;
begin
  SetUp(True);

  Args := TStringList.Create;
  //@Krom: StrictDelimiter doesn't exist in D7
  //Args.StrictDelimiter := True;
  Args.Delimiter := ' ';

  GoalLog := TStringList.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Intent of this design is to rip the specified lines with least impact
    MP := TKMMissionParserPatcher.Create;

    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      //Treat all goals

      //Remove goals solely used to display messages at a time
      GoalLog.Clear;
      GoalLoc := 1;
      repeat
        //ADD_GOAL gcTime *status* MsgId Delay
        GoalLoc := PosEx('!ADD_GOAL 2 ', Txt, GoalLoc);
        if GoalLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments

          //Look for command end marker (!, eol, /)
          GoalEnd := GoalLoc + 1;
          while (GoalEnd < Length(Txt)) and not (Txt[GoalEnd] in ['!', #13, '/']) do
            Inc(GoalEnd);

          GoalTxt := Copy(Txt, GoalLoc, GoalEnd - GoalLoc);
          GoalTxt := StringReplace(GoalTxt, '    ', ' ', [rfReplaceAll]);
          GoalTxt := StringReplace(GoalTxt, '   ', ' ', [rfReplaceAll]);
          GoalTxt := StringReplace(GoalTxt, '  ', ' ', [rfReplaceAll]);
          Args.DelimitedText := GoalTxt;
          //Is this a gcTime MsgId goal
          if Args[3] <> '0' then
          begin
            Memo1.Lines.Append(TruncateExt(ExtractFileName(PathToMaps[I])) + ' ' + GoalTxt);

            GoalLog.Append('  if States.GameTime = ' + Args[4] + ' then' + EolW +
                           '    Actions.ShowMsg( ?, States.Text(' + Args[3] + '));');

            //Cut Goal out
            L := LeftStr(Txt, GoalLoc - 1);
            R := RightStr(Txt, Length(Txt) - GoalEnd + 1);
            Txt := L + R;

            //Keep GoalLoc in place incase there are two consequential goals
          end
          else
            Inc(GoalLoc, Length(GoalTxt));
        end;
      until (GoalLoc = 0);

      if GoalLog.Count > 0 then
        GoalLog.SaveToFile(ChangeFileExt(PathToMaps[I], '.goals.log'));

      MP.SaveToFile(Txt, PathToMaps[I]);
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


procedure GetCommandParams(CommandTxt, Txt: AnsiString; FromLoc: Integer; var aLoc, aEnd, aId: Integer);
var
  s: string;
begin
  aLoc := PosEx(CommandTxt, Txt, FromLoc+1);
  aId := -1;
  if aLoc <> 0 then
  begin
    //Many maps have letters aligned in columns, meaning that
    //command length is varying cos of spaces between arguments
    //Look for command end marker (!, eol, /)
    aEnd := aLoc + Length(CommandTxt);
    while (aEnd < Length(Txt)) and not (Txt[aEnd] in ['!', #13, '/']) do
      Inc(aEnd);
    s := Trim(Copy(Txt, aLoc + Length(CommandTxt), aEnd - (aLoc + Length(CommandTxt))));
    aId := StrToIntDef(s, -1);
  end;
end;


function HasNoParam(aLoc, NextCurrLoc: Integer): Boolean;
begin
  Result := (aLoc = 0) or ((aLoc > NextCurrLoc) and (NextCurrLoc <> 0));
end;


function HasParam(aLoc, NextCurrLoc: Integer): Boolean;
begin
  Result := (aLoc <> 0) and ((aLoc < NextCurrLoc) or (NextCurrLoc = 0));
end;


procedure TForm1.AddAIPlayersToMPMaps(aAICommandTxt: String);
var
  I, K: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd, NextCurrLoc, AILoc, AIEnd: Integer;
  Txt: AnsiString;
  PlayerId, AiId: Integer;
  MP: TKMMissionParserPatcher;
  PlayersSet: array [0 .. MAX_HANDS - 1] of Boolean;
  s: string;
begin
  //Intent of this design is to rip the specified lines with least impact
  MP := TKMMissionParserPatcher.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    if Pos('\MapsMP\', PathToMaps[I]) <> 0 then
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      CurrLoc := 1;
      FillChar(PlayersSet, SizeOf(PlayersSet), #0);
      repeat
        //SET_CURR_PLAYER player_id
        CurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc);
        if CurrLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments
          //Look for command end marker (!, eol, /)
          CurrEnd := CurrLoc + 16;
          while (CurrEnd < Length(Txt)) and not (Txt[CurrEnd] in ['!', #13, '/']) do
            Inc(CurrEnd);
          s := Trim(Copy(Txt, CurrLoc + 16, CurrEnd - (CurrLoc + 16)));
          PlayerId := StrToInt(s);

          NextCurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc+1);

          GetCommandParams('!SET_AI_PLAYER', Txt, CurrLoc, AILoc, AIEnd, AiId);

          //Many times MP maps change CURR player to adjoin similar stuff in sections
          if not PlayersSet[PlayerId] then
            if HasNoParam(AILoc, NextCurrLoc) then
            begin
              //Add from new line
              Insert(EolW + aAICommandTxt, Txt, CurrEnd);
              if AiId <> -1 then
                PlayersSet[AiId] := True
              else
                PlayersSet[PlayerId] := True;
            end;

          CurrLoc := CurrEnd;
        end;
      until (CurrLoc = 0);

      MP.SaveToFile(Txt, PathToMaps[I]);

      s := '';
      for K := 0 to MAX_HANDS - 1 do
        s := s + IfThen(PlayersSet[K], '1', '0');

      Memo1.Lines.Append(s + ' ' + TruncateExt(ExtractFileName(PathToMaps[I])));
    end;
  finally
    PathToMaps.Free;
  end;
end;


procedure TForm1.AddMissingAIPlayers;
var
  I, K: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd, NextCurrLoc,
  EnableLoc, EnableEnd,
  UserLoc, UserEnd,
  HumanLoc, HumanEnd,
  AILoc, AIEnd,
  AdvAILoc, AdvAIEnd: Integer;
   Txt: AnsiString;
  PlayerId, AiId, AdvAiId, TmpId: Integer;
  MP: TKMMissionParserPatcher;
  PlayersSet: array [0 .. MAX_HANDS - 1] of Boolean;
  s: string;
begin
  //Intent of this design is to rip the specified lines with least impact
  MP := TKMMissionParserPatcher.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      CurrLoc := 1;
      FillChar(PlayersSet, SizeOf(PlayersSet), #0);
      repeat
        //SET_CURR_PLAYER player_id
        CurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc);
        if CurrLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments
          //Look for command end marker (!, eol, /)
          CurrEnd := CurrLoc + 16;
          while (CurrEnd < Length(Txt)) and not (Txt[CurrEnd] in ['!', #13, '/']) do
            Inc(CurrEnd);
          s := Trim(Copy(Txt, CurrLoc + 16, CurrEnd - (CurrLoc + 16)));
          PlayerId := StrToInt(s);

          NextCurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc+1);

          GetCommandParams('!ENABLE_PLAYER', Txt, CurrLoc, EnableLoc, EnableEnd, TmpId);
          GetCommandParams('!SET_AI_PLAYER', Txt, CurrLoc, AILoc, AIEnd, AiId);
          GetCommandParams('!SET_ADVANCED_AI_PLAYER', Txt, CurrLoc, AdvAILoc, AdvAIEnd, AdvAiId);
          GetCommandParams('!SET_USER_PLAYER', Txt, CurrLoc, UserLoc, UserEnd, TmpId);
          GetCommandParams('!SET_HUMAN_PLAYER', Txt, CurrLoc, HumanLoc, HumanEnd, TmpId);

          //Many times MP maps change CURR player to adjoin similar stuff in sections
          if not PlayersSet[PlayerId] then
            if HasNoParam(AdvAiLoc, NextCurrLoc) //Has no advanced AI player
              and HasNoParam(UserLoc, NextCurrLoc) //Has no Human player
              and HasNoParam(AiLoc, NextCurrLoc)
              and HasNoParam(HumanLoc, NextCurrLoc) then //Has no AI Player
            begin
              //Add from new line
              if HasParam(EnableLoc, NextCurrLoc) then
                TmpId := EnableEnd
              else
                TmpId := CurrEnd;
              Insert(EolW + '!SET_AI_PLAYER', Txt, TmpId);
              if AiId <> -1 then
                PlayersSet[AiId] := True
              else
                PlayersSet[PlayerId] := True;
            end;

          CurrLoc := CurrEnd;
        end;
      until (CurrLoc = 0);

      MP.SaveToFile(Txt, PathToMaps[I]);

      s := '';
      for K := 0 to MAX_HANDS - 1 do
        s := s + IfThen(PlayersSet[K], '1', '0');

      Memo1.Lines.Append(s + ' ' + TruncateExt(ExtractFileName(PathToMaps[I])));
    end;
  finally
    PathToMaps.Free;
  end;
end;


procedure TForm1.AddAdvancedAIPlayersToMPMaps;
var
  I, K: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd, NextCurrLoc,
  HumanLoc, HumanEnd,
  UserLoc, UserEnd,
  AILoc, AIEnd,
  AdvAILoc, AdvAIEnd: Integer;
  Txt: AnsiString;
  PlayerId, AiId, UserId, AdvAiId, TmpId: Integer;
  MP: TKMMissionParserPatcher;
  PlayersSet: array [0 .. MAX_HANDS - 1] of Boolean;
  s: string;
begin
  //Intent of this design is to rip the specified lines with least impact
  MP := TKMMissionParserPatcher.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    if Pos('\MapsMP\', PathToMaps[I]) <> 0 then
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      CurrLoc := 1;
      FillChar(PlayersSet, SizeOf(PlayersSet), #0);
      repeat
        //SET_CURR_PLAYER player_id
        CurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc);
        if CurrLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments
          //Look for command end marker (!, eol, /)
          CurrEnd := CurrLoc + 16;
          while (CurrEnd < Length(Txt)) and not (Txt[CurrEnd] in ['!', #13, '/']) do
            Inc(CurrEnd);
          s := Trim(Copy(Txt, CurrLoc + 16, CurrEnd - (CurrLoc + 16)));
          PlayerId := StrToInt(s);

          NextCurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc+1);

          GetCommandParams('!SET_AI_PLAYER', Txt, CurrLoc, AILoc, AIEnd, AiId);
          GetCommandParams('!SET_ADVANCED_AI_PLAYER', Txt, CurrLoc, AdvAILoc, AdvAIEnd, AdvAiId);
          GetCommandParams('!SET_USER_PLAYER', Txt, CurrLoc, UserLoc, UserEnd, TmpId);
          GetCommandParams('!SET_HUMAN_PLAYER', Txt, CurrLoc, HumanLoc, HumanEnd, TmpId);

          //Many times MP maps change CURR player to adjoin similar stuff in sections
          if not PlayersSet[PlayerId] then
            if HasNoParam(AdvAILoc, NextCurrLoc) //No advanced AI player
              and (HasParam(UserLoc, NextCurrLoc) or HasParam(HumanLoc, NextCurrLoc)) //Has Human player
              and HasParam(AiLoc, NextCurrLoc) then //Has AI Player
            begin
              //Add from new line
              Insert(EolW + '!SET_ADVANCED_AI_PLAYER', Txt, AIEnd);
              if AdvAiId <> -1 then
                PlayersSet[AdvAiId] := True
              else
                PlayersSet[PlayerId] := True;
            end;

          CurrLoc := CurrEnd;
        end;
      until (CurrLoc = 0);

      MP.SaveToFile(Txt, PathToMaps[I]);

      s := '';
      for K := 0 to MAX_HANDS - 1 do
        s := s + IfThen(PlayersSet[K], '1', '0');

      Memo1.Lines.Append(s + ' ' + TruncateExt(ExtractFileName(PathToMaps[I])));
    end;
  finally
    PathToMaps.Free;
  end;
end;


procedure TForm1.Button5Click(Sender: TObject);
begin
  SetUp(True);

  AddAIPlayersToMPMaps('!SET_AI_PLAYER');

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


procedure TForm1.Button10Click(Sender: TObject);
begin
  SetUp(True);

  AddAdvancedAIPlayersToMPMaps;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


procedure TForm1.Button11Click(Sender: TObject);
var
  I, Cnt: Integer;
  SL, PathToMaps: TStringList;
begin
  SetUp(True);

  SL := TStringList.Create;
  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    Cnt := PathToMaps.Count;
    for I := 0 to PathToMaps.Count - 1 do
    begin
      SL.Clear;
      //Load and save all .DAT files
      SL.LoadFromFile(PathToMaps[I]);
      SL.SaveToFile(PathToMaps[I]);
    end;
  finally
    PathToMaps.Free;
    SL.Free;
  end;

  Memo1.Lines.Append(IntToStr(Cnt));

  TearDown;
end;


function TForm1.ValidateUnitName(aValue: String): Boolean;
begin
  Result := AnsiEndsText('.pas', aValue) and AnsiStartsText('KM_', aValue);
end;


procedure TForm1.Button12Click(Sender: TObject);
var
  I, Cnt: Integer;
  SL, PathToUnits: TStringList;
  PathToExt: UnicodeString;
begin
  SetUp(True);

  SL := TStringList.Create;
  PathToUnits := TStringList.Create;
  try
    GetAllPathsInDir(IncludeTrailingBackslash(ExeDir) + PathDelim + 'src', PathToUnits, ValidateUnitName);

    PathToExt := IncludeTrailingBackslash(ExeDir) + PathDelim + 'src' + PathDelim + 'ext' + PathDelim;
    PathToUnits.Add(PathToExt + 'KromUtils.pas');
    PathToUnits.Add(PathToExt + 'KromIOUtils.pas');
    PathToUnits.Add(PathToExt + 'KromOGLUtils.pas');
    PathToUnits.Add(PathToExt + 'KromShellUtils.pas');

    Cnt := PathToUnits.Count;
    for I := 0 to PathToUnits.Count - 1 do
    begin
      Memo1.Lines.Append(PathToUnits[I]);
      SL.Clear;
      //Load and save all units
      SL.LoadFromFile(PathToUnits[I]);
      SL.SaveToFile(PathToUnits[I]);
    end;
  finally
    PathToUnits.Free;
    SL.Free;
  end;

  Memo1.Lines.Append(IntToStr(Cnt));

  TearDown;
end;

procedure TForm1.Button13Click(Sender: TObject);
var
  I, Cnt: Integer;
  PathToMaps: TStringList;
begin
  SetUp(True);

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    Cnt := PathToMaps.Count;
    for I := 0 to PathToMaps.Count - 1 do
    begin
      gLog.AddTime('Resave map: ' + PathToMaps[I]);
      gGameApp.NewMapEditor(PathToMaps[I]);
      gLog.AddTime('Opened map: ' + PathToMaps[I]);
      gGameApp.SaveMapEditor(PathToMaps[I]);
      gLog.AddTime('Saved map: ' + PathToMaps[I]);
      Memo1.Lines.Append(Format('%d: %s', [I, ExtractFileName(PathToMaps[I])]));
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Cnt));

  TearDown;
end;


procedure TForm1.Button14Click(Sender: TObject);
begin
  SetUp(True);

  AddMissingAIPlayers;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;

procedure TForm1.Button6Click(Sender: TObject);

  function IsBuildingMap(aPath: string): Boolean;
  var
    Txt: string;
  begin
    Result := True;
    if not FileExists(ChangeFileExt(aPath, '.txt')) then
      Exit;
    Txt := TFile.ReadAllText(ChangeFileExt(aPath, '.txt'));
    Result := (Pos('SetCoop', Txt) = 0) and (Pos('SetSpecial', Txt) = 0);
  end;

var
  I: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd: Integer;
  Txt: AnsiString;
  MP: TKMMissionParserPatcher;
begin
  SetUp(True);

  //Intent of this design is to rip the specified lines with least impact
  MP := TKMMissionParserPatcher.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    if (Pos('\MapsMP\', PathToMaps[I]) <> 0) and IsBuildingMap(PathToMaps[I]) then
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      if Pos('!SET_TACTIC', Txt) <> 0 then
        Continue;

      //First strip out existing AI defaults that we don't want
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER WORKER_FACTOR.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER CONSTRUCTORS.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER EQUIP_RATE_LEATHER.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER EQUIP_RATE_IRON.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER EQUIP_RATE.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER RECRUTS.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER RECRUT_COUNT.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER MAX_SOLDIER.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_CHARACTER AUTO_ATTACK_RANGE.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_NO_BUILD.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_AUTO_REPAIR.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_AUTO_DEFENCE.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_AUTO_DEFEND.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_DEFEND_ALLIES.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_AUTO_ATTACK.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_UNLIMITED_EQUIP.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!SET_AI_ARMY_TYPE.*'+EolA, '');

      Txt := TRegEx.Replace(Txt, '!SET_AI_ATTACK.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!COPY_AI_ATTACK.*'+EolA, '');
      Txt := TRegEx.Replace(Txt, '!CLEAR_AI_ATTACK.*'+EolA, '');

      CurrLoc := 1;
      repeat
        //SET_CURR_PLAYER player_id
        CurrLoc := PosEx('!SET_AI_PLAYER', Txt, CurrLoc);
        if CurrLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments
          //Look for command end marker (!, eol, /)
          CurrEnd := CurrLoc + 14;
          while (CurrEnd < Length(Txt)) and not (Txt[CurrEnd] in ['!', #13, '/']) do
            Inc(CurrEnd);

          Insert(EolA + '!SET_AI_AUTO_REPAIR', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER WORKER_FACTOR 10', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER CONSTRUCTORS 20', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER EQUIP_RATE_LEATHER 500', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER EQUIP_RATE_IRON 500', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER RECRUTS 10', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_CHARACTER AUTO_ATTACK_RANGE 6', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_UNLIMITED_EQUIP', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_AUTO_DEFEND', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_AUTO_ATTACK', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_DEFEND_ALLIES', Txt, CurrEnd);
          Insert(EolA + '!SET_AI_ARMY_TYPE 3', Txt, CurrEnd);

          CurrLoc := CurrEnd;
        end;
      until (CurrLoc = 0);

      MP.SaveToFile(Txt, PathToMaps[I]);

      Memo1.Lines.Append(TruncateExt(ExtractFileName(PathToMaps[I])));
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


procedure TForm1.Button7Click(Sender: TObject);
var
  I: Integer;
  PathToMaps: TStringList;
  GoalLoc, GoalEnd: Integer;
  Txt, GoalTxt: AnsiString;
  MP: TKMMissionParserPatcher;
  Args: TStringList;
begin
  SetUp(True);

  Args := TStringList.Create;
  //@Krom: StrictDelimiter doesn't exist in D7
  //Args.StrictDelimiter := True;
  Args.Delimiter := ' ';

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Intent of this design is to rip the specified lines with least impact
    MP := TKMMissionParserPatcher.Create;

    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      //Show goals which have messages in them
      GoalLoc := 1;
      repeat
        //ADD_GOAL *condition* *status* MsgId *player_id*
        GoalLoc := PosEx('!ADD_GOAL ', Txt, GoalLoc);
        if GoalLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments

          //Look for command end marker (!, eol, /)
          GoalEnd := GoalLoc + 1;
          while (GoalEnd < Length(Txt)) and not (Txt[GoalEnd] in ['!', #13, '/']) do
            Inc(GoalEnd);

          GoalTxt := Copy(Txt, GoalLoc, GoalEnd - GoalLoc);
          GoalTxt := StringReplace(GoalTxt, '    ', ' ', [rfReplaceAll]);
          GoalTxt := StringReplace(GoalTxt, '   ', ' ', [rfReplaceAll]);
          GoalTxt := StringReplace(GoalTxt, '  ', ' ', [rfReplaceAll]);
          Args.DelimitedText := GoalTxt;
          //Is this a gcTime MsgId goal
          if Args[3] <> '0' then
          begin
            Memo1.Lines.Append(TruncateExt(ExtractFileName(PathToMaps[I])) + ' ' + GoalTxt);

            //Found only one case, so it was easier to fix by hand
            Inc(GoalLoc, Length(GoalTxt));
          end
          else
            Inc(GoalLoc, Length(GoalTxt));
        end;
      until (GoalLoc = 0);
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


procedure TForm1.Button8Click(Sender: TObject);
var
  I, K: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd: Integer;
  Txt: AnsiString;
  PlayerId: Integer;
  MP: TKMMissionParserPatcher;
  PlayersSet: array [0 .. MAX_HANDS - 1] of Boolean;
  s: string;
begin
  SetUp(True);

  //Intent of this design is to rip the specified lines with least impact
  MP := TKMMissionParserPatcher.Create;

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    if Pos('\MapsMP\', PathToMaps[I]) <> 0 then
    begin
      Txt := MP.ReadMissionFileWOChanges(PathToMaps[I]);

      //First pass, check if SET_USER_PLAYER is already placed
      //if at least one is there we assume this map should not be fixed
      if Pos('!SET_USER_PLAYER', Txt) <> 0 then Continue;

      //Show goals which have messages in them
      CurrLoc := 1;
      FillChar(PlayersSet, SizeOf(PlayersSet), #0);
      repeat
        //SET_CURR_PLAYER player_id
        CurrLoc := PosEx('!SET_CURR_PLAYER ', Txt, CurrLoc);
        if CurrLoc <> 0 then
        begin
          //Many maps have letters aligned in columns, meaning that
          //command length is varying cos of spaces between arguments
          //Look for command end marker (!, eol, /)
          CurrEnd := CurrLoc + 16;
          while (CurrEnd < Length(Txt)) and not (Txt[CurrEnd] in ['!', #13, '/']) do
            Inc(CurrEnd);

          s := Trim(Copy(Txt, CurrLoc + 16, CurrEnd - (CurrLoc + 16)));
          PlayerId := StrToInt(s);

          //Many times MP maps change CURR player to adjoin similar stuff in sections
          if not PlayersSet[PlayerId] then
          begin
            //Add from new line
            Insert(EolA + '!SET_USER_PLAYER ', Txt, CurrEnd);
            PlayersSet[PlayerId] := True;
          end;

          CurrLoc := CurrEnd;
        end;
      until (CurrLoc = 0);

      MP.SaveToFile(Txt, PathToMaps[I]);

      s := '';
      for K := 0 to MAX_HANDS - 1 do
        s := s + IfThen(PlayersSet[K], '1', '0');

      Memo1.Lines.Append(s + ' ' + TruncateExt(ExtractFileName(PathToMaps[I])));
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


//Delete command SET_NEW_REMAP from all maps (this command is unused) 
procedure TForm1.btnRemoveNewRemapClick(Sender: TObject);
var
  Parser: TKMMissionParserColorCheck;
  PathToMaps: TStringList;
  I, Deleted: Integer;
  Txt: AnsiString;
begin
  SetUp(True);

  Deleted := 0;
  PathToMaps := TStringList.Create;
  Parser := TKMMissionParserColorCheck.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);
    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := Parser.ReadMissionFileWOChanges(PathToMaps[I]);
      if Pos('SET_NEW_REMAP', Txt) <> 0 then
        Inc(Deleted);
      Txt := TRegEx.Replace(Txt, '!SET_NEW_REMAP.*'+EolA, '');
      Parser.SaveToFile(Txt, PathToMaps[I], False);
    end;
    Memo1.Lines.Append('SET_NEW_REMAP deleted from ' + IntToStr(Deleted) + ' maps');
    Memo1.Lines.Append('Checked ' + IntToStr(PathToMaps.Count) + ' maps');
  finally
    PathToMaps.Free;
    Parser.Free;
  end;
  TearDown;
end;


procedure TForm1.ResetCommands(var aCommands: TKMMissionColorInfoArray);
var
  I: Integer;
begin
  SetLength(aCommands, MAX_HANDS);
  for I := 0 to MAX_HANDS - 1 do
  begin
    // reset only Parsed, start and end should be overwritten
    aCommands[I].CurrPlayer.Parsed := False;
    aCommands[I].SetMapColor.Parsed := False;
    aCommands[I].SetRgbColor.Parsed := False;
  end;
end;


//Some maps have both SET_MAP_COLOR and SET_RGB_COLOR,
//SET_MAP_COLOR is always coming first, means SET_RGB_COLOR is always overriding color previously set by SET_MAP_COLOR.
//This method finds all such maps and deletes SET_MAP_COLOR command.
procedure TForm1.btnDeleteUnusedSetMapColorClick(Sender: TObject);
var
  I, J, K, TmpValue, ChangedCnt: Integer;
  Txt: AnsiString;
  PathToMaps: TStringList;
  Parser: TKMMissionParserColorCheck;
  Commands: TKMMissionColorInfoArray;
  DeleteColorFromPlayerArr: TIntegerArray;
  IsMapColorFirst: Boolean;
begin
  SetUp(True);

  SetLength(DeleteColorFromPlayerArr, MAX_HANDS);
  
  PathToMaps := TStringList.Create;
  Parser := TKMMissionParserColorCheck.Create;

  IsMapColorFirst := Sender = btnDeleteUnusedSetMapColor;

  ChangedCnt := 0;
  
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := Parser.ReadMissionFileWOChanges(PathToMaps[I]);

      ResetCommands(Commands);
        
      GetColorCommandsInfo(Txt, Commands);

      SetLength(DeleteColorFromPlayerArr, MAX_HANDS);
      //Save Hand indexes which have both color commands, where we want to delete SET_MAP_COLOR command 
      K := 0;
      for J := 0 to MAX_HANDS - 1 do
      begin
        if Commands[J].CurrPlayer.Parsed
          and Commands[J].SetMapColor.Parsed 
          and Commands[J].SetRgbColor.Parsed 
          and (IsMapColorFirst and (Commands[J].SetMapColor.StartPos < Commands[J].SetRgbColor.EndPos)
            or (not IsMapColorFirst and (Commands[J].SetMapColor.StartPos > Commands[J].SetRgbColor.EndPos))) then
        begin
          DeleteColorFromPlayerArr[K] := J;
          Inc(K);
        end;
      end;

      SetLength(DeleteColorFromPlayerArr, K);

      //Sort this hand indexes descending by command position in file
      for J := Low(DeleteColorFromPlayerArr) to High(DeleteColorFromPlayerArr) do
        for K := J + 1 to High(DeleteColorFromPlayerArr) do
          //Sort in reverse direction, because we want to start deleting from the end of file
          if Commands[DeleteColorFromPlayerArr[J]].SetMapColor.EndPos < Commands[DeleteColorFromPlayerArr[K]].SetMapColor.EndPos then
          begin
            TmpValue := DeleteColorFromPlayerArr[J];
            DeleteColorFromPlayerArr[J] := DeleteColorFromPlayerArr[K];
            DeleteColorFromPlayerArr[K] := TmpValue;
          end;

     if Length(DeleteColorFromPlayerArr) > 0 then
       Inc(ChangedCnt);   
      //Delete extra command from file    
      for J := Low(DeleteColorFromPlayerArr) to High(DeleteColorFromPlayerArr) do
        Delete(Txt, Commands[DeleteColorFromPlayerArr[J]].SetMapColor.StartPos - Length(EolA),
               Commands[DeleteColorFromPlayerArr[J]].SetMapColor.EndPos - Commands[DeleteColorFromPlayerArr[J]].SetMapColor.StartPos + Length(EolA));
        
      Parser.SaveToFile(Txt, PathToMaps[I], False);
    end;
    Memo1.Lines.Append('Checked ' + IntToStr(PathToMaps.Count) + ' maps' + EolA);
    Memo1.Lines.Append('Changed ' + IntToStr(ChangedCnt) + ' maps');
  finally
    PathToMaps.Free;
    FreeAndNil(Parser);
  end;

  TearDown;
end;


procedure TForm1.GetColorCommandsInfo(aTxt: AnsiString; var aColorInfoArray: TKMMissionColorInfoArray);
var
  CurrLoc, CurrEnd, NextCurrLoc: Integer;
  SetColorLoc, SetColorEnd: Integer;
  PlayerId: Integer;
  s: String;
begin
  CurrLoc := 1;
  repeat
    CurrLoc := PosEx('!SET_CURR_PLAYER ', aTxt, CurrLoc);
    if CurrLoc <> 0 then
    begin
      //Many maps have letters aligned in columns, meaning that
      //command length is varying cos of spaces between arguments
      //Look for command end marker (!, eol, /)
      CurrEnd := CurrLoc + 16;
      while not (aTxt[CurrEnd] in [#0, '!', #13, '/']) do
        Inc(CurrEnd);
      s := Trim(Copy(aTxt, CurrLoc + 16, CurrEnd - (CurrLoc + 16)));
      PlayerId := StrToInt(s);
      if InRange(PlayerId, 0, MAX_HANDS-1) 
        and not aColorInfoArray[PlayerId].CurrPlayer.Parsed then //If we parsed already CurrPlayer, then do not update its EndPos
      begin
        aColorInfoArray[PlayerId].CurrPlayer.Parsed := True;
        aColorInfoArray[PlayerId].CurrPlayer.EndPos := CurrEnd;
      end;

      NextCurrLoc := PosEx('!SET_CURR_PLAYER ', aTxt, CurrLoc+1);
      SetColorLoc := PosEx('!SET_MAP_COLOR', aTxt, CurrLoc+1);
      SetColorEnd := SetColorLoc + 14;

      while (SetColorEnd < Length(aTxt)) and not (aTxt[SetColorEnd] in ['!', #13, '/']) do
        Inc(SetColorEnd);
        
      if (SetColorLoc <> 0) and ((SetColorLoc < NextCurrLoc) or (NextCurrLoc = 0)) then
      begin
        aColorInfoArray[PlayerId].SetMapColor.Parsed := True;
        aColorInfoArray[PlayerId].SetMapColor.StartPos := SetColorLoc;
        aColorInfoArray[PlayerId].SetMapColor.EndPos := SetColorEnd;
      end;

      SetColorLoc := PosEx('!SET_RGB_COLOR', aTxt, CurrLoc+1);
      SetColorEnd := SetColorLoc + 14;

      while (SetColorEnd < Length(aTxt)) and not (aTxt[SetColorEnd] in ['!', #13, '/']) do
        Inc(SetColorEnd);
        
      if (SetColorLoc <> 0) and ((SetColorLoc < NextCurrLoc) or (NextCurrLoc = 0)) then
      begin
        aColorInfoArray[PlayerId].SetRgbColor.Parsed := True;
        aColorInfoArray[PlayerId].SetRgbColor.StartPos := SetColorLoc;
        aColorInfoArray[PlayerId].SetRgbColor.EndPos := SetColorEnd;
      end;

      CurrLoc := CurrEnd;
    end;
  until (CurrLoc = 0);
end;


function TForm1.CheckNoColorCommandsForAllMaps(var NoColorsMaps: TStringList; aSetMissingColor: Boolean): Integer;
var
  I: Integer;
  PathToMaps: TStringList;
  Parser: TKMMissionParserColorCheck;
  Txt: AnsiString;
  Commands: TKMMissionColorInfoArray;
begin
  PathToMaps := TStringList.Create;
  Parser := TKMMissionParserColorCheck.Create;

  NoColorsMaps.Clear;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);
    for I := 0 to PathToMaps.Count - 1 do
    begin
      Txt := Parser.ReadMissionFileWOChanges(PathToMaps[I]);

      ResetCommands(Commands);
      GetColorCommandsInfo(Txt, Commands);

      if not Parser.IsValid(Commands) then
      begin
        NoColorsMaps.Add(PathToMaps[I]);
        if aSetMissingColor then
        begin
          Parser.SetDefaultColorsForMission(Txt, Commands);
          Parser.SaveToFile(Txt, PathToMaps[I], False);
        end;
      end;
    end;
    Result := PathToMaps.Count;
  finally
    PathToMaps.Free;
    Parser.Free;
  end;
end;


//Check all players in all maps have at least one of commands SET_MAP_COLOR or SET_RGB_COLOR
//if Sender = btnSetDefColor, then For every player, who do have any of these commands add SET_RGB_COLOR command
procedure TForm1.btnCheckColorClick(Sender: TObject);
var
  I: Integer;
  NoColorMaps: TStringList;
  CheckedCnt: Integer;
  DoSetDefaultColors: Boolean;
begin
  SetUp(True);

  DoSetDefaultColors := Sender = btnSetDefColor;

  NoColorMaps := TStringList.Create;
  try
    CheckedCnt := CheckNoColorCommandsForAllMaps(NoColorMaps, DoSetDefaultColors);

    if NoColorMaps.Count = 0 then
      Memo1.Lines.Append('All maps have color commands SET_MAP_COLOR or SET_RGB_COLOR for every player')
    else
    begin
      if DoSetDefaultColors then
        Memo1.Lines.Append('Set default Colors for Maps:' + EolA)
      else
        Memo1.Lines.Append('Maps without SET_MAP_COLOR or SET_RGB_COLOR:' + EolA);

      for I := 0 to NoColorMaps.Count - 1 do
        Memo1.Lines.Append(TruncateExt(ExtractFileName(NoColorMaps[I])));

      if DoSetDefaultColors then
        Memo1.Lines.Append('Fixed maps total: ' + IntToStr(NoColorMaps.Count))
      else
        Memo1.Lines.Append('Not valid maps total: ' + IntToStr(NoColorMaps.Count));
    end;

    Memo1.Lines.Append('Checked ' + IntToStr(CheckedCnt) + ' maps');
  finally
    NoColorMaps.Free;
  end;

  TearDown;
end;


function TForm1.XorUnXor(UnXor: Boolean; F: TMemoryStream): Boolean;
var
  K, Num: Integer;
begin
  Result := False;
  if F.Size > 0 then
  begin
    //Detect whether mission is encoded so we can support decoded/encoded .DAT files
    //We can't test 1st char, it can be any. Instead see how often common chracters meet
    Num := 0;
    for K := 0 to F.Size - 1 do               //tab, eol, 0..9, space, !
    if PByte(Cardinal(F.Memory)+K)^ in [9,10,13,ord('0')..ord('9'),$20,$21] then
      Inc(Num);

    //Usually 30-50% is numerals/spaces, tested on typical KaM maps, take half of that as margin
    if (UnXOR and (Num/F.Size < 0.20))
    or (not UnXOR and (Num/F.Size > 0.20)) then
    begin
      for K := 0 to F.Size - 1 do
        PByte(Cardinal(F.Memory)+K)^ := PByte(Cardinal(F.Memory)+K)^ xor 239;
      Result := True;
    end;
  end
  else
    Result := False;
end;


procedure TForm1.btnXorAllClick(Sender: TObject);
var
  I: Integer;
  PathToMaps: TStringList;
  F: TMemoryStream;
  UnXOR: Boolean;
  MapCount: Integer;
begin
  SetUp(True);

  UnXOR := (Sender = btnUnXorAll);

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    MapCount := 0;
    for I := 0 to PathToMaps.Count - 1 do
    begin
      //Load and decode .DAT file into FileText
      F := TMemoryStream.Create;
      try
        F.LoadFromFile(PathToMaps[I]);
        if F.Size > 0 then
        begin
          if XorUnXor(UnXOR, F) then
            Inc(MapCount);
          F.SaveToFile(PathToMaps[I]);
        end else
          Memo1.Lines.Append('Mission file ' + ExtractFileName(PathToMaps[I]) + ' is empty');
      finally
        F.Free;
      end;
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(MapCount) + ' maps changed');

  TearDown;
end;


procedure TForm1.Button9Click(Sender: TObject);
var
  I: Integer;
  PathToMaps: TStringList;
  CurrLoc, CurrEnd, Replaced: Integer;
  ScriptFile, Txt: AnsiString;
  F: TMemoryStream;
begin
  SetUp(True);

  PathToMaps := TStringList.Create;
  try
    TKMapsCollection.GetAllMapPaths(ExeDir, PathToMaps);

    //Parse only MP maps
    for I := 0 to PathToMaps.Count - 1 do
    begin
      ScriptFile := ChangeFileExt(PathToMaps[I], '.script');
      if FileExists(ScriptFile) then
      begin
        F := TMemoryStream.Create;
        F.LoadFromFile(ScriptFile);
        SetLength(Txt, F.Size);
        F.Read(Txt[1], F.Size);

        Replaced := 0;
        CurrLoc := PosEx('States.Text(', Txt, 1);
        if CurrLoc = 0 then Continue;
        while CurrLoc <> 0 do
        begin
          Inc(Replaced);
          Txt := StuffString(Txt, CurrLoc, Length('States.Text('), '''<$');
          CurrEnd := PosEx(')', Txt, CurrLoc);
          Txt := StuffString(Txt, CurrEnd, Length(')'), '>''');

          CurrLoc := PosEx('States.Text(', Txt, CurrLoc);
        end;

        F.Clear;
        F.Write(Txt[1], Length(Txt));
        F.SaveToFile(ScriptFile);

        Memo1.Lines.Append(ScriptFile + ' - ' + IntToStr(Replaced));
      end;
    end;
  finally
    PathToMaps.Free;
  end;

  Memo1.Lines.Append(IntToStr(Memo1.Lines.Count));

  TearDown;
end;


{ TMissionParserColorCheck }
procedure TKMMissionParserColorCheck.SetDefaultColorsForMission(var aTxt: AnsiString; aCommands: TKMMissionColorInfoArray);
var
  IntArr: TIntegerArray;
  I, J, TmpValue, TotalOffset: Integer;
  InsertStr: AnsiString;
begin
  IntArr := GetPlayersWithoutColorArr(aCommands);

  //Sort first
  for I := Low(IntArr) to High(IntArr) do
    for J := I + 1 to High(IntArr) do
      if aCommands[IntArr[I]].CurrPlayer.EndPos > aCommands[IntArr[J]].CurrPlayer.EndPos then
      begin
        TmpValue := IntArr[I];
        IntArr[I] := IntArr[J];
        IntArr[J] := TmpValue;
      end;

  TotalOffset := 0;

  for I := Low(IntArr) to High(IntArr) do
  begin
    InsertStr := EolA + '!SET_RGB_COLOR ' + IntToStr(KAM_ORIGINAL_TEAM_COLORS[IntArr[I]]);
    Insert(InsertStr, aTxt, aCommands[IntArr[I]].CurrPlayer.EndPos + TotalOffset);
    Inc(TotalOffset, Length(InsertStr));
  end;
end;


function TKMMissionParserColorCheck.GetPlayersWithoutColorStr(aCommands: TKMMissionColorInfoArray): string;
var
  I: Integer;
  IntArr: TIntegerArray;
begin
  Result := '';
  IntArr := GetPlayersWithoutColorArr(aCommands);
  for I := Low(IntArr) to High(IntArr) do
  begin
    if Result <> '' then
      Result := Result + ' ';
    Result := Result + IntToStr(IntArr[I]);
  end;
end;


function TKMMissionParserColorCheck.GetPlayersWithoutColorArr(aCommands: TKMMissionColorInfoArray): TIntegerArray;
var
  I, J: Integer;
begin
  SetLength(Result, MAX_HANDS);

  J := 0;
  for I := 0 to MAX_HANDS - 1 do
    if aCommands[I].CurrPlayer.Parsed 
    and not (aCommands[I].SetMapColor.Parsed or aCommands[I].SetRgbColor.Parsed) then
    begin
      Result[J] := I;
      Inc(J);
    end;

  SetLength(Result, J);
end;


function TKMMissionParserColorCheck.IsValid(aCommands: TKMMissionColorInfoArray): Boolean;
var
  I: Integer;
begin
  Result := True;
  for I := 0 to MAX_HANDS - 1 do
    if aCommands[I].CurrPlayer.Parsed then
      Result := Result and (aCommands[I].SetMapColor.Parsed or aCommands[I].SetRgbColor.Parsed);
end;


end.
