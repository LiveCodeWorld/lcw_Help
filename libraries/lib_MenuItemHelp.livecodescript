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
function menuItem_PageArray mTitle, pMenuController
   # Checks
   if pMenuController is empty then
      put menu_GetGlobalController (mTitle) into pMenuController
   end if
   if exists (pMenuController) is false then
      return "Error, menu_Controller does not exist:" && pMenuController
   else
      put pMenuController into mController
   end if
   
   # Curly Data
   put menuItem_CurlyData (mTitle, mController) into curlyData
   
   # PageArray
   put help_CreateMenuPageArray (mTitle, mController, "links") into pageArray
   if pageArray is empty then return empty
   
   # Merge
   curly_MergePageArray pageArray, curlyData
   return pageArray
end menuItem_PageArray

function menuItem_CurlyData mTitle, pMenuController
   # Checks
   if pMenuController is empty then
      put menu_GetGlobalController (mTitle) into pMenuController
   end if
   if exists (pMenuController) is false then
      return "Error, menu_Controller does not exist:" && pMenuController
   else
      put pMenuController into mController
   end if
   
   # Basic curly_Data
   put the curly_Data of mController into curlyData
   
   # Tiddly Asset
   put help_TiddlyMenuFile (mTitle) into tiddlyAssetlink
   curly_SetAll curlyData, "tiddlyAssetlink", tiddlyAssetlink
   
   # Title Bullets
   put the menuItem_TitleBullets of mController into menuItemTitles
   curly_SetAll curlyData, "menuItemTitles", menuItemTitles
   
   # Handler Bullets
   put the menuItem_HandlerBullets of mController into menuItemBullets
   curly_SetAll curlyData, "menuItemBullets", menuItemBullets
   --
   return curlyData
end menuItem_CurlyData

command tiddly_CreateMenuHelp gMenuTitle, pShortTemplate
   put help_TiddlyMenuFile (gMenuTitle) into tFile
   
   # Create tiddlywiki file
   tiddly_Create tFile, pShortTemplate
   if item 1 of the result is "Error" then return the result
   --
   set the tiddly_Title [strapline] of tiddlyView to gMenuTitle
   
   # Fetch a handler template    
   put help_HkeyCurlyData (hKey, false) into hkeyCurlyData
   put hkeyPageTitle into hkeyCurlyData ["title"]
   --
   display_Data hkeyCurlyData
   
   put wikiPage_Help ("handler", hkeyCurlyData, pScriptHelp) into hkeyPageArray
   --
   display_Data hkeyPageArray
   
   -- put the menu_HandlerLines of mController into mLines
   -- put help_ConstructMenuPageTitle (gMenuTitle) into pageTitle
   -- put help_ConstructHandlerStory (mHandlers, mController) into pageArray
   -- put pageTitle into pageArray ["title"]
   -- display_TiddlyWikiFile tFile, wTitle
end tiddly_CreateMenuHelp

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


--> Props
-
getprop menu_Handlers [pAddDviders]
   -- put the menu_Controller of the target into mController
   put the long id of the target into mController
   put menuItem_List (mController, pAddDviders) into hNames
   return hNames
end menu_Handlers

getprop menu_HandlerLines [pAddDviders]
   put the long id of the target into mController
   put menuItem_List (mController, pAddDviders) into hNames
   repeat for each line hName in hNames
      if hName is among the chars of "-_" then
         if pAddDviders is not false then
            put "-" & CR after mLines
         end if
         next repeat
      end if
      
      put menu_CommandToText (hName) & CR after mLines
   end repeat
   delete char -1 of mLines
   return mLines
end menu_HandlerLines

getprop help_MenuPageArray
   put the long id of the target into mController
   put the menu_GlobalTitle of mController into gMenuTitle
   put help_FetchMenuPageArray (gMenuTitle, mController) into pageArray
   return pageArray
end help_MenuPageArray

getprop menuItem_TitleBullets [pAddDviders]
   put the menu_HandlerLines [pAddDviders] of the target into mItemLines 
   repeat for each line mItemLine in mItemLines
      if mItemLine = "_" then
         put "-" & CR after mItemBullets
      else
         put "-" && markdown_Link (mItemLine) & CR after mItemBullets
      end if
   end repeat
   delete char -1 of mItemBullets
   return mItemBullets
end menuItem_TitleBullets

getprop menuItem_HandlerBullets
   put the menu_Handlers of the target into hNames
   if line 1 of hNames = "_" then delete line 1 of hNames
   if line -1 of hNames = "_" then delete line -1 of hNames
   
   -- put markdown_LinkedBullets (hNames) into mItemBullets
   repeat for each line hName in hNames
      if hName = "_" then
         put "-" & CR after mItemBullets
      else
         put "-" && markdown_Link (hName) & CR after mItemBullets
      end if
   end repeat
   delete char -1 of mItemBullets
   return mItemBullets
end menuItem_HandlerBullets

getprop menuItem_PermaBullets [pFast]
   -- pFast can be true, false, or gMenutitle
   put the long id of the target into mController
   put the menu_Handlers [pFast] of mController into hNames
   
   # Construct markdown
   _SetCommitStuff mController, sFile, checkoutFolder, relativePath, commitHash, repoBit
   repeat for each line hName in hNames
      set the cursor to busy
      switch
         case hName = "_"
            put "- -" & CR after someMarkdown
            break
         default
            put menu_CommandToText (hName) into mText
            put _Markdownline (hName, mController, commitHash, repoBit, relativePath, mText) & CR after someMarkdown
      end switch   
   end repeat
   delete char -1 of someMarkdown
   return someMarkdown
end menuItem_PermaBullets

getprop handler_PermaMarkdown [pNotPrivate]
   put the long id of the target into hObject
   
   # Collect handler names
   put the script_HandlerNames [pNotPrivate] of hObject into hNames
   put help_ConstructMarkdown (hNames, hObject)into someMarkdown
   return someMarkdown
end handler_PermaMarkdown

getprop transport_PermaMarkdown [pNotPrivate]
   put the long id of the target into hObject
   
   # Collect handler names
   put the script_HandlerNames [pNotPrivate] of hObject into hNames
   put help_ConstructMarkdown (hNames, hObject)into someMarkdown
   return someMarkdown
end transport_PermaMarkdown


--> Help | Construct
-
function help_ConstructMarkdown hNames, hObject
   # Construct markdown
   _SetCommitStuff hObject, sFile, checkoutFolder, relativePath, commitHash, repoBit
   repeat for each line hName in hNames
      set the cursor to busy
      switch
         case hName = "_"
            put "- -" & CR after someMarkdown
            break
         default
            put _Markdownline (hName, hObject, commitHash, repoBit, relativePath) & CR after someMarkdown
      end switch   
   end repeat
   delete char -1 of someMarkdown
   return someMarkdown
end help_ConstructMarkdown

function help_ConstructMenuMarkdown gMenuTitle, pMenuController
   local pageArray
   if pMenuController is empty then put menu_GetGlobalController (gMenuTitle) into pMenuController
   if exists (pMenuController) is false then return empty
   
   # Update git and push if needed
   ask_PushGithub pMenuController
   
   # Construct menu-markdown  
   put the menuItem_PermaBullets [gMenuTitle] of pMenuController into someMarkdown
   put "# Menu" & CR&CR before someMarkdown
   --
   return someMarkdown
end help_ConstructMenuMarkdown

private function _Markdownline hName, hObject, commitHash, repoBit, relativePath, pText
   if pText is empty then put hName into pText
   --
   put hkey_Construct (hName, "M", hObject) into hKey
   hkeyLine_Offsets hObject, hKey, sLineNum, eLineNum
   put github_ConstructPermalink (commitHash, repoBit, relativePath, sLineNum, eLineNum) into webPermalink
   get "-" && "- [" & webPermalink && pText & "]"
   return it
end _Markdownline

private command _SetCommitStuff hObject, @sFile, @checkoutFolder, @relativePath, @commitHash, @repoBit
   put the filename of hObject into sFile
   put git_GetCommitFileHash (sFile, 1) into commitHash
   git_SetRelative sFile, relativePath, checkoutFolder
   --
   put "LiveCodeWorld" into repoBit
   set the itemdelimiter to slash
   put item -1 of checkoutFolder into item 2 of repoBit
   set the itemdelimiter to comma
end _SetCommitStuff


--> Display
-
command display_MenuItemHelp hKey
   hkeyLine_Deconstruct hKey, hName, hType, mController
   -- put the stack_Name of mController into mTitle
   
   set the itemdelimiter to "_"
   switch
      case hType is not "M"
      case item 1 of hName is not "menu"
         return "Error, handler is not a menu-item:" && hKey
      default
         put the menu_GlobalTitle of mController into mTitle
         if mTitle is empty then
            return "Error, handler is not in a menu_Controller:" && hKey
         end if
   end switch
   --
   put help_TiddlyMenuFile (mTitle) into mFile
   if there is not a file mFile then
      breakpoint
      tiddly_CreateMenuHelp mTitle
   end if
   
   display_MenuHelp mTitle
end display_MenuItemHelp

command display_MenuHelp mTitle
   put help_TiddlyMenuFile (mTitle) into mFile
   if there is not a file mFile then
      return "Error, help_TiddlyMenuFile() does not exist:" &&mFile
   end if
   --
   display_TiddlyWiki mFile
   put the result into tiddlyView
   --
   put the menuBar_View of tiddlyView into mBarView
   set the menuButton_Title of btn 2 of mBarView to "Global | Help | Tiddly | Menu"
   --
   return tiddlyView
end display_MenuHelp


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
   if helpURL is empty then
      return empty
   end if
   --
   launch url helpURL
   return helpURL
end launch_MenuItemHelp


--> Menu | File | Help
-
function help_ListTiddlyMenuTitles pPretty
   put help_ListShortMenuFiles() into shortFiles
   repeat for each line shortFile in shortFiles
      set the itemDelimiter to "."
      get item 1 of shortFile
      if pPretty is not false then
         set the itemDelimiter to "-"
         repeat with itemNum = 1 to the number of items of it
            put item itemNum of it into sItem
            put text_InitialCaps (sItem) into nItem
            put nItem into item itemNum of it
         end repeat
      end if
      
      replace "-" with " | " in it
      put it & CR after mTitles
   end repeat
   delete char -1 of mTitles
   return mTitles
end help_ListTiddlyMenuTitles

function help_ListTiddlyMenuFiles pListShort
   if pListShort is true then
      put help_TiddlyMenuFolder() into mFolder
      put files (mFolder) into shortFiles
      filter shortFiles with "*.html"
      return shortFiles
   else
      put help_TiddlyMenuFolder() into mFolder
      return file_ListLong (mFolder)
   end if
end help_ListTiddlyMenuFiles

function help_TiddlyMenuFile gMenuTitle
   put help_TiddlyMenuFolder() into mFolder
   put help_ShortMenuFile (gMenuTitle) into shortFile
   --
   put mFolder & shortFile into mFile
   return mFile
end help_TiddlyMenuFile

function help_TiddlyMenuFolder
   put help_MenuDomain() into mDomain
   put help_TiddlyFolder (mDomain, "menus") into mFolder
   return mFolder
end help_TiddlyMenuFolder


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
         put help_HandlerTitle (hKey) into pageTitle
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
