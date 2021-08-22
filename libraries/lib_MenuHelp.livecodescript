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

--> To Organise
-

--> Props
-
getprop menu_PermalinkMarkdown [pFast]
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
end menu_PermalinkMarkdown

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

command launch_ObjectHelp tObject
   put the help_Url [true] of tObject into helpURL
   if helpURL is empty then return empty
   --
   launch url helpURL
   return helpURL
end launch_ObjectHelp

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
   put fedwiki_ConstructUrlFromSlug (menuSubDomain) into someURL
   if someURL is empty then return empty
   --
   launch url someURL
   return someURL
end launch_MenuWikiDomain


--> Working on
-
function help_ConstructMenuStory gMenuTitle, pHow, pMenuController
   # Markdown to Github permalinks version
   if pHow is not among the items of "handler,reference" then
      put help_ConstructHandlerStoryMD (gMenuTitle, pMenuController) into storyArray
      return storyArray
   end if
   
   # Find the mController
   if pMenuController is empty then
      put menu_GetGlobalController (gMenuTitle) into pMenuController
   end if
   if exists (pMenuController) is false then return empty
   
   put the menu_Handlers [gMenuTitle] of pMenuController into mHandlers
   put help_ConstructHandlerStory (mHandlers, pHandlerObject) into pageArray
   
   return pageArray ["story"]
end help_ConstructMenuStory

function help_ConstructHandlerStoryMD gMenuTitle, pMenuController
   put help_ConstructMenuMarkdown (gMenuTitle, pMenuController) into someMarkdown
   put storyArray_ConstructItem (someMarkdown, "markdown") into storyArray [1]
   return storyArray
end help_ConstructHandlerStoryMD


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
   put the menu_PermalinkMarkdown [gMenuTitle] of pMenuController into someMarkdown
   put "# Menu" & CR&CR before someMarkdown
   --
   return someMarkdown
end help_ConstructMenuMarkdown

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

private function _Markdownline hName, hObject, commitHash, repoBit, relativePath, pText
   if pText is empty then put hName into pText
   --
   put hkey_Construct (hName, "M", hObject) into hKey
   hkeyLine_Offsets hObject, hKey, sLineNum, eLineNum
   put github_ConstructPermalink (commitHash, repoBit, relativePath, sLineNum, eLineNum) into webPermalink
   get "-" && "- [" & webPermalink && pText & "]"
   return it
end _Markdownline

private function fedwiki_ConstructSlug pageTitle
   -- it is very annoying that "_" is not an allowed character
   replace space with "-" in pageTitle
   repeat for each char someChar in  "()_|.,:;'"
      replace someChar with empty in pageTitle
   end repeat
   put tolower (pageTitle) into pageSlug
   return pageSlug
end fedwiki_ConstructSlug

