script "behavior_ViewHandler"
--> MetaData
-
copyright: David Bovill
license: GPLv3
name: behavior_ViewHandler
type: behavior
version: 0.1

/*Here you make make notes as a basic form of help for this view.
Full help text can be found on the linked wiki for the view.*/



--> Working on
-

--> Events
-
on preOpenControl
   put the name of stack "behavior_ViewTiddlyWiki" into bObject
   set the behavior of stack "behavior_View_Handler" to bObject
end preOpenControl

on resizeControl
   put the rect of me into viewRect
   LayoutControl viewRect
end resizeControl

command LayoutControl pRect
   lock screen
   if pRect is empty then put the rect of me into pRect
   
   -- do your geometry here
   unlock screen
end LayoutControl


--> Objects
-
getprop view_Object
   return the long id of me
end view_Object
