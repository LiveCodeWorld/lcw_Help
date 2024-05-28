script "lib_HelpUpdate"
--> MetaData
-
copyright: David bovill
license: GPLv3
name: lib_HelpUpdate
type: library
version: 0.1

/*
This libray is for augmented-writing support writing script wiki-pages.
Pages may have been hand-written, but these handlers are designed to update the code-related parts of teh page.
*/


--> Working on
-
command help_UpdateHandler hKey
   put help_FetchHkeyPageArray (hKey) into pageArray
   --
   help_SetPageArrayHandler pageArray, hKey
   put the result into foundHandler
   if foundHandler is empty then return empty
   --
   help_SetPageArrayCalls pageArray, hKey, foundHandler
   --
   help_StoreHkeyPageArray hKey, pageArray
   return foundHandler
end help_UpdateHandler

command help_UpdateHandlerCalls hKey
   put help_FetchHkeyPageArray (hKey) into pageArray
   --
   help_SetPageArrayCalls pageArray, hKey
   put the result into mdCalls
   --
   help_StoreHkeyPageArray hKey, pageArray
   return mdCalls
end help_UpdateHandlerCalls

command help_UpdateHandlerCode hKey
   put help_FetchHkeyPageArray (hKey) into pageArray
   --
   help_SetPageArrayHandler pageArray, hKey
   put the result into foundHandler
   if foundHandler is empty then return empty
   --
   help_StoreHkeyPageArray hKey, pageArray
   return foundHandler
end help_UpdateHandlerCode


--> Help | Update | Object
-
command help_UpdateObjectCodeSection sObject
   local storyArray
   ask_PushGithub sObject
   --
   switch the script_Type of sObject
      case "menu"
      case "controller"
         put the help_MenuPageArray of sObject into pageArray
         break
      default
         put help_FetchObjectPageArray (sObject) into pageArray
         put _ObjectStoryArray (sObject) into storyArray
         pageArray_ReplaceSectionBody pageArray, "Code", storyArray
   end switch
   --
   help_StoreObjectPageArray sObject, pageArray
   return pageArray
end help_UpdateObjectCodeSection

private function _ObjectStoryArray sObject
   put the github_Permalink of sObject into permaLink
   put the script_HandlerNames [true] of sObject into hNames
   put help_CodeSectionMarkdown (hNames, permaLink) into sMarkdown
   get storyArray_ConstructItem (sMarkdown, "markdown")
   put it into storyArray[1]
   return storyArray
end _ObjectStoryArray


--> Help | Update
-
command help_TidyHandler @someHandler, pIndentNum
   -- was "help_IndentHandler"
   if pIndentNum is not a number then put 4 into pIndentNum
   --
   put word 1 to -1 of someHandler into someHandler
   repeat with lineNum = 1 to the number of lines of someHandler
      put line lineNum of someHandler into someLine
      get word 1 to -1 of someLine
      put offset (it, someLine) into sNum
      subtract 1 from sNum
      put round (sNum/pIndentNum) into repeatNum
      put text_RepeatString (space, repeatNum) & it into newLine
      put newLine into line lineNum of someHandler
   end repeat
end help_TidyHandler

function help_CodeSectionMarkdown hNames, permaLink
   put "The library contains the following public handlers:" into sMarkdown
   put CR&CR & fedwiki_MarkdownIndex (hNames) after sMarkdown
   --
   put CR&CR & "The model is written in [[Livecode]]." after sMarkdown
   put space & "You can view the source here - [" after sMarkdown
   put permaLink after sMarkdown
   put space & "gist]" after sMarkdown
   --
   return sMarkdown
end help_CodeSectionMarkdown

command help_UpdateFromHkey hKey
   put help_FetchHkeyPageArray (hKey) into pageArray
   put help_HkeyCurlyData (hKey, true) into curlyData
   curly_MergePageArray pageArray, curlyData
   help_StoreHkeyPageArray hKey, pageArray
end help_UpdateFromHkey

command help_UpdateFromObject sObject
   -- does not use script_Help to update first paragraph
   put help_FetchObjectPageArray (sObject) into pageArray
   put help_ObjectCurlyData (sObject) into curlyData
   curly_MergePageArray pageArray, curlyData
   help_StoreObjectPageArray sObject, pageArray
end help_UpdateFromObject
