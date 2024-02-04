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

--> Working on
-
function help_FetchTemplateJson scriptType
   put help_ConstructDomain (scriptType) into fedwikiDomain
   _FixScriptType scriptType
   put scriptType & "-" & "template" into pageSlug
   put pageJson_Fetch (fedwikiDomain, pageSlug) into pageJSON
   return pageJSON
end help_FetchTemplateJson

function _ForkDomainItems
   return "livecode.world,library.livecode.world,model.livecode.world,menu.livecode.world,handler.livecode.world,project.livecode.world,fedwiki.org"
end _ForkDomainItems


--> Props
-
getprop help_Domain
   put the script_Type of the target into scriptType
   put help_ConstructDomain (scriptType) into wikiDomain
   return wikiDomain
end help_Domain

getprop help_Url [pCheckURL]
   put the long id of the target into tObject
   put the stack_Name of tObject into stackName
   put the script_Type of tObject into scriptType
   put help_ConstructURL (stackName, scriptType, pCheckURL) into someURL
   return someURL
end help_Url


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
function help_FetchTemplateArray scriptType, pStripJournal
   -- see also "federation_FetchTemplatePageArray"
   put help_FetchTemplateJson (scriptType) into templateJSON
   put json_ToArray (templateJSON) into templateArray
   if pStripJournal is true then
      pageArray_StripJournal templateArray
   end if
   return templateArray
end help_FetchTemplateArray

function help_ConstructDomain scriptType
   _FixScriptType scriptType
   put scriptType & ".livecode.world" into wikiDomain
   return wikiDomain
end help_ConstructDomain


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


--> Private
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

private command _AddGitHubObjectCurlyData @curlyData, sObject
   put the github_LaunchURL of sObject into objectLink
   put objectLink into curlyData ["all"]["github link"]
   put the github_ProjectURL of sObject into curlyData ["all"]["project link"]
   --
   put githubURL && "github" into githubLink
   put "You can view the source for [[sObject]] on [" & objectLink && "github" & "]" into githubPara
   put merge (githubPara) into curlyData ["id"]["8869c0772777be8e"]
end _AddGitHubObjectCurlyData

private command _FixScriptType @scriptType
   switch scriptType
      case "home"
         put "project" into scriptType
         break
      case "controller"
         put "menu" into scriptType
         break
   end switch
end _FixScriptType
