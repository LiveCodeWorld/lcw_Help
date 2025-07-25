﻿script "lib_MenuHelp"
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
command ask_CreateMenuPage mController, pDisplayView
   put the name of mController into oName
   if pDisplayView is empty then
      put rev_ScriptEditorStack () into pDisplayView
   end if
   get "Are you sure you wish to create the wiki help page for the script of [[oName]]? This will overwrite any existing page."
   lcw_Answer it, pDisplayView, oName
   
   help_CreateMenuFromController mController
   put the result into helpURL
   return helpURL
end ask_CreateMenuPage

function help_CreateMenuPageArray gMenuTitle, mController, pHow
   put menu_StripGlobal (gMenuTitle) into pageTitle
   
   # Fetch template
   put platform_LivecodeDomain ("menu") into wikiDomain
   put pageArray_Fetch (wikiDomain, "menu-template") into pageArray
   
   # Add forks, rename and tidy
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   
   # Replace Menu section
   put help_ConstructMenuStory (gMenuTitle, pHow, mController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   --
   return pageArray
end help_CreateMenuPageArray

private command help_MenuMergeAndStore pageArray, mController
   # Curly merge
   put the curly_Data of mController into curlyData
   curly_MergePageArray pageArray, curlyData
   
   # Store
   help_StoreMenuPageArray pageArray
   return the result
end help_MenuMergeAndStore

command help_StoreMenuPageArray pageArray
   put pageArray ["title"] into pageTitle -- could get from stackName?
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put help_ConstructDomain ("menu") into wikiDomain
   --
   pageArray_Set wikiDomain, pageSlug, pageArray
   put the result into shellResult -- url
   return shellResult
end help_StoreMenuPageArray

function help_ConstructMenuStory gMenuTitle, pHow, pMenuController
   # Find the mController
   if pMenuController is empty then
      put menu_GetGlobalController (gMenuTitle) into pMenuController
   end if
   if exists (pMenuController) is false then return empty
   
   switch pHow
      case "handler"
      case "reference"
         # Markdown to Github permalinks version
         put help_ConstructHandlerStoryMD (gMenuTitle, pMenuController) into storyArray
         break
      case "menu"
         put the menu_Handlers [gMenuTitle] of pMenuController into mHandlers
         put help_ConstructHandlerStory (mHandlers, pMenuController) into pageArray
         put pageArray ["story"] into storyArray
         break
      default
         put the menuItem_PermaBullets of pMenuController into sMarkdown
         get itemArray_Construct ("markdown", empty, sMarkdown)
         put it into storyArray[1]
   end switch
   return storyArray
end help_ConstructMenuStory

function help_ConstructHandlerStoryMD gMenuTitle, pMenuController
   put help_ConstructMenuMarkdown (gMenuTitle, pMenuController) into sMarkdown
   put itemArray_Construct ("markdown", empty, sMarkdown) into storyArray [1]
   return storyArray
end help_ConstructHandlerStoryMD

function help_FetchMenuPageArray gMenuTitle, mController, pHow
   put help_FetchMenuTemplate (gMenuTitle, mController) into pageArray
   put help_ConstructMenuStory (gMenuTitle, pHow, mController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   return pageArray
end help_FetchMenuPageArray

function help_FetchMenuTemplate gMenuTitle, mController
   put platform_LivecodeDomain ("menu") into wikiDomain
   put help_ConstructMenuPageTitle (gMenuTitle) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   if pageArray is empty then
      put platform_LivecodeDomain ("menu") into wikiDomain
      return merge ("Error, there is no page '[[pageTitle]]' on [[wikiDomain]] to clone!")
   end if
   return pageArray
end help_FetchMenuTemplate


--> Help | Menu | Create
-
command launch_MenuControllerHelp mController, pDisplayView
   put the menu_GlobalTitle of mController into gMenuTitle
   if gMenuTitle is empty then return "Error, no menu_GlobalTitle for:" && mController
   
   -- put the help_Url [true] of mController into helpURL
   put help_ConstructMenuUrl (gMenuTitle, true) into helpURL
   if helpURL is not empty then
      launch url helpURL
      return helpURL
   end if
   
   ask_CreateMenuPage mController, pDisplayView
   put the result into helpURL
   return helpURL
end launch_MenuControllerHelp

command help_CreateMenuFromController mController
   put the menu_GlobalTitle of mController into gMenuTitle
   if gMenuTitle is empty then return "Error, no menu_GlobalTitle for:" && mController
   
   ask_PushGithub mController
   help_CreateMenuPage gMenuTitle, mController
   --
   put help_ConstructMenuUrl (gMenuTitle, true) into helpURL
   launch url helpURL
   return helpURL
end help_CreateMenuFromController

command help_CreateMenuPage gMenuTitle, pMenuController
   if pMenuController is empty then put menu_GetGlobalController (gMenuTitle) into pMenuController
   --
   put help_CreateMenuPageArray (gMenuTitle, pMenuController, "links") into pageArray
   if pageArray is empty then return empty
   help_MenuMergeAndStore pageArray, pMenuController
   --
   if item 1 of the result = "Error" then
      return the result
   else
      put help_ConstructMenuUrl (gMenuTitle, true) into someURL
      return someURL
   end if
end help_CreateMenuPage

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

command help_UpdateMenu gMenuTitle, pHow, pMenuController
   if pMenuController is empty then
      put menu_GetGlobalController (gMenuTitle) into pMenuController
   end if
   --
   put menu_StripGlobal (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into menuPageSlug
   --
   put platform_LivecodeDomain ("menu") into wikiDomain
   put pageArray_Fetch (wikiDomain, menuPageSlug) into pageArray
   if pageArray is empty then return empty
   --
   put help_ConstructMenuStory (gMenuTitle, pHow, pMenuController) into storyArray
   pageArray_ReplaceSectionBody pageArray, "Menu", storyArray
   --
   help_MenuMergeAndStore pageArray, pMenuController
   --
   return the result
end help_UpdateMenu

function help_FetchMenuHelpArray gMenuTitle
   -- fetch wiki-page in "menu.livecode.wiki"
   put platform_LivecodeDomain ("menu") into wikiDomain
   --
   put menu_StripGlobal (gMenuTitle) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end help_FetchMenuHelpArray

command help_MenuItemMergeAndStore hKey, menuSubDomain, pageArray, pUpdate
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put help_HkeyCurlyData (hKey, pUpdate) into curlyData
   curly_MergePageArray pageArray, curlyData
   --
   pageArray_Set menuSubDomain, pageSlug, pageArray
   put the result into shellResult
   if shellResult is empty then
      return pageArray
   else
      return shellResult
   end if
end help_MenuItemMergeAndStore


--> Help | Launch
-
command launch_MenuHelp gMenuTitle
   if gMenuTitle is empty then
      put debug_CallingObject() into mController
      put the menu_GlobalTitle of mController into gMenuTitle
   end if
   if menu_Exists (gMenuTitle) is false then
      return "Error, cannot locate menu:" && gMenuTitle
   end if
   
   put help_ConstructMenuUrl (gMenuTitle, true) into someURL
   if someURL is not empty then
      launch url someURL
      return someURL
   end if
   
   help_CreateMenuPage gMenuTitle
   if item 1 of the result = "Error" then
      return the result
   else
      put help_ConstructMenuUrl (gMenuTitle, true) into someURL
      launch url someURL
      return someURL
   end if
end launch_MenuHelp

command launch_OrCreateProject projectName
   launch_ProjectHelp projectName
   --
   if the result is empty then
      if exists (stack projectName) is false then
         lcw_AnswerWarning "Cannot locate project home stack '[[projectName]]", projectName
      end if
      
      put the name of stack projectName into homeStackObject
      help_CreateFromObject homeStackObject
      --
      launch_ProjectHelp projectName
   end if
end launch_OrCreateProject

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
   put fedwiki_UrlFromSlug (menuSubDomain) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_MenuWikiDomain


--> Help
-
function help_ConstructHandlerStory mHandlers, pHandlerObject
   local pageArray
   repeat for each line hName in mHandlers 
      switch
         case hName = "-"
            pageArray_AddPagefold pageArray, "."
            break
         case pHow is "handler"
            put fedwiki_ConstructSlug (hName) into pageSlug
            put menu_CommandToText (hName) into mText
            --
            put platform_LivecodeDomain ("handler") into wikiDomain
            pageArray_AddReference pageArray, pageSlug, wikiDomain, mText, hName
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
            put hkey_Construct (hName, "M", pHandlerObject) into hKey
            --
            put the github_HandlerURL [hKey] of pHandlerObject into handlerURL
            put "-" && mText && "- [" & handlerURL && "github]" into someMarkdown
            --
            pageArray_AddMarkdown pageArray, someMarkdown
      end switch   
   end repeat
   return pageArray
end help_ConstructHandlerStory


--> Help | Menu | Wiki
-
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
   put platform_LivecodeDomain ("menu") into wikiDomain
   put firstBit & wikiDomain into menuSubDomain
   return menuSubDomain
end help_MenuWikiDomain


--> Help | Construct
-
function help_ConstructHkeyURL hKey, pCheckURL
   put help_ConstructHandlerSlug (hKey) into pageSlug
   put platform_LivecodeDomain ("handler") into wikiDomain
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   --
   put fedwiki_UrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructHkeyURL

function help_ConstructMenuPageTitle gMenuTitle
   -- replace "_" with " | " in stackName
   put menu_StripGlobal (gMenuTitle) into pageTitle
   return word 1 to -1 of pageTitle
end help_ConstructMenuPageTitle

function help_CheckMenu gMenuTitle
   put help_FetchMenuHelpArray (gMenuTitle) into pageArray
   return pageArray is not empty
end help_CheckMenu


--> Private
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

