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

getprop disabled_Help
   switch
      case LocalArray ["helpURL"] is empty
      case LocalArray ["helpActive"] is false
         return "delete"
      default
         return false
   end switch
end disabled_Help

getprop disabled_CreateHelp
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
end menu_Help

on menu_CreateHelp sObject
   lcw_CreateObjectHelp sObject
   launch_ObjectHelp sObject
end menu_CreateHelp

on menu_UpdateHelp sObject
   lcw_UpdateObjectHelp sObject
   launch_ObjectHelp sObject
end menu_UpdateHelp

on _
end _


--> Dev | Menu
-
on _LaunchDomain sObject
   put the script_Type of sObject into scriptType
   put LocalArray ["helpURL"] & CR &  help_ConstructDomain (scriptType)
end _LaunchDomain

on _LaunchGoogleDig
   launch url "https://toolbox.googleapps.com/apps/dig/#A/"
end _LaunchGoogleDig
