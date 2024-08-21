;DIRECTIVES====================================================================

#Requires AutoHotkey v1.1.33+ ;Potentially might work on lower versions, but definitely not v2
#NoEnv  ;Recommended for performance and compatibility with future AutoHotkey releases.
#SingleInstance Force ;Prevents multiple versions of script running
SendMode Input ;Makes Send synonymous with SendInput
#UseHook On ;Helps ensure modifier keys don't remain pressed after hotkey ends
OnClipboardChange("ClipChanged")

 
;VARIABLES=====================================================================


Global A_Return := "`r`n"
Global ClipChange :=
Global ClipSave


Global Clipdeck := []
Global ClipdeckNextLine
Global ClipdeckRecall


;FUNCTIONS=====================================================================

ClipDeckCopy(mode, duration:=1, displaytext:="Oops")
{
	ClipSave() ;Saves the existing clipboard for later restoration
	ClipChange := ;Tracks when the clipboard actually receives cliptext
	If (mode = "copy")
	{
		Send {Ctrl Down}c{Ctrl Up}
	}
	Else if (mode = "cut")
	{
		Send {Ctrl Down}x{Ctrl Up}
	}
	Else
	{
		Tip(displaytext)
		Send {Alt Up}
		Exit
	}
	cycle := 0
	Loop ;Waits for the clipboard to receive cliptext before proceeding
	{
		If (ClipChange = True)
		{
			ClipChange := ;Resets ClipChange on success
			Return
		}
		cycle := cycle+.1
		Sleep 15
		If (cycle > duration) ;Timeout
		{
			Tip(displaytext)
			Send {Alt Up}
			Exit
		}
	}
	clipText := Clipboard
	ClipRestore()
}



	Clip(cliptext, duration:=1, displaytext:="Oops")
	;Sends cliptext to the clipboard, then waits for it to be received before the script continues
	{
		ClipSave() ;Saves the existing clipboard for later restoration
		ClipChange := ;Tracks when the clipboard actually receives cliptext
		cycle := 0
		Clipboard := cliptext
		Loop ;Waits for the clipboard to receive cliptext before proceeding
		{
			If (ClipChange = True)
			{
				ClipChange := ;Resets ClipChange on success
				Return
			}
			cycle := cycle+.1
			Sleep 15
			If (cycle > duration) ;Timeout
			{
				Tip(displaytext)
				Send {Alt Up}
				Exit
			}
		}
	}

	ClipChanged()
	;Tells Clip(), CopyClip(), and CutClip() when the clipboard has received new text
	{
		ClipChange := True
	}

	ClipSave(duration:=1)
	;Stores the current clipboard for later restoration
	{
		ClipChange :=
		cycle := 0
		ClipSave := Clipboard
		Clipboard :=
		Loop
		{
			If (ClipChange = True) ;Waits for the clipboard to actually register a change before continuing
			{
				ClipChange := ;Resets ClipChange on success
				Return
			}
			cycle := cycle+.1
			Sleep 25
			If (cycle > duration) ;Timeout
			{
				Send {Alt Up}
				Exit
			}
		}
	}

	ClipRestore(duration:=1)
	;Restores the saved clipboard from ClipSave
	{
		Sleep 200 ;To prevent restoring the clipboard before the previous line has finished pasting
		ClipChange :=
		cycle := 0
		ClipBoard := ClipSave ;Restores the saved clipboard
		Loop ;Waits for the clipboard to receive ClipSave before proceeding
		{
			If (ClipChange = True)
			{
				ClipChange := ;Resets ClipChange on success
				;ClipSave :=
				Return
			}
			cycle := cycle+.1
			Sleep 25
			If (cycle > duration) ;Timeout
			{
				Send {Alt Up}
				Exit
			}
		}
	}

	Tip(tiptext)
	;Displays a tooltip for 2 seconds
	{
		Tooltip, %tiptext%
		SetTimer, RemoveToolTip, -2000
	}

	RemoveToolTip:
	;Clears the current tooltip
		ToolTip
	Return

	ArrayTrim(An_array)
	;Removes empty values from an array
	{
		for index, value in an_array
		{
			if (value = "")
			{
				an_array.RemoveAt(index)
			}
		}
	}


{ ;CLIPDECK GUI=========================================================

ClipdeckInitialize()
{
	Gui, new, , Clipdeck
	Gui Clipdeck:-SysMenu Resize -MaximizeBox +AlwaysOnTop +Owner +MinSize  ;-SysMenu omits title bar; Resize makes the window resizable, but adds the Maximize button back; -MaximizeBox removes it again; +Owner avoids a taskbar button
	Gui, Clipdeck:Add, ListView, vClipdeckNextLine -multi, Win#|Line text
	Gui, Clipdeck:Add, Button,, Clear Deck
	Gui, Clipdeck:Add, Button, hidden, Spacer
	Gui, Clipdeck:Add, Button,, Split
	Gui, Clipdeck:Add, Button, default, Drop


	loc := "X0 Y0" ;Initially positions the GUI at the top left of the screen

	
	ClipdeckAdd(Clipboard, loc)
	LV_Modify(1, "Select") ;Selects the first/only item in Clipdeck
}

ClipdeckGuiSize:
{
	Gui Clipdeck:Default
	GuiControl, Move, ClipdeckNextLine, % "w"A_GuiWidth-75 "h"A_GuiHeight-60
	GuiControl, MoveDraw, Button1, % "y"A_GuiHeight-29
	GuiControl, MoveDraw, Button2, % "y"A_GuiHeight-29 "x"A_GuiWidth-120
	GuiControl, MoveDraw, Button3, % "y"A_GuiHeight-29 "x"A_GuiWidth-80
	GuiControl, MoveDraw, Button4, % "y"A_GuiHeight-29 "x"A_GuiWidth-40
	Return
}

ClipdeckAdd(LineText, loc:="")
;Adds clipboard text to the listview
{
	Gui Clipdeck:Default
	LV_Add(Vis, LV_GetCount()+1, LineText)
	LV_ModifyCol(AutoHdr)
	row_count := LV_GetCount()
	LV_height = % (row_count*18)+44
	pane_height := % (LV_height)+60
	GuiControl, Move, ClipdeckNextLine, H%LV_height%
	Gui, Clipdeck:Show, NoActivate %loc% H%pane_height%, % "Next line (1/"LV_GetCount()")" ;ClipdeckInitialize will provide a loc that positions the window; any subsequent calls of ClipdeckAdd will have a blank loc so as not to reposition a window that may have been moved
	ClipRestore()
	Return
}


ClipdeckRetrieve()
;Returns the selected row text to be pasted
{
	Gui Clipdeck:Default
	If (LV_GetNext() = 0)
	{
		LV_Modify(1, "Select")
	}
	this_row := LV_GetNext()
	LV_GetText(line_text, this_row, 2)
	Clip(line_text)
	Return this_row
}

ClipdeckRemove()
;Removes text from the listview
{
	Gui Clipdeck:Default
	If (LV_GetNext() = 0) ;If no row selected, selects the first
	{
		LV_Modify(1, "Select")
	}
	this_row := LV_GetNext()
	LV_Delete(this_row) ;Deletes selected row
	LV_Modify(this_row, "Select") ;Selects the next row, which now has the position number of the row we just deleted
	row_count := LV_GetCount()
	Loop, %row_count%
	{
		LV_Modify(A_Index, Col1, A_Index) ;Updates Win# for remaining rows
	}
	LV_height = % (row_count*18)+44
	pane_height := % (LV_height)+60
	GuiControl, Move, ClipdeckNextLine, H%LV_height%
	Gui, Clipdeck:Show, NoActivate H%pane_height%, % "Next line (1/"LV_GetCount()")" ;ClipdeckInitialize will provide a loc that positions the window; any subsequent calls of ClipdeckAdd will have a blank loc so as not to reposition a window that may have been moved
}

ClipdeckDestroyCheck()
;Detroys the GUI if Clipdeck is empty
{
	Gui Clipdeck:Default
	If (LV_GetCount() = 0)
	{
		Gui, Clipdeck:Destroy
		ClipRestore()
		Return
	}
}

ClipdeckButtonSplit:
;Seperates each paragraph of text into its own Clipdeck entry
{
	line_array := []
	Gui Clipdeck:Default
	count := LV_GetCount()
	Loop, %count%
	{
		LV_GetText(this_line, A_Index, 2)
		line_array.Push(StrSplit(this_line, "`r", "`n")*)
	}
	ArrayTrim(line_array) ;Removes empty lines
	LV_Delete() ;Deletes the existing list
	Loop % line_array.length()
	{
		ClipdeckAdd(line_array[A_Index]) ;Adds each line back to the Clipdeck
	}
	Sleep 10 ;Seems to need a moment for the next line to do anything
	LV_Modify(1, "Select")
	Return
}

ClipdeckButtonDrop:
;Removes the next/selected item from the Clipdeck
{
	ClipdeckRemove()
	ClipdeckDestroyCheck()
	Return
}
	
ClipdeckButtonClearDeck:
;Clears the entire deck
{
	count := LV_GetCount()
	Loop, %count%
	{
		LV_GetText(line_text, A_Index, 2) ;Retrieves the selected row's text
		all_lines := all_lines . line_text . A_Return ;Concatenates to previous rows
	}
	ClipdeckRecall := all_lines
	Gui, Clipdeck:Destroy
	ClipRestore()
	Return
}

ClipdeckPasteAll()
;Paste all items from Clipdeck
{
	
	Gui Clipdeck:Default
	count := LV_GetCount()
	Loop, %count%
	{
		this_row := LV_GetNext() ;Gets the selected row number
		LV_GetText(line_text, this_row, 2) ;Retrieves the selected row's text
		If (this_row = count) ;Loops around to the beginning of the list if the user selected a starting row other than the top
		{
			this_row := 0
		}
		LV_Modify(this_row+1, "Select") ;Selects the next row for the next loop
		all_lines := all_lines . line_text . A_Return ;Concatenates to previous rows
	}
	Clip(all_lines)
	Send ^v
	ClipdeckRecall := all_lines
	Gui, Clipdeck:Destroy
	LV_Delete()
	ClipRestore()
	Return
}


;HOTKEYS===================================================================

#c::
;Clipdeck copy
{
	ClipDeckCopy("copy", 2, "No text selected") ;Copies selected text
	If not WinExist("Next line (1") ;Creates the Clipdeck GUI if it doesn't already exist
	{
		ClipdeckInitialize()
	}
	Else ;If the GUI does exist, just adds the copied text to Clipdeck
	{
		ClipdeckAdd(ClipBoard)
	}
	;ClipRestore() ;Restores the previous clipboard
	Return
}

#x::
;Clipdeck cut
{
	ClipDeckCopy("cut", 2, "No text selected") ;Copies selected text
	If not WinExist("Next line (1") ;Creates the Clipdeck GUI if it doesn't already exist
	{
		ClipdeckInitialize()
	}
	Else ;If the GUI does exist, just adds the copied text to Clipdeck
	{
		ClipdeckAdd(ClipBoard)
	}
	;ClipRestore() ;Restores the previous clipboard
	Return
}

#`::
;Clipdeck paste last item
{
	Clip(ClipdeckRecall)
	Send ^v
	ClipRestore()
	Return
}

#IfWinExist Next line (1/
;Paste hotkeys only work if the Clipdeck GUI window exists

#v::
;Clipdeck paste
{
	ClipdeckRetrieve() ;Gets the next item to paste
	ClipdeckRemove() ;Removes that item from Clipdeck
	Send ^v ;Pastes
	ClipdeckRecall := Clipboard
	ClipRestore()
	ClipdeckDestroyCheck() ;Destroys the GUI if Clipdeck is empty
	Return
}


#1::
#Numpad1::
#2::
#Numpad2::
#3::
#Numpad3::
#4::
#Numpad4::
#5::
#Numpad5::
#6::
#Numpad6::
#7::
#Numpad7::
#8::
#Numpad8::
#9::
#Numpad9::
#0::
#Numpad0::
;Pastes the Clipdeck item at the list position of the hotkey number
{
	Gui Clipdeck:Default
	paste_num := SubStr(A_ThisHotkey, 0) ;Gets the number used in the hotkey
	If paste_num = 0
	{
		paste_num := 10
	}
	LV_Modify(paste_num, "Select") ;Selects that item in the list
	ClipdeckRetrieve() ;Gets that item to paste
	Send ^v ;Pastes
	ClipdeckRecall := Clipboard
	ClipRestore()
	Return
}

#b::
;Clipdeck paste without removing the pasted item from the deck
{	
	Gui Clipdeck:Default
	ClipdeckRetrieve() ;Gets the next item to paste
	Send ^v ;Pastes
	ClipdeckRecall := Clipboard
	ClipRestore()
	row_number := LV_GetNext() ;Gets the list number of the next item
	LV_Modify(row_number, "-Select") ;Deselecting allows this to loop at the end of the list
	LV_Modify(row_number+1, "Select") ;Selects the next item for the next paste
	If (row_number = LV_GetCount()) ;Loops around to the beginning of the list
	{
		LV_Modify(1, "Select")
	}
	Return
}


^#v::
;Paste all
{
	ClipdeckPasteAll()
	Return
}

#z::Goto, ClipdeckButtonClearDeck ;Clears the entire deck

}

