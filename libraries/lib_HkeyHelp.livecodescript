script "lib_HkeyHelp"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_HkeyHelp
type: library
version: 0.1

/*Some help*/


--> Working on
-
function markdown_TagItems someTags, pNotThese
   repeat for each line someTag in someTags
      if someTag is among the items of pNotThese then next repeat
      put "[[" & someTag & "]], " after handlerTagList
   end repeat
   delete char -2 to -1 of handlerTagList
   return handlerTagList
end markdown_TagItems


--> Help
-
getprop script_MarkdownHandlerIndex
   put the long id of the target into hObject
   put the revAvailableHandlers of hObject into hTable
   repeat for each line hTableLine in hTable
      put word 1 of hTableLine into hType
      if char 1 of hType = "P" then next repeat
      
      put word 2 of hTableLine into hName
      put word 3 of hTableLine + 1 into sLineNum
      put word 4 of hTableLine + 1 into eLineNum
      
      put github_handlerURL (hObject, sLineNum, eLineNum) into githubURL 
      put "- [" & hName & "](" & githubURL & ")" & CR after markdownIndex
   end repeat
   delete char -1 of markdownIndex
   return markdownIndex
end script_MarkdownHandlerindex


--> Hkey | Help
-
command help_CreateFromHkey hKey, pScriptHelp
   put hkey_IsMenuHandler (hKey) into isMenuHandler
   switch
      case isMenuHandler is true
         help_CreateMenuItem hKey, pScriptHelp
         break
      case hkey_IsTransportHandler (hKey)
         transport_CreateHkeyHelp hKey, pScriptHelp
         break
      default
         put help_FromHkey (hKey, pScriptHelp) into pageArray
         breakpoint
         help_StoreHkeyPageArray hKey, pageArray
   end switch
end help_CreateFromHkey

function help_FromHkey hKey, pScriptHelp
   put help_ConstructHandlerTitle (hKey) into pageTitle
   put help_HkeyCurlyData (hKey, false) into curlyData
   put pageTitle into curlyData ["title"]
   --
   put wikiPage_Help ("handler", curlyData, pScriptHelp) into pageArray
   return pageArray
end help_FromHkey

function help_GetHkeyTags hKey
   put help_FetchHkeyPageArray (hKey) into pageData
   _SetHkeyPageItemDictionary pageData
   --
   put pageData_GetText (pageData, "handlerTags") into handlerTags
   replace "[[" with empty in handlerTags
   replace "]]" with empty in handlerTags
   replace "-" with empty in handlerTags
   replace space with empty in handlerTags
   return handlerTags
end help_GetHkeyTags

function help_ConstructHandlerSlug hKey
   put help_ConstructHandlerTitle (hKey) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   return pageSlug
end help_ConstructHandlerSlug

function help_ConstructHandlerTitle hKey
   -- here we can experiment with different types of names
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   return hName
end help_ConstructHandlerTitle

function help_HkeyCurlyData hKey, pUpdate
   local curlyData
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   --
   curly_SetAll curlyData, "object", the name of hObject
   curly_SetAll curlyData, "stackName", the stack_Name of hObject
   curly_SetAll curlyData, "handlerType", hkey_GetType (hKey)
   --   
   put handler_Get (hKey, true) into someHandler
   help_TidyHandler someHandler
   curly_SetAll curlyData, "someHandler", someHandler
   --
   put hkey_GetDotText (hKey) into dotText
   if dotText is not empty then curly_SetAll curlyData, "dotText", dotText
   --
   put _ConstructHandlerSyntax (someHandler, hKey) into handlerSyntax
   curly_SetAll curlyData, "handlerSyntax", handlerSyntax
   --
   put _ConstructCallList (someHandler) into callList
   curly_SetAll curlyData, "callList", callList
   --
   put _ConstructParamList (someHandler) into paramList
   curly_SetAll curlyData, "paramList", paramList
   --
   put _ConstructHandlerTags (hKey, pUpdate) into handlerTags -- also look inside handler
   curly_SetAll curlyData, "handlerTags", handlerTags
   --
   put the project_Name of hObject into projectName
   put _ConstructHandlerMetadata (hKey, projectName) into handlerMetadata
   curly_SetAll curlyData, "projectName", projectName
   curly_SetAll curlyData, "handlerMetadata", handlerMetadata
   --
   curly_SetAll curlyData, "githubHandlerURL", the github_HandlerURL [hKey] of hObject
   curly_SetAll curlyData, "githubPermalink", the github_Permalink [hKey] of hObject
   -- curly_SetAll curlyData, "githubObjectURL", github_GetUrl (stackName) -- seems slow
   --
   return curlyData
end help_HkeyCurlyData


--> Help | pageArray | Set
-
command help_SetPageArrayCalls @pageArray, hKey, pHandler
   put pageArray_FindFirstSectionItem ("Calls", "markdown", pageArray) into itemNum
   if itemNum = 0 then return empty
   if pHandler is empty then
      put hkey_FetchHandler (hKey) into pHandler
   end if
   --
   put _ConstructCallList (pHandler) into mdCalls
   --
   pageArray_EditItem pageArray, mdCalls, itemNum
   return mdCalls
end help_SetPageArrayCalls

command help_SetPageArrayHandler @pageArray, hKey
   put pageArray_FindFirstSectionItem ("Handler", "code", pageArray) into itemNum
   if itemNum = 0 then return empty
   
   put hkey_FetchHandler (hKey) into someHandler
   help_TidyHandler someHandler
   pageArray_EditItem pageArray, someHandler, itemNum
   return someHandler
end help_SetPageArrayHandler


--> Private
-
private function _ConstructHandlerTags hKey, pUpdate
   -- used by "help_HkeyCurlyData()"
   local handlerTagList
   
   put hkey_ConstructKeywords (hKey) into handlerTags
   if pUpdate is true then
      put comma after handlerTags
      put help_GetHkeyTags (hkey) into lcwHandlerTags
      repeat for each item lcwHandlerTag in lcwHandlerTags
         if lcwHandlerTag is not among the items of handlerTags then
            put lcwHandlerTag & comma after handlerTags
         end if
      end repeat
      delete char -1 of handlerTags
   end if
   --
   put markdown_TagItems (handlerTags, "from,to") into handlerTagList
   --
   return handlerTagList
end _ConstructHandlerTags

private function _GitPath hObject
   -- put the github_RelativePath of hObject into relPath
   put the stack_Folder of stack "LCW" into gitFolder
   put the filename of hObject into sFile
   --
   set the itemdelimiter to slash
   put the number of items of gitFolder + 1 into sNum
   put item sNum to -1 of sFile into relPath
   return relPath
end _GitPath

private function _ConstructHandlerMetadata hKey, projectName
   put hkey_GetType (hKey) into handlerType
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put _GitPath (hObject) into relPath
   
   put "Type:" && handlerType & CR after handlerMetaData
   put "Project:" && projectName & CR after handlerMetaData
   put "Github:" && relPath & CR after handlerMetaData
   put "OS: all" & CR after handlerMetaData
   put "Platforms: all" & CR after handlerMetaData
   -- put "Checked: false" & CR after handlerMetaData
   --
   delete char -1 of handlerMetaData
   return handlerMetadata
end _ConstructHandlerMetadata

private function _ConstructHandlerSyntax someHandler, hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put line 1 of someHandler into handlerLine
   replace "@" with empty in handlerLine
   switch
      case hType contains "f"
         put word 2 of handlerLine && "(" & word 3 to -1 of handlerLine & ")" into handlerSyntax
         break
      case hType contains "c"
      case hType contains "m"
         put word 2 to -1 of handlerLine into handlerSyntax
         break
      default
         put "the" && word 2 to -1 of handlerLine into handlerSyntax
   end switch
   return handlerSyntax
end _ConstructHandlerSyntax

private function _ConstructCallList someHandler
   # Extract calls from handler
   put handler_ExtractCalls (someHandler) into shortCalls
   -- hkey_StoreCalls hKey, shortCalls
   -- put the handler_PublicCalls [hKey] of hObject into shortCalls
   
   # Default text if empty
   if shortCalls is empty then
      return "There are no calls for this handler."
   end if
   
   # Construct list
   repeat for each line shortCall in shortCalls
      put word 2 of shortCall into hName
      put "- [[" & hName & "]]" & CR after markdownList
   end repeat
   delete char -1 of markdownList
   return markdownList
end _ConstructCallList

private function _ConstructParamList someHandler
   put word 1 to -1 of line 1 of someHandler into hLine
   if word 1 of hLine = "private" then delete word 1 of hLine
   put word 3 to -1 of hLine into paramList
   replace "[" with empty in paramList
   replace "]" with empty in paramList
   replace "@" with empty in paramList
   repeat for each item someParam in paramList
      put "-" && word 1 of someParam && ": param description goes here" & CR after paramTable
   end repeat
   delete char -1 of paramTable
   return paramTable
end _ConstructParamList
