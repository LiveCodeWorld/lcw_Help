script "lib_TransportHelp"
--> MetaData
-
copyright: Anonymous
license: GPLv3
name: lib_TransportHelp
type: library
version: 0.1

/*Some help*/


--> Working on
-
command help_CreateTransportPage tObject, pageTitle, pScriptHelp
   put "transport" into scriptType
   --
   put the dep_StackNames of tObject into dProjectNames
   replace comma with CR in dProjectNames
   --
   put the stack_Name of tObject into stackName
   put stackName into tName
   replace ".lc" with empty in tName
   put help_ConstructTitle (stackName, scriptType) into pageTitle
   
   put help_ObjectCurlyData (tObject, scriptType) into curlyData
   /*
   put the transport_DepHkeyArray of tObject into hKeyArray
   put hkeyArray_GetProjectDepArray (hkeyArray) into dArray
   put the keys of dArray into dProjectNames
   --  put hkeyArray_GetStackDepArray (hkeyArray) into objectDepArray
   */
   
   put pageTitle into curlyData ["all"]["transport name"]
   put tName into curlyData ["all"]["transport route"]
   put the rig_RouteNames of tObject into routeNames
   put help_GetTagItems (routeNames) into curlyData ["all"]["tagNames"]
   put fedwiki_MarkdownIndex (dProjectNames) into curlyData ["all"]["Project Deps"]
   put "https://rest.livecode.world/" & tName into curlyData ["all"]["restURL"]
   
   put pageTitle into curlyData ["title"]
   put wikiPage_Help ("Transport", curlyData, pScriptHelp) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain ("transport") into helpDomain
      return merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'")
   end if
   
   # Get script markdown
   put help_ConstructMarkdown (routeNames, tObject)into someMarkdown
   put "# Routes" & CR&CR before someMarkdown
   
   # Replace "Routes section
   put storyArray_ConstructItem (someMarkdown, "markdown") into storyArray [1]
   pageArray_ReplaceSectionBody pageArray, "Routes", storyArray
   
   # Store 
   help_StorePageArray pageArray, scriptType
   return the result
end help_CreateTransportPage

function help_ConstructTransportTitle stackName
   set the itemdelimiter to "."
   put text_InitialCaps (item 1 of stackName) && "Transport" after pageTitle
   return pageTitle
end help_ConstructTransportTitle


--> Transport | Help
-
command transport_CreateHkeyHelp hKey, pScriptHelp
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   if the result = "index" then
      put _TransportHkeyCurlyData (hKey) into curlyData
      help_Create pageTitle, "transport", curlyData, pScriptHelp
   else
      -- updates "Welcome Visitors" every time! Could check.
      transport_CreateRouteWelcomeHelp hKey
      transport_CreateRouteHelp hKey
   end if
   put the result into shellResult
   return shellResult
end transport_CreateHkeyHelp

command transport_CreateRouteWelcomeHelp routeHkey
   hkey_Normalize routeHkey
   put routeHkey into indexHkey
   put "index" into word 2 of indexHkey
   _TransportInfo indexHkey, indexDomain, indexTitle, indexSlug, iObject   
   _TransportInfo routeHkey, rootDomain, routeTitle, routeSlug, rObject
   
   -- check Welcome-visitors for subdomain
   put transport_FetchHkeyHelpPageArray (indexHkey) into pageArray
   switch
      case pageArray is empty
         breakpoint -- Welcome-visitors for subdomain does not exist. Let's create it
         break
      case pageArray ["title"] is not indexTitle
         breakpoint -- 
         
         help_Create indexTitle, "transport", curlyData, pScriptHelp
         put the result into pageArray
         if pageArray is not an array then
            breakpoint
            return empty
         end if
         
         pageArray_Rename pageArray, "Welcome Visitors"
         pageArray_StripJournal pageArray
         pageArray_AddFork pageArray, "transport.livecode.world,handler.livecode.world,library.livecode.world,model.livecode.world,fedwiki.org"
         break
      default
         breakpoint -- Welcome-visitors for subdomain already exists so let's update metadata
         
         put pageArray_Fetch (rootDomain, "welcome-visitors") into pageArray -- get old subpage welcome
         put _TransportHkeyCurlyData (indexHkey) into curlyData -- update with latest index.lc metadata
         curly_MergePageArray pageArray, curlyData
   end switch
   --
   pageArray_Set rootDomain, "welcome-visitors", pageArray
   return pageArray
end transport_CreateRouteWelcomeHelp

command transport_CreateRouteHelp hKey
   put _TransportHkeyCurlyData (hKey) into curlyData
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   --
   put pageArray_Fetch ("transport.livecode.world", "transport-route-template") into pageArray
   pageArray_Rename pageArray, pageTitle
   --
   curly_MergePageArray pageArray, curlyData
   pageArray_StripJournal pageArray
   pageArray_AddFork pageArray, "transport.livecode.world,handler.livecode.world,library.livecode.world,model.livecode.world,fedwiki.org"
   --
   pageArray_Set wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end transport_CreateRouteHelp

command transport_UpdateHelp hKey
   put transport_FetchHkeyHelpPageArray (hKey) into pageArray
   put _TransportHkeyCurlyData (hKey) into curlyData
   curly_MergePageArray pageArray, curlyData
   transport_StoreHkeyHelpPageArray hKey, pageArray
end transport_UpdateHelp

function transport_HelpURL hKey, pCheckURL
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   if pCheckURL is true then
      put fedwiki_IsWikiPage (wikiDomain, pageSlug) into isWiki
      if isWiki is false then
         return empty
      end if
   end if
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end transport_HelpURL

function transport_IndexHkey hObject
   put hKeyLine_Construct ("index", "c", hObject) into hKey
   return hKey
end transport_IndexHkey

function transport_IndexDotText hObject
   put transport_IndexHkey (hObject) into hKey
   put hkey_GetDotText (hKey) into dotText
   return dotText   
end transport_IndexDotText


--> Transport | Model
-
function transport_FetchHkeyHelpPageArray hKey
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end transport_FetchHkeyHelpPageArray

command transport_StoreHkeyHelpPageArray hKey, pageArray
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   pageArray_Set wikiDomain, pageSlug, pageArray
   put the result into shellResult
   return shellResult
end transport_StoreHkeyHelpPageArray


--> Private
-
private function _TransportHkeyCurlyData hKey
   put help_HkeyCurlyData (hKey) into curlyData
   --
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put the result into hName
   put hName into curlyData ["all"]["hName"]
   put pageTitle into curlyData ["all"]["transportName"]
   --
   _SetTransportMetadata curlyData, hKey
   _SetCurlyRestURL curlyData, hObject, hName
   _SetCurlyTransportRoutes curlyData, hObject
   _SetTransportWhere curlyData, hKey
   --
   return curlyData
end _TransportHkeyCurlyData

private command _SetTransportWhere @curlyData, hKey
   _TransportInfo hKey, wikiDomain, pageTitle, pageSlug, hObject
   put itemArray_ConstructReference (pageSlug, wikiDomain, wikiDomain, pageTitle) into itemArray
   curly_SetReplaceArray curlyData, itemArray, "4ecda1442570d900"
end _SetTransportWhere

private command _SetTransportMetadata @curlyData, hKey
   put hkey_GetType (hKey) into handlerType
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the github_RelativePath of hObject into relPath
   --
   put "Type: transport" & CR after handlerMetaData
   put "Project:" && the project_Name of hObject & CR after handlerMetaData
   put "Github:" && relPath & CR after handlerMetaData
   delete char -1 of handlerMetaData
   --
   put handlerMetaData into curlyData ["id"]["da8cf69872f38050"]
end _SetTransportMetadata

private command _SetCurlyTransportRoutes @curlyData, sObject
   put the rig_ControllerHandlers of sObject into handlerNames
   replace comma with CR in handlerNames
   line_Delete "index", handlerNames
   if handlerNames is not empty then
      put fedwiki_MarkdownIndex (handlerNames) into curlyData ["id"]["642e249b4a7faa02"]
   end if
end _SetCurlyTransportRoutes

private command _SetCurlyRestURL @curlyData, sObject, hName
   put the stack_Name of sObject into stackName
   set the itemdelimiter to "."
   put item 1 of stackName into shortFile
   put "https://rest.livecode.world/" & shortFile into restURL
   if hName is not "index" then
      put slash & hName after restURL
   end if
   put "POST" && restURL into curlyData ["id"]["10ea2af363e51a5f"]
   put restURL into curlyData ["all"]["restURL"]
end _SetCurlyRestURL
