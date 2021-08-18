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

-- getprop disabed_UpdateHelp
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

-- getprop disabled_RecreateHelp
if the shiftKey is "Down" then return false
switch
   case LocalArray ["helpURL"] is not empty
   case LocalArray ["helpActive"] is false
      return "delete"
   default
      return false
end switch
end disabled_RecreateHelp


--> Global | Script | Help | Menu
-
on menu_Help sObject
   launch_ObjectHelp sObject
   if the result is empty then
      menu_RecreateHelp sObject
   end if
end menu_Help

on menu_ProjectHelp sObject
   put the project_Name of sObject into projectName
   launch_OrCreateProject projectName
end menu_ProjectHelp

on _
end _

on menu_RecreateObjectHelp sObject
   put the name of sObject into oName
   put rev_ScriptEditorStack () into editorStack
   lcw_Answer "Are you sure you wish to create the wiki help page for the script of [[oName]]? This will overwrite any existing page.", editorStack, oName
   
   ask_PushGithub sObject
   help_CreateFromObject sObject
   launch_ObjectHelp sObject
end menu_RecreateObjectHelp

on menu_UpdateCodeSection sObject
   help_UpdateObjectCodeSection sObject
   launch_ObjectHelp sObject
end menu_UpdateCodeSection

on menu_UpdateObjectHelp sObject
   help_UpdateFromObject sObject
   launch_ObjectHelp sObject
end menu_UpdateObjectHelp

on menu_UploadGraph sObject, sGraph
   breakPoint
end menu_UploadGraph

getprop uploadGraph_Params [sObject]
   return empty
end uploadGraph_Params
