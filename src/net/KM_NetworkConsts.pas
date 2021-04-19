unit KM_NetworkConsts;
{$I KaM_Remake.inc}
interface
uses
  KM_NetworkTypes;


const
  NET_MP_GAME_STATE: array [TKMNetGameState] of TMPGameState = (mgsNone, mgsNone, mgsNone, mgsLobby, mgsLoading, mgsGame, mgsGame);
  NET_ALLOWED_PACKETS_SET: array [TKMNetGameState] of set of TKMessageKind = (
    //lgsNone
    [],
    //lgsConnecting
    [mkRefuseToJoin,mkIndexOnServer,mkGameVersion,mkWelcomeMessage,mkPing,
     mkConnectedToRoom,mkPingInfo,mkKicked,mkServerName,mkReqPassword],
    //lgsQuery
    [mkAllowToJoin,mkRefuseToJoin,mkAuthChallenge,mkPing,mkPingInfo,mkKicked],
    //lgsLobby
    [mkAskForAuth,mkAskToJoin,mkClientLost,mkReassignHost,mkDisconnect,mkPing,mkPingInfo,mkPlayersList,
     mkStartingLocQuery,mkSetTeam,mkFlagColorQuery,mkResetMap,mkMapSelect,mkSaveSelect,
     mkReadyToStart,mkStart,mkTextChat,mkKicked,mkLangCode,mkGameOptions,mkServerName,
     mkFileRequest,mkFileSendStarted,mkFileChunk,mkFileEnd,mkFileAck,mkFileProgress,
     mkTextTranslated,mkHasMapOrSave,mkSetPassword],
    //lgsLoading
    [mkAskForAuth,mkClientLost,mkReassignHost,mkDisconnect,mkPing,mkPingInfo,mkPlayersList,
     mkReadyToPlay,mkPlay,mkTextChat,mkKicked,mkTextTranslated,mkVote],
    //lgsGame
    [mkAskForAuth,mkClientLost,mkReassignHost,mkDisconnect,mkPing,mkPingInfo,{mkFPS,}mkPlayersList,mkReadyToReturnToLobby,
     mkCommands,mkTextChat,mkResyncFromTick,mkAskToReconnect,mkKicked,mkClientReconnected,mkTextTranslated,mkVote],
    //lgsReconnecting
    [mkIndexOnServer,mkGameVersion,mkWelcomeMessage,mkPing,{mkFPS,}mkConnectedToRoom,
     mkPingInfo,mkPlayersList,mkReconnectionAccepted,mkRefuseReconnect,mkKicked]
  );

  JOIN_TIMEOUT = 8000; //8 sec. Timeout for join queries
  RECONNECT_PAUSE = 3000; //Time in ms which we wait before attempting to reconnect (stops the socket from becoming overloaded)
  VOTE_TIMEOUT = 60000; //60 sec. Timeout for votes

implementation

end.

