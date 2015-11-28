#import <UIKit/UIKit.h>
@protocol SPDragDelegate, SPDropDelegate, SPDragProxyIconDelegate;

/// Controller for managing drag an drop between views (possibly between applications).
@interface SPDragNDropController : NSObject
+ (id)sharedController;
@property(nonatomic,weak) id<SPDragProxyIconDelegate> proxyIconDelegate;

- (void)registerDragSource:(UIView *)draggable delegate:(id<SPDragDelegate>)delegate;
- (void)unregisterDragSource:(UIView *)draggable;

- (void)registerDropTarget:(UIView *)droppable delegate:(id<SPDropDelegate>)delegate;
- (void)unregisterDropTarget:(id)droppableOrDelegate;
@end

/// Information about a dragging operation that is in progress
@protocol SPDraggingInfo <NSObject>
@property(nonatomic,readonly) UIPasteboard *pasteboard;
@end


@protocol SPDragDelegate <NSObject>
@required
/*!
	Dragging was just initiated from `draggable`. Put the object(s) to be dragged onto
	`pasteboard`. Not doing so will cancel the drag.
*/
- (void)beginDragOperationFromView:(UIView*)draggable ontoPasteboard:(UIPasteboard*)pasteboard;
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

@protocol SPDragProxyIconDelegate <NSObject>
- (UIImage*)dragController:(SPDragNDropController*)dragndrop iconViewForDrag:(id<SPDraggingInfo>)drag getTitle:(NSString**)title getSubtitle:(NSString**)subtitle;
@end