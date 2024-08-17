# ClipDeck Clipboard Manager
ClipDeck is an AutoHotkey clipboard manager that works alongside the normal Windows clipboard, letting you copy multiple items to a GUI window and paste them in any order.


## Hotkeys
### Win+c
Copy to clipdeck


### Win+x
Cut to clipdeck

### Win+v
Paste from clipdeck. By default, it pastes in the order that text was copied in, but you can click a different item in the GUI to paste from there instead.

### Win+(any digit)
Pastes the item at that list number, E.G., Win+5 pastes the fifth item in the GUI list. 0 is treated as 10; double digits are not supported.

### Win+b
Paste from clipdeck, but without removing the pasted item, allowing it to be pasted multiple times.

### Control+Win+v
Pastes all clipdeck entries, each as its own paragraph.

### Win+` (Backtick, the key about Tab on most keyboards)
Empties the entire deck, as the Clear Deck GUI button.

## GUI Window Buttons
### Clear Deck
Empties the entire deck.

### Split
Splits multi-paragraph items so each paragraph is its own clipdeck item.

### Drop
Removes the selected item from the deck.



