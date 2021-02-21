unit KM_MissionScript;
{$I KaM_Remake.inc}
interface
uses
  KM_Defaults;


type
  TKMMissionParsingMode = (
                          mpmSingle,
                          mpmMulti,  //Skip players
                          mpmEditor  //Ignore errors, load armies differently
                        );

  TKMCommandType = (
    ctUnknown = 0,
    ctSetMap,
    ctSetMaxPlayer,
    ctSetCurrPlayer,
    ctHumanPlayer,
    ctUserPlayer,
    ctSetHouse,
    ctSetTactic,
    ctAIPlayer,
    ctAdvancedAIPlayer,
    ctEnablePlayer,
    ctSetNewRemap,
    ctSetMapColor,
    ctSetRGBColor,
    ctCenterScreen,
    ctChooseLoc,
    ctChooseLocAddWare,
    ctChooseLocAddUnit,
    ctClearUp,
    ctBlockTrade,
    ctBlockUnit,
    ctBlockHouse,
    ctReleaseHouse,
    ctReleaseAllHouses,
    ctAddGoal,
    ctAddLostGoal,
    ctSetUnit,
    ctSetRoad,
    ctSetField,
    ctSetWinefield,
    ctSetFieldStaged,
    ctSetWinefieldStaged,
    ctSetStock,
    ctAddWare,
    ctSetAlliance,
    ctSetHouseDamage,
    ctSetHouseDeliveryMode,
    ctSetHouseRepairMode,
    ctSetHouseClosedForWorker,
    ctSetUnitByStock,
    ctUnitAddToLast,
    ctSetUnitFood,
    ctSetGroup,
    ctSetGroupFood,
    ctSendGroup,
    ctAttackPosition,
    ctAddWareToSecond,
    ctAddWareTo,
    ctAddWareToLast,
    ctAddWareToAll,
    ctAddWeapon,
    ctAICharacter,
    ctAINoBuild,
    ctAIAutoRepair,
    ctAIAutoAttack,
    ctAIAutoDefend,
    ctAIDefendAllies,
    ctAIUnlimitedEquip,
    ctAIArmyType,
    ctAIStartPosition,
    ctAIDefence,
    ctAIAttack,
    ctCopyAIAttack,
    ctClearAIAttack,
    ctSetRallyPoint);

const
  COMMANDVALUES: array [TKMCommandType] of AnsiString = (
    '',
    'SET_MAP',
    'SET_MAX_PLAYER',
    'SET_CURR_PLAYER',
    'SET_HUMAN_PLAYER', //Default human player (name left for compatibility with KaM)
    'SET_USER_PLAYER', //Player can be human
    'SET_HOUSE',
    'SET_TACTIC',
    'SET_AI_PLAYER', //Player can be AI
    'SET_ADVANCED_AI_PLAYER', //Player can be Advanced AI
    'ENABLE_PLAYER',
    'SET_NEW_REMAP',
    'SET_MAP_COLOR',
    'SET_RGB_COLOR',
    'CENTER_SCREEN',
    'CHOOSE_LOC',
    'CHOOSE_LOC_ADD_WARE',
    'CHOOSE_LOC_ADD_UNIT',
    'CLEAR_UP',
    'BLOCK_TRADE',
    'BLOCK_UNIT',
    'BLOCK_HOUSE',
    'RELEASE_HOUSE',
    'RELEASE_ALL_HOUSES',
    'ADD_GOAL',
    'ADD_LOST_GOAL',
    'SET_UNIT',
    'SET_STREET',
    'SET_FIELD',
    'SET_WINEFIELD',
    'SET_FIELD_STAGED',
    'SET_WINEFIELD_STAGED',
    'SET_STOCK','ADD_WARE',
    'SET_ALLIANCE',
    'SET_HOUSE_DAMAGE',
    'SET_HOUSE_DELIVERY_MODE',
    'SET_HOUSE_REPAIR_MODE',
    'SET_HOUSE_CLOSED_FOR_WORKER',
    'SET_UNIT_BY_STOCK',
    'ADD_UNIT_TO_LAST',
    'SET_UNIT_FOOD',
    'SET_GROUP',
    'SET_GROUP_FOOD',
    'SEND_GROUP',
    'ATTACK_POSITION',
    'ADD_WARE_TO_SECOND',
    'ADD_WARE_TO',
    'ADD_WARE_TO_LAST',
    'ADD_WARE_TO_ALL',
    'ADD_WEAPON',
    'SET_AI_CHARACTER',
    'SET_AI_NO_BUILD',
    'SET_AI_AUTO_REPAIR',
    'SET_AI_AUTO_ATTACK',
    'SET_AI_AUTO_DEFEND',
    'SET_AI_DEFEND_ALLIES',
    'SET_AI_UNLIMITED_EQUIP',
    'SET_AI_ARMY_TYPE',
    'SET_AI_START_POSITION',
    'SET_AI_DEFENSE',
    'SET_AI_ATTACK',
    'COPY_AI_ATTACK',
    'CLEAR_AI_ATTACK',
    'SET_RALLY_POINT');

type
  TKMMissionParserCommon = class
  protected
    fMissionFileName: string;
    fLastHand: TKMHandID; //Current Player

    // Fatal errors generate exceptions
    // Minor error descriptions accumulate here
    fMinorErrors: string;

    function TextToCommandType(const ACommandText: AnsiString): TKMCommandType;
    function ReadMissionFile(const aFileName: string): AnsiString;
    procedure TokenizeScript(const aText: AnsiString; aMaxCmd: Byte; aCommands: array of AnsiString);
    procedure ProcessCommand(CommandType: TKMCommandType; P: array of Integer; const TextParam: AnsiString = ''); virtual; abstract;
    procedure AddError(const ErrorMsg: string);
  public
    property MinorErrors: string read fMinorErrors;
    procedure LoadMission(const aFileName: string); virtual;
  end;


implementation
uses
  Classes, SysUtils;


{ TMissionParserCommon }
procedure TKMMissionParserCommon.LoadMission(const aFileName: string);
begin
  fMissionFileName := aFileName;
  fLastHand := -1;
end;


function TKMMissionParserCommon.TextToCommandType(const ACommandText: AnsiString): TKMCommandType;
var
  I: TKMCommandType;
begin
  Result := ctUnknown;

  for I := Low(TKMCommandType) to High(TKMCommandType) do
  begin
    if ACommandText = '!' + COMMANDVALUES[I] then
    begin
      Result := I;
      Break;
    end;
  end;

  //Commented out because it slows down mission scanning
  //if Result = ctUnknown then gLog.AddToLog(String(ACommandText));
end;


//Read mission file to a string and if necessary - decode it
function TKMMissionParserCommon.ReadMissionFile(const aFileName: string): AnsiString;
var
  I,Num: Cardinal;
  F: TMemoryStream;
begin
  if not FileExists(aFileName) then
    raise Exception.Create(Format('Mission file %s could not be found', [aFileName]));

  //Load and decode .DAT file into FileText
  F := TMemoryStream.Create;
  try
    F.LoadFromFile(aFileName);

    if F.Size = 0 then
      raise Exception.Create(Format('Mission file %s is empty', [aFileName]));

    //Detect whether mission is encoded so we can support decoded/encoded .DAT files
    //We can't test 1st char, it can be any. Instead see how often common chracters meet
    Num := 0;
    for I:=0 to F.Size-1 do               //tab, eol, 0..9, space, !
      if PByte(Cardinal(F.Memory)+I)^ in [9,10,13,ord('0')..ord('9'),$20,$21] then
        inc(Num);

    //Usually 30-50% is numerals/spaces, tested on typical KaM maps, take half of that as margin
    if (Num/F.Size < 0.20) then
    for I := 0 to F.Size - 1 do
      PByte(Cardinal(F.Memory)+I)^ := PByte(Cardinal(F.Memory)+I)^ xor 239;

    //Save text after decoding but before cleaning
    if WRITE_DECODED_MISSION then
      F.SaveToFile(aFileName + '.txt');

    for I := 0 to F.Size - 1 do
      if PByte(Cardinal(F.Memory)+I)^ in [9, 10, 13] then //tab, eol
        PByte(Cardinal(F.Memory)+I)^ := $20; //Space

    Num := 0;
    for I := 0 to F.Size - 1 do
    begin
      PByte(Cardinal(F.Memory)+Num)^ := PByte(Cardinal(F.Memory)+I)^;
      if (Num <= 0)
      or (
          (PWord(Cardinal(F.Memory) + Num-1)^ <> $2020) //Skip double spaces and !!
      and (PWord(Cardinal(F.Memory) + Num-1)^ <> $2121)) then
        Inc(Num);
    end;

    SetLength(Result, Num); //Because some extra characters were removed
    F.Position := 0;
    F.ReadBuffer(Result[1], Num);
  finally
    F.Free;
  end;
  //FileText should now be formatted nicely with 1 space between each parameter/command
end;


procedure TKMMissionParserCommon.TokenizeScript(const aText: AnsiString; aMaxCmd: Byte; aCommands: array of AnsiString);
var
  CommandText, strParam, TextParam: AnsiString;
  ParamList: array of Integer;
  I, K, intParam: Integer;
  CommandType: TKMCommandType;
  J: Integer;
  DoProcess: Boolean;
begin
  SetLength(ParamList, aMaxCmd);

  I := 1;
  repeat
    if aText[I] = '!' then
    begin
      //Default uninitialized values
      TextParam := '';
      CommandText := '';
      for K := 0 to aMaxCmd - 1 do
        ParamList[K] := -1;

      //Extract command until a space
      repeat
        CommandText := CommandText + aText[I];
        Inc(I);
      until((aText[I] = #32) or (I >= Length(aText)));

      //We can skip certain commands to speed up the scan
      //for implementations that need only Preview/Info
      DoProcess := Length(aCommands) = 0;
      for J := Low(aCommands) to High(aCommands) do
      if (CommandText = aCommands[J]) then
        DoProcess := True;

      if DoProcess then
      begin
        //Now convert command into type
        CommandType := TextToCommandType(CommandText);
        Inc(I);
        //Extract parameters
        for K := 0 to aMaxCmd - 1 do
          if (I < Length(aText)) and (aText[I] <> '!') then
          begin
            strParam := '';
            repeat
              strParam := strParam + aText[I];
              Inc(I);
            until((I >= Length(aText)) or (aText[I] = '!') or (aText[I] = #32)); //Until we find another ! OR we run out of data

            //Convert to an integer, if possible
            if TryStrToInt(string(strParam), intParam) then
              ParamList[K] := intParam
            else
              if K = 0 then
                TextParam := strParam; //Accept text for first parameter

            if (I <= Length(aText)) and (aText[I] = #32) then
              Inc(I);
          end;

        // We now have command text and parameters, so process them
        ProcessCommand(CommandType, ParamList, TextParam);
      end;
    end
    else
      Inc(I);
  until (I >= Length(aText));
end;


// A nice way of debugging script errors.
// Shows the error to the user so they know exactly what they did wrong.
procedure TKMMissionParserCommon.AddError(const ErrorMsg: string);
begin
    fMinorErrors := fMinorErrors + ErrorMsg + '|';
end;


end.
