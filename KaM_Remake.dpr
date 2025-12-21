program KaM_Remake;
{$I KaM_Remake.inc}
uses
  //{$IFDEF WDC} FastMM5, {$ENDIF} //Can be used only in Delphi, not Lazarus
  //{$IFDEF WDC} FastMM4, {$ENDIF} //Can be used only in Delphi, not Lazarus
  {$IFDEF USE_MAD_EXCEPT}
  madExcept,
  madLinkDisAsm,
  madListHardware,
  madListModules,
  {$ENDIF}
  {$IFDEF UNIX} cthreads, {$ENDIF} //Required for thread support on Unix/Linux
  Forms,
  Dialogs,
  {$IFDEF WDC} 
    WinApi.Windows, // To allow to set {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE} for 3Gb or 4Gb RAM usage for Win32 Delphi app
  {$ENDIF}

  {$IFDEF WDC} UITypes, {$ENDIF} // For MessageDlg invoked from this file
  {$IFDEF FPC} Interfaces, {$ENDIF}
  KM_FormMain in 'src\forms\KM_FormMain.pas' {FormMain},
  KM_FormLogistics in 'src\forms\KM_FormLogistics.pas' {FormLogistics},
  KM_FormLoading in 'src\forms\KM_FormLoading.pas' {FormLoading},

  KM_VclMenuHint in 'src\forms\KM_VclMenuHint.pas',
  KM_VclHelpers in 'src\forms\KM_VclHelpers.pas',

  iaWin.NameDelphiThreads in 'src\ext\iaWin.NameDelphiThreads.pas',
  
  uPSCompiler in 'src\ext\pascalscript_submodule\Source\uPSCompiler.pas',
  uPSDebugger in 'src\ext\pascalscript_submodule\Source\uPSDebugger.pas',
  uPSDisassembly in 'src\ext\pascalscript_submodule\Source\uPSDisassembly.pas',
  uPSPreProcessor in 'src\ext\pascalscript_submodule\Source\uPSPreProcessor.pas',
  uPSRuntime in 'src\ext\pascalscript_submodule\Source\uPSRuntime.pas',
  uPSUtils in 'src\ext\pascalscript_submodule\Source\uPSUtils.pas',

  KM_AI in 'src\ai\KM_AI.pas',
  KM_AIArmyEvaluation in 'src\ai\KM_AIArmyEvaluation.pas',
  KM_AIAttacks in 'src\ai\KM_AIAttacks.pas',
  KM_AICityPlanner in 'src\ai\KM_AICityPlanner.pas',
  KM_AIDefensePos in 'src\ai\KM_AIDefensePos.pas',
  KM_AIFields in 'src\ai\KM_AIFields.pas',
  KM_AIGeneral in 'src\ai\KM_AIGeneral.pas',
  KM_AIGoals in 'src\ai\KM_AIGoals.pas',
  KM_AIInfluences in 'src\ai\KM_AIInfluences.pas',
  KM_AIMayor in 'src\ai\KM_AIMayor.pas',
  KM_AIMayorBalance in 'src\ai\KM_AIMayorBalance.pas',
  KM_AISetup in 'src\ai\KM_AISetup.pas',
  KM_AITypes in 'src\ai\KM_AITypes.pas',

  KM_ArmyAttackNew in 'src\ai\newAI\KM_ArmyAttackNew.pas',
  KM_ArmyDefence in 'src\ai\newAI\KM_ArmyDefence.pas',
  KM_ArmyManagement in 'src\ai\newAI\KM_ArmyManagement.pas',
  KM_Eye in 'src\ai\newAI\KM_Eye.pas',
  KM_CityBuilder in 'src\ai\newAI\KM_CityBuilder.pas',
  KM_CityManagement in 'src\ai\newAI\KM_CityManagement.pas',
  KM_CityPlanner in 'src\ai\newAI\KM_CityPlanner.pas',
  KM_CityPredictor in 'src\ai\newAI\KM_CityPredictor.pas',
  KM_Supervisor in 'src\ai\newAI\KM_Supervisor.pas',
  KM_AIParameters in 'src\ai\newAI\KM_AIParameters.pas',

  KM_CommonClasses in 'src\common\KM_CommonClasses.pas',
  KM_CommonClassesExt in 'src\common\KM_CommonClassesExt.pas',
  KM_CommonExceptions in 'src\common\KM_CommonExceptions.pas',
  KM_CommonGameTypes in 'src\common\KM_CommonGameTypes.pas',
  KM_CommonTypes in 'src\common\KM_CommonTypes.pas',
  KM_Defaults in 'src\common\KM_Defaults.pas',
  KM_Entity in 'src\common\KM_Entity.pas',
  KM_Lists in 'src\common\KM_Lists.pas',
  KM_Points in 'src\common\KM_Points.pas',
  KM_WorkerThread in 'src\common\KM_WorkerThread.pas',
  KM_WorkerThreadUtils in 'src\common\KM_WorkerThreadUtils.pas',

  KM_Console in 'src\KM_Console.pas',
  
  KM_Controls in 'src\controls\KM_Controls.pas',
  KM_ControlsBase in 'src\controls\KM_ControlsBase.pas',
  KM_ControlsChart in 'src\controls\KM_ControlsChart.pas',
  KM_ControlsColor in 'src\controls\KM_ControlsColor.pas',
  KM_ControlsDragger in 'src\controls\KM_ControlsDragger.pas',
  KM_ControlsDrop in 'src\controls\KM_ControlsDrop.pas',
  KM_ControlsEdit in 'src\controls\KM_ControlsEdit.pas',
  KM_ControlsForm in 'src\controls\KM_ControlsForm.pas',
  KM_ControlsList in 'src\controls\KM_ControlsList.pas',
  KM_ControlsMemo in 'src\controls\KM_ControlsMemo.pas',
  KM_ControlsMinimapView in 'src\controls\KM_ControlsMinimapView.pas',
  KM_ControlsPopUp in 'src\controls\KM_ControlsPopUp.pas',
  KM_ControlsProgressBar in 'src\controls\KM_ControlsProgressBar.pas',
  KM_ControlsScroll in 'src\controls\KM_ControlsScroll.pas',
  KM_ControlsSwitch in 'src\controls\KM_ControlsSwitch.pas',
  KM_ControlsTrackBar in 'src\controls\KM_ControlsTrackBar.pas',
  KM_ControlsTypes in 'src\controls\KM_ControlsTypes.pas',
  KM_ControlsUtils in 'src\controls\KM_ControlsUtils.pas',
  KM_ControlsWaresRow in 'src\controls\KM_ControlsWaresRow.pas',

  {$IFDEF USE_MAD_EXCEPT} KM_Crashreport in 'src\KM_Crashreport.pas', {$ENDIF}

  KM_DevPerfLog in 'src\perflog\KM_DevPerfLog.pas',
  KM_DevPerfLogForm in 'src\perflog\KM_DevPerfLogForm.pas',
  KM_DevPerfLogSingle in 'src\perflog\KM_DevPerfLogSingle.pas',
  KM_DevPerfLogStack in 'src\perflog\KM_DevPerfLogStack.pas',
  KM_DevPerfLogTypes in 'src\perflog\KM_DevPerfLogTypes.pas',

  {$IFDEF USE_MAD_EXCEPT} KM_Exceptions in 'src\KM_Exceptions.pas', {$ENDIF}

  KM_Game in 'src\game\KM_Game.pas',
  KM_GameClasses in 'src\game\KM_GameClasses.pas',
  KM_GameTypes in 'src\game\KM_GameTypes.pas',
  KM_GameInfo in 'src\game\KM_GameInfo.pas',
  KM_GameOptions in 'src\game\KM_GameOptions.pas',
  KM_GameParams in 'src\game\KM_GameParams.pas',
  KM_GameSavePoints in 'src\game\KM_GameSavePoints.pas',
  KM_FogOfWar in 'src\game\KM_FogOfWar.pas',
  
  KM_GameInputProcess in 'src\game\gip\KM_GameInputProcess.pas',
  KM_GameInputProcess_Multi in 'src\game\gip\KM_GameInputProcess_Multi.pas',
  KM_GameInputProcess_Single in 'src\game\gip\KM_GameInputProcess_Single.pas',
  
  KM_GameUIDTracker in 'src\game\misc\KM_GameUIDTracker.pas',
  {$IFDEF DBG_RNG_SPY} KM_RandomChecks in 'src\game\misc\KM_RandomChecks.pas', {$ENDIF}
  
  KM_Alerts in 'src\game\notifications\KM_Alerts.pas',
  KM_MessageLog in 'src\game\notifications\KM_MessageLog.pas',
  KM_MessageStack in 'src\game\notifications\KM_MessageStack.pas',  

  KM_Cursor in 'src\gui\KM_Cursor.pas',
  KM_InterfaceDefaults in 'src\gui\KM_InterfaceDefaults.pas',
  KM_InterfaceGame in 'src\gui\KM_InterfaceGame.pas',
  KM_InterfaceGamePlay in 'src\gui\KM_InterfaceGamePlay.pas',
  KM_InterfaceMainMenu in 'src\gui\KM_InterfaceMainMenu.pas',
  KM_InterfaceMapEditor in 'src\gui\KM_InterfaceMapEditor.pas',
  KM_InterfaceTypes in 'src\gui\KM_InterfaceTypes.pas',
  KM_Viewport in 'src\gui\KM_Viewport.pas',

  KM_GUICommonKeys in 'src\gui\pages_common\KM_GUICommonKeys.pas',
  KM_GUICommonGameOptions in 'src\gui\pages_common\KM_GUICommonGameOptions.pas',
  KM_GUICommonOptions in 'src\gui\pages_common\KM_GUICommonOptions.pas',
  
  KM_GUIGameBuild in 'src\gui\pages_game\KM_GUIGameBuild.pas',
  KM_GUIGameChat in 'src\gui\pages_game\KM_GUIGameChat.pas',
  KM_GUIGameHouse in 'src\gui\pages_game\KM_GUIGameHouse.pas',
  KM_GUIGameUnit in 'src\gui\pages_game\KM_GUIGameUnit.pas',
  KM_GUIGameRatios in 'src\gui\pages_game\KM_GUIGameRatios.pas',
  KM_GUIGameStats in 'src\gui\pages_game\KM_GUIGameStats.pas',
  KM_GUIGameResultsMP in 'src\gui\pages_game\KM_GUIGameResultsMP.pas',
  KM_GUIGameResultsSP in 'src\gui\pages_game\KM_GUIGameResultsSP.pas',
  KM_GUIGameSpectator in 'src\gui\pages_game\KM_GUIGameSpectator.pas',
  KM_GUIGameSpectatorItemLines in 'src\gui\pages_game\KM_GUIGameSpectatorItemLines.pas',

  KM_GUIMapEdExtras in 'src\gui\pages_maped\KM_GUIMapEdExtras.pas',
  KM_GUIMapEdHouse in 'src\gui\pages_maped\KM_GUIMapEdHouse.pas',
  KM_GUIMapEdMarkerDefence in 'src\gui\pages_maped\KM_GUIMapEdMarkerDefence.pas',
  KM_GUIMapEdMarkerReveal in 'src\gui\pages_maped\KM_GUIMapEdMarkerReveal.pas',
  
  KM_GUIMapEdMenu in 'src\gui\pages_maped\menu\KM_GUIMapEdMenu.pas',
  KM_GUIMapEdMenuLoad in 'src\gui\pages_maped\menu\KM_GUIMapEdMenuLoad.pas',
  KM_GUIMapEdMenuSave in 'src\gui\pages_maped\menu\KM_GUIMapEdMenuSave.pas',
  KM_GUIMapEdMenuResize in 'src\gui\pages_maped\menu\KM_GUIMapEdMenuResize.pas',
  KM_GUIMapEdMenuQuickPlay in 'src\gui\pages_maped\menu\KM_GUIMapEdMenuQuickPlay.pas',
  KM_GUIMapEdMenuQuit in 'src\gui\pages_maped\menu\KM_GUIMapEdMenuQuit.pas',

  KM_GUIMapEdMessage in 'src\gui\pages_maped\KM_GUIMapEdMessage.pas',

  KM_GUIMapEdPlayer in 'src\gui\pages_maped\player\KM_GUIMapEdPlayer.pas',
  KM_GUIMapEdPlayerBlockHouse in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerBlockHouse.pas',
  KM_GUIMapEdPlayerBlockTrade in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerBlockTrade.pas',
  KM_GUIMapEdPlayerBlockUnit in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerBlockUnit.pas',
  KM_GUIMapEdPlayerColors in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerColors.pas',
  KM_GUIMapEdPlayerGoals in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerGoals.pas',
  KM_GUIMapEdPlayerGoalPopUp in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerGoalPopUp.pas',
  KM_GUIMapEdPlayerView in 'src\gui\pages_maped\player\KM_GUIMapEdPlayerView.pas',

  KM_GUIMapEdMission in 'src\gui\pages_maped\mission\KM_GUIMapEdMission.pas',
  KM_GUIMapEdMissionAlliances in 'src\gui\pages_maped\mission\KM_GUIMapEdMissionAlliances.pas',
  KM_GUIMapEdMissionMode in 'src\gui\pages_maped\mission\KM_GUIMapEdMissionMode.pas',
  KM_GUIMapEdMissionPlayers in 'src\gui\pages_maped\mission\KM_GUIMapEdMissionPlayers.pas',

  KM_GUIMapEdRMG in 'src\gui\pages_maped\terrain\KM_GUIMapEdRMG.pas',
  KM_GUIMapEdTerrain in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrain.pas',
  KM_GUIMapEdTerrainBrushes in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainBrushes.pas',
  KM_GUIMapEdTerrainHeights in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainHeights.pas',
  KM_GUIMapEdTerrainTiles in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainTiles.pas',
  KM_GUIMapEdTerrainObjects in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainObjects.pas',
  KM_GUIMapEdTerrainOverlays in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainOverlays.pas',
  KM_GUIMapEdTerrainSelection in 'src\gui\pages_maped\terrain\KM_GUIMapEdTerrainSelection.pas',

  KM_GUIMapEdTown in 'src\gui\pages_maped\town\KM_GUIMapEdTown.pas',
  KM_GUIMapEdTownUnits in 'src\gui\pages_maped\town\KM_GUIMapEdTownUnits.pas',
  KM_GUIMapEdTownHouses in 'src\gui\pages_maped\town\KM_GUIMapEdTownHouses.pas',
  KM_GUIMapEdTownScript in 'src\gui\pages_maped\town\KM_GUIMapEdTownScript.pas',
  KM_GUIMapEdTownDefence in 'src\gui\pages_maped\town\KM_GUIMapEdTownDefence.pas',
  KM_GUIMapEdTownOffence in 'src\gui\pages_maped\town\KM_GUIMapEdTownOffence.pas',
  KM_GUIMapEdTownAttackPopUp in 'src\gui\pages_maped\town\KM_GUIMapEdTownAttackPopUp.pas',
  KM_GUIMapEdTownFormationsPopUp in 'src\gui\pages_maped\town\KM_GUIMapEdTownFormationsPopUp.pas',

  KM_GUIMapEdUnit in 'src\gui\pages_maped\KM_GUIMapEdUnit.pas',

  KM_GUIMenuCampaign in 'src\gui\pages_menu\KM_GUIMenuCampaign.pas',
  KM_GUIMenuCampaigns in 'src\gui\pages_menu\KM_GUIMenuCampaigns.pas',
  KM_GUIMenuCredits in 'src\gui\pages_menu\KM_GUIMenuCredits.pas',
  KM_GUIMenuError in 'src\gui\pages_menu\KM_GUIMenuError.pas',
  KM_GUIMenuLoad in 'src\gui\pages_menu\KM_GUIMenuLoad.pas',
  KM_GUIMenuLoading in 'src\gui\pages_menu\KM_GUIMenuLoading.pas',
  KM_GUIMenuLobby in 'src\gui\pages_menu\KM_GUIMenuLobby.pas',
  KM_GUIMenuMain in 'src\gui\pages_menu\KM_GUIMenuMain.pas',
  KM_GUIMenuMapEditor in 'src\gui\pages_menu\KM_GUIMenuMapEditor.pas',
  KM_GUIMenuMultiplayer in 'src\gui\pages_menu\KM_GUIMenuMultiplayer.pas',
  KM_GUIMenuOptions in 'src\gui\pages_menu\KM_GUIMenuOptions.pas',
  KM_GUIMenuReplays in 'src\gui\pages_menu\KM_GUIMenuReplays.pas',
  KM_GUIMenuSingleMap in 'src\gui\pages_menu\KM_GUIMenuSingleMap.pas',
  KM_GUIMenuSinglePlayer in 'src\gui\pages_menu\KM_GUIMenuSinglePlayer.pas',

  KM_Hand in 'src\hands\KM_Hand.pas',
  KM_HandsCollection in 'src\hands\KM_HandsCollection.pas',
  KM_HandConstructions in 'src\hands\KM_HandConstructions.pas',
  KM_HandEntity in 'src\hands\KM_HandEntity.pas',
  KM_HandEntityHelper in 'src\hands\KM_HandEntityHelper.pas',
  KM_HandLocks in 'src\hands\KM_HandLocks.pas',
  KM_HandLogistics in 'src\hands\KM_HandLogistics.pas',
  KM_HandSpectator in 'src\hands\KM_HandSpectator.pas',
  KM_HandStats in 'src\hands\KM_HandStats.pas',
  KM_HandTypes in 'src\hands\KM_HandTypes.pas',
  KM_WareDistribution in 'src\hands\KM_WareDistribution.pas',

  KM_HouseArmorWorkshop in 'src\houses\KM_HouseArmorWorkshop.pas',
  KM_HouseBarracks in 'src\houses\KM_HouseBarracks.pas',
  KM_HouseInn in 'src\houses\KM_HouseInn.pas',
  KM_HouseCollection in 'src\houses\KM_HouseCollection.pas',
  KM_HouseMarket in 'src\houses\KM_HouseMarket.pas',
  KM_Houses in 'src\houses\KM_Houses.pas',
  KM_HouseSchool in 'src\houses\KM_HouseSchool.pas',
  KM_HouseStore in 'src\houses\KM_HouseStore.pas',
  KM_HouseSwineStable in 'src\houses\KM_HouseSwineStable.pas',
  KM_HouseTownHall in 'src\houses\KM_HouseTownHall.pas',
  KM_HouseWoodcutters in 'src\houses\KM_HouseWoodcutters.pas',

  KM_GameApp in 'src\KM_GameApp.pas',
  KM_Log in 'src\KM_Log.pas',
  KM_Main in 'src\KM_Main.pas',
  KM_System in 'src\KM_System.pas',
  
  KM_Campaigns in 'src\mission\KM_Campaigns.pas',
  KM_CampaignClasses in 'src\mission\KM_CampaignClasses.pas',
  KM_CampaignUtils in 'src\mission\KM_CampaignUtils.pas',
  KM_CampaignTypes in 'src\mission\KM_CampaignTypes.pas',
  KM_Maps in 'src\mission\KM_Maps.pas',
  KM_MapTypes in 'src\mission\KM_MapTypes.pas',
  KM_MapUtils in 'src\mission\KM_MapUtils.pas',  
  KM_MapUtilsExt in 'src\mission\KM_MapUtilsExt.pas',  
  KM_MissionScript in 'src\mission\KM_MissionScript.pas',
  KM_MissionScript_Info in 'src\mission\KM_MissionScript_Info.pas',
  KM_MissionScript_Preview in 'src\mission\KM_MissionScript_Preview.pas',
  KM_MissionScript_Standard in 'src\mission\KM_MissionScript_Standard.pas',
  
  KM_MapEditor in 'src\maped\KM_MapEditor.pas',
  KM_MapEditorHistory in 'src\maped\KM_MapEditorHistory.pas',
  KM_MapEdTypes in 'src\maped\KM_MapEdTypes.pas',
  
  KM_Audio in 'src\media\KM_Audio.pas',
  KM_MediaTypes in 'src\media\KM_MediaTypes.pas',
  KM_Music in 'src\media\KM_Music.pas',
  KM_ScriptSound in 'src\media\KM_ScriptSound.pas',
  KM_Sound in 'src\media\KM_Sound.pas',
  KM_Video in 'src\media\KM_Video.pas',
  KM_VLC in 'src\media\KM_VLC.pas',
  
  KM_Minimap in 'src\minimap\KM_Minimap.pas', 
  KM_MinimapGame in 'src\minimap\KM_MinimapGame.pas',
  KM_MinimapMission in 'src\minimap\KM_MinimapMission.pas',

  KM_Outline in 'src\navmesh\KM_Outline.pas',
  KM_NavMesh in 'src\navmesh\KM_NavMesh.pas',
  KM_NavMeshGenerator in 'src\navmesh\KM_NavMeshGenerator.pas',
  KM_PolySimplify in 'src\navmesh\KM_PolySimplify.pas',
  KM_NavMeshPathFinding in 'src\navmesh\KM_NavMeshPathFinding.pas',
  KM_NavMeshFloodFill in 'src\navmesh\KM_NavMeshFloodFill.pas',
  KM_NavMeshFloodPositioning in 'src\navmesh\KM_NavMeshFloodPositioning.pas',
  KM_NavMeshInfluences in 'src\navmesh\KM_NavMeshInfluences.pas',
  KM_NavMeshDefences in 'src\navmesh\KM_NavMeshDefences.pas',
  //KM_NavMeshArmyPositioning in 'src\navmesh\KM_NavMeshArmyPositioning.pas',
  KM_NavMeshArmyVectorField in 'src\navmesh\KM_NavMeshArmyVectorField.pas',

  {$IFDEF USESECUREAUTH}
    KM_NetAuthSecure in 'src\net\KM_NetAuthSecure.pas',
  {$ELSE}
    KM_NetAuthUnsecure in 'src\net\KM_NetAuthUnsecure.pas',
  {$ENDIF}
  KM_NetClient in 'src\net\KM_NetClient.pas',
  {$IFDEF WDC} KM_NetClientOverbyte in 'src\net\KM_NetClientOverbyte.pas', {$ENDIF}
  {$IFDEF FPC} KM_NetClientLNet in 'src\net\KM_NetClientLNet.pas', {$ENDIF}
  KM_NetConsts in 'src\net\KM_NetConsts.pas',
  KM_NetDedicatedServer in 'src\net\KM_NetDedicatedServer.pas',
  KM_NetFileTransfer in 'src\net\KM_NetFileTransfer.pas',
  KM_NetGameInfo in 'src\net\KM_NetGameInfo.pas',
  KM_NetServerLocator in 'src\net\KM_NetServerLocator.pas',
  KM_NetRoom in 'src\net\KM_NetRoom.pas',
  KM_NetServer in 'src\net\KM_NetServer.pas',
  {$IFDEF WDC} KM_NetServerOverbyte in 'src\net\KM_NetServerOverbyte.pas', {$ENDIF}
  {$IFDEF FPC} KM_NetServerLNet in 'src\net\KM_NetServerLNet.pas', {$ENDIF}
  KM_NetServerPoller in 'src\net\KM_NetServerPoller.pas',
  KM_NetTypes in 'src\net\KM_NetTypes.pas',
  KM_NetUDP in 'src\net\KM_NetUDP.pas',
  {$IFDEF WDC} KM_NetUDPOverbyte in 'src\net\KM_NetUDPOverbyte.pas', {$ENDIF}
  {$IFDEF FPC} KM_NetUDPLNet in 'src\net\KM_NetUDPLNet.pas', {$ENDIF}
  KM_Networking in 'src\net\KM_Networking.pas',
  KM_NetworkUtils in 'src\net\KM_NetworkUtils.pas',

  KM_HTTPClient in 'src\net\http\KM_HTTPClient.pas',
  {$IFDEF WDC} KM_HTTPClientOverbyte in 'src\net\http\KM_HTTPClientOverbyte.pas', {$ENDIF}
  {$IFDEF FPC} KM_HTTPClientLNet in 'src\net\http\KM_HTTPClientLNet.pas', {$ENDIF}


  KM_PathFinding in 'src\pathfinding\KM_PathFinding.pas',
  KM_PathFindingAStarOld in 'src\pathfinding\KM_PathFindingAStarOld.pas',
  KM_PathFindingAStarNew in 'src\pathfinding\KM_PathFindingAStarNew.pas',
  KM_PathFindingJPS in 'src\pathfinding\KM_PathFindingJPS.pas',
  KM_PathFindingRoad in 'src\pathfinding\KM_PathFindingRoad.pas',

  KM_Projectiles in 'src\KM_Projectiles.pas',

  KM_Render in 'src\render\KM_Render.pas',
  KM_RenderAux in 'src\render\KM_RenderAux.pas',
  KM_RenderControl in 'src\render\KM_RenderControl.pas',
  KM_RenderDebug in 'src\render\KM_RenderDebug.pas',
  KM_RenderGameAux in 'src\render\KM_RenderGameAux.pas',
  KM_RenderPool in 'src\render\KM_RenderPool.pas',
  KM_RenderTerrain in 'src\render\KM_RenderTerrain.pas',
  KM_RenderTypes in 'src\render\KM_RenderTypes.pas',
  KM_RenderQuery in 'src\render\KM_RenderQuery.pas',
  KM_RenderUI in 'src\render\KM_RenderUI.pas',

  KM_Pics in 'src\res\KM_Pics.pas',  
  KM_Resource in 'src\res\KM_Resource.pas',
  KM_ResCursors in 'src\res\KM_ResCursors.pas',
  KM_ResExporter in 'src\res\KM_ResExporter.pas',
  KM_ResFonts in 'src\res\KM_ResFonts.pas',
  KM_ResHouses in 'src\res\KM_ResHouses.pas',
  KM_ResInterpolation in 'src\res\KM_ResInterpolation.pas',
  KM_ResKeys in 'src\res\KM_ResKeys.pas',
  KM_ResKeyFuncs in 'src\res\KM_ResKeyFuncs.pas',
  KM_ResLocales in 'src\res\KM_ResLocales.pas',
  KM_ResMapElements in 'src\res\KM_ResMapElements.pas',
  KM_ResPalettes in 'src\res\KM_ResPalettes.pas',
  KM_ResSound in 'src\res\KM_ResSound.pas',
  KM_ResSprites in 'src\res\KM_ResSprites.pas',
  KM_ResTexts in 'src\res\KM_ResTexts.pas',
  KM_ResTypes in 'src\res\KM_ResTypes.pas',
  KM_ResTileset in 'src\res\KM_ResTileset.pas',
  KM_ResTilesetTypes in 'src\res\KM_ResTilesetTypes.pas',
  KM_ResUnits in 'src\res\KM_ResUnits.pas',
  KM_ResWares in 'src\res\KM_ResWares.pas',
  KM_Saves in 'src\res\KM_Saves.pas',

  KM_ScriptFilesCollection in 'src\scripting\KM_ScriptFilesCollection.pas',
  KM_ScriptErrorHandler in 'src\scripting\KM_ScriptErrorHandler.pas',
  KM_Scripting in 'src\scripting\KM_Scripting.pas',
  KM_ScriptingActions in 'src\scripting\KM_ScriptingActions.pas',
  KM_ScriptingConsoleCommands in 'src\scripting\KM_ScriptingConsoleCommands.pas',
  KM_ScriptingEvents in 'src\scripting\KM_ScriptingEvents.pas',
  KM_ScriptingIdCache in 'src\scripting\KM_ScriptingIdCache.pas',
  KM_ScriptPreProcessor in 'src\scripting\KM_ScriptPreProcessor.pas',
  KM_ScriptPreProcessorGame in 'src\scripting\KM_ScriptPreProcessorGame.pas',
  KM_ScriptingStates in 'src\scripting\KM_ScriptingStates.pas',
  KM_ScriptingTypes in 'src\scripting\KM_ScriptingTypes.pas',
  KM_ScriptingUtils in 'src\scripting\KM_ScriptingUtils.pas',
  KM_ScriptValidatorResult in 'src\scripting\KM_ScriptValidatorResult.pas',

  KM_Settings in 'src\settings\KM_Settings.pas',
  KM_SettingsXML in 'src\settings\KM_SettingsXML.pas',
  KM_GameAppSettings in 'src\settings\KM_GameAppSettings.pas',
  KM_GameAppSettingsPart in 'src\settings\KM_GameAppSettingsPart.pas',
  KM_KeysSettings in 'src\settings\KM_KeysSettings.pas',
  KM_GameSettings in 'src\settings\KM_GameSettings.pas',
  KM_MainSettings in 'src\settings\KM_MainSettings.pas',
  KM_ServerSettings in 'src\settings\KM_ServerSettings.pas',
  KM_Resolutions in 'src\settings\KM_Resolutions.pas',
  KM_WindowParams in 'src\settings\KM_WindowParams.pas',
  KM_SettingsDev in 'src\settings\KM_SettingsDev.pas',

  KM_RandomMapGenerator in 'src\terrain\KM_RandomMapGenerator.pas',
  KM_RMGUtils in 'src\terrain\KM_RMGUtils.pas',
  KM_Terrain in 'src\terrain\KM_Terrain.pas',
  KM_TerrainDeposits in 'src\terrain\KM_TerrainDeposits.pas',
  KM_TerrainFinder in 'src\terrain\KM_TerrainFinder.pas',
  KM_TerrainPainter in 'src\terrain\KM_TerrainPainter.pas',
  KM_TerrainSelection in 'src\terrain\KM_TerrainSelection.pas',
  KM_TerrainTypes in 'src\terrain\KM_TerrainTypes.pas',
  KM_TerrainUtils in 'src\terrain\KM_TerrainUtils.pas',
  KM_TerrainWalkConnect in 'src\terrain\KM_TerrainWalkConnect.pas',

  KM_UnitActionAbandonWalk in 'src\units\actions\KM_UnitActionAbandonWalk.pas',
  KM_UnitActionFight in 'src\units\actions\KM_UnitActionFight.pas',
  KM_UnitActionGoInOut in 'src\units\actions\KM_UnitActionGoInOut.pas',
  KM_UnitActionStay in 'src\units\actions\KM_UnitActionStay.pas',
  KM_UnitActionSteer in 'src\units\actions\KM_UnitActionSteer.pas',
  KM_UnitActionStormAttack in 'src\units\actions\KM_UnitActionStormAttack.pas',
  KM_UnitActionWalkTo in 'src\units\actions\KM_UnitActionWalkTo.pas',
  
  KM_UnitGroup in 'src\units\KM_UnitGroup.pas',
  KM_UnitGroupTypes in 'src\units\KM_UnitGroupTypes.pas',
  KM_Units in 'src\units\KM_Units.pas',
  KM_UnitsCollection in 'src\units\KM_UnitsCollection.pas',
  KM_UnitVisual in 'src\units\KM_UnitVisual.pas',
  KM_UnitWarrior in 'src\units\KM_UnitWarrior.pas',
  KM_UnitWorkPlan in 'src\units\KM_UnitWorkPlan.pas',
  
  KM_UnitTaskAttackHouse in 'src\units\tasks\KM_UnitTaskAttackHouse.pas',
  KM_UnitTaskBuild in 'src\units\tasks\KM_UnitTaskBuild.pas',
  KM_UnitTaskDelivery in 'src\units\tasks\KM_UnitTaskDelivery.pas',
  KM_UnitTaskDie in 'src\units\tasks\KM_UnitTaskDie.pas',
  KM_UnitTaskGoEat in 'src\units\tasks\KM_UnitTaskGoEat.pas',
  KM_UnitTaskGoHome in 'src\units\tasks\KM_UnitTaskGoHome.pas',
  KM_UnitTaskDismiss in 'src\units\tasks\KM_UnitTaskDismiss.pas',
  KM_UnitTaskGoOutShowHungry in 'src\units\tasks\KM_UnitTaskGoOutShowHungry.pas',
  KM_UnitTaskMining in 'src\units\tasks\KM_UnitTaskMining.pas',
  KM_UnitTaskSelfTrain in 'src\units\tasks\KM_UnitTaskSelfTrain.pas',
  KM_UnitTaskThrowRock in 'src\units\tasks\KM_UnitTaskThrowRock.pas',

  KM_CommonShellUtils in 'src\utils\KM_CommonShellUtils.pas',
  KM_CommonUtils in 'src\utils\KM_CommonUtils.pas',
  KM_Utils in 'src\utils\KM_Utils.pas',
  KM_UtilsExt in 'src\utils\KM_UtilsExt.pas',
  
  KromOGLUtils in 'src\utils\KromOGLUtils.pas',
  KromUtils in 'src\utils\KromUtils.pas',
  KromShellUtils in 'src\utils\KromShellUtils.pas',
  
  BinaryHeap in 'src\utils\algorithms\BinaryHeap.pas',
  BinaryHeapGen in 'src\utils\algorithms\BinaryHeapGen.pas',
  KM_BinPacking in 'src\utils\algorithms\KM_BinPacking.pas',
  KM_Hungarian in 'src\utils\algorithms\KM_Hungarian.pas',
  KM_FloodFill in 'src\utils\algorithms\KM_FloodFill.pas',
  KM_MarchingSquares in 'src\utils\algorithms\KM_MarchingSquares.pas',
  KM_SoftShadows in 'src\utils\algorithms\KM_SoftShadows.pas',
  KM_Sort in 'src\utils\algorithms\KM_Sort.pas',
  
  KM_FileIO in 'src\utils\io\KM_FileIO.pas',
  KM_IoGraphicUtils in 'src\utils\io\KM_IoGraphicUtils.pas',
  KM_IoJSON in 'src\utils\io\KM_IoJSON.pas',
  KM_IoPNG in 'src\utils\io\KM_IoPNG.pas',
  KM_IoXML in 'src\utils\io\KM_IoXML.pas',
  
  KM_MethodParser in 'src\utils\method_parser\KM_MethodParser.pas',
  KM_MethodParserParams in 'src\utils\method_parser\KM_MethodParserParams.pas';

  //KM_PerfLog in 'src\unused\KM_PerfLog.pas', //unused


{$IFDEF WDC}
  // Enable usage of 3Gb or 4Gb of RAM for Win32 Delphi application
  // https://docwiki.embarcadero.com/RADStudio/Alexandria/en/Increasing_the_Memory_Address_Space
  {$SetPEFlags IMAGE_FILE_LARGE_ADDRESS_AWARE}
{$ENDIF}

{$IFDEF WDC}
// We have our icon in KaM_Remake_Icon.ico and specify that in project settings.
// Now Delphi will take that and compile it itself into KaM_Remake.res, which we dont need to commit,
// since it gets autogenerated on recompile.
// How will it work with FPC - not sure, but FPC is a second-class citizen, we don't really care.
// KaM_Remake_Icon.res can be removed if it works.
// Hence, thie line below is commented out:
//  {$R KaM_Remake_Icon.res} // Keeps the Icon
  {$R KaM_Remake.res} // Standard RES file, keeps the Icon
  {$R KaM_Manifest.res}
{$ENDIF}
{$IFDEF MSWindows}
  {$IFDEF FPC}
//    {$R KaM_Remake_Icon.res}
    {$R KaM_Manifest.res}
  {$ENDIF}
{$ENDIF}

begin
  Application.Initialize;
  Application.Title := 'KaM Remake';

  try
    gMain := TKMMain.Create;
    try
      if gMain.Start then
        Application.Run;
    finally
      // If there is an exception we get into this "finally" block first,
      // Control goes to KM_Exceptions only afterwards
      // Maybe we will rethink this and arrange gMain.Free to happen after exception is handled?
      gMain.Free; // Prevents memory leak of TKMMain showing up in FastMM
      gMain := nil;
    end;
  except
    // We know and control EGameInitError instances and can show them without generating a crashreport
    // Other exceptions will be catched by madExcept
    on E: EGameInitError do
      // MessageDlg works better than Application.MessageBox or others, it stays on top and pauses here until the user clicks ok
      MessageDlg(E.Message, mtWarning, [mbOk], 0);
  end;

end.
