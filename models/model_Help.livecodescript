script "model_Help"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: model_HandlerHelp
type: model
version: 0.1


--> Help | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function help_FetchHkeyPageArray hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   return help_FetchHkeyPageArray (hName)
end help_FetchHkeyPageArray

command help_StoreHkeyPageArray hKey, pageArray
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   help_StoreHandlerPageArray hName, pageArray
   return the result
end help_StoreHkeyPageArray

function help_FetchHandlerPageArray hName
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   put pageArray_Fetch ("handler.livecode.world", pageSlug) into pageArray
   return pageArray
end help_FetchHandlerPageArray

command help_StoreHkeyPageArray hName, pageArray
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   pageArray_Store "handler.livecode.world", pageSlug, pageArray
   put the result into shellResult
   return shellResult
end help_StoreHkeyPageArray

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

