script "Global | Hkey | Help | Menu"
--> MetaData
-
license: GPLv3
name: Global | Hkey | Help | Menu
target: hKey
type: controller
version: 0.2


--> Menu | Props
-
local LocalArray

on _Init tObject
   -- assumes we are interacting with Script Editor list field
   put tObject into LocalArray ["tObject"]
   
   put scriptEditor_GetHkey() into hKey
   put hKey into LocalArray ["hKey"]
   --
   switch
      case hkey_IsMenuHandler (hKey)
         put true into LocalArray ["isMenu"]
         put false into LocalArray ["isTransport"]
         put false into LocalArray ["isHandler"]
         break
      case hkey_IsTransportHandler (hKey)
         put true into LocalArray ["isTransport"]
         put false into LocalArray ["isMenu"]
         put false into LocalArray ["isHandler"]
         break
      default
         put true into LocalArray ["isHandler"]
         put false into LocalArray ["isMenu"]
         put false into LocalArray ["isTransport"]
   end switch
end _Init

getprop menu_Target [tObject]
   _Init tObject
   return LocalArray ["hKey"]
end menu_Target

getprop disabled_TransporterHelp [hKey]
   if LocalArray ["isTransport"] is true then
      return false
   else
      return "delete"
   end if
end disabled_TransporterHelp

getprop disabled_CreateMenuPage [hKey]
   put hkey_GetMenuTitle (hKey) into gMenuTitle
   put help_FetchMenuHelpArray (gMenuTitle) into pageArray
   if pageArray is empty then
      return false
   else
      return true
   end if
end disabled_CreateMenuPage

private function _StackName hKey
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   return stackName
end _StackName

getprop disabled_MenuHandlerHelp [hKey]
   if LocalArray ["isMenu"] is true then
      return false
   else
      return "delete"
   end if
end disabled_MenuHandlerHelp

getprop disabled_HandlerHelp [hKey]
   if LocalArray ["isHandler"] is true then
      return false
   else
      return "delete"
   end if
end disabled_HandlerHelp

getprop updateHelpGraph_Params [hKey]
   put hkey_ListDotFiles (hKey) into shortFiles
   -- put hkey_ListSvgFiles (hKey) into shortFiles
   return shortFiles
end updateHelpGraph_Params


--> Global | Hkey | Help | Menu
-
on menu_HandlerHelp hKey
   launch_HkeyHelp hKey
   if the result is empty then
      _RecreateHelp hKey
   end if
end menu_HandlerHelp

function git_NeedsUpdating sObject
   put the git_IsActive of object
end git_NeedsUpdating

on _RecreateHelp hKey
   hkeyLine_Deconstruct hKey, hName, hType, hObject
   put LocalArray ["tObject"] into tObject
   lcw_Answer "Are you sure you wish to create the wiki help page for handler '[[hName]]'? This will overwrite any existing page.", tObject, hName
   
   if the git_IsCommitted of hObject is false then
      -- if the git_IsClean of hObject is false then
      ask_PushGithub hObject
   end if
   --
   help_CreateFromHkey hKey
   put the result into pageArray
   if pageArray is not an array then
      breakpoint
   else
      launch_HkeyHelp hKey
   end if
end _RecreateHelp

on menu_MenuHandlerHelp hKey
   launch_MenuItemHelp hKey
   if the result is empty then
      help_CheckUpdateMenuItem hKey
      help_CreateMenuItem hKey
      launch_MenuItemHelp hKey
   end if
end menu_MenuHandlerHelp

on menu_DisplayVersions hKey
   hkeyLine_Deconstruct hKey, hName, hType, hObject
   put the result into shortHkey
   --
   put the github_Permalink [shortHkey] of hObject into webPermalink
   --
   launch url webPermalink
end menu_DisplayVersions

on menu_LaunchGithubUrl hKey
   launch_HkeyGitHub hKey
end menu_LaunchGithubUrl

on _
end _

on menu_TransporterHelp hKey
   put transport_HelpURL (hKey, true) into someURL
   if someURL is empty then
      transport_CreateHelp hKey
      put transport_HelpURL (hKey) into someURL
   end if
   launch url someURL
end menu_TransporterHelp

on menu_UpdateHelpGraph hKey, shortFile
   switch
      case LocalArray ["isTransport"]
         put transport_FetchPageArray (hKey) into pageArray
         transport_UpdatePageGraph pageArray, hKey
         transport_StorePageArray hKey, pageArray
         break
      default
         set the itemdelimiter to "."
         put item 1 of shortFile into graphStyle
         put hkey_GetDotText (hKey, graphStyle) into dotText
         --
         put lcw_FetchHandlerArray (hKey) into pageArray
         pageArray_ReplaceGraph pageArray, dotText
         --
         lcw_StoreHandlerArray hKey, pageArray
         --
         launch_HkeyHelp hKey
   end switch
end menu_UpdateHelpGraph

on menu_UpdateMetadata hKey
   switch
      case hkey_IsMenuHandler (hKey)
         help_UpdateMenuItem hKey
         launch_MenuItemHelp hKey
         break
      case hkey_IsTransportHandler (hKey)
         transport_UpdateHelp hKey
         put transport_HelpURL (hKey, true) into someURL
         launch url someURL
         break
      default
         help_UpdateFromHkey hKey
         launch_HkeyHelp hKey
   end switch
end menu_UpdateMetadata

on _
end _

on submenu_Dev
   return "Dev | Menu"
end submenu_Dev


--> Dev | Menu
-
on _TestRawPermalink hKey
   -- not working
   hkeyLine_Deconstruct hKey, hName, hType, hObject
   put the result into shortHkey
   --
   put the github_RawPermalink of hObject into rawPermalink
   --
   launch url rawPermalink
end _TestRawPermalink

on _CreateMenuPage hKey
   put _StackName (hKey) into stackName
   put help_ConstructMenuPageTitle (stackName) into gMenuTitle
   --
   help_CreateMenu gMenuTitle
   --
   launch_HelpMenu stackName
end _CreateMenuPage

on _UpdateMenuPage hKey
   put _StackName (hKey) into stackName
   put help_ConstructMenuPageTitle (stackName) into gMenuTitle
   --
   help_UpdateMenu gMenuTitle, "reference"
   --
   launch_HelpMenu stackName
end _UpdateMenuPage

on _
end _

on _CreateMenuSubdomain hKey
   help_CreateMenuSubdomain hKey
   --
   launch_MenuItemHelp hKey
end _CreateMenuSubdomain

on _UpdateMenuSubdomain hKey
   help_UpdateMenuSubdomain hKey, "reference"
   --
   hkey_Deconstruct hKey, hName, hType, hObject, hNum
   put the stack_Name of hObject into stackName
   launch_MenuSubdomain stackName
end _UpdateMenuSubdomain
