<img src="Resources/logo.png" width="200" height="200">

# CoreDragon

![cocoapods](https://img.shields.io/cocoapods/v/CoreDragon.svg) ![license](https://img.shields.io/cocoapods/l/CoreDragon.svg) <br />[![Twitter](https://img.shields.io/badge/twitter-@nevyn-blue.svg)](http://twitter.com/nevyn) [![email](https://img.shields.io/badge/email-nevyn.jpg@gmail.com-lightgrey.svg)](mailto:nevyn.jpg@gmail.com)

CoreDragon is a drag'n'drop library for iOS applications. Instead of using context menus, modal view controllers, share sheets and other "indirect manipulation" ways of moving data around, it's much more intuitive to just grab the thing you want to move, and drop it on the place where you want to move it to.

CoreDragon uses similar concepts as the drag'n' drop APIs on MacOS, and modifies them to work better in a world with view controllers. It works within a single application, and on modern iPads, between applications that are running in split screen mode.

CoreDragon was originally called SPDragNDrop, and was a Hackweek experiment written by me during the December 2012 Hackweek at Spotify. Since I really loved the idea and would hate for the code+idea to just rot away, Spotify allowed me to release the code under Apache 2.0 before my employment there ended.

I'm working on some proper demo applications. Until then, [see a demo movie](https://www.youtube.com/watch?v=sCm0F4UrXJg).

## Installation


1. Add `pod 'CoreDragon'` to your Podfile
2. Run `pod install`
3. Add `#import <CoreDragon/CoreDragon.h>` from your bridging header, prefix header, or wherever you want to use drag'n'drop features

## Getting Started

### Installation
By default, CoreDragon uses a long-press-and-drag gesture to start and perform dragging. To install this default gesture, call `enableLongPressDraggingInWindow:` from your Application Delegate like so:

```objc
- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	[[DragonController sharedController] enableLongPressDraggingInWindow:self.window];
    return YES;
}
```

### Registering things that can be dragged

When you have a view that you would like to allow your users to drag, you can register it with `-[DragonController registerDragSource:delegate:]`. You would probably call it from a view controller's `viewDidLoad`, setting the view controller as the delegate. Whenever a dragging operation is initiated from this view, it is up to your view controller to provide the data for the object being dragged by putting it on a pasteboard:

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[DragonController sharedController] registerDragSource:label1 delegate:self];
}

- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView *)draggable
{
	// Required: Provide the data to be dragged by adding it to the dragging info's pasteboard:
	[drag.pasteboard setValue:text forPasteboardType:(NSString*)kUTTypePlainText];
	
	// By default, the item being dragged is represented by a screenshot of the draggable view.
	// Optionally, you can set 'title', 'subtitle' and 'draggingIcon' on the dragging info
	// to give it a pretty icon.
	NSString *text = [(UILabel*)draggable text];
    drag.title = text;
    drag.draggingIcon = [UIImage imageNamed:@"testimage"];
}

```

Drag sources are automatically unregistered when they are deinited.

### Registering drop targets

Now that the user is holding an object with their finger, they will need somewhere to drop it. You can register drop targets in a very similar manner to drag sources. The delegate protocol for drop targets has several methods:

* For accepting the dragged data (required)
* For indicating that it does or does not support being dragged to
* For springloading (hovering over the drop target to navigate into it, like hovering an icon in Finder while dragging)
* For customizing the visualization of the drop target based on where the user's finger is pointing (to support custom highlighting in a table view, etc).

A simple drop target could look like so:

```objc
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[DragonController sharedController] registerDropTarget:label2 delegate:self];
}

// Ensure that we only receive drops for plain text
- (BOOL)dropTarget:(UIView *)droppable canAcceptDrag:(id<DragonInfo>)drag
{
	return [drag.pasteboard containsPasteboardTypes:@[(NSString*)kUTTypePlainText]];
}

// When some plain text is dropped on this target, set the label's text to the incoming text.
- (void)dropTarget:(UIView *)droppable acceptDrag:(id<DragonInfo>)drag atPoint:(CGPoint)p
{
	[(UITextView*)droppable setText:[drag.pasteboard valueForPasteboardType:(NSString*)kUTTypePlainText]];
}

```

## Examples

### DragonFrame

A "photo frame" app with the simplest possible drag and drop support. Has a single image view which
accepts drops on one tab, and another tab with a few example photos.

Features:

* Registering drag sources (example photos)
* Registering drop targets (the photo frame)
* Two-handed navigation: Grab a photo with one hand, and tap the tab bar to navigate to the photo frame.

### DragonPhotos

This is a photo organizer app with folder support, demoing all features of CoreDragon.

Photos are laid out in a collection view in a user-defined order. Dropping a photo onto another photo creates a folder. Photos can be imported from the camera roll, or dragged to the application.

Features:

* Registering drag sources (photos and folders)
* Registering drop targets (folders and the view controller's root view)
* Multiple dragging representations.
	* Image data is put on pasteboard to support dragging images to other applications.
	* Database reference is put on pasteboard to support reordering and reorganizing photos within the
	  application.
* Custom highlighting. It is possible to re-order objects within a folder by drag-and-drop, with an indicator showing the new location for an item as a custom highlight view.
* Spring-loading. By hovering an object over a folder, the hovered folder view controller is opened, so
  that you can continue organizing within it.
* Two-handed navigation. Instead of spring-loading, you can grab an object with one hand, and then tap
  in the application with your other hand to navigate to the location in the application where
  you want to drop the object.

![dragonphotos](https://cloud.githubusercontent.com/assets/34791/11920705/4f69cb44-a72b-11e5-95fb-8b0e89deec3b.PNG)

### DragonChat

TO BE IMPLEMENTED

A fake chat app with demo conversations, where you can attach photos to the conversation by dragging them
from DragonPhotos. The purpose of this app is to show a real-world use case of drag&drop.

## License

[Apache 2.0](LICENSE.txt)

## Background

I've always loved multitouch. In addition, I love working spatially with windows and drag&drop. Neither concept has gained much traction on iPad, and not even exploring those concepts means missing out.

At Spotify, I got my windows by [copying Loren Brichter's stacked panes navigation](https://github.com/spotify/SPStackedNav). Finally, I had tactile, direct manipulation navigation. However, all contextual operations were still performed in modes. If you wanted to share a track with a friend, you'd go into the context menu mode for your track by long-pressing it, then the sharing mode by choosing an option in a table, then the friend selection mode... To me, it would be so much more natural to just grab the track, and drag it onto the icon representing my friend. Suddenly you'd be able to remove all these modes, and have direct manipulation of your objects.

I met my hero [Bret Victor](http://worrydream.com) at WWDC 2012, and we talked for a while about drag & drop on iPad, and he added a very important point I hadn't thought about for many years: with multitouch, you can pick something up with one hand, and navigate with the other. This concept had already blown my mind once back in 2005, when [TactaPad released a few amazing concept movies and then never showed themselves again](http://www.tactiva.com/tactadrawmovielarge.html).

So during Hackweek December 2012, I mocked up drag&drop inside the Spotify iPad app. It worked really well. You could pick up a track with your right hand, tap the tab bar with your left hand, navigate around the UI a bit either by tapping on items with your left hand or springloading with your right, and dropping your item when you were done.

<img src="https://dl.dropboxusercontent.com/u/6775/dragndrop.gif" width=400/>

Unfortunately, the idea never got any traction within the company and the branch died. That was over a year ago, and the code is now uncompileable. (Yes, when your build system breaks with every point update of Xcode, code really does rot.) Thus, the only screenshot I have is of the trivial demo app in this repo. Hopefully it is inspiring enough that you now feel the immediate need to use the code or the concept in your own app! Hooray!

After WWDC 2015, when split-screen multitasking was introduced, I started working on inter-app drag'n'drop. [Here's what it looked like on 20150831](https://lookback.io/watch/gFRLes3mS5CWRYqNN), and [further progress on 20151129](https://www.youtube.com/watch?v=sCm0F4UrXJg).
