script "Global | Help | Object | Menu"
--> MetaData
-
license: GPLv3
name: Global | Help | Object | Menu
type: controller
version: 0.2


--> Menu | Init
-
local LocalArray

getprop menu_Target [tObject]
   put menu_GetTarget ("Global | Help | Object | Menu") into mController
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


--> Global | Help | Object | Menu
-
on menu_Help sObject
   launch_ObjectHelp sObject
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

getprop disabled_CreateHelpWiki [sObject]
   put the help_Domain of sObject into wikiDomain
   put wiki_GetFolder (wikiDomain) is not empty into wikiExists
   return wikiExists
end disabled_CreateHelpWiki

on menu_CreateHelpWiki sObject
   put the help_Domain of sObject into wikiDomain
   put lcw_Ask ("Create new wiki...", wikiDomain, "New Wiki") into wikiDomain
   --
   wikiServer_Create wikiDomain
   display_LocalWikis "", "", "*livecode.world"
end menu_CreateHelpWiki

