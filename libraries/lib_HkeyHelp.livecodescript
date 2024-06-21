script "lib_HkeyHelp"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_HkeyHelp
type: library
version: 0.2

/* A library to automate teh creation of help for Livecode handlers.
*/


--> Move
-
function project_FolderTokind shortFolder
   -- singular form plural
   switch
      case shortFolder = "libraries"
         return "library"
      case char -1 of shortFolder = "s"
         delete char -1 of shortFolder
         return shortFolder
      default
         return shortFolder
   end switch
end project_FolderTokind


--> Working on
-
function camelcase_BulletList hNameList
   local kWordArray
   replace comma with CR in hNameList
   --
   repeat for each line hName in hNameList
      put text_SplitIntoWords (hName) into kWords
      put toLower (kWords) into kWords
      split kWords with CR as set
      --
      union kWordArray with kWords 
   end repeat
   put keys (kWordArray) into tagItems
   --
   put markdown_TagItems (tagItems) into keyWordLinks
   -- replace CR with ", " in keyWordLinks
   return keyWordLinks
end camelcase_BulletList

function handler_KeyWordsFromName hName
   put text_SplitIntoWords (hName) into kWords
   put toLower (kWords) into kWords
   return kWords
end handler_KeyWordsFromName

private function _ConstructHandlerTags hKey
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


--> Props
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
      
      put github_GetHandlerURL (hObject, sLineNum, eLineNum) into githubURL 
      put "- [" & hName & "](" & githubURL & ")" & CR after markdownIndex
   end repeat
   delete char -1 of markdownIndex
   return markdownIndex
end script_MarkdownHandlerindex


--> Working on
-
function script_SingularType pluralType
   switch pluralType
      case "libraries"
         return "library"
      default 
         if char -1 of pluralType = "s" then delete char -1 of pluralType
         return tolower (pluralType)
   end switch
end script_SingularType

getprop script_WhereYaml
   put the script_WhereData of hObject into whereYaml
   combine whereYaml with CR and ": "
   return whereYaml
end script_WhereYaml

getprop script_WhereData
   put the long id of the target into sObject
   
   # Collect script info
   put the project_Name of sObject into projectName
   put the module_Name of sObject into moduleName
   put the name of sObject into whereData ["Script"]
   --
   put _GitPath (sObject) into relPath
   put _ShortFile (relPath) into shortFile
   put _KindFromPath (relPath) into sKind
   -- put _ShortFolder (relPath) into sKind
   
   # Construct whereData
   put projectName into whereData ["Project"]
   if moduleName is not empty then
      put moduleName into whereData ["Module"]
   end if
   put sKind into whereData ["Kind"]
   put shortFile into whereData ["File"]
   put relPath into whereData ["Path"]
   --
   return whereData
end script_WhereData

function handler_WhereData hKey
   local handlerMetaData
   --
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the result into shortHkey
   if exists (hObject) is false then return "Error, object does not exist:" && hObject
   
   put the script_WhereData of hObject into hMetaData
   /*
   put the project_Name of hObject into projectName
   put the module_Name of hObject into moduleName
   --
   put _GitPath (hObject) into relPath
   put _ShortFolder (relPath) into libType
   put _ShortFile (relPath) into shortFile
   
   put projectName into hMetaData ["Project"]
   if moduleName is not empty then
      put moduleName into hMetaData ["Module"]
   end if
   put libType into hMetaData ["Kind"]
   put shortFile into hMetaData ["File"]
   put relPath into hMetaData ["Path"]
   */
   put word 1 to 2 of shortHkey into hMetaData ["Hkey"]
   put the name of hObject into hMetaData ["Script"]
   --
   return hMetaData
end handler_WhereData

function handler_MetaData hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   --
   put hkey_GetType (hKey) into hMetaData ["Type"]
   put "all" into hMetaData ["OS"]
   put "all" into hMetaData ["Platforms"]
   --
   put handler_Get (hKey, true) into sHandler
   help_TidyHandler sHandler
   put sHandler into hMetaData ["script"]
   --
   put handler_ConstructLine (sHandler, hType) into hLine
   put hLine into hMetaData ["Handler"]
   --
   return hMetaData
end handler_MetaData

function handler_ConstructLine sHandler, hType
   put line 1 of sHandler into hLine
   --
   if char 1 of hType = "p" then
      delete word 1 to 2 of hLine
   else
      delete word 1 of hLine
   end if
   
   switch
      case hType contains "f"
         put "(" before word 2 of hLine
         put ")" after hLine
         break
      case hType contains "g"
      case hType contains "s"
         put "[" before word 2 of hLine
         put "]" after hLine
         break
   end switch
   --
   return hLine 
end handler_ConstructLine


--> Help | Hkey | CurlyData
-
function help_HkeyCurlyData hKey
   local curlyData
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the result into shortHkey
   if exists (hObject) is false then return "Error, object doeas not exist for hKey:" && hKey
   
   # Stack and Object
   put the stack_Name of hObject into stackName
   curly_SetAll curlyData, "stackName", stackName
   curly_SetAll curlyData, "object", the name of hObject
   
   # Hkey
   put "[[" & hType && hName & "]] of stack [[" & stackName & "]]" into hkeyLink
   put hkey_GetType (hKey) into hTypeWord
   --
   curly_SetAll curlyData, "hKey", hKey
   curly_SetAll curlyData, "shortHkey", shortHkey
   curly_SetAll curlyData, "hkeyLink", hkeyLink
   curly_SetAll curlyData, "hTypeWord", hTypeWord
   
   put the project_Name of hObject into projectName
   curly_SetAll curlyData, "projectName", projectName
   
   # Project and Module
   put the module_Name of hObject into moduleName
   if moduleName is not empty then
      curly_SetAll curlyData, "moduleName", moduleName
   end if
   
   # Handler and Syntax
   put handler_MetaData (hKey) into hMetaData
   put hMetaData ["script"] into sHandler
   curly_SetAll curlyData, "someHandler", sHandler
   --
   put _ConstructHandlerSyntax (sHandler, hKey) into handlerSyntax
   curly_SetAll curlyData, "handlerSyntax", handlerSyntax
   
   # Metadata and Where Yaml
   put handler_WhereData (hKey) into whereData
   put _WhereYaml (whereData) into whereYaml
   put _HandlerYaml (hMetaData) into handlerYaml
   -- 
   curly_SetAll curlyData, "handlerYaml", handlerYaml
   curly_SetAll curlyData, "whereYaml", whereYaml
   
   # Kind and handler line
   put whereData ["Kind"] into pluralType
   put script_SingularType (pluralType) into libType
   curly_SetAll curlyData, "libType", libType
   curly_SetAll curlyData, "hLine", hLine
   
   # Dot
   put hkey_GetDotText (hKey) into dotText
   if dotText is empty then
      put _DefaultDotText (hKey) into dotText
   end if
   if dotText is not empty then curly_SetAll curlyData, "dotText", dotText
   
   # Calls
   put _ConstructCallList (sHandler) into callList
   curly_SetAll curlyData, "callList", callList
   
   # Params
   put _ConstructParamList (sHandler) into paramList
   curly_SetAll curlyData, "paramList", paramList
   
   # Tags
   put _ConstructHandlerTags (hKey, pUpdate) into handlerTags -- also look inside handler
   curly_SetAll curlyData, "handlerTags", handlerTags
   
   # Github
   curly_SetAll curlyData, "githubHandlerURL", the github_HandlerURL [hKey] of hObject
   curly_SetAll curlyData, "githubPermalink", the github_Permalink [hKey] of hObject
   -- curly_SetAll curlyData, "githubObjectURL", github_GetUrl (stackName) -- seems slow
   
   # Deps
   curly_SetAll curlyData, "handlerDeps", _StackLinkList (hkey, hObject)
   
   return curlyData
end help_HkeyCurlyData


--> Hkey | Help
-
command help_CreateFromHkey hKey, pScriptHelp
   put hkey_IsMenuHandler (hKey) into isMenuHandler
   switch
      case isMenuHandler is true
         breakpoint
         help_CreateMenuItem hKey, pScriptHelp
         break
      case hkey_IsTransportHandler (hKey)
         breakpoint
         transport_CreateHkeyHelp hKey, pScriptHelp
         break
      default
         put help_FromHkey (hKey, pScriptHelp) into pageArray
         help_StoreHkeyPageArray hKey, pageArray
         return pageArray
   end switch
end help_CreateFromHkey

function help_FromHkey hKey, pScriptHelp
   put help_ConstructHandlerTitle (hKey) into pageTitle
   put help_HkeyCurlyData (hKey) into curlyData
   put pageTitle into curlyData ["title"]
   --
   put help_ForkDomains () into forkDomains
   put wikiPage_Help ("handler", curlyData, pScriptHelp, forkDomains) into pageArray
   return pageArray
end help_FromHkey

function help_GetHkeyTags hKey
   put help_FetchHkeyPageArray (hKey) into pageData
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
   
   put hkey_FetchHandler (hKey) into sHandler
   help_TidyHandler sHandler
   pageArray_EditItem pageArray, sHandler, itemNum
   return sHandler
end help_SetPageArrayHandler


--> Private
-
private function _ConstructCallList sHandler, pIncludePrivate
   # Extract calls from handler
   put handler_ExtractCalls (sHandler) into shortCalls
   
   # Default text if empty
   if shortCalls is empty then
      return "There are no calls for this handler."
   end if
   
   # Construct list
   repeat for each line shortCall in shortCalls
      put word 2 of shortCall into hName
      
      if char 1 of hName = "_" then
         if pIncludePrivate is true then
            put "- [[" & hName & "]]" & CR after markdownList
         end if
      else
         put "- [[" & hName & "]]" & CR after markdownList
      end if
   end repeat
   delete char -1 of markdownList
   return markdownList
end _ConstructCallList

private function _ConstructHandlerSyntax sHandler, hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put line 1 of sHandler into handlerLine
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

private function _ShortFile relPath
   set the itemdelimiter to slash
   return item -1 of relPath
end _ShortFile

private function _ShortFolder relPath
   set the itemdelimiter to slash
   return item -2 of relPath
end _ShortFolder

function _KindFromPath relPath
   set the itemdelimiter to slash
   put item 1 of relPath into shortFolder
   put project_FolderTokind (shortFolder) into projectFolderKind
   return projectFolderKind
end _KindFromPath

private function _GitPath hObject
   -- put the github_RelativePath of hObject into relPath
   put the stack_Folder of stack "LCW" into gitFolder
   --
   put the stack_Name of hObject into stackName
   put the effective filename of stack stackName into sFile
   --
   set the itemdelimiter to slash
   put the number of items of gitFolder + 1 into sNum
   put item sNum to -1 of sFile into relPath
   return relPath
end _GitPath

private function _ConstructParamList sHandler
   put word 1 to -1 of line 1 of sHandler into hLine
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

private function _HandlerYaml hMetaData
   delete variable hMetaData ["script"]
   combine hMetaData with CR and ": "
   return hMetaData
end _HandlerYaml

private function _WhereYaml whereData
   combine whereData with CR and ": "
   return whereData
end _WhereYaml

private function _StackLinkList hkey, hObject
   put the stack_Object of hObject into stackObject
   put hKey_GetArray (hkey) into hkeyArray
   put hkeyArray_DepStackBulletList (hkeyArray, stackObject) into linkList
   return linkList
end _StackLinkList

private function _DefaultDotText hKey
   return "{{dotText}}"
end _DefaultDotText
