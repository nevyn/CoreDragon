#import <UIKit/UIKit.h>
@protocol SPDragDelegate, SPDropDelegate;

/// Controller for managing drag an drop between views (possibly between applications).
@interface DragonController : NSObject
/*! Get the shared DragonController. Only use this singleton: don't instantiate
	more of them. */
+ (id)sharedController;

/*! Allow drags to be started from the 'draggable' UIView. The given delegate
	will be asked to customize this drag (by providing the data to be dragged, etc)
	if/when a drag starts. */
- (void)registerDragSource:(UIView *)draggable delegate:(id<SPDragDelegate>)delegate;
/*! Stop allowing drags from this view.*/
- (void)unregisterDragSource:(UIView *)draggable;

/*! Allow drags to end up in the 'droppable' UIView. The given delegate
	will be asked to accept the drop data if/when a drag ends over this view. */
- (void)registerDropTarget:(UIView *)droppable delegate:(id<SPDropDelegate>)delegate;
/*! Stop allowing drops to this view. */
- (void)unregisterDropTarget:(id)droppableOrDelegate;
@end

/// Information about a dragging operation that is about to start or is in progress.
@protocol SPDraggingInfo <NSObject>
@property(nonatomic,readonly) UIPasteboard *pasteboard;

// Can only be set during 'beingDragOperation:fromView:'
/*! An icon to represent the data you just put in pasteboard. If not set, the
	drag will be represented by a screenshot of the dragged view. */
@property(nonatomic,strong) UIImage *draggingIcon;
/*! If draggingIcon is set, you can optionally also set a title to be shown next
	to the icon while dragging. */
@property(nonatomic,copy) NSString *title;
/*! And additionally, a subtitle can be displayed below the title. */
@property(nonatomic,copy) NSString *subtitle;
@end


@protocol SPDragDelegate <NSObject>
@required
/*!
	Dragging was just initiated from `draggable`. Put the object(s) to be dragged onto
	the pasteboard in `drag`. Not doing so will cancel the drag.
*/
- (void)beginDragOperation:(id<SPDraggingInfo>)drag fromView:(UIView*)draggable;
@end

@protocol SPDropDelegate <NSObject>
@required
/// Whether you can drop the items on on `droppable` or not (either for accepting the drop, or for springloading)
- (BOOL)dropTarget:(UIView*)droppable canAcceptDrag:(id<SPDraggingInfo>)drag;

@optional
/// Default 'YES' if `dropTarget:acceptDrag:atPoint:` is implemented, otherwise NO
- (BOOL)dropTarget:(UIView*)droppable shouldAcceptDrag:(id<SPDraggingInfo>)drag;
- (void)dropTarget:(UIView*)droppable acceptDrag:(id<SPDraggingInfo>)drag atPoint:(CGPoint)p;

/// Default 'YES' if `dropTarget:springload:atPoint:` is implemented, otherwise NO
- (BOOL)dropTarget:(UIView*)droppable shouldSpringload:(id<SPDraggingInfo>)drag;
- (void)dropTarget:(UIView*)droppable springload:(id<SPDraggingInfo>)drag atPoint:(CGPoint)p;

// If you want to customize the highlight shown for a drag based on where the finger is right now
// (e g for doing out-of-edit drag rearrangement in table views), implement this method.
- (void)dropTarget:(UIView *)droppable updateHighlight:(UIView*)highlightContainer forDrag:(id<SPDraggingInfo>)drag atPoint:(CGPoint)p;
@end