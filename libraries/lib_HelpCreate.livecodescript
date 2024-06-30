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

--> Working on
-
private command _AddkeyWords @curlyData, sObject, scriptType
   switch scriptType
      case "view"
      case "module"
         put the behavior_Objects of sObject into bObjects
         repeat for each line bObject in bObjects
            put the script_HandlerNames [true] of bObject & CR after handlerNames
         end repeat
         delete char -1 of handlerNames
         break
      default
         put the script_HandlerNames [true] of sObject into handlerNames
   end switch
   --
   put camelcase_BulletList (handlerNames) into keywordList
   -- put markdown_LinkedBullets (handlerNames) into keywordList
   curly_SetAll curlyData, "keywordList", keywordList
end _AddkeyWords



--> Props
-
getprop curly_Data [pHkey]
   put the long id of the target into sObject
   --
   if pHkey is empty then
      put the object_CurlyData of sObject into curlyData
   else
      put the handler_Key [pHkey] of sObject intro hKey
      put help_HkeyCurlyData (hKey) into curlyData
   end if
   return curlyData
end curly_Data

getprop object_CurlyData [pGraphStyle]
   local curlyData, scriptHelp, scriptYaml
   put the long id of the target into sObject
   
   # Script Metadata
   put the long id of the target into sObject
   put the script_MetaData of sObject into sMetaData   
   put sMetaData ["type"] into scriptType
   
   # Dot
   put the script_DotText [pGraphStyle] of sObject into dotText
   if dotText is empty then
      put "digraph G {Dot->Empty}" into dotText
   else
      -- put dot_LayoutEngine (pGraphStyle) into layoutEngine
      -- put "		layout=" & layoutEngine & ";" & CR before line 3 of dotText
      dot_AddLayout dotText, pGraphStyle
   end if
   curly_SetAll curlyData, "dotText", dotText
   
   # YAML
   _ProcessScriptMetadata sMetaData, scriptHelp, scriptYaml
   curly_SetAll curlyData, "scriptYaml", scriptYaml
   curly_SetAll curlyData, "scriptHelp", scriptHelp
   
   # Metadata and Where Yaml
   put the script_WhereData of sObject into whereData
   put whereData into whereYaml
   combine whereYaml with CR and ": "
   curly_SetAll curlyData, "whereYaml", whereYaml
   
   # Object
   put the stack_Name of sObject into stackName
   put whereData ["Project"] into projectName
   put scriptType into curlyData ["scriptType"]
   put projectName into curlyData ["projectName"]
   put stackName into curlyData ["stackName"]
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
         _AddProjectData curlyData, sObject, projectName
         put the result into pageTitle
         break
      case "behavior"
      case "transport"
      case "library"
      default
         # Domain
         put help_ConstructDomain (scriptType) into wikiDomain
         curly_SetAll curlyData, "wikiDomain", wikiDomain
         
         # Deps
         put script_GetHkeyArray (sObject) into hKeyArray
         -- put the script_LinkArray of sObject into hkeyArray
         --
         put hkeyArray_DepProjects (hkeyArray, sObject) into depProjects
         put markdown_LinkedBullets (depProjects) into projectBullets
         put hkeyArray_DepStackBulletList (hkeyArray, sObject) into stackDeps
         --
         curly_SetAll curlyData, "projectDeps", projectBullets
         curly_SetAll curlyData, "stackDeps", stackDeps
         
         # Work out Page Title
         put help_ConstructTitle (stackName, scriptType) into pageTitle 
   end switch
   --
   curly_SetAll curlyData, "title", pageTitle
   put pageTitle into curlyData ["title"]
   
   # Keywords
   _AddkeyWords curlyData, sObject, scriptType
   
   # Related libraries and models
   put help_RelatedStacks (stackName) into stackIndex
   put markdown_LinkedBullets (stackIndex) into relatedBullets
   curly_SetAll curlyData, "relatedBullets", relatedBullets
   
   # Handlers
   -- put the handler_GithubBullets of sObject into handlerBullets
   put the handler_Bullets of sObject into handlerBullets
   -- put markdown_LinkedBullets (handlerNames) into handlerBullets   
   curly_SetAll curlyData, "handlerBullets", handlerBullets
   
   # External Calls
   put the script_ExternalCalls of sObject into externalCalls
   put fedwiki_HkeyMarkdownIndex (externalCalls) into externalBullets
   curly_SetAll curlyData, "externalCalls", externalBullets
   
   # Github
   put the github_LaunchURL of sObject into githubLaunchURL
   curly_SetAll curlyData, "github_LaunchURL", githubLaunchURL
   
   # Github Paragraph
   put merge ("View source code over at [" & githubLaunchURL && "github" & "]") into githubPara
   curly_SetAll curlyData, "githubPara", githubPara
   
   return curlyData
end object_CurlyData

function help_ForkDomains scriptType  
   switch scriptType
      case "Model"
         put "handler,library" into subDomains
         break
      case "Library"
         put "handler,model" into subDomains
         break
      default
         put "handler,model,library" into subDomains
   end switch
   put ",behavior,project,module" after subDomains
   
   repeat for each item subDomain in subDomains
      put subDomain & ".livecode.world" & CR after forkDomains
   end repeat
   delete char -1 of forkDomains
   return forkDomains
end help_ForkDomains

getprop help_PageArray [pOverlayName]
   put the long id of the target into sObject
   
   # CurlyData
   put the object_CurlyData [pOverlayName] of sObject into curlyData
   put curlyData ["title"] into pageTitle
   put curlyData ["scriptType"] into scriptType
   put curlyData ["all"]["scriptHelp"] into scriptHelp
   put curlyData ["stackName"] into stackName
   
   # PageArray
   put help_ForkDomains (scriptType) into forkDomains
   put wikiPage_Help (scriptType, curlyData, scriptHelp, forkDomains, pOverlayName) into pageArray
   
   # Check
   if pageArray_Check (pageArray) is false then
      put help_ConstructDomain (scriptType) into helpDomain
      put merge ("Error, could not fetch template for '[[scriptType]]' at '[[helpDomain]]'") into someMarkdown
      put pageArray_Construct ("Error", someMarkdown) into pageArray
   end if
   
   return pageArray
end help_PageArray


--> Display
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
   put "module.livecode.world" into wikiDomain
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

command draft_ScriptHelp sObject, pOverlayName
   put the help_PageArray [pOverlayName] of sObject into helpPageArray
   put the help_Domain of sObject into wikiDomain
   draft_PageArray wikiDomain, helpPageArray
   put the result into wikiBrowser
   return wikiBrowser
end draft_ScriptHelp

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


--> Help | Create | Object
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
         breakpoint
         help_CreateTransportPage sObject
         break
      default
         put help_ConstructFromObject (sObject, scriptType) into pageArray
         help_StorePageArray pageArray, scriptType
   end switch
   return pageArray
end help_CreateFromObject

function help_ConstructFromObject sObject, pSubDomain
   put the curly_Data of sObject into curlyData
   if pSubDomain is empty then
      put curlyData ["scriptType"] into pSubDomain
   end if
   --
   put wikiPage_Help (pSubDomain, curlyData) into pageArray
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
   
   put the handler_Bullets of sObject into handlerBullets
   -- put the handler_GithubBullets of sObject into handlerBullets
   curly_SetAll curlyData, "Handler List", handlerBullets
   curly_SetAll curlyData, "title", stackName
   return stackName
end _AddIDE

private command _AddProjectData @curlyData, sObject, projectName
   put the project_Deps of sObject into projectDeps
   put markdown_LinkedBullets (projectDeps) into markdownIndex
   --
   curly_SetAll curlyData, "Project Dep List", markdownIndex
   
   # Project Modules
   put project_ConstructKeyWordLinks (projectName) into keyWordLinks
   curly_SetAll curlyData, "keyWordLinks", keyWordLinks
   
   # Project Modules
   put _ModuleBullets (sObject) into muduleBullets
   curly_SetAll curlyData, "muduleBullets", muduleBullets
   
   # Project Components
   put _ProjectComponents (projectName) into componentMarkdown
   curly_SetAll curlyData, "Project Components", componentMarkdown
   
   # Page Title
   put project_ConstructPageTitle (projectName) into pageTitle
   curly_SetAll curlyData, "title", pageTitle
   --
   return pageTitle
end _AddProjectData

private function _ProjectComponents projectName
   put project_GetStackNameArray (projectName) into stackNameArray
   repeat for each item shortFolder in "Modules,Models,Libraries,Controllers,Views"
      put stackNameArray [shortFolder] into sArray
      put the keys of sArray into someIndex
      if someIndex is empty then next repeat
      
      put "#" && shortFolder & CR&CR after pMarkdown
      sort someIndex
      put markdown_LinkedBullets (someIndex) & CR&CR after pMarkdown
   end repeat
   delete char -1 of pMarkdown
   return pMarkdown
end _ProjectComponents

private function _ModuleBullets sObject
   put the project_Modules of sObject into projectModules
   put markdown_LinkedBullets (projectModules) into muduleBullets
   return muduleBullets
end _ModuleBullets

private function _ProjectTags
   return projectTags
end _ProjectTags
