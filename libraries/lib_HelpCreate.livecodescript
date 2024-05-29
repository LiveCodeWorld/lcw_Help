script "lib_HelpCreate"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: lib_HelpCreate
type: library
version: 0.1

/*
This new library is designed for rapid creation of {{wiki-help}} pages.
*/


--> Move
-
function wikiPage_Help subDomain, curlyData, pScriptHelp
   -- subDomain = scriptType 
   put curlyData ["title"] into pageTitle
   put help_ConstructDomain (subDomain) into wikiDomain
   
   # Fetch Template
   put wikiTemplate_GetHelp (subDomain) into pageArray
   if pageArray_Check (pageArray) is false then return empty
   
   # Rename
   help_RenameTemplate pageArray, pageTitle, wikiDomain
   
   # Curly Merge
   curly_MergePageArray pageArray, curlyData
   if pScriptHelp is not empty then
      put pageArray ["story"][1]["text"] into oText
      put pScriptHelp & CR&CR & oText into newFirstPara
      put newFirstPara into pageArray ["story"][1]["text"]
   end if
   
   
   # Add Fork
   pageArray_StripJournal pageArray
   put url_GetTLD (wikiDomain) into tldDomains
   put CR & "fedwiki.org" after tldDomains
   pageArray_AddFork pageArray, tldDomains
   --
   return pageArray
end wikiPage_Help


--> Working on
-
function curlyData_ConstructObject sObject, sMetaData, stackName
   local curlyData, scriptHelp, scriptYaml
   
   # YAML
   -- put the object_Yaml of sObject into curlyData ["all"]["objectYaml"]
   _ProcessScriptMetadata sMetaData, scriptHelp, scriptYaml
   --
   curly_SetAll curlyData, "scriptYaml", scriptYaml
   curly_SetAll curlyData, "scriptHelp", scriptHelp
   
   # Object
   put the stack_Name of sObject into stackName
   put the project_Name of sObject into projectName
   put sMetaData ["type"] into scriptType
   --
   switch scriptType
      case "menu"
      case "controller"
         _AddController curlyData, sObject, stackName
         put the result into pageTitle
         break
      case "ide"
         _AddIDE curlyData, sObject, stackName
         put the result into pageTitle
         break
      case "home"
      case "project"
         _AddProjectData curlyData, sObject
         put the result into pageTitle
         break
      case "transport"
      case "library"
      default
         # Deps
         -- put the script_MarkdownHandlerindex of tObject into curlyData ["all"]["Handler List"]
         -- put the script_Deps of tObject into curlyData ["all"]["Stack Deps"]
         
         put help_ConstructDomain (scriptType) into wikiDomain
         curly_SetAll curlyData, "wikiDomain", wikiDomain
         
         # Work out Page Title
         put help_ConstructTitle (stackName, scriptType) into pageTitle 
   end switch
   --
   curly_SetAll curlyData, "title", pageTitle
   
   # Not sure?
   put pageTitle into curlyData ["title"]
   put scriptType into curlyData ["scriptType"]
   put projectName into curlyData ["projectName"]
   
   # Keywords
   put the script_HandlerNames [true] of sObject into handlerNames
   curly_SetAll curlyData, "keywordList", keywordList
   
   # Related libraries and models
   put help_RelatedStacks (stackName) into stackIndex
   put markdown_LinkedBullets (stackIndex) into relatedBullets
   curly_SetAll curlyData, "relatedBullets", relatedBullets
   
   # Handlers and Calls
   put the script_ExternalCalls of sObject into externalCalls
   put fedwiki_MarkdownIndex (handlerNames) into handlerBullets   
   put fedwiki_HkeyMarkdownIndex (externalCalls) into externalBullets
   --
   curly_SetAll curlyData, "handlerBullets", handlerBullets
   curly_SetAll curlyData, "externalCalls", externalBullets
   
   # Github
   put the github_LaunchURL of sObject into githubLaunchURL
   curly_SetAll curlyData, "github_LaunchURL", githubLaunchURL
   -- curly_SetAll curlyData, "github_ProjectURL", the github_ProjectURL of sObject
   
   # Github Paragraph
   -- put the name of sObject into oName
   put merge ("View source code over at [" & githubLaunchURL && "github" & "]") into githubPara
   --
   curly_SetAll curlyData, "githubPara", githubPara
   
   # Dot
   put the script_DotText of sObject into dotText
   if dotText is not empty then
      put the script_LinkArray of sObject into hkeyArray
      --
      put "		layout=neato;" & CR before line 3 of dotText
      curly_SetAll curlyData, "dotText", dotText
   end if
   return curlyData
end curlyData_ConstructObject

getprop help_PageArray
   put the long id of the target into sObject
   --
   -- put the help_ObjectCurlyData of sObject into curlyData
   put the script_MetaData of sObject into sMetaData
   put sMetaData ["type"] into scriptType
   put the stack_Name of sObject into stackName
   put curlyData_ConstructObject (sObject, sMetaData, stackName) into curlyData
   
   # Construct
   put curlyData ["title"] into pageTitle
   put wikiPage_Help (scriptType, curlyData) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain (scriptType) into helpDomain
      put merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'") into someMarkdown
      put pageArray_Construct ("Error", someMarkdown) into pageArray
   end if
   
   return pageArray
end help_PageArray

getprop help_ObjectCurlyData sObject
   put the long id of the target into sObject
   --
   put the script_MetaData of sObject into sMetaData
   put the stack_Name of sObject into stackName
   --
   put curlyData_ConstructObject (sObject, sMetaData, stackName) into curlyData
   return curlyData
end help_ObjectCurlyData


--> Display | Ghost
--
command display_HelpDraft sObject
   put the help_PageArray of sObject into helpPageArray
   -- comment 
   put the help_Domain of sObject into wikiDomain
   display_WikiGhost wikiDomain, helpPageArray
   put the result into wikiBrowser
   return wikiBrowser
end display_HelpDraft

command display_WikiGhost wikiDomain, pageArray
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
   
   /*
   # Display Page (if exists)
   put wikiFile_Construct (wikiDomain, pageSlug) into wikiFile
   if there is a file wikiFile then
      set the page_Title [wikiDomain] of wikiBrowser to pageTitle
   end if
   */
   return wikiBrowser
end display_WikiGhost


--> Help | Create | Object
-
command launch_ObjectHelp tObject, pDisplayObject
   put the help_Url [true] of tObject into helpURL
   if helpURL is empty then
      put the name of tObject into oName
      if exists (pDisplayObject) is false then
         put rev_ScriptEditorStack () into pDisplayObject
      end if
      lcw_Answer "Are you sure you wish to create the wiki help page for the script of [[oName]]? This will overwrite any existing page.", pDisplayObject, oName
      
      ask_PushGithub tObject
      help_CreateFromObject tObject
      put the help_Url [true] of tObject into helpURL
   end if
   --
   launch url helpURL
   return helpURL
end launch_ObjectHelp

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
         breakpoint
         help_CreateTransportPage sObject
         break
      default
         put help_ConstructFromObject (sObject, scriptType) into pageArray
         help_StorePageArray pageArray, scriptType
   end switch
   return pageArray
end help_CreateFromObject

function help_ConstructFromObject sObject, pScriptType
   if pScriptType is empty then
      put the script_Type of sObject into pScriptType
   end if
   
   put the help_ObjectCurlyData of sObject into curlyData 
   --
   put wikiPage_Help (pScriptType, curlyData) into pageArray
   return pageArray
end help_ConstructFromObject

command help_Create pageTitle, scriptType, curlyData, pScriptHelp
   # Construct
   put pageTitle into curlyData ["titel"]
   put wikiPage_Help (scriptType, curlyData, pScriptHelp) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain (scriptType) into helpDomain
      return merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'")
   end if
   
   help_StorePageArray pageArray, scriptType
   return pageArray
end help_Create

command help_StorePageArray pageArray, scriptType
   # Check pageArray
   if pageArray_Check (pageArray) is false then return "Error, not storing. Faulty pageArray"
   
   # Work out domain and slug
   put help_ConstructDomain (scriptType) into helpDomain
   put pageArray ["title"] into pageTitle
   put fedwiki_ConstructSlug (pageTitle) into pageSlug
   
   # Store
   pageArray_Set wikiDomain, pageSlug, pageArray, true
   put the result into wikiFile
   return wikiFile
end help_StorePageArray


--> Private
-
private command _ProcessScriptMetadata sMetaData, @scriptHelp, @scriptYaml
   put sMetaData ["script_Help"] into scriptHelp
   delete variable sMetaData ["script_Help"]
   --
   replace "{{" with "[[" in scriptHelp
   replace "}}" with "]]" in scriptHelp
   
   put metadata_ArrayToYaml (sMetaData) into scriptYaml
end _ProcessScriptMetadata

command _AddController @curlyData, sObject, stackName
   # Menu Handlers
   put the menu_Handlers [stackName] of sObject into mHandlerIndex
   curly_SetAll curlyData, "Menu Handler Index", mHandlerIndex
   
   # Title
   put help_ConstructMenuPageTitle (stackName) into pageTitle
   curly_SetAll curlyData, "title", pageTitle
   --
   return pageTitle
end _AddController

command _AddIDE @curlyData, sObject, stackName
   -- curly_SetAll curlyData, relFolder, "rel folder"
   -- curly_SetAll curlyData, shortFile, "short file"
   
   curly_SetAll curlyData, "Handler List", the script_MarkdownHandlerindex of sObject
   curly_SetAll curlyData, "title", stackName
   return stackName
end _AddIDE

private command _AddProjectData @curlyData, sObject
   put the project_Deps of sObject into projectDeps
   put fedwiki_MarkdownIndex (projectDeps) into markdownIndex
   --
   curly_SetAll curlyData, "Project Dep List", markdownIndex
   
   # Project Components
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
   
   curly_SetAll curlyData, "Project Components", pMarkdown
   curly_SetAll curlyData, "title", stackName
   --
   return stackName
end _AddProjectData
