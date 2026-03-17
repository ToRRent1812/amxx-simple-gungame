## amxx-simple-gungame
Modern, lightweight version of gungame for CS1.6 and Czero
______________________
In my taste, the old, popular gungame plugin by avalanche is too complex and has a lot of not needed bloat. So I decided to make my own version.  
There are 4 different weapon lists that are randomised per map  
Progression is xp based.  
1 kill = 1 XP  
1 Headshot = 2 XP  
Knife/HE kill = Steal 1 XP
Handicap: Die 5 times with 1 weapon = 1 XP

There is a top5 hud message below radar, below crosshair You can see your progress.
Plugin uses mostly cstrike and reapi for it to work.
_______________________
## SCREENSHOTS
coming soon
_______________________
## CVARS
gg_xp_needed 2 - Amount of XP needed to level up
gg_hightier_xp_needed 5 - Amount of XP needed to level up high tier weapon from "golden 5"
gg_knife_steal 1 - Enable/Disable XP stealing

________________________
## Instalattion
Make sure You have __latest__ [ReHLDS with libraries](https://rehlds.dev/) and [AMXX 1.10](https://www.amxmodx.org/downloads.php)
Download simple_gungame.amxx from plugins folder and put into server/cstrike/addons/amxmodx/plugins  
Open server/cstrike/addons/amxmodx/configs/plugins.ini with text editor and at the end of the file, create a new line __simple_gungame.amxx__
