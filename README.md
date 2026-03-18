# SIMPLE GUNGAME
Modern, lightweight version of gungame for CS1.6 and Czero  
In my taste, the old, popular gungame plugin by avalanche is too complex and has a lot of bloat. 
I decided to make this gamemode from scratch using reapi/regamedll_cs.  
______________________
## FEATURES
There are 4 different weapon lists that are randomised per map: price based, reverse price, category based, reverse category  
Progression is xp based:  
1 kill = 1 XP  
1 Headshot = 2 XP  
Knife/HE kill = Steal 1 XP  
Stuck on a gun? Die 5 times = 1 XP  
  
There is a realtime top5 leaderboard below radar, below crosshair You can see your progress.  
Mode is compatible with __gg___, __dm___ and __fy___ maps, players respawn after 2 seconds.  
Final level is a special golden knife. It was written to support this [amazing knife](https://gamebanana.com/mods/607584). Because of his licence, I can't post the files directly but If You want to use a different one, feel free to edit .sma file.  
Plugin has [CSR Ranked Play](https://github.com/ToRRent1812/cs-ranked-play) integration  
Plugin has __Mapchooser.amxx__, __Mapchooser4.amxx__ and __Galileo.amxx__ map vote integration  
## SCREENSHOTS
<img width="583" height="556" alt="Zrzut ekranu_20260318_192608" src="https://github.com/user-attachments/assets/0064347e-e786-4a00-b378-ae7f69f741f1" />
<img width="583" height="556" alt="Zrzut ekranu_20260318_192612" src="https://github.com/user-attachments/assets/edc1c742-5298-4f4b-8c77-752f06dace3c" />
<img width="1910" height="1080" alt="Zrzut ekranu_20260318_192819" src="https://github.com/user-attachments/assets/37b5f14b-2692-4749-b181-5078cd391bbe" />



## CVARS
__gg_xp_needed 2__ - Amount of XP needed to level up  
__gg_hightier_xp_needed 5__ - Amount of XP needed to level up high tier weapon: Deagle, AK, M4, Famas, AWP   
__gg_knife_steal 1__ - Enable/Disable XP stealing  
__gg_death_bonus 5__ - How many deaths on 1 weapon level before getting 1 xp  
__gg_respawn_time 2.0__ - Delay before respawn  
## Instalattion
Make sure You have __latest__ [ReHLDS with libraries](https://rehlds.dev/) and [AMXX 1.10](https://www.amxmodx.org/downloads.php) 
Download zip file from [Releases](https://github.com/ToRRent1812/amxx-simple-gungame/releases) and put into server/cstrike/addons/amxmodx/  
Put sound folder into server/cstrike/  
Open server/cstrike/addons/amxmodx/configs/plugins.ini with text editor and at the end of the file, create a new line __simple_gungame.amxx__
