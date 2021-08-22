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
command help_UpdateObjectCodeSection sObject
   local storyArray
   ask_PushGithub sObject
   put help_FetchObjectPageArray (sObject) into pageArray
   --
   put the github_Permalink of sObject into permaLink
   put the script_HandlerNames [true] of sObject into hNames
   put help_CodeSectionMarkdown (hNames, permaLink) into sMarkdown
   get storyArray_ConstructItem (sMarkdown, "markdown")
   put it into storyArray[1]
   --
   pageArray_ReplaceSectionBody pageArray, "Code", storyArray
   help_StoreObjectPageArray sObject, pageArray
   return pageArray
end help_UpdateObjectCodeSection


--> Help | Update
-
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
   put help_FetchHandlerPageArray (hKey) into pageArray
   put help_HkeyCurlyData (hKey, true) into curlyData
   curly_MergePageArray pageArray, curlyData
   help_StoreHandlerPageArray hKey, pageArray
end help_UpdateFromHkey

command help_UpdateFromObject sObject
   -- does not use script_Help to update first paragraph
   put help_FetchObjectPageArray (sObject) into pageArray
   put help_ObjectCurlyData (sObject) into curlyData
   curly_MergePageArray pageArray, curlyData
   help_StoreObjectPageArray sObject, pageArray
end help_UpdateFromObject
