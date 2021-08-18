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
lcw_Help uses the livecode.world federated wiki to store it's help.
As such you need to initiate the lcw_Wiki rpject for these handlers to work.
*/

--> Props
-
getprop help_Url [pCheckURL]
   put the long id of the target into tObject
   put the stack_Name of tObject into stackName
   put the script_Type of tObject into scriptType
   put help_ConstructURL (stackName, scriptType, pCheckURL) into someURL
   return someURL
end help_Url

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


--> Working on
-
private command _AddObjectCurlyData @curlyData, scriptType, sObject
   put the stack_Name of sObject into stackName
   put the project_Name of sObject into projectName 
   put scriptType into curlyData ["scriptType"]
   put projectName into curlyData ["projectName"]
   --
   switch scriptType
      case "menu"
      case "controller"
         -- put the script_Metadata ["name"] of sObject into stackName
         put stackName into menuTitle
         put the menu_Handlers [menuTitle] of sObject into mHandlers
         put mHandlers into curlyData ["all"]["Menu Handler Index"]
         -- put fedwiki_MarkdownIndex (mHandlers) into curlyData ["id"]["abb62f579a1d7288"]
         --
         put help_ConstructMenuPageTitle (stackName) into pageTitle
         put pageTitle into curlyData ["title"]
         --
         return pageTitle
      case "ide"         
         put the script_MarkdownHandlerindex of sObject into curlyData ["all"]["Handler List"]
         put relFolder into curlyData ["all"]["rel folder"]
         put shortFile into curlyData ["all"]["short file"]
         put stackName into curlyData ["title"]
         break
      case "home"
      case "project"
         put the project_Deps of sObject into projectDeps
         put fedwiki_MarkdownIndex (projectDeps) into markdownIndex
         put markdownIndex into curlyData ["all"]["Project Dep List"]
         --
         put project_GetStackNameArray (projectName) into stackNameArray
         repeat for each item shortFolder in "Libraries,Models,Controllers,Modules,Views"
            put stackNameArray [shortFolder] into sArray
            put the keys of sArray into someIndex
            if someIndex is empty then next repeat
            
            put "#" && shortFolder & CR&CR after pMarkdown
            sort someIndex
            put fedwiki_MarkdownIndex (someIndex) & CR&CR after pMarkdown
         end repeat
         delete char -1 of pMarkdown
         put pMarkdown into curlyData ["all"]["Project Components"]
         put stackName into curlyData ["title"]
         break
      case "transport"
      case "library"
      default
         -- put "8869c0772777be8e" into githubLinkID
         --put the script_MarkdownHandlerindex of tObject into curlyData ["all"]["Handler List"]
         -- put the script_Deps of tObject into curlyData ["all"]["Stack Deps"]
         
         put help_ConstructDomain (scriptType) into wikiDomain
         put help_ConstructTitle (stackName, scriptType) into pageTitle 
         put pageTitle into curlyData ["title"]
   end switch
   
   return stackName
end _AddObjectCurlyData

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
   put _GetMarkdownTagItems (someTags, "from,to") into handlerTagList
   --
   return handlerTagList
end _ConstructHandlerTags

private function _GetMarkdownTagItems someTags, pNotThese
   repeat for each line someTag in someTags
      if someTag is among the items of pNotThese then next repeat
      put "[[" & someTag & "]], " after handlerTagList
   end repeat
   delete char -2 to -1 of handlerTagList
   return handlerTagList
end _GetMarkdownTagItems


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

function help_GetHkeyTags hKey
   put lcw_FetchPageData (hKey) into pageData
   put pageData_GetText (pageData, "handlerTags") into handlerTags
   replace "[[" with empty in handlerTags
   replace "]]" with empty in handlerTags
   replace "-" with empty in handlerTags
   replace space with empty in handlerTags
   return handlerTags
end help_GetHkeyTags


--> Help | Template | Model
-
function help_FetchTemplateArray scriptType, pStripJournal
   -- see also "federation_FetchTemplatePageArray"
   put help_FetchTemplateJson (scriptType) into templateJSON
   put json_ToArray (templateJSON) into templateArray
   if pStripJournal is true then
      pageArray_StripJournal templateArray
   end if
   return templateArray
end help_FetchTemplateArray

function help_FetchTemplateJson scriptType
   put help_ConstructDomain (scriptType) into fedwikiDomain
   _FixScriptTyle scriptType
   put scriptType & "-" & "template" into pageSlug
   put pageJson_Fetch (fedwikiDomain, pageSlug) into pageJSON
   return pageJSON
end help_FetchTemplateJson

function help_ConstructDomain scriptType
   _FixScriptTyle scriptType
   put scriptType & ".livecode.world" into wikiDomain
   return wikiDomain
end help_ConstructDomain

command _FixScriptTyle @scriptType
   switch scriptType
      case "home"
         put "project" into scriptType
         break
      case "controller"
         put "menu" into scriptType
         break
   end switch
end _FixScriptTyle


--> Help | Create
-
command help_CreateFromObject sObject
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
         put help_ConstructHandlerTitle (hKey) into pageTitle
         put help_HkeyCurlyData (hKey, false) into curlyData
         --
         help_Create pageTitle, "handler", curlyData, pScriptHelp
   end switch
   put the result into shellResult -- error, fetching ip address for droplet AtopiaDropletName
   return shellResult
end help_CreateFromHkey

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
   pageArray_Store helpDomain, pageSlug, pageArray
   put the result into shellResult
   if item 1 of shellResult is "error" then
      return shellResult
   else
      return pageArray
   end if
end help_CreatePageArray

function help_FetchNewPageArray pageTitle, scriptType, curlyData, pScriptHelp
   put help_ConstructDomain (scriptType) into wikiDomain
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
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
         put curly_GetData (curlyData, "callList") into callList
         if word 1 of callList is not "-" then
            -- not a list
            put pageArray_FindItemType ("graphviz", pageArray) into itemNum
            pageArray_DeleteItem pageArray, itemNum
         end if
   end switch
   --
   return pageArray
end help_FetchNewPageArray

command help_RenameTemplate @pageArray, pageTitle, pWikiDomain
   put "livecode.world,library.livecode.world,model.livecode.world,menu.livecode.world,handler.livecode.world,fedwiki.org" into forkDomains
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

function help_ConstructMenuUrl gMenuTitle, pCheckURL
   put help_ConstructDomain ("menu") into wikiDomain
   put help_ConstructMenuPageTitle (gMenuTitle) into menuPageTitle
   put fedwiki_ConstructSlug (menuPageTitle) into pageSlug
   
   # Return emmpty if page does not exist
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   
   # Construct and return page utl
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructMenuUrl

function help_ConstructURL stackName, scriptType, pCheckURL
   put help_ConstructDomain (scriptType) into wikiDomain
   put help_ConstructTitle (stackName, scriptType) into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   --
   if pCheckURL is true and fedwiki_PageExists (wikiDomain, pageSlug) is false then return empty
   --
   put fedwiki_ConstructUrlFromSlug (wikiDomain, pageSlug) into someURL
   return someURL
end help_ConstructURL

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

function help_HkeyCurlyData hKey, pUpdate
   -- also used by handlers in "lib_Transport"
   local curlyData
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   --
   put the stack_Name of hObject into stackName
   put stackName into curlyData ["all"]["stackName"]
   --
   put the project_Name of hObject into projectName
   put projectName into curlyData ["all"]["projectName"]
   --  
   put the github_Permalink [hKey] of hObject into curlyData ["all"]["githubPermalink"]
   -- put the github_HandlerURL [hKey] of hObject into curlyData ["all"]["githubHandlerURL"]
   put github_GetUrl (stackName) into curlyData ["all"]["githubObjectURL"]
   --
   put hkey_GetType (hKey) into curlyData ["all"]["handlerType"]
   -- older style
   help_SetHkeyInfo hKey, wikiDomain, pageSlug, pageTitle
   put storyArray_ConstructReference (pageSlug, wikiDomain, wikiDomain, pageTitle) into itemArray
   curly_SetReplaceArray curlyData, itemArray, "4ecda1442570d900"
   --
   _SetHkeyPageItemDictionary curlyData
   --
   put hkey_FetchHandler (hKey) into someHandler
   help_IndentHandler someHandler
   curly_SetData curlyData, "someHandler", someHandler
   --
   put hkey_GetDotText (hKey) into dotText
   if dotText is not empty then
      curly_SetData curlyData, "dotText", dotText
   end if
   --
   put _ConstructHandlerMetadata (hKey, projectName) into handlerMetadata
   curly_SetData curlyData, "handlerMetadata", handlerMetadata
   --
   put _ConstructHandlerSyntax (someHandler, hKey) into handlerSyntax
   curly_SetData curlyData, "handlerSyntax", handlerSyntax
   --
   put _ConstructCallList (someHandler, hKey) into callList
   curly_SetData curlyData, "callList", callList
   --
   put _ConstructParamList (someHandler) into paramList
   curly_SetData curlyData, "paramList", paramList
   --
   put _ConstructHandlerTags (hKey, pUpdate) into handlerTags -- also look inside handler
   curly_SetData curlyData, "handlerTags", handlerTags
   --
   return curlyData
end help_HkeyCurlyData

function help_ObjectCurlyData sObject, scriptType
   local curlyData
   --   
   put the object_Yaml of sObject into curlyData ["id"]["da8cf69872f38050"]
   --
   put the script_HandlerNames [true] of sObject into handlerNames
   put the script_ExternalCalls of sObject into externalCalls
   --
   put fedwiki_MarkdownIndex (handlerNames) into curlyData ["id"]["5ac622dfbefa2589"]
   put fedwiki_HkeyMarkdownIndex (externalCalls) into curlyData ["id"]["8b1940e31f034b01"]
   --
   _AddGithubObjectCurlyData curlyData, sObject
   _AddObjectCurlyData curlyData, scriptType, sObject
   --
   return curlyData
end help_ObjectCurlyData


--> Help
-
command help_IndentHandler @someHandler
   put word 1 to -1 of someHandler into someHandler
   repeat for each line hLine in someHandler
      put word 1 to -1 of hLine into goodLine
      put offset (goodLine, hLine) into spaceNum
      if spaceNum = 1 then
         put goodLine & CR after goodHandler
      else
         put round (spaceNum/2) into newSpaceNum
         put char 1 to newSpaceNum of hLine & goodLine & CR after goodHandler
      end if
   end repeat
   delete char -1 of goodHandler
   put goodHandler into someHandler
end help_IndentHandler


--> LCW | Handler | Model
-
/*
Here we reference handlers stared on "handler.livecode.world"
We define a new concept "handerArray" to mean a "pageArray" for handlers.
*/

function lcw_FetchPageData hKey
   put lcw_FetchHandlerArray (hKey) into pageData
   _SetHkeyPageItemDictionary pageData
   return pageData
end lcw_FetchPageData

function lcw_FetchHandlerArray hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   put pageArray_Fetch ("handler.livecode.world", pageSlug) into pageArray
   return pageArray
end lcw_FetchHandlerArray

command lcw_StoreHandlerArray hKey, pageArray
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put fedwiki_ConstructSlug (hName) into pageSlug
   --
   pageArray_Store "handler.livecode.world", pageSlug, pageArray
   put the result into shellResult
   return shellResult
end lcw_StoreHandlerArray

function lcw_FetchObjectPageArray sObject
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   put pageArray_Fetch (wikiDomain, pageSlug) into pageArray
   return pageArray
end lcw_FetchObjectPageArray

command lcw_StoreObjectPageArray sObject, pageArray
   _ObjectDomainInfo sObject, pageTitle, pageSlug, wikiDomain
   pageArray_Store wikiDomain, pageSlug, pageArray
   return the result
end lcw_StoreObjectPageArray


--> Private
-
private command _ObjectDomainInfo sObject, @pageTitle, @pageSlug, @wikiDomain
   put the stack_Name of sObject into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   put the script_Type of sObject into scriptType
   put help_ConstructDomain (scriptType) into wikiDomain
end _ObjectDomainInfo

private function _ConstructHandlerMetadata hKey, projectName
   put hkey_GetType (hKey) into handlerType
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the github_RelativePath of hObject into relPath
   
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

private function _ConstructCallList someHandler, hKey
   -- we store them as we find them - because we can
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the handler_PublicCalls [hKey] of hObject into shortPublicCalls
   
   # Extract calls from handler (and store them)
   put handler_ExtractCalls (someHandler) into shortCalls
   hkey_StoreCalls hKey, shortCalls
   -- put hkey_FetchCalls (hKey) into shortCalls
   
   # Construct list
   repeat for each line shortCall in shortPublicCalls
      put word 2 of shortCall & CR after callNames
   end repeat
   delete char -1 of callNames
   put fedwiki_MarkdownIndex (callNames) into callList
   
   # If empty
   if callList is empty then
      return "There are no calls for this handler."
   end if
   return callList
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

private command _AddProjectArrayBit @curlyData, shortFolder, stackNameArray
   put markdownIndex into curlyData ["all"][shortFolder]
end _AddProjectArrayBit

private command _SetHkeyPageItemDictionary @curlyData
   curly_SetItemIDArray curlyData, "refArray", "4ecda1442570d900"
   curly_SetItemIDArray curlyData, "someHandler", "39e7dd9a1560241a"
   curly_SetItemIDArray curlyData, "handlerSyntax", "54f306e694aa494b"
   curly_SetItemIDArray curlyData, "handlerMetadata", "da8cf69872f38050"
   curly_SetItemIDArray curlyData, "callList", "0c0d997d16532d79"
   curly_SetItemIDArray curlyData, "handlerTags", "26d290f03f2aa26e"
   curly_SetItemIDArray curlyData, "dotText", "b6853287820608f3"
   curly_SetItemIDArray curlyData, "paramList", "0a99c44502e29156"
   curly_SetItemIDArray curlyData, "githubPara", "8869c0772777be8e"
end _SetHkeyPageItemDictionary

private command _AddGitHubObjectCurlyData @curlyData, sObject
   put the github_LaunchURL of sObject into objectLink
   put objectLink into curlyData ["all"]["github link"]
   put the github_ProjectURL of sObject into curlyData ["all"]["project link"]
   --
   put githubURL && "github" into githubLink
   put "You can view the source for [[sObject]] on [" & objectLink && "github" & "]" into githubPara
   put merge (githubPara) into curlyData ["id"]["8869c0772777be8e"]
end _AddGitHubObjectCurlyData
