- [ ] Implement some proper example apps!
	- [ ] Fake 'chat' app
	- [-] 'Photos' app
		- [X] List photos
		- [X] Move photos between folders
		- [X] Reorder photos
		- [X] Springloading
- [ ] Visualize the drop targets as cut-outs (instead of blue rectangles) and dim the rest of the screen
- [ ] Support different dragging modes (moving, copying, aliasing, ...)
- [ ] Support multiple dragged items
- [ ] Promises (only put description of data on pasteboard until transfer is needed)

- [ ] When drag fails, if original view isn't on screen anymore, find a better 'cancellation' animation.
- [ ] Protocol versioning
- [ ] Make unregistering drag sources/drop targets be optional (unregistered when dealloc'd)

- [X] Hide the item being dragged (so it doesn't look like we have two of them)
- [X] Cocoapods spec
- [X] Better readme/documentation
- [X] Use secure coding
- [X] Put the dragging metadata as an alt type in the first pasteboard item instead
	  of adding it as a separate item
- [X] Add a drop shadow under the drag screenshot
- [X] Implement a "successful drop" animation
- [X] Implement timeout, so that if no one seems to be taking care of a drag conclusion,
      do it from the source app
- [X] Use a top-layer root window instead of 'dragging container'
- [X] Change API to use pasteboard instead of modelObject
- [X] Send drag metadata such as thumbnail, icon, name over auxilliary pasteboard
- [X] Make everybody know when a remote app can accept a drag, so we can do
	  cancellation/acceptance correctly at the end of a drag.
- [X] After the drag destination app has handled the drag, tell the source app
	  to restore the pasteboard!
- [X] If drop target doesn't accept drop, don't send the drop to it when dragging ends!
- [X] Fix connection reestablishment when foregrounding
- [X] Get rid of SPDragProxyIconDelegate and just put it into DragonDelegate like on Mac

- [X] Make gesture recognizer survive view disappearing from its superview.
	  We need to be able to navigate away from the drag source during dnd.
- [X] Find a better name, and rename project

## oooh?!

- [ ] A shelf! Which is just a representation of the pasteboard and its items :)
