script "lib_MenuItemHelp"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_MenuItemHelp
type: library
version: 0.3

/*
This library is for creating help for menu-items.
Each menu-item has it's own wiki-page on a wiki named after the menu.
*/


--> Working on
-

--> Launch
-
command launch_HkeyGitHub hKey
   hkeyLine_Deconstruct hKey, hName, hType, hObject
   put the github_HandlerURL [hKey] of hObject into githubURL -- uses "revAvailableHandlers"
   --
   launch url githubURL
   if the result is not empty then
      put githubURL
   end if
end launch_HkeyGitHub

command launch_HkeyHelp hKey
   put help_ConstructHkeyURL (hKey, true) into helpURL
   if helpURL is empty then return empty
   --
   launch url helpURL
   return helpURL
end launch_HkeyHelp

command launch_MenuItemHelp hKey
   put help_ConstructMenuItemUrl (hKey, true) into helpURL
   if helpURL is empty then return empty
   --
   launch url helpURL
   return helpURL
end launch_MenuItemHelp


--> Help | Menu | Item
-
function help_ConstructMenuItemUrl hKey, pCheckURL
   hkeyLine_Deconstruct hKey, hName, hType, mController
   put the stack_Name of mController into gMenuTitle
   --
   get help_ConstructMenuPageTitle (gMenuTitle)
   put help_MenuWikiDomain (it) into menuSubDomain
   --
   put menu_CommandToText (hName) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put fedwiki_UrlFromSlug (menuSubDomain, pageSlug) into helpURL
   --
   put fedwiki_PageExists (menuSubDomain, pageSlug) into pageExists
   if pCheckURL is true and pageExists is false then return empty
   --
   return helpURL
end help_ConstructMenuItemUrl

function help_FetchMenuItemArray hKey, pFetchWelcome
   -- not used
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   if pFetchWelcome is true then
      -- wiki farms return json for welcome visitors wehn site does not exist!
      if fedwiki_WikiExists (menuSubDomain) is false then
         return empty
      end if
      put pageArray_Fetch (menuSubDomain, "welcome-visitors") into pageArray
   else
      put pageArray_Fetch (menuSubDomain, hkeySlug) into pageArray
   end if
   return pageArray
end help_FetchMenuItemArray


--> Help | Menu | Item | Updatee
-
command help_UpdateMenuItem hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put pageArray_Fetch (menuSubDomain, hkeySlug) into hkeyPageArray
   if hkeyPageArray is empty then return empty
   --
   put help_HkeyCurlyData (hKey, true) into curlyData
   curly_MergePageArray hkeyPageArray, curlyData
   --
   pageArray_Set menuSubDomain, hkeySlug, hkeyPageArray
   return hkeyPageArray
end help_UpdateMenuItem

command help_CheckUpdateMenuItem hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   
   # Menu-page: - create or update
   help_CreateOrUpdateMenuPage gMenuTitle
   
   # Menu-item: - create or update
   _CreateOrUpdateMenuItem hKey, menuSubDomain
end help_CheckUpdateMenuItem

function help_CheckMenuWikiDomain hKey
   -- not used
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put fedwiki_WikiExists (menuSubDomain) into wikiDomainExists
   return wikiDomainExists
end help_CheckMenuWikiDomain


--> Help | Menu | Item | Create
-
command help_CreateMenuItem hKey, pScriptHelp
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   --
   if word 1 of gMenuTitle is not "Global" then return empty
   
   -- fetch a handler template    
   put help_HkeyCurlyData (hKey, false) into hkeyCurlyData
   put hkeyPageTitle into hkeyCurlyData ["title"]
   --
   put wikiPage_Help ("handler", hkeyCurlyData, pScriptHelp) into hkeyPageArray
   --
   pageArray_Set menuSubDomain, hkeySlug, hkeyPageArray
   return the result
end help_CreateMenuItem


--> Help | Menu | Subdomain | Create
-
command help_CreateMenuWikiDomain hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put the result into mController
   --
   put fedwiki_WikiExists (menuSubDomain) into subDomainExists
   if subDomainExists is false then
      return merge ("error, subdomain [[menuSubDomain]] does not exist")
   end if
   
   -- fetch, rename and store menuPageArray
   put help_ConstructMenuPageTitle (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into menuPageSlug
   --
   put platform_LivecodeDomain ("menu") into wikiDomain
   put pageArray_Fetch (wikiDomain, menuPageSlug) into menuPageArray
   if menuPageArray is empty then
      return merge ("error, there is no page [[menuPageSlug]] on menu.livecode.wiki to clone")
   end if
   --
   put help_ConstructMenuStory (gMenuTitle, "reference", mController) into storyArray
   pageArray_ReplaceSectionBody menuPageArray, "Menu", storyArray
   --
   pageArray_Rename menuPageArray, "Welcome Visitors"
   pageArray_StripJournal menuPageArray
   --
   put _ForkDomains ("handler,model") into forkDomains
   pageArray_AddFork menuPageArray, forkDomains
   --
   pageArray_Set menuSubDomain, "welcome-visitors", menuPageArray
   --
   if the result is empty then
      return menuPageArray
   else
      return the result
   end if
end help_CreateMenuWikiDomain

command help_UpdateMenuWikiDomain hKey, pHow
   -- no checks at the moment
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put the result into mController
   --
   put fedwiki_WikiExists (menuSubDomain) into subDomainExists
   if subDomainExists is false then return empty
   --
   put pageArray_Fetch (menuSubDomain, "welcome-visitors") into pageArray
   if pageArray is empty then return empty
   --
   put help_ConstructMenuStory (gMenuTitle, pHow, mController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   --
   help_MenuItemMergeAndStore hKey, menuSubDomain, pageArray, true
   --
   return the result
end help_UpdateMenuWikiDomain

command help_SetHkeyInfo hKey, @wikiDomain, @pageSlug, @pageTitle
   -- used by "help_HkeyCurlyData" 
   switch
      case hkey_IsMenuHandler (hKey)
         _SetMenuItemHelpInfo hKey, gMenuTitle, pageTitle, wikiDomain, pageSlug
         break
      case hkey_IsTransportHandler (hKey)
         put "transport.fedwiki.club" into wikiDomain
         hkey_Deconstruct hKey, hName, hType, hObject, hNum
         put the stack_Name of hObject into stackName
         put help_ConstructTransportTitle (stackName) into pageTitle 
         break
      default
         -- not a special handler so add to global library
         put platform_LivecodeDomain ("handler") into wikiDomain
         put help_ConstructHandlerTitle (hKey) into pageTitle
         put fedwiki_ConstructSlug (pageTitle) into pageSlug
   end switch
end help_SetHkeyInfo


--> Private
-
private function _ForkDomains subNameList
   put "fedwiki.club" into forkDomains
   put comma & platform_LivecodeDomain() after forkDomains
   --
   repeat for each item subName in subNameList
      put comma & platform_LivecodeDomain (subName) after forkDomains
   end repeat
   return forkDomains
end _ForkDomains

private command _CreateOrUpdateMenuItem hKey, menuSubDomain
if fedwiki_WikiExists (menuSubDomain) is true then
   help_UpdateMenuWikiDomain hKey, "reference"
   if the result is empty then
      breakpoint -- should create
   end if
else
   help_CreateMenuWikiDomain hKey
end if
end _CreateOrUpdateMenuItem

private command _SetMenuItemHelpInfo hKey, @gMenuTitle, @hkeyPageTitle, @menuSubDomain, @hkeySlug
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   --
   -- put hkey_GetMenuTitle (hKey) into gMenuTitle
   put line 1 of the script_GlobalMenuTitles of hObject into gMenuTitle
   put the script_Type of hObject into sType
   --
   if sType is not among the items of "menu,controller" then
      -- it's a bit old and not yet organised
      display_DebugHistory
      --
      breakpoint
      lcw_AnswerWarning "Menu is not prepared for indexing!"
      return empty
   end if
   
   --
   put menu_CommandToText (hName) into hkeyPageTitle
   put fedwiki_ConstructSlug (hkeyPageTitle) into hkeySlug
   --
   set the itemdelimiter to "|"
   if word 1 to -1 of item 1 of gMenuTitle = "Global" then
      put help_ConstructMenuWikiDomain (gMenuTitle) into menuSubDomain
      return hObject
   else
      -- could be a local menu such as "Dev | Menu" of a global menu
      --
      put the script_metadata ["name"] of hObject into gMenuTitle
      replace "_" with " | " in gMenuTitle
      --
      put the script_MenuTitles of hObject into mTitles
      filter mTitles with "Global | *"
      --
      set the wholematches to true
      if gMenuTitle is among the lines of mTitles then
         put help_ConstructMenuWikiDomain (gMenuTitle) into menuSubDomain
         return hObject
      else
         breakpoint
         lcw_AnswerWarning merge ("[[gMenuTitle]] is not present. Menu is not prepared for indexing!")
         return empty
      end if
   end if
end _SetMenuItemHelpInfo
