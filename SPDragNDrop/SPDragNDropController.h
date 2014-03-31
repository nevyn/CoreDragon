#import <UIKit/UIKit.h>
@protocol SPDragDelegate, SPDropDelegate, SPDragProxyIconDelegate;

@interface SPDragNDropController : NSObject
+ (id)sharedController;
// A view in the window that applies rotation transforms, and covers the whole window. You need to set
// this from your application (manually or by calling createDraggingContainerInWindow:)
@property(nonatomic,retain) UIView *draggingContainer;
- (void)createDraggingContainerInWindow:(UIWindow*)window;

@property(nonatomic,unsafe_unretained) id<SPDragProxyIconDelegate> proxyIconDelegate;

- (void)registerDragSource:(UIView *)draggable delegate:(id<SPDragDelegate>)delegate;
- (void)registerDropTarget:(UIView *)droppable delegate:(id<SPDropDelegate>)delegate;
- (void)unregisterDropTarget:(id)droppableOrDelegate;
@end


@protocol SPDragDelegate <NSObject>
@required
/// The model object that dragging this draggable somewhere will provide (the thing to put in the pasteboard,
/// with Mac terminology)
- (id)modelObjectForDraggable:(UIView*)draggable;
@end

@protocol SPDropDelegate <NSObject>
@required
// Whether you can drop 'modelObjects' on 'droppable' or not (either for accepting the drop, or for springloading)
- (BOOL)droppable:(UIView*)droppable canAcceptModelObject:(id)modelObject;

@optional
// Default 'YES' if acceptDrop is implemented, otherwise NO
- (BOOL)droppable:(UIView*)droppable shouldAcceptDrop:(id)modelObject;
- (void)droppable:(UIView*)droppable acceptDrop:(id)modelObject atPoint:(CGPoint)p;

// Default 'YES' if springloads is implemented, otherwise NO
- (BOOL)droppable:(UIView*)droppable shouldSpringload:(id)modelObject;
- (void)droppable:(UIView*)droppable springload:(id)modelObject atPoint:(CGPoint)p;

// If you want to customize the highlight shown for a drag based on where the finger is right now
// (e g for doing out-of-edit drag rearrangement in table views), implement this method.
- (void)droppable:(UIView *)droppable updateHighlight:(UIView*)highlightContainer forDragOf:(id)modelObject atPoint:(CGPoint)p;

@end

@protocol SPDragProxyIconDelegate <NSObject>
- (UIView*)dragController:(SPDragNDropController*)dragndrop iconViewForModelObject:(id)modelObject getTitle:(NSString**)title getSubtitle:(NSString**)subtitle;
@end