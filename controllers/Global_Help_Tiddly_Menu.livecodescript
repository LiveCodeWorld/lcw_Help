﻿script "Global | Help | Tiddly | Menu"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: Global | Help | Tiddly | Menu
type: controller
version: 0.1


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

command saveStackRequest
   put the params
   pass saveStackRequest
end saveStackRequest


--> Global | Help | Tiddly | Menu
-
on menu_HelpTiddly dView
   put the params
end menu_HelpTiddly

private on _
end _

on menu_Behavior dView
   put the behavior of dView into bObject
   edit the script of bObject
end menu_Behavior

on menu_ModuleTools dView
   put the view_Name of dView into viewName
   display_ModuleTools viewName
end menu_ModuleTools

private on __
end __

on submenu_Dev
   return menu_DevTitle ("Global | Help | Tiddly | Menu")
end submenu_Dev
