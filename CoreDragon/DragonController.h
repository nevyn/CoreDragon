#import <UIKit/UIKit.h>
@protocol DragonDelegate, DragonDropDelegate;

NS_ASSUME_NONNULL_BEGIN

/// Controller for managing drag an drop between views (possibly between applications).
@interface DragonController : NSObject

/*! Get the shared DragonController. Only use this singleton: don't instantiate
	more of them. */
+ (instancetype)sharedController;

#pragma mark Gesture handling

/*! To enable drag'n'drop within your application, some gesture must be used to start
	a dragging operation. You can enable the default 'long-press-then-drag' gesture
	by calling `allowLongPressDraggingInWindow:` with your app's main window
	(or any other window).
	
	@see also `dragGesture:`
	*/
- (void)enableLongPressDraggingInWindow:(UIWindow*)window;
/*! Uninstall the 'long-press-then-drag' gesture from your window. */
- (void)disableLongPressDraggingInWindow:(UIWindow*)window;

/*! To enable a custom drag'n'drop gesture, set this method as your gesture
	recognizer's action method. */
- (void)dragGesture:(UIGestureRecognizer*)grec;

#pragma mark Drag sources

/*! Allow drags to be started from the 'draggable' UIView. The given delegate
	will be asked to customize this drag (by providing the data to be dragged, etc)
	if/when a drag starts. */
- (void)registerDragSource:(UIView *)draggable delegate:(id<DragonDelegate>)delegate;
/*! Stop allowing drags from this view.*/
- (void)unregisterDragSource:(UIView *)draggable;

#pragma mark Drop targets

/*! Allow drags to end up in the 'droppable' UIView. The given delegate
	will be asked to accept the drop data if/when a drag ends over this view. */
- (void)registerDropTarget:(UIView *)droppable delegate:(id<DragonDropDelegate>)delegate;
/*! Stop allowing drops to this view. */
- (void)unregisterDropTarget:(id)droppableOrDelegate;

#pragma mark Misc
/*!	Is the user currently dragging something, in this app or any other app? */
- (BOOL)draggingOperationIsInProgress;

/*! Recalculates active drop targets, e.g. to allow for refreshing cells in scrolling table view. */
- (void)recalculateActiveDropTargets;

/*! Explicitely invalidates and redraws a highlight for a specific view. */
- (void)invalidateHighlightForView:(UIView *)view;

@end

/// Information about a dragging operation that is about to start or is in progress.
@protocol DragonInfo <NSObject>
@property(nonatomic,readonly) UIPasteboard *pasteboard;

// Can only be set during 'beingDragOperation:fromView:'
/*! An icon to represent the data you just put in pasteboard. If not set, the
	drag will be represented by a screenshot of the dragged view. */
@property(nonatomic,strong,nullable) UIImage *draggingIcon;
/*! If draggingIcon is set, you can optionally also set a title to be shown next
	to the icon while dragging. */
@property(nonatomic,copy,nullable) NSString *title;
/*! And additionally, a subtitle can be displayed below the title. */
@property(nonatomic,copy,nullable) NSString *subtitle;
@end


@protocol DragonDelegate <NSObject>
@required
/*!
	Dragging was just initiated from `draggable`. Put the object(s) to be dragged onto
	the pasteboard in `drag`. Not doing so will cancel the drag.
*/
- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView*)draggable;
@end

@protocol DragonDropDelegate <NSObject>
@required
/// Whether you can drop the items on on `droppable` or not (either for accepting the drop, or for springloading)
- (BOOL)dropTarget:(UIView*)droppable canAcceptDrag:(id<DragonInfo>)drag;

@optional
/// Default 'YES' if `dropTarget:acceptDrag:atPoint:` is implemented, otherwise NO
- (BOOL)dropTarget:(UIView*)droppable shouldAcceptDrag:(id<DragonInfo>)drag;
- (void)dropTarget:(UIView*)droppable acceptDrag:(id<DragonInfo>)drag atPoint:(CGPoint)p;

/// Default 'YES' if `dropTarget:springload:atPoint:` is implemented, otherwise NO
- (BOOL)dropTarget:(UIView*)droppable shouldSpringload:(id<DragonInfo>)drag;
- (void)dropTarget:(UIView*)droppable springload:(id<DragonInfo>)drag atPoint:(CGPoint)p;

// If you want to customize the highlight shown for a drag based on where the finger is right now
// (e g for doing out-of-edit drag rearrangement in table views), implement this method.
- (void)dropTarget:(UIView *)droppable updateHighlight:(UIView*)highlightContainer forDrag:(id<DragonInfo>)drag atPoint:(CGPoint)p;
@end

/// Sent when a drag operation starts.
static NSString *const DragonDragOperationStartedNotificationName = @"eu.thirdcog.dragon.dragStarted";
/// Sent when a drag operation stops.
static NSString *const DragonDragOperationStoppedNotificationName = @"eu.thirdcog.dragon.dragStopped";

NS_ASSUME_NONNULL_END
