script "lib_MenuHelp"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_MenuHelp
type: library
version: 0.1

/*
This library is for creating and displaying help for LCW menus in wiki.
*/


--> Working on
-
function help_ConstructMenuStory mTitle, pHow, pMenuController
   local pageArray
   if pMenuController is empty then
      put menu_GetGlobalController (gMenuTitle) into pMenuController
   end if
   if exists (pMenuController) is false then return empty
   
   put the menu_Index [mTitle] of pMenuController into mHandlers
   repeat for each line hName in mHandlers 
      switch
         case hName = "-"
            pageArray_AddPagefold pageArray, "."
            break
         case pHow is "handler"
            put fedwiki_ConstructSlug (hName) into pageSlug
            put menu_CommandToText (hName) into mText
            --
            pageArray_AddReference pageArray, pageSlug, "handler.livecode.world", mText, hName
            break
         case pHow is "reference"
            put menu_CommandToText (hName) into mText
            put fedwiki_ConstructSlug (mText) into pageSlug  
            put help_ConstructMenuSubDomain (mTitle) into menuSubDomain
            --
            pageArray_AddReference pageArray, pageSlug, menuSubDomain, hName, mText
            break
         default
            put menu_CommandToText (hName) into mText
            put hkey_Construct (hName, "M", pMenuController) into hKey
            put the github_HandlerURL [hKey] of pMenuController into handlerURL
            put "-" && mText && "- [" & handlerURL && "github]" into someMarkdown
            --
            pageArray_AddMarkdown pageArray, someMarkdown
      end switch   
   end repeat
   return pageArray ["story"]
end help_ConstructMenuStory


--> Help | Menu | Create
-
command help_CreateMenu gMenuTitle, pMenuController
   if pMenuController is empty then put menu_GetGlobalController (gMenuTitle) into pMenuController
   --
   put help_CreateMenuPageArray (gMenuTitle, pMenuController, "links") into pageArray
   if pageArray is empty then return empty
   help_MenuMergeAndStore pMenuController, pageArray
   --
   return the result
end help_CreateMenu

function help_CreateMenuPageArray gMenuTitle, mController, pHow
   put menu_StripGlobal (gMenuTitle) into pageTitle
   
   # Fetch template
   put pageArray_Fetch ("menu.livecode.world", "menu-template") into pageArray
   
   # Add forks, rename and tidy
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   
   # Replace Menu section
   put help_ConstructMenuStory (gMenuTitle, pHow, mController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   --
   return pageArray
end help_CreateMenuPageArray

private command help_MenuMergeAndStore mController, pageArray
   put pageArray ["title"] into pageTitle -- could get from stackName ?
   --
   put help_ConstructDomain ("menu") into wikiDomain
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put help_ObjectCurlyData (mController, "menu") into curlyData
   curly_MergePageArray pageArray, curlyData
   --
   pageArray_Store wikiDomain, pageSlug, pageArray
   put the result into shellResult
   if shellResult is empty then
      return pageArray
   else
      return shellResult
   end if
end help_MenuMergeAndStore


--> Help | Launch
-
command launch_HelpMenu stackName
   put help_ConstructMenuUrl (stackName, true) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_HelpMenu

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

command launch_ObjectHelp tObject
   put the help_Url [true] of tObject into helpURL
   if helpURL is empty then return empty
   --
   launch url helpURL
   return helpURL
end launch_ObjectHelp

command launch_ProjectHelp projectName
   put the help_Url [true] of stack projectName into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_ProjectHelp

command launch_MenuSubdomain stackName
   put help_ConstructMenuPageTitle (stackName) into pageTitle
   put help_MenuSubDomain (pageTitle) into menuSubDomain
   --
   put fedwiki_ConstructUrlFromSlug (menuSubDomain) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_MenuSubdomain


--> Help | Construct
-
function help_ConstructHkeyURL hKey, pCheckURL
   put help_ConstructHandlerSlug (hKey) into pageSlug
   put "handler.livecode.world" into wikiDomain
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   --
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructHkeyURL

function help_ConstructMenuItemUrl hKey, pCheckURL
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   --
   put help_ConstructMenuPageTitle (stackName) into pageTitle
   put help_MenuSubDomain (pageTitle) into menuSubDomain
   --
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put fedwiki_ConstructUrlFromSlug (menuSubDomain, pageSlug) into helpURL
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   --
   return helpURL
end help_ConstructMenuItemUrl


--> Help | Menu | PageTitle
-
function help_ConstructMenuPageTitle gMenuTitle
   -- replace "_" with " | " in stackName
   put menu_StripGlobal (gMenuTitle) into pageTitle
   return word 1 to -1 of pageTitle
end help_ConstructMenuPageTitle


--> Help | Menu | Info
-
function help_ConstructMenuSubDomain gMenuTitle
   put menu_StripGlobal (gMenuTitle) into pageTitle
   put help_MenuSubDomain (pageTitle) into menuSubDomain
   return menuSubDomain
end help_ConstructMenuSubDomain

function help_MenuSubDomain pageTitle
   set the itemdelimiter to "|"
   put the number of items of pageTitle - 1 into maxNum
   repeat with itemNum = maxNum down to 1
      put word 1 to -1 of item itemNum of pageTitle into dBit
      put tolower (dBit) & "." after firstBit
   end repeat
   put firstBit & "menu.livecode.world" into menuSubDomain
   return menuSubDomain
end help_MenuSubDomain


--> Help
-
command help_SetHkeyInfo hKey, @wikiDomain, @pageSlug, @pageTitle   
   switch
      case hkey_IsMenuHandler (hKey)
         _SetMenuItemHelpInfo hKey, gMenuTitle, pageTitle, wikiDomain, pageSlug
         break
      case hkey_IsTransportHandler (hKey)
         put "transport.fedwiki.org" into wikiDomain
         hkey_Deconstruct hKey, hName, hType, hObject, hNum
         put the stack_Name of hObject into stackName
         put help_ConstructTransportTitle (stackName) into pageTitle 
         break
      default
         -- not a special handler so add to global library
         put "handler.livecode.world" into wikiDomain
         put help_ConstructHandlerTitle (hKey) into pageTitle
         put fedwiki_ConstructSlug (pageTitle) into pageSlug
   end switch
end help_SetHkeyInfo


--> Help | Menu | Check
-
command help_CheckUpdateMenuItem hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   
   # Menu-page: - create or update
   _CreateOrUpdate gMenuTitle
   
   # Menu-item: - create or update
   _CreateOrUpdateMenuItem hKey, menuSubDomain
end help_CheckUpdateMenuItem

function help_CheckMenu gMenuTitle
   put help_FetchMenuHelpArray (gMenuTitle) into pageArray
   return pageArray is not empty
end help_CheckMenu

function help_CheckMenuSubdomain hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put fedwiki_WikiExists (menuSubDomain) into subdomainExists
   return subdomainExists
end help_CheckMenuSubdomain


--> Help | Menu | Item
-
command help_CreateMenuItem hKey, pScriptHelp
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   --
   if word 1 of gMenuTitle is not "Global" then return empty
   
   -- fetch a handler template    
   put help_HkeyCurlyData (hKey, false) into hkeyCurlyData
   put help_FetchNewPageArray (hkeyPageTitle, "handler", hkeyCurlyData, pScriptHelp) into hkeyPageArray
   --
   pageArray_Store menuSubDomain, hkeySlug, hkeyPageArray
   return the result
end help_CreateMenuItem

command help_UpdateMenuItem hKey
   _SetMenuItemHelpInfo hKey, gMenuTitle, hkeyPageTitle, menuSubDomain, hkeySlug
   put pageArray_Fetch (menuSubDomain, hkeySlug) into hkeyPageArray
   if hkeyPageArray is empty then return empty
   --
   put help_HkeyCurlyData (hKey, true) into curlyData
   curly_MergePageArray hkeyPageArray, curlyData
   --
   pageArray_Store menuSubDomain, hkeySlug, hkeyPageArray
   return hkeyPageArray
end help_UpdateMenuItem


--> Help | Menu | Subdomain | Create
-
command help_CreateMenuSubdomain hKey
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
   put pageArray_Fetch ("menu.livecode.world", menuPageSlug) into menuPageArray
   if menuPageArray is empty then
      return merge ("error, there is no page [[menuPageSlug]] on menu.livecode.world to clone")
   end if
   --
   put help_ConstructMenuStory (gMenuTitle, "reference", mController) into storyArray
   pageArray_ReplaceSectionBody menuPageArray, "Menu", storyArray
   --
   pageArray_Rename menuPageArray, "Welcome Visitors"
   pageArray_StripJournal menuPageArray
   pageArray_AddFork menuPageArray, "handler.livecode.world,model.livecode.world,fedwiki.org"
   --
   pageArray_Store menuSubDomain, "welcome-visitors", menuPageArray
   --
   if the result is empty then
      return menuPageArray
   else
      return the result
   end if
end help_CreateMenuSubdomain

command help_UpdateMenuSubdomain hKey, pHow
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
end help_UpdateMenuSubdomain


--> Help | Menu | Create
-
command help_UpdateMenu gMenuTitle, pHow, pMenuController
   if pMenuController is empty then
      put menu_GetGlobalController (gMenuTitle) into pMenuController
   end if
   --
   put menu_StripGlobal (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into menuPageSlug
   --
   put pageArray_Fetch ("menu.livecode.world", menuPageSlug) into pageArray
   if pageArray is empty then return empty
   --
   put help_ConstructMenuStory (gMenuTitle, pHow, pMenuController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   --
   help_MenuMergeAndStore pMenuController, pageArray
   --
   return the result
end help_UpdateMenu


--> Help | Menu | Fetch
-
function help_FetchMenuHelpArray gMenuTitle
   -- fetch wiki-page in "menu.livecode.world"
   put menu_StripGlobal (gMenuTitle) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageArray_Fetch ("menu.livecode.world", pageSlug) into pageArray
   return pageArray
end help_FetchMenuHelpArray

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


--> Private
-
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
      put help_ConstructMenuSubDomain (gMenuTitle) into menuSubDomain
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
         put help_ConstructMenuSubDomain (gMenuTitle) into menuSubDomain
         return hObject
      else
         breakpoint
         lcw_AnswerWarning merge ("[[gMenuTitle]] is not present. Menu is not prepared for indexing!")
         return empty
      end if
   end if
end _SetMenuItemHelpInfo

private command _CreateOrUpdate gMenuTitle
   if help_CheckMenu (gMenuTitle) is true then
      help_UpdateMenu gMenuTitle, "reference"
      if the result is empty then
         breakpoint -- should create
      end if
   else
      help_CreateMenu gMenuTitle
   end if
end _CreateOrUpdate

private command _CreateOrUpdateMenuItem hKey, menuSubDomain
   if fedwiki_WikiExists (menuSubDomain) is true then
      help_UpdateMenuSubdomain hKey, "reference"
      if the result is empty then
         breakpoint -- should create
      end if
   else
      help_CreateMenuSubdomain hKey
   end if
end _CreateOrUpdateMenuItem

private command help_MenuItemMergeAndStore hKey, menuSubDomain, pageArray, pUpdate
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put help_HkeyCurlyData (hKey, pUpdate) into curlyData
   curly_MergePageArray pageArray, curlyData
   --
   pageArray_Store menuSubDomain, pageSlug, pageArray
   put the result into shellResult
   if shellResult is empty then
      return pageArray
   else
      return shellResult
   end if
end help_MenuItemMergeAndStore


--> Deps
-
private function fedwiki_ConstructSlug pageTitle
   -- it is very annoying that "_" is not an allowed character
   replace space with "-" in pageTitle
   repeat for each char someChar in  "()_|.,:;'"
      replace someChar with empty in pageTitle
   end repeat
   put tolower (pageTitle) into pageSlug
   return pageSlug
end fedwiki_ConstructSlug

