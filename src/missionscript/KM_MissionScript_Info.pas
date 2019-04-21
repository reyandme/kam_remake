unit KM_MissionScript_Info;
{$I KaM_Remake.inc}
interface
uses
  KM_MissionScript, KM_Maps;


type
  TKMMissionParsing = (
    pmBase, //Load base map info for SP maplist (player count, tactic, description)
    pmExtra //Load extra map info to be displayed when map is selected (goals, alliances, etc)
    );


  TKMMissionParserInfo = class(TKMMissionParserCommon)
  private
    fMapInfo: TKMapInfo; //We are given this structure and asked to fill it
    function LoadMapInfo(const aFileName: string): Boolean;
  protected
    function ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''): Boolean; override;
  public
    function LoadMission(const aFileName: string; aMapInfo: TKMapInfo; aParsing: TKMMissionParsing): Boolean; reintroduce;
  end;


implementation
uses
  SysUtils, Math,
  KM_Resource,
  KM_CommonClasses, KM_Defaults, KM_Utils;


{ TMissionParserInfo }
function TKMMissionParserInfo.LoadMission(const aFileName: string; aMapInfo: TKMapInfo; aParsing: TKMMissionParsing): Boolean;
const
  CommandsBase: array [0..3] of AnsiString = (
    '!SET_MAX_PLAYER', '!SET_TACTIC', '!SET_CURR_PLAYER', '!SET_USER_PLAYER');
  CommandsExtra: array [0..11] of AnsiString = (
    '!SET_MAX_PLAYER', '!SET_TACTIC',
    '!SET_CURR_PLAYER', '!SET_HUMAN_PLAYER', '!SET_USER_PLAYER',
    '!SET_AI_PLAYER', '!SET_ADVANCED_AI_PLAYER', '!ADD_GOAL', '!ADD_LOST_GOAL', '!SET_ALLIANCE', '!SET_MAP_COLOR', '!SET_RGB_COLOR');
var
  FileText: AnsiString;
begin
  fMapInfo := aMapInfo;

  inherited LoadMission(aFileName);

  Result := False;

  FileText := ReadMissionFile(aFileName);
  if FileText = '' then
    Exit;

  //For info we need only few commands,
  //it makes sense to skip the rest
  case aParsing of
    pmBase:   if not TokenizeScript(FileText, 4, CommandsBase) then Exit;
    pmExtra:  if not TokenizeScript(FileText, 4, CommandsExtra) then Exit;
  end;

  if not LoadMapInfo(ChangeFileExt(fMissionFileName, '.map')) then
    Exit;

  Result := fFatalErrors = '';
end;


function TKMMissionParserInfo.ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''): Boolean;
begin
  case CommandType of
    ctSetMaxPlayer:    fMapInfo.LocCount := P[0];

    ctSetTactic:       fMapInfo.MissionMode := mmTactic;

    ctSetCurrPlayer:   fLastHand := P[0];

    ctHumanPlayer:     begin
                          //Default human player can be human, obviously
                          fMapInfo.DefaultHuman     := P[0];
                          fMapInfo.CanBeHuman[P[0]] := True;
                        end;

    ctUserPlayer:      if P[0] = -1 then
                          fMapInfo.CanBeHuman[fLastHand] := True
                        else
                          fMapInfo.CanBeHuman[P[0]] := True;

    ctAIPlayer:       if P[0] = -1 then
                          fMapInfo.CanBeAI[fLastHand] := True
                        else
                          fMapInfo.CanBeAI[P[0]] := True;

    ctAdvancedAIPlayer:if P[0] = -1 then
                          fMapInfo.CanBeAdvancedAI[fLastHand] := True
                        else
                          fMapInfo.CanBeAdvancedAI[P[0]] := True;

    ctAddGoal:         if fLastHand >= 0 then
                          //If the condition is time then P[3] is the time, else it is player ID
                          if TKMGoalCondition(P[0]) = gcTime then
                            fMapInfo.AddGoal(gltVictory, fLastHand, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), -1)
                          else
                            fMapInfo.AddGoal(gltVictory, fLastHand, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), P[3]);

    ctAddLostGoal:     if fLastHand >= 0 then
                          //If the condition is time then P[3] is the time, else it is player ID
                          if TKMGoalCondition(P[0]) = gcTime then
                            fMapInfo.AddGoal(gltSurvive, fLastHand, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), -1)
                          else
                            fMapInfo.AddGoal(gltSurvive, fLastHand, TKMGoalCondition(P[0]), TKMGoalStatus(P[1]), P[3]);

    ctSetAlliance:     if (fLastHand >= 0) and (P[0] <> fLastHand) then //Can't be enemies with yourself
                          if P[1] = 1 then
                            fMapInfo.Alliances[fLastHand, P[0]] := atAlly
                          else
                            fMapInfo.Alliances[fLastHand, P[0]] := atEnemy;

    ctSetMapColor:     if fLastHand >= 0 then
                          //For now simply use the minimap color for all color, it is too hard to load all 8 shades from ctSetNewRemap
                          fMapInfo.FlagColors[fLastHand] := gRes.Palettes.DefaultPalette.Color32(P[0]);

    ctSetRGBColor:     if fLastHand >= 0 then
                          fMapInfo.FlagColors[fLastHand] := P[0] or $FF000000;
  end;

  Result := True;
end;


//Acquire essential terrain details
function TKMMissionParserInfo.LoadMapInfo(const aFileName: string): Boolean;
var
  S: TKMemoryStream;
  newX, newY: Integer;
  ErrorStr: UnicodeString;
begin
  Result := False;
  if not FileExists(aFileName) then Exit;

  ErrorStr := '';
  S := TKMemoryStream.Create;
  try
    S.LoadFromFile(aFileName);
    try
      LoadMapHeader(S, newX, newY);
    except
      on E: Exception do
        ErrorStr := E.Message;
    end;
  finally
    S.Free;
  end;

  if ErrorStr <> '' then
  begin
    AddError(ErrorStr, True);
    Exit;
  end;

  fMapInfo.MapSizeX := newX;
  fMapInfo.MapSizeY := newY;
  Result := True;
end;


end.
