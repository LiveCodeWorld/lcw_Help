script "Global | Script | Help | Menu"
--> MetaData
-
license: GPLv3
name: Global | Script | Help | Menu
type: controller
version: 0.2


--> Menu | Init
-
local LocalArray

getprop menu_Target [tObject]
   put menu_GetTarget ("Global | Script | Help | Menu") into mController
   if exists (mController) is false then put scriptEditor_Object() into mController
   _Init mController
   return mController
end menu_Target

private command _Init mController
   put env_ProjectIsActive ("lcw_Wiki") into helpActive   
   if helpActive then
      put the help_Url [true] of mController into helpURL
      put helpURL into LocalArray ["helpURL"]
      put scriptType into LocalArray ["scriptType"]
   end if
   put helpActive into LocalArray ["helpActive"]
end _Init

getprop disabed_UpdateHelp
   switch
      case LocalArray ["helpURL"] is empty
      case LocalArray ["helpActive"] is false
         return "delete"
      default
         return false
   end switch
end disabed_UpdateHelp

-- getprop disabled_Help
switch
   case LocalArray ["helpURL"] is empty
   case LocalArray ["helpActive"] is false
      return "delete"
   default
      return false
end switch
end disabled_Help

-- getprop disabled_CreateHelp
if the shiftKey is "Down" then return false
switch
   case LocalArray ["helpURL"] is not empty
   case LocalArray ["helpActive"] is false
      return "delete"
   default
      return false
end switch
end disabled_CreateHelp

-- on menu_MenuHandlerHelp mController
launch_MenuItemHelp hKey
if the result is empty then
   help_CheckUpdateMenuItem hKey
   help_CreateMenuItem hKey
   launch_MenuItemHelp hKey
end if
end menu_MenuHandlerHelp


--> Global | Script | Help | Menu
-
on menu_Help sObject
   launch_ObjectHelp sObject
   if the result is empty then
      _CreateHelp sObject
   end if
end menu_Help

on menu_ProjectHelp sObject
   put the project_Name of sObject into projectName
   launch_ProjectHelp projectName
   --
   if the result is empty then
      if exists (stack projectName) is false then
         lcw_AnswerWarning "Cannot locate project home stack '[[projectName]]", projectName
      end if
      
      put the name of stack projectName into homeStackObject
      help_CreateFromObject homeStackObject
      --
      launch_ProjectHelp projectName
   end if
end menu_ProjectHelp

on _
end _

on _CreateHelp sObject
   put the name of sObject into oName
   put rev_ScriptEditorStack () into editorStack
   lcw_Answer "Are you sure you wish to create the wiki help page for the script of [[oName]]? This will overwrite any existing page.", editorStack, oName
   
   if the git_IsCommitted of sObject is false then ask_PushGithub sObject
   help_CreateFromObject sObject
   launch_ObjectHelp sObject
end _CreateHelp

on _UpdateHelp sObject
   help_UpdateFromObject sObject
   launch_ObjectHelp sObject
end _UpdateHelp
