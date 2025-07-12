script "Global | Livecode | Dictionary | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Livecode | Dictionary | Menu
type: controller
version: 0.1

/*Here you can describe this menu.
Full help text should be provided on the linked wiki.*/


--> Variables
-
local LocalArray

--> Menu | Props
-
getprop menu_Target [tObject]
   put the display_View of tObject into LocalArray ["dView"]
   put the displayed_Object of tObject into sObject
   return sObject
end menu_Target

private function _dView
   return LocalArray ["dView"]
end _dView

getprop menu_CheckTarget [dView]
   return exists (dView)
end menu_CheckTarget


--> Global | Livecode | Dictionary | Menu
-
on menu_CreateDictionaryEntry dView
   put lcw_Ask (sQuestion, "specialFolderPath", dView) into dTitle
   --
   -- put wikiPage_LivecodeHelp (dTitle) into pArray
   put dict_ConstructPageArray (dTitle) into pArray
   if pArray is not an array then
      lcw_AnswerWarning "Cannot find dictionary enty for '[[dTitle]]'!", dView, dTitle
   end if
   
   # Create wiki page
   dict_StorePageArray pArray
   
   # Launch in browser
   put dict_DefaultDomain() into wDomain
   launch_Fedwiki wDomain, dTitle, "https"
   
   # Display Dictionary
   display_LivecodeDictionary sTitle
end menu_CreateDictionaryEntry

private on _
end _

on menu_LivecodeDictionary dView
   display_LivecodeDictionary "specialFolderPath"
end menu_LivecodeDictionary

private on __
end __

on menu_ExportNewTerms
   put 1000 * date_DaysAgoInSeconds(3) into cutOff
   --
   put dict_ListTerms() into dTerms
   repeat for each line dTitle in dTerms
      set the cursor to busy
      put dict_WikiPagePath (dTitle) into pagePath
      if there is a file pagePath then
         put dict_GetPageArray (dTitle) into pageArray
         --
         put pageArray_GetLastModified (pageArray) into tDate
         if tDate < cutOff then
            put dTitle & CR after badTerms
            next repeat
         end if
      end if
      
      # Construct pArray
      put dict_ConstructPageArray (dTitle) into pArray
      if pArray is not an array then
         put dTitle & CR after badTerms
         next repeat
      end if
      
      # Create wiki page
      dict_StorePageArray pArray
      if the shiftKey is "Down" then
         breakpoint
         exit repeat
      else
         put dTitle
      end if
   end repeat
   --
   if badTerms is not empty then
      display_Data badTerms, "Bad Terms'"
   end if
end menu_ExportNewTerms

on menu_TestDictionary dView
   put lcw_Ask (sQuestion, "specialFolderPath", dView) into dTitle
   --
   put dict_TermDescription (dTitle)
   display_LivecodeHelpPage dTitle
   
   put dict_DefaultDomain() into wDomain
   launch_Fedwiki wDomain, dTitle, "https"
end menu_TestDictionary

on submenu_Dev
   return menu_DevTitle ("Global | Livecode | Dictionary | Menu")
end submenu_Dev
