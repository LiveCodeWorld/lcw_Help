script "lib_Draft"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_Draft
type: library
version: 0.1


--> Working on
-
command draft_ScriptHelp sObject, pOverlayName
   put the help_PageArray [pOverlayName] of sObject into helpPageArray
   
   draft_WikiPage "localhost", helpPageArray 
   put the result into wikiBrowser
   return wikiBrowser
end draft_ScriptHelp



--> Draft
-
command draft_ModuleHelp moduleName, pOverlayName
   put view_GetTemplateObject (moduleName) into mObject
   if exists (mObject) is false then
      breakpoint
      return "Error, cannot find module:" && moduleName
   end if
   --
   put the help_PageArray [pOverlayName] of mObject into helpPageArray
   --
   -- put the help_Domain of mObject into wikiDomain
   put "module." & LcwDomain into wikiDomain
   draft_PageArray wikiDomain, helpPageArray
   put the result into wikiBrowser
   return wikiBrowser
end draft_ModuleHelp

command draft_ProjectHelp sObject, pOverlayName
   put the help_PageArray [pOverlayName] of sObject into helpPageArray
   -- 
   put the help_Domain of sObject into wikiDomain
   draft_PageArray wikiDomain, helpPageArray
   put the result into wikiBrowser
   return wikiBrowser
end draft_ProjectHelp

command draft_WikiPage wikiDomain, pageArray, pLaunch
   put pLaunch is not false into pLaunch
   
   # Display Ghost
   -- put fedWiki_FindBrowser (wikiDomain, pLaunch) into wikiBrowser
   
   put display_ListWikiBrowsers (wikiDomain) into wikiBrowser
   if exists (wikiBrowser) is true then
      object_GoTo wikiBrowser
      --
      set the ghost_PageArray of wikiBrowser to pageArray
      return wikiBrowser
   else if pLaunch is true then
      display_Wiki wikiDomain
      put the result into wikiBrowser
      
      # Wait (until wiki loaded)
      wait 40 ticks with messages
      set the ghost_PageArray of wikiBrowser to pageArray
      return wikiBrowser
   else
      return "Error, wiki browser is not open."
   end if
end draft_WikiPage

command draft_HandlerHelp hKey
   answer "Display draft, or create handler help.." with "Draft" or "Create"
   if it is "Draft" then
      put draft_HkeyPageArray(hKey) into pageArray
      --
      put help_HandlerDomain() into handlerDomain
      draft_WikiPage handlerDomain, pageArray
      put the result into wikiBrowser
      return wikiBrowser
   else
      hkeyHelp_Create hKey
      put the result into handlerURL
      return handlerURL
   end if
end draft_HandlerHelp

function draft_HkeyPageArray hKey
   put hkey_ArrayFile (hKey) into hkeyArrayFile
   if there is not a file hkeyArrayFile then
      graph_Hkey hKey
   end if
   --
   put help_FromHkey (hKey) into pageArray
   return pageArray
end draft_HkeyPageArray

command draft_PageArray wikiDomain, pageArray
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Find Wiki Browser
   put display_ListWikiBrowsers (wikiDomain) into wikiBrowser
   if exists (wikiBrowser) is true then
      object_GoTo wikiBrowser
   else
      display_Wiki wikiDomain
      put the result into wikiBrowser
      wait 40 ticks
   end if
   
   # Display Ghost
   set the ghost_PageArray of wikiBrowser to pageArray
   
   # Display Page (if exists)
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      set the page_Title [wikiDomain] of wikiBrowser to pageTitle
   end if
   return wikiBrowser
end draft_PageArray


--> Deps
-
