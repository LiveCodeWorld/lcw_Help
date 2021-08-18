script "Global | Display | Menu | Help | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Display | Menu | Help | Menu
type: controller
version: 0.1


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   if exists (tObject) is false then
      -- no idea whu this might be empty
      -- display_DebugHistory "Global | Display | Help | Menu", true
      return empty
   end if
   put the title_Text of tObject into gMenuTitle
   put menu_GetGlobalController(gMenuTitle) into mController
   menu_SetTarget "Global | Script | Help | Menu", mController
   put gMenuTitle into LocalArray ["gMenuTitle"]
   --
   return mController
end menu_Target

getprop menu_CheckTarget [mController]
   if exists (mController) is false then
      pass menu_CheckTarget -- no idea why
   end if
   
   get the menu_GlobalTitle of mController
   if it is empty then
      return false
   else
      return true
   end if
end menu_CheckTarget

-- getprop disabled_CreateMenuWiki [mController]
put _GetMenuWikiDomain (mController) into menuWikiDomain
put fedwiki_WikiExists (menuWikiDomain) into domainExists
return domainExists
end disabled_CreateMenuWiki

-- private function _GetMenuWikiDomain mController
put _GetGlobalMenuTitle (mController) into gMenuTitle
put help_ConstructMenuWikiDomain (gMenuTitle) into menuWikiDomain
return menuWikiDomain
end _GetMenuWikiDomain

private function _GetGlobalMenuTitle mController
   put line 1 of the script_GlobalMenuTitles of mController into gMenuTitle
   return gMenuTitle
end _GetGlobalMenuTitle


--> Global | Display | Menu | Help | Menu
-
on submenu_ObjectHelp
   return "Global | Script | Help | Menu"
end submenu_ObjectHelp

on menu_CreateMenuHelp mController
   put LocalArray ["gMenuTitle"] into gMenuTitle
   put rev_ScriptEditorStack () into editorStack
   lcw_Answer "Are you sure you wish to create the wiki help page for the menu '[[gMenuTitle]]'? This will overwrite any existing page.", editorStack, gMenuTitle
   --
   ask_PushGithub mController
   help_CreateMenuPage gMenuTitle
   launch_MenuHelp gMenuTitle
end menu_CreateMenuHelp

on _
end _

on menu_EditMenuController
   put LocalArray ["gMenuTitle"] into gMenuTitle
   --
   menu_Edit gMenuTitle
end menu_EditMenuController

on menu_AddWikiDomain sObject
   # Add to DigitalOcena DNS
   _AddMenuWikiDomain sObject
   --
   menu_LaunchMenuWiki sObject
end menu_AddWikiDomain

on menu_StoreMenuWelcomeVisitors sObject
   put line 1 of the script_GlobalMenuTitles of mController into gMenuTitle
   put help_ConstructMenuWikiDomain (gMenuTitle) into menuWikiDomain
   --  
   # Fetch, rename and store menu pageArray from "menu.livecode.world"
   put help_FetchMenuWikiPageArray (gMenuTitle, mController, menuWikiDomain) into menuPageArray
   pageArray_Store menuWikiDomain, "welcome-visitors", menuPageArray
   --
   menu_LaunchMenuWiki mController
end menu_StoreMenuWelcomeVisitors

on menu_LaunchMenuWiki mController
   put the stack_Name of mController into stackName
   launch_MenuWikiDomain stackName
end menu_LaunchMenuWiki

on _
end _

on _TestMenuHandlers mController
   put _GetGlobalMenuTitle (mController) into gMenuTitle
   --
   put the menu_Handlers [gMenuTitle] of mController into mHandlers
   --
   display_Data mHandlers, gMenuTitle, "menu_Handlers [gMenuTitle]"
end _TestMenuHandlers

on _TestFastMenuHandlers mController
   put _GetGlobalMenuTitle (mController) into gMenuTitle
   --
   put the menu_Handlers [true] of mController into mHandlers
   --
   display_Data mHandlers, gMenuTitle, "menu_Handlers [true]"
end _TestFastMenuHandlers

on _TestSlowMenuHandlers mController
   put _GetGlobalMenuTitle (mController) into gMenuTitle
   --
   put the menu_Handlers [false] of mController into mHandlers
   --
   display_Data mHandlers, gMenuTitle, "menu_Handlers [false]"
end _TestSlowMenuHandlers


--> Private
-
private command _AddMenuWikiDomain mController
   put _GetMenuWikiDomain (mController) into menuWikiDomain
   set the itemdelimiter to "."
   put item 1 to -3 of menuWikiDomain into subDomain
   --
   digitalocean_CreateARecord "livecode.world", subDomain
   if the result is not empty then
      put the result
   end if
end _AddMenuWikiDomain

on _
end _

on _UpdateMenuWiki hKey
   help_UpdateMenuWikiDomain hKey, "reference"
   --
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   launch_MenuWikiDomain stackName
end _UpdateMenuWiki 

on _UpdateMenuPage hKey
   put _StackName (hKey) into stackName
   put help_ConstructMenuPageTitle (stackName) into gMenuTitle
   --
   help_UpdateMenu gMenuTitle, "reference"
   --
   launch_MenuHelp stackName
end _UpdateMenuPage

on _
end _

on _LaunchGoogleDig
   launch url "https://toolbox.googleapps.com/apps/dig/#A/"
end _LaunchGoogleDig
