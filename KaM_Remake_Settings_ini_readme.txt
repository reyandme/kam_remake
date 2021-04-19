[GFX]
FullScreen=0
VSync=1
ResolutionWidth=1024
ResolutionHeight=768
RefreshRate=60
FPSCap=60         ;Limit FPS with that value
Brightness=1
AlphaShadows=1
LoadFullFonts=0

[Window]
WindowWidth=1024
WindowHeight=748
WindowLeft=440
WindowTop=217
WindowState=0

[Misc]
NoRenderMaxTime=1000    ;Longest period of (in ms) withput game render. Usefull while watching replay on very high speed (x300)

[Game]
Autosave=1
AutosaveOnGameEnd=0
AutosaveFrequency=600
AutosaveCount=5
ReplayAutopause=0
ReplayShowBeacons=0  ;Show players beacons while watching replay
SpecShowBeacons=0    ;Show player beacons while spectating
ShowGameTime=0       ;If set then show always game time label
ShowPlayersColors=1  ;Show player colors, if false(0) then show self/enemy/ally colors
PlayerColorSelf=0707FF  ;Player Color in BGR
PlayerColorAlly=07FFFF  ;Ally Color in BGR
PlayerColorEnemy=FFFF00 ;Enemy Color in BGR
ScrollSpeed=10
SpeedPace=100           ;game pace - time in ms for 1 game tick
SpeedMedium=3           ;game speed 1 (F6 by default) 
SpeedFast=6             ;game speed 2 (F7 by default) 
SpeedVeryFast=10        ;game speed 3 (F8 by default) 
Locale=eng
DayGamesCount=0
LastDayGamePlayed=30.12.1899
WareDistribution=5500534434004530

[SFX]
SFXVolume=0,5
MusicVolume=0,5
MusicDisabled=0
ShuffleEnabled=0

[Multiplayer]
Name=NoName
LastIP=127.0.0.1
LastPort=56789
LastRoom=0
LastPassword=
FlashOnMessage=1

[Server]
ServerName='KaM Remake Server'
WelcomeMessage=
ServerPort=56789
AnnounceDedicatedServer=1
MaxRooms=16
PacketsAccumulatingDelay=20
HTMLStatusFile=KaM_Remake_Server_Status.html
MasterServerAnnounceInterval=180
MasterServerAddressNew=http:;kam.hodgman.id.au/
AutoKickTimeout=20
PingMeasurementInterval=1000
DynamicFOW=0           ;enable/disable Dynamic FOW
MapsRosterEnabled=0    ;enable map roster (filter maps with listed below)
MapsRoster=            ;map list for roster by map hash. Use [Menu] FavouriteMaps as an example (set up rosted maps as favourite, then copy paste ini parameter, after game exit or saving INI from File Menu)
LimitPTFrom=0          ;PT limit
LimitPTTo=300
LimitSpeedFrom=0       ;Speeds limit
LimitSpeedTo=10
LimitSpeedAfterPTFrom=0
LimitSpeedAfterPTTo=10

[Menu]
FavouriteMaps=         ;list of favourite maps
MapSPType=0            
ReplaysType=0
MapEdMapType=0
MapEdNewMapX=64
MapEdNewMapY=64
MapEdSPMapCRC=0
MapEdMPMapCRC=0
MapEdMPMapName=
MapEdDLMapCRC=0
CampaignName=
ReplaySPSaveName=
ReplayMPSaveName=
SPScenarioMapCRC=0
SPMissionMapCRC=0
SPTacticMapCRC=0
SPSpecialMapCRC=0
SPSaveFileName=
LobbyMapType=0

