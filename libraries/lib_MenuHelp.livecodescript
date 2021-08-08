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


--> Help | Launch
-
command launch_MenuHelp gMenuTitle
   put help_ConstructMenuUrl (gMenuTitle, true) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_MenuHelp

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

command launch_MenuWikiDomain stackName
   put help_ConstructMenuPageTitle (stackName) into pageTitle
   put help_MenuWikiDomain (pageTitle) into menuSubDomain
   --
   put fedwiki_ConstructUrlFromSlug (menuSubDomain) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_MenuWikiDomain


--> Working on
-
function help_ConstructMenuMarkdown mTitle, pMenuController
   local pageArray
   if pMenuController is empty then put menu_GetGlobalController (gMenuTitle) into pMenuController
   if exists (pMenuController) is false then return empty
   
   put the filename of pMenuController into sFile
   put git_GetCommitFileHash (sFile, 1) into commitHash
   git_SetRelative sFile, relativePath, checkoutFolder
   --
   put "LiveCodeWorld" into repoBit
   set the itemdelimiter to slash
   put item -1 of checkoutFolder into item 2 of repoBit
   set the itemdelimiter to comma
   --
   put "# Menu" & CR&CR into someMarkdown
   put the menu_Index [mTitle] of pMenuController into mHandlers
   repeat for each line hName in mHandlers
      set the cursor to busy
      switch
         case hName = "-"
            put "- -" & CR after someMarkdown
            break
         default
            put menu_CommandToText (hName) into mText
            put hkey_Construct (hName, "M", pMenuController) into hKey
            --
            -- put the github_Permalink [hKey] of pMenuController into webPermalink
            --
            hkeyLine_Offsets pMenuController, hKey, sLineNum, eLineNum
            put github_ConstructPermalink (commitHash, repoBit, relativePath, sLineNum, eLineNum) into webPermalink
            
            get "-" && "- [" & webPermalink && mText & "]"
            put it & CR after someMarkdown
      end switch   
   end repeat
   delete char -1 of someMarkdown
   --
   put storyArray_ConstructItem (someMarkdown, "markdown") into storyArray [1]
   return storyArray
end help_ConstructMenuMarkdown

function help_ConstructMenuStory mTitle, pHow, pMenuController
   if pHow is not among the items of "handler,reference" then
      put help_ConstructMenuMarkdown (mTitle, pMenuController) into storyArray
      return storyArray
   end if
   
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
            put help_ConstructMenuWikiDomain (mTitle) into menuSubDomain
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


--> Help | Menu | Wiki
-
function help_FetchMenuWikiPageArray gMenuTitle, mController, pWikiDomain
   put help_ConstructMenuStory (gMenuTitle, "reference", mController) into storyArray
   --
   put help_ConstructMenuPageTitle (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into menuPageSlug
   put pageArray_Fetch ("menu.livecode.world", menuPageSlug) into menuPageArray
   if menuPageArray is empty then return merge ("Error, there is no page [[menuPageSlug]] on menu.livecode.world to clone")
   --
   pageArray_ReplaceSectionBody menuPageArray, "Menu", storyArray
   --
   # Add forks, rename and tidy
   help_RenameTemplate menuPageArray, "Welcome Visitors", pWikiDomain
   --
   return menuPageArray
end help_FetchMenuWikiPageArray

function help_ConstructMenuWikiDomain gMenuTitle
   put menu_StripGlobal (gMenuTitle) into pageTitle
   put help_MenuWikiDomain (pageTitle) into menuSubDomain
   return menuSubDomain
end help_ConstructMenuWikiDomain

function help_MenuWikiDomain pageTitle
   set the itemdelimiter to "|"
   put the number of items of pageTitle - 1 into maxNum
   repeat with itemNum = maxNum down to 1
      put word 1 to -1 of item itemNum of pageTitle into dBit
      put tolower (dBit) & "." after firstBit
   end repeat
   put firstBit & "menu.livecode.world" into menuSubDomain
   return menuSubDomain
end help_MenuWikiDomain


--> Help | Menu | Create
-
command help_CreateOrUpdateMenuPage gMenuTitle
   if help_CheckMenu (gMenuTitle) is true then
      help_UpdateMenu gMenuTitle, "reference"
      if the result is empty then
         breakpoint -- should create
      end if
   else
      help_CreateMenuPage gMenuTitle
   end if
end help_CreateOrUpdateMenuPage

command help_CreateMenuPage gMenuTitle, pMenuController
   if pMenuController is empty then put menu_GetGlobalController (gMenuTitle) into pMenuController
   --
   put help_CreateMenuPageArray (gMenuTitle, pMenuController, "links") into pageArray
   if pageArray is empty then return empty
   help_MenuMergeAndStore pMenuController, pageArray
   --
   return the result
end help_CreateMenuPage

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


--> Help | Menu | PageTitle
-
function help_ConstructMenuPageTitle gMenuTitle
   -- replace "_" with " | " in stackName
   put menu_StripGlobal (gMenuTitle) into pageTitle
   return word 1 to -1 of pageTitle
end help_ConstructMenuPageTitle


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

function help_CheckMenu gMenuTitle
   put help_FetchMenuHelpArray (gMenuTitle) into pageArray
   return pageArray is not empty
end help_CheckMenu


--> Private
-
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

