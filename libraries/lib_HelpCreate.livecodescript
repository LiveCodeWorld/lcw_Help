script "lib_HelpCreate"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_HelpCreate
type: library
version: 0.1

/*
*/


--> Working on
-
command display_HelpDraft sObject
   put the help_PageArray of sObject into helpPageArray
   -- comment 
   put the help_Domain of sObject into wikiDomain
   put display_ListWikiBrowsers (wikiDomain) into lcwBrowser
   if exists (lcwBrowser) is true then
      object_GoTo lcwBrowser
   else
      display_Wiki wikiDomain
      put the result into lcwBrowser
      wait 20 ticks
   end if
   --
   put helpPageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      set the page_Title [wikiDomain] of lcwBrowser to pageTitle
   end if
   
   set the ghost_PageArray of lcwBrowser to helpPageArray
   return lcwBrowser
end display_HelpDraft

getprop help_PageArray
   put the long id of the target into sObject
   --
   put the script_MetaData of sObject into sMetaData
   put sMetaData ["script_Help"] into scriptHelp
   put sMetaData ["type"] into scriptType
   
   put help_ObjectCurlyData (sObject, scriptType) into curlyData
   put curlyData ["title"] into pageTitle
   
   # Construct
   put help_FetchNewPageArray (pageTitle, scriptType, curlyData, scriptHelp) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain (scriptType) into helpDomain
      put merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'") into someMarkdown
      put pageArray_Construct ("Error", someMarkdown) into pageArray
   end if
   
   return pageArray
end help_PageArray
   

--> Help | Create
-
command help_CreateFromObject sObject
   breakpoint
   put the script_Type of sObject into scriptType
   switch scriptType
      case "controller"
      case "menu"
         put line 1 of the script_GlobalMenuTitles of sObject into gMenuTitle -- just in case
         --
         put the stack_Name of sObject into stackName
         if stackName is not gMenuTitle then breakpoint -- stackName should be gMenuTitle
         --
         help_CreateMenuPage gMenuTitle
         break
      case "transport"
         help_CreateTransportPage sObject
         break
      default
         put the script_MetaData ["script_Help"] of sObject into pScriptHelp
         put help_ObjectCurlyData (sObject, scriptType) into curlyData
         put curlyData ["title"] into pageTitle
         --
         help_Create pageTitle, scriptType, curlyData, pScriptHelp
         put the result into shellResult
         return shellResult
   end switch
end help_CreateFromObject

command help_Create pageTitle, scriptType, curlyData, pScriptHelp
   # Construct
   put help_FetchNewPageArray (pageTitle, scriptType, curlyData, pScriptHelp) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain (scriptType) into helpDomain
      return merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'")
   end if
   
   help_CreatePageArray pageArray, scriptType
   return the result
end help_Create

command help_CreatePageArray pageArray, scriptType
   # Check pageArray
   if pageArray_Check (pageArray) is false then return "Error, not storing. Faulty pageArray"
   
   # Work out domain and slug
   put help_ConstructDomain (scriptType) into helpDomain
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Store
   pageArray_Set helpDomain, pageSlug, pageArray
   put the result into wikiFile
   wikiSiteMap_Create helpDomain
   return wikiFile
end help_CreatePageArray

function help_FetchNewPageArray pageTitle, scriptType, curlyData, pScriptHelp
   put help_ConstructDomain (scriptType) into wikiDomain
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Fetch Template
   put help_FetchTemplateArray (scriptType) into pageArray
   if pageArray_Check (pageArray) is false then return empty
   if pScriptHelp is not empty then put pScriptHelp into pageArray ["story"][1]["text"]
   --
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   --
   switch scriptType
      case "transport"
      default
         curly_MergePageArray pageArray, curlyData
         dispay_Data curlyData, "Hanlder", "curlyData"
         exit to top
         
         put curly_GetData (curlyData, "callList") into callList
         if word 1 of callList is not "-" then
            -- not a list
            put pageArray_FindItemType ("graphviz", pageArray) into itemNum
            pageArray_DeleteItem pageArray, itemNum
         end if
   end switch
   
   # Add Fork
   pageArray_StripJournal pageArray
   put url_GetTLD (wikiDomain) into tldDomains
   put CR & "fedwiki.org" after tldDomains
   pageArray_AddFork pageArray, tldDomains
   --
   
   return pageArray
end help_FetchNewPageArray
