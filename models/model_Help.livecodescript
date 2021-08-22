script "model_Help"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_HandlerHelp
type: model
version: 0.1


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
   if item 1 of the result = "Error" then
      return the result
   else
      put help_ConstructMenuUrl (gMenuTitle, true) into someURL
      return someURL
   end if
end help_CreateMenuPage

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

function help_CreateMenuPageArray gMenuTitle, mController, pHow
   put menu_StripGlobal (gMenuTitle) into pageTitle
   
   # Fetch template
   put pageArray_Fetch ("menu.livecode.world", "menu-template") into pageArray
   
   # Add forks, rename and tidy
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   
   # Replace Menu section
   put help_ConstructMenuStory (gMenuTitle, pHow, mController) into storyArray
   pageArray_ReplaceSection pageArray, "Menu", storyArray
   --
   return pageArray
end help_CreateMenuPageArray

function help_FetchMenuHelpArray gMenuTitle
   -- fetch wiki-page in "menu.livecode.world"
   put menu_StripGlobal (gMenuTitle) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put pageArray_Fetch ("menu.livecode.world", pageSlug) into pageArray
   return pageArray
end help_FetchMenuHelpArray

command help_MenuItemMergeAndStore hKey, menuSubDomain, pageArray, pUpdate
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

private command help_MenuMergeAndStore mController, pageArray
   put pageArray ["title"] into pageTitle -- could get from stackName ?
   --
   put help_ConstructDomain ("menu") into wikiDomain
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   put help_ObjectCurlyData (mController, "menu") into curlyData
   curly_MergePageArray pageArray, curlyData
   
   # Store
   -- help_CreatePageArray pageArray, "menu"
   pageArray_Store wikiDomain, pageSlug, pageArray
   put the result into shellResult -- url
   if item 1 of shellResult is "Error" then
      return shellResult
   else
      return pageArray
   end if
end help_MenuMergeAndStore


--> Help | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function help_FetchHandlerPageArray hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   put pageArray_Fetch ("handler.livecode.world", pageSlug) into pageArray
   return pageArray
end help_FetchHandlerPageArray

command help_StoreHandlerPageArray hKey, pageArray
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   pageArray_Store "handler.livecode.world", pageSlug, pageArray
   put the result into shellResult
   return shellResult
end help_StoreHandlerPageArray

function help_FetchObjectPageArray sObject
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end help_FetchObjectPageArray

command help_StoreObjectPageArray sObject, pageArray
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   pageArray_Store wikiDomain, pageSlug, pageArray
   return the result
end help_StoreObjectPageArray


--> Private
-
private command _ObjectDomainInfo sObject, @pageTitle, @pageSlug, @wikiDomain
   put the stack_Name of sObject into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the script_Type of sObject into scriptType
   put help_ConstructDomain (scriptType) into wikiDomain
end _ObjectDomainInfo

