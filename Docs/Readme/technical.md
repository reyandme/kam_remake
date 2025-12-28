# ⛏️ Technical details

The game uses a custom, open source engine, written from scratch - but still relies on the original resource files. We assume that you own the original KaM game (the installer checks for it), otherwise you should buy it – it's available in a number of online gaming stores.

The KaM Remake executable is freeware and is built by enthusiasts. Applications used: Delphi XE2 - Delphi Yukon 12, FastMM4, Lazarus, OpenGL, OpenAL, Overbyte ICS, zLib, Ogg Vorbis, PNGImage, MadExcept, libZPlay.

### 🌳 Contributing

Get started at <https://trello.com/c/anU9APld/1265-faq-for-new-developers-testers> or <https://github.com/reyandme/kam_remake/wiki/ProjectCompilation>.  
Our Discord is a good place to seek for help in development.

### 🏹 KaM Remake Maps and Campaigns repository
All Maps and Campaigns are in the [kam_remake_maps repo](https://github.com/reyandme/kam_remake_maps "KaM Remake Maps and Campaigns repository") maps and campaigns

# 🪓 Dedicated Server

Executables for the multiplayer dedicated server are included with the game (and also available at <https://www.kamremake.com/download/>), for Windows/Linux x86 and x86_64. The server listens for connections on a TCP port (56789 by default). It can be configured in **KaM_Remake_Settings.ini** (created at start) in the [Server] section. Any queries or comments regarding the Linux builds are welcome on our Discord channel.

> [!Note]
> The dedicated server is not required to play multiplayer. Clicking "Start Local Server" or "Start Internet Server" from the network menu has the same effect, except you must participate in the game and the server cannot be left to maintain itself. The dedicated server is only necessary if you want to provide a server without playing. The main purpose of the dedicated server is to allow servers to be hosted 24/7, which players can join and participate in any time they like. If you are able to provide this service we would be pleased.  

## Connecting from the internet - port forwarding

Please ensure your firewall is allowing clients to connect to the server, by allowing TCP port 56789 (or whichever you chose). You may then connect to it from the same computer and/or other computers. (For the same computer, connect to the address 127.0.0.1 or localhost)

To use on the internet, you must forward the TCP port 56789 (or whichever you chose) from your router to your PC running the dedicated server. (for more information on port forwarding visit http://portforward.com/) Tell your friends to connect to your server name from the list if you chose to make your server publicly announced, or your external IP address if not, which is displayed to you on the homepage of http://portforward.com/. 

## Connecting from LAN
If you are playing on the same computer that is running the dedicated server, or on the same LAN, it should be detected automatically and available on lobby list.

If you want to hide the server on the Internet lobby list, use option "AnnounceDedicatedServer=0".

## How the server works
The server acts as a hub to transfer the data between game clients. The dedicated server does not understand gameplay, it just moves packets around. The first client to join a room will be assigned hosting rights, allowing them to setup the game. If that client disconnects, the hosting rights will be passed to the next player on the list.


