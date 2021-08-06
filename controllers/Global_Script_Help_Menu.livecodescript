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
   put scriptEditor_Object() into sObject
   
   put env_ProjectIsActive ("lcw_Wiki") into helpActive   
   if helpActive then
      put the help_Url [true] of sObject into helpURL
      put helpURL into LocalArray ["helpURL"]
      put scriptType into LocalArray ["scriptType"]
   end if
   
   put helpActive into LocalArray ["helpActive"]
   put tObject into LocalArray ["tObject"]
   return sObject
end menu_Target

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


--> Global | Script | Help | Menu
-
on menu_Help sObject
   launch_ObjectHelp sObject
   if the result is empty then
      _CreateHelp sObject
   end if
end menu_Help

on menu_CreateHelp sObject
   put the name of sObject into oName
   put rev_ScriptEditorStack () into editorStack
   --
   lcw_Answer "Are you sure you wish to create the wiki help page for the script of [[oName]]? This will overwrite any existing page.", editorStack, oName
   if the git_IsCommitted of oName is false then
      ask_PushGithub oName
   end if
   --
   help_CreateFromObject sObject
   launch_ObjectHelp sObject
end menu_CreateHelp

on _
end _

on menu_UpdateHelp sObject
   help_UpdateFromObject sObject
   launch_ObjectHelp sObject
end menu_UpdateHelp

on menu_ProjectHelp sObject
   put the project_Name of sObject into projectName
   launch_ProjectHelp projectName
   if the result is empty then
      if exists (stack projectName) is false then
         lcw_AnswerWarning "Cannot locate project home stacl '[[projectName]]", projectName
      end if
      
      put the name of stack projectName into homeStackObject
      help_CreateFromObject homeStackObject
      --
      launch_ProjectHelp projectName
   end if
end menu_ProjectHelp


--> Dev | Menu
-
on _LaunchGoogleDig
   launch url "https://toolbox.googleapps.com/apps/dig/#A/"
end _LaunchGoogleDig
