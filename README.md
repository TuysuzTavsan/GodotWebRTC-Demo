# GodotMultiplayerDemo

Godot multiplayer demo via webrtc + signaling server.<br />
Main purpose of this project is making a minimal multiplayer game with lobby system via webrtc and signaling server.<br />
This project is finished since I reached my goal for this one.<br />

---------------------------------------
USING GAME ENGINE GODOT VERSION 4.0.3.<br />
Project files include webrtc extension for 4.0.3 if you want to use different version of godot make sure you also change webrtc extension.<br />
----------------------------------------
------------------------------
2 Seperate Projects:<br />
1-Client<br />
2-Server (signaling server for webrtc)<br />
-------------------------------



Code is designed to support mesh network. <br />
When the lobby owner starts game, server will send each pear which peers it needs to establish connection.<br />
We store multiplayer information on a global singleton = User.gd.<br />
User.gd has a Client which is a class with websocket connection = Client.gd.<br />
Scene hierarchy: Main >> Intro >> Main Menu >> LOBBY MENU >> IN LOBBY MENU >> GAME SCENE<br />
when any peer connects to each other they will add a player with their peer id as multiplayer authority.<br />

----------
You can use this project as a multiplayer template and build further.<br />
However 2 things you need to be aware of are =<br />
1- Lobbys are not getting deleted after game starts (I did not add this feature)<br />
2- You can find a better way to set player names (I set them in player_character.gd it was a temporary solution.)<br />
If you use this project in any way you dont need to credit to me.<br />
However please do not post this in anywhere without making any changes to it as if it was your project (as it is)<br />
----------

Project tested with:<br />
1- Server and client runs on same pc.<br />
2- Server runs windows server on seperate location. Client runs on different locations. (Tested with friends)<br />
3- Server runs on Ubuntu server on seperate location. Client runs on different locations. (Tested with friends)<br />

-----
Youtube Showcase link:<br />
https://www.youtube.com/watch?v=aztZ2aokEZE<br />
-----

--------
ALSO DO NOT FORGET TO CHANGE SERVER IP ADDRESS AND PORT. IT IS LOCATED AT THE FIRST LINES ON CLIENT.GD. IF YOU CHANGE THE PORT CHANGE SERVER PROJECTS PORT ALSO!<br />
--------

-----
RESOURCES<br />
-----
Game scene background art: https://analogstudios.itch.io/islands <br />
Pirate character art: https://seartsy.itch.io/free-pirate<br />
