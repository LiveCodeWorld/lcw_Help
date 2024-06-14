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
function wikiTemplate_GetHelp subDomain
   put subDomain & ".livecode.world" into wikiDomain
   put subDomain & "-" & "template" into pageSlug
   put pageArray_Get (wikiDomain, pageSlug) into pageArray
   return pageArray
end wikiTemplate_GetHelp

function help_FetchTemplateArray scriptType, pStripJournal -- old us "wikiTemplate_GetHelp"
   -- see also "federation_FetchTemplatePageArray"
   put help_FetchTemplateJson (scriptType) into templateJSON
   put json_ToArray (templateJSON) into templateArray
   if pStripJournal is true then
      pageArray_StripJournal templateArray
   end if
   return templateArray
end help_FetchTemplateArray

function help_FetchTemplateJson scriptType -- old us "wikiTemplate_GetHelp
   put help_ConstructDomain (scriptType) into fedwikiDomain
   script_FixType scriptType
   put scriptType & "-" & "template" into pageSlug
   put pageJson_Fetch (fedwikiDomain, pageSlug) into pageJSON
   return pageJSON
end help_FetchTemplateJson

private function _ForkDomainItems
   return "livecode.world,library.livecode.world,model.livecode.world,menu.livecode.world,handler.livecode.world,project.livecode.world,fedwiki.org"
end _ForkDomainItems


--> CurlyData
-
function help_RelatedStacks stackName
   put word 1 to 3 of text_SplitCaps (stackName) into sFilter
   replace space with empty in sFilter
   put "*" after sFilter
   --
   put env_ListUsedStackNames() into modelsAndLibs
   filter modelsAndLibs with sFilter
   return modelsAndLibs
end help_RelatedStacks


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
function help_ConstructDomain scriptType
   script_FixType scriptType
   put scriptType & ".livecode.world" into wikiDomain
   return wikiDomain
end help_ConstructDomain

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

command script_FixType @scriptType
   switch scriptType
      case "home"
         put "project" into scriptType
         break
      case "controller"
         put "menu" into scriptType
         break
   end switch
end script_FixType
