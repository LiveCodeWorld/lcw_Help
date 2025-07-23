script "lib_Help"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Help
type: library
version: 0.4
deps: lcw_Wiki

/*
lcw_Help uses the federated wiki to store it's help.
As such you need to initiate the lcw_Wiki rpject for these handlers to work.
*/

--> Launch
-
command launch_ScriptHelp sObject
   put the script_MetaData of sObject into mArray
   put mArray ["name"] into pageTitle
   put mArray ["type"] into scriptType
   --
   put help_ConstructDomain (scriptType) into hDomain
   --
   launch_Fedwiki hDomain, pageTitle, "https"
   return the result
end launch_ScriptHelp


--> Working on
-
command hkeyHelp_Create hKey, pLaunch, pProtocol
   # Construct pageArray
   put draft_HkeyPageArray (hKey) into pageArray
   
   # Store Old
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put help_HandlerDomain() into handlerDomain
   pageArray_Set handlerDomain, pageSlug, pageArray, true
   
   # Move Old
   put hkey_Folder (hKey) into hkeyFolder
   old_MoveHandlerFolder hkeyFolder
   
   # Launch
   put fedwiki_ConstructURL (handlerDomain, pageSlug, pProtocol) into handlerURL
   if pLaunch is true then
      launch url handlerURL
   end if
   return handlerURL
end hkeyHelp_Create


--> Props
-
getprop scriptHelp_PageArray
   put the long id of the target into sObject
   --
   put the scriptHelp_Domain of sObject into hDomain
   put the scriptHelp_Slug of sObject into pSlug
   put pageArray_Get (hDomain, pSlug) into pArray
   return pArray
end scriptHelp_PageArray

setprop scriptHelp_PageArray [pDeleteSiteMap] pArray
   put the long id of the target into sObject
   --
   put the scriptHelp_Domain of sObject into hDomain
   put the scriptHelp_Slug of sObject into pSlug
   pageArray_Set hDomain, pSlug, pArray, pDeleteSiteMap
   put the result into wikiFile
   return wikiFile
end scriptHelp_PageArray

getprop scriptHelp_PageFile
   put the long id of the target into sObject
   --
   put the scriptHelp_Domain of sObject into hDomain
   put the scriptHelp_Slug of sObject into pSlug
   --
   put wikiFile_Construct (hDomain, pSlug) into wikiFile
   return wikiFile
end scriptHelp_PageFile

getprop scriptHelp_Slug
   put the script_MetaProp ["name"] of the target into sName
   put fedwiki_ConstructSlug (sName) into pSlug
   return pSlug
end scriptHelp_Slug

getprop scriptHelp_Domain
   put the script_Type of the target into sType
   put help_ConstructDomain (sType) into hDomain
   return hDomain
end scriptHelp_Domain

getprop scriptHelp_JsonFile
   put the script_MetaData of the target into mArray
   put mArray ["name"] into pageTitle
   put mArray ["type"] into scriptType
   
   put help_ConstructDomain (scriptType) into helpDomain
   put fedwiki_ConstructSlug (pageTitle) into pSlug
   
   put wikiFile_Construct (helpDomain, pSlug) into wikiFile
   return wikiFile
end scriptHelp_JsonFile

getprop script_HelpFile [pDontCreate]
   -- old metadata files (now wiki json)
   put the long id of the target into sObject
   put the textStack_MetadataFolder [pDontCreate] of sObject into metadataFolder
   put metadataFolder & "help.html" into someFile
   return someFile
end script_HelpFile

getprop scriptHelp_Url [pCheckURL]
   put the long id of the target into tObject
   put the stack_Name of tObject into stackName
   put the script_Type of tObject into scriptType
   put help_ConstructURL (stackName, scriptType, pCheckURL) into someURL
   return someURL
end scriptHelp_Url


--> Menu | File | Help
-
function help_ListMenuTitles pPretty
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
end help_ListMenuTitles

function help_ListMenuFiles
   put help_MenuFolder() into mFolder
   return file_ListLong (mFolder)
end help_ListMenuFiles

function help_ListShortMenuFiles
   put help_MenuFolder() into mFolder
   put files (mFolder) into shortFiles
   filter shortFiles with "*.html"
   return shortFiles
end help_ListShortMenuFiles

function help_MenuFolder
   put help_MenuDomain() into mDomain
   put help_TiddlyFolder (mDomain, "menus") into mFolder
   return mFolder
end help_MenuFolder

function help_MenuFile gMenuTitle
   put help_MenuFolder() into mFolder
   put help_ShortMenuFile (gMenuTitle) into shortFile
   --
   put mFolder & shortFile into mFile
   return mFile
end help_MenuFile

function help_TiddlyFile shortFile, wDomain, pShortFolder
   put help_TiddlyFolder (wDomain, pShortFolder) into tiddlyFolder
   put tiddlyFolder & shortFile into mFile
   return mFile
end help_TiddlyFile

function help_ListShortTiddlyFiles wDomain, pShortFolder
   put help_TiddlyFolder (wDomain, pShortFolder) into tiddlyFolder
   put files (tiddlyFolder) into shortFiles
   filter shortFiles with "*.html"
   return shortFiles
end help_ListShortTiddlyFiles

function help_TiddlyFolder wDomain, pShortFolder
   if pShortFolder is empty then put "tiddly-wikis" into pShortFolder
   --
   put wikiFolder_ConstructAssets (wDomain, pShortFolder) into tiddlyFolder
   folder_CreateNested tiddlyFolder
   return tiddlyFolder
end help_TiddlyFolder

function help_ShortMenuFile gMenuTitle
   get replaceText (gMenuTitle, "\s*\|\s*", "-")
   put tolower (it) & ".html" into shortFile
   return shortFile
end help_ShortMenuFile


--> Help
-
function help_MenuDomain
   -- the domain and short name of wiki folder
   put "menu." & platform_LivecodeDomain() into menuDomain
   return menuDomain
end help_MenuDomain

function help_HandlerDomain
   -- the domain and short name of wiki folder
   put "handler." & platform_LivecodeDomain() into handlerDomain
   return handlerDomain
end help_HandlerDomain

function help_ConstructSlug subDomain
   _FixType subDomain
   put subDomain & "-" & "template" into pageSlug
   return pageSlug
end help_ConstructSlug

function help_RelatedStacks stackName
   put word 1 to 3 of text_SplitCaps (stackName) into sFilter
   replace space with empty in sFilter
   put "*" after sFilter
   --
   put env_ListUsedStackNames() into modelsAndLibs
   filter modelsAndLibs with sFilter
   return modelsAndLibs
end help_RelatedStacks


--> Help | Tags
-
function help_GetTagItems hNames
   put help_GetTags (hNames, ",") into tagItems
   replace CR with empty in tagItems
   delete char 1 to 2 of tagItems
   return tagItems
end help_GetTagItems

function help_GetTags hNames, pBullet
   if pBullet is empty then put "-" into pBullet -- comma or "1."
   replace comma with CR in hNames
   repeat for each line hName in hNames
      put text_SplitIntoWords (hName) into tagNames
      repeat for each line tagName in tagNames
         put tolower (tagName) into someTag
         put pBullet && "[[" & someTag & "]]" into tagLine
         put someTag into tagArray [tagLine]
      end repeat
   end repeat
   put the keys of tagArray into helpTagLines
   sort lines of helpTagLines by token 4 of each 
   return helpTagLines
end help_GetTags


--> Help | Template | Model
-
function help_ConstructDomain scriptType
   _FixType scriptType
   put platform_LivecodeDomain (scriptType) into wikiDomain
   return wikiDomain
end help_ConstructDomain

command help_RenameTemplate @pageArray, pageTitle, pWikiDomain
   put _ForkDomainItems() into forkDomains
   --
   pageArray_Rename pageArray, pageTitle
   pageArray_StripJournal pageArray
   
   # Strip wikidomain fromm forks (not important)
   set the wholematches to true
   put itemOffset (pWikiDomain, forkDomains) into itemNum
   delete item itemNum of forkDomains
   
   # Add forks to journal
   pageArray_AddFork pageArray, forkDomains
end help_RenameTemplate


--> Help | Construct
-
function help_ConstructTitle stackName, scriptType
   switch
      case scriptType = "transport"
         return help_ConstructTransportTitle (stackName)
      case scriptType is "controller"
      case scriptType is "menu"
         return help_ConstructMenuPageTitle (stackName)
      default
         return stackName
   end switch
end help_ConstructTitle

function help_ConstructMenuUrl gMenuTitle, pCheckURL
   put help_ConstructDomain ("menu") into wikiDomain
   put help_ConstructMenuPageTitle (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into pageSlug
   
   # Return emmpty if page does not exist
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   
   # Construct and return page utl
   put fedwiki_UrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructMenuUrl

function help_ConstructURL stackName, scriptType, pCheckURL
   put help_ConstructDomain (scriptType) into wikiDomain
   put help_ConstructTitle (stackName, scriptType) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   --
   put fedwiki_UrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructURL


--> Private
-
private function _ForkDomainItems
   put "fedwiki.club" into forkDomains
   --
   put comma & platform_LivecodeDomain() after forkDomains
   repeat for each item subName in "library,model,menu,handler,project"
      put comma & platform_LivecodeDomain (subName) after forkDomains
   end repeat
   return forkDomains
end _ForkDomainItems

private command _FixType @scriptType
   switch scriptType
      case "home"
         put "project" into scriptType
         break
      case "controller"
         put "menu" into scriptType
         break
      case "view"
         put "module" into scriptType
         break
   end switch
end _FixType
