#import "SPDragNDropController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "SPDropHighlightView.h"
#import "SPDraggingContainerWindow.h"
#import "SPDragProxyView.h"
#import <CerfingMeshPipeTransport/CerfingMeshPipe.h>

@class SPDropTarget, SPDragSource;

//#define DNDLog(...) NSLog(__VA_ARGS__)
#define DNDLog(...)

static const void *kDragSourceKey = &kDragSourceKey;
static const void *kDropTargetKey = &kDropTargetKey;
static const NSTimeInterval kSpringloadDelay = 1.3;
static NSString *const kDragMetadataKey = @"eu.thirdcog.dragndrop.meta";

@interface SPDraggingState : NSObject <SPDraggingInfo>
// Initial, transferrable state
@property(nonatomic,strong) UIImage *screenshot;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,strong) UIImage *proxyIcon;
@property(nonatomic,strong) UIPasteboard *pasteboard;
@property(nonatomic,assign) CGPoint initialPositionInScreenSpace;
@property(nonatomic,assign) NSString *operationIdentifier;

// During-drag state
@property(nonatomic,strong) NSArray *originalPasteboardContents;
@property(nonatomic,strong) UIView *dragInitiator; // the thing that was long-pressed
@property(nonatomic,strong) UIView *proxyView; // thing under finger
@property(nonatomic,strong) NSArray *activeDropTargets;
@property(nonatomic,strong) NSTimer *springloadingTimer;
@property(nonatomic,weak) SPDropTarget *hoveringTarget;
@end

@interface SPDragSource : NSObject
@property(nonatomic,weak) UIView *view;
@property(nonatomic,weak) id<SPDragDelegate> delegate;
@property(nonatomic) UILongPressGestureRecognizer *longPressGrec;
@end

@interface SPDropTarget : NSObject
@property(nonatomic,weak) UIView *view;
@property(nonatomic,weak) id<SPDropDelegate> delegate;
@property(nonatomic,strong) SPDropHighlightView *highlight;
- (BOOL)canSpringload:(id<SPDraggingInfo>)drag;
- (BOOL)canDrop:(id<SPDraggingInfo>)drag;
@end

@interface SPDragNDropController () <UIGestureRecognizerDelegate, CerfingConnectionDelegate>
{
	NSMutableSet *_dragSources;
    NSMutableSet *_dropTargets;
	CerfingMeshPipe *_cerfing;
}
@property(nonatomic,strong) SPDraggingState *state;
@property(nonatomic,strong) SPDraggingContainerWindow *draggingContainer;
@end

@implementation SPDragNDropController
+ (id)sharedController
{
    static SPDragNDropController *singleton = nil;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        singleton = [SPDragNDropController new];
    });
    return singleton;
}

- (id)init
{
    if (!(self = [super init]))
        return nil;
	
	_dragSources = [NSMutableSet new];
    _dropTargets = [NSMutableSet new];
	
	[[NSNotificationCenter defaultCenter] addObserver:self selector:@selector(_establishMeshPipe) name:UIApplicationDidBecomeActiveNotification object:nil];
	[self _establishMeshPipe];
	
	self.draggingContainer = [[SPDraggingContainerWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
	self.draggingContainer.hidden = NO;
	
    return self;
}

- (void)dealloc
{
	[[NSNotificationCenter defaultCenter] removeObserver:self];
	
    self.draggingContainer.hidden = YES;
    self.draggingContainer = nil;
	
	for(SPDragSource *source in _dragSources) {
		[source.view removeGestureRecognizer:source.longPressGrec];
		objc_setAssociatedObject(source.view, kDragSourceKey, nil, OBJC_ASSOCIATION_RETAIN);
	}
}

#pragma mark - Network establish

- (void)_establishMeshPipe
{
	_cerfing = nil;
	
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?:
						[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?:
						[[NSProcessInfo processInfo] processName];
	
	_cerfing = [[CerfingMeshPipe alloc] initWithBasePort:23576 count:16 peerName:appName];
	_cerfing.delegate = self;
}



#pragma mark - Registration

- (void)registerDragSource:(UIView *)draggable delegate:(id<SPDragDelegate>)delegate
{
	SPDragSource *source = [SPDragSource new];
	source.delegate = delegate;
	source.longPressGrec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dragGesture:)];
	source.longPressGrec.delegate = self;
	[draggable addGestureRecognizer:source.longPressGrec];

    objc_setAssociatedObject(draggable, kDragSourceKey, source, OBJC_ASSOCIATION_RETAIN);
}

- (void)unregisterDragSource:(UIView *)draggable
{
    SPDragSource *source = objc_getAssociatedObject(draggable, kDragSourceKey);
	if(source) {
		[draggable removeGestureRecognizer:source.longPressGrec];
		[_dragSources removeObject:source];
		objc_setAssociatedObject(draggable, kDragSourceKey, NULL, OBJC_ASSOCIATION_RETAIN);
	}
}

- (void)registerDropTarget:(UIView *)droppable delegate:(id<SPDropDelegate>)delegate
{
    [self unregisterDropTarget:droppable];
    
    SPDropTarget *target = [SPDropTarget new];
    target.view = droppable;
    target.delegate = delegate;
    [_dropTargets addObject:target];
    objc_setAssociatedObject(droppable, kDropTargetKey, target, OBJC_ASSOCIATION_ASSIGN);
    
    
    if(_state) {
		if([target.delegate dropTarget:target.view canAcceptDrag:_state]) {
            _state.activeDropTargets = [_state.activeDropTargets arrayByAddingObject:target];
            [self highlightDropTargets];
        }
    }
}

- (void)unregisterDropTarget:(id)droppable
{
    for(SPDropTarget *target in [_dropTargets allObjects]) {
        if(target.view == droppable || target.delegate == droppable) {
            [_dropTargets removeObject:target];
            [target.highlight removeFromSuperview];
            objc_setAssociatedObject(target.view, kDropTargetKey, nil, OBJC_ASSOCIATION_ASSIGN);
            break;
        }
    }
}

static UIImage *screenshotForView(UIView *view)
{
    CGSize sz = view.frame.size;
    
    UIGraphicsBeginImageContextWithOptions(sz, YES, UIScreen.mainScreen.scale);
    
    [view.layer renderInContext:UIGraphicsGetCurrentContext()];
    UIImage *screenShot = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return screenShot;
}

#pragma mark - Gesture recognition, network and state handling

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return _state != nil;
}

- (void)dragGesture:(UILongPressGestureRecognizer*)grec
{
	
    if(grec.state == UIGestureRecognizerStateBegan) {
        UIView *initiator = grec.view;
        [self startDraggingWithInitiator:initiator event:grec];
    } else if(grec.state == UIGestureRecognizerStateChanged) {
        [self continueDraggingFromGesture:[grec locationInView:_draggingContainer]];
    } else if(grec.state == UIGestureRecognizerStateEnded) {
        [self concludeDraggingFromGesture];
    } else if(grec.state == UIGestureRecognizerStateCancelled) {
        [self cancelDragging];
    }
}

#pragma mark Application frame and coordinate system util

- (CGPoint)convertLocalPointToScreenSpace:(CGPoint)localPoint
{
	return [self.draggingContainer convertPoint:localPoint toCoordinateSpace:self.draggingContainer.screen.fixedCoordinateSpace];
}

- (CGPoint)convertScreenPointToLocalSpace:(CGPoint)remotePoint
{
	return [self.draggingContainer convertPoint:remotePoint fromCoordinateSpace:self.draggingContainer.screen.fixedCoordinateSpace];
}

#pragma mark Start dragging

- (void)startDraggingWithInitiator:(UIView*)initiator event:(UIGestureRecognizer*)grec
{
	if(_state != nil) {
		[self _cleanUpDragging];
	}
	
	SPDragSource *source = objc_getAssociatedObject(initiator, kDragSourceKey);
    id<SPDragDelegate> delegate = source.delegate;

    SPDraggingState *state = [SPDraggingState new];
    state.dragInitiator = initiator;
	state.operationIdentifier = [[NSUUID UUID] UUIDString];
	
	// Setup pasteboard contents
	state.pasteboard = [UIPasteboard generalPasteboard];
	state.originalPasteboardContents = state.pasteboard.items;
	state.pasteboard.items = @[];
	[delegate beginDragOperationFromView:initiator ontoPasteboard:state.pasteboard];
	if(state.pasteboard.items.count == 0) {
		NSLog(@"%@: Cancelling drag operation because no item was put on pasteboard", [self class]);
		state.pasteboard.items = state.originalPasteboardContents;
		return;
	}
	
    // Dragging displayables
    NSString *title = nil, *subtitle = nil;
    state.proxyIcon = [self.proxyIconDelegate dragController:self iconViewForDrag:state getTitle:&title getSubtitle:&subtitle];
	state.title = title;
	state.subtitle = subtitle;
	if(!state.proxyIcon)
		state.screenshot = screenshotForView(initiator);
	
	// Put displayables on pasteboard for transfer to other apps
	NSMutableDictionary *meta = [@{
		@"uuid": state.operationIdentifier,
	} mutableCopy];
	if(state.proxyIcon) meta[@"proxyIcon"] = UIImagePNGRepresentation(state.proxyIcon);
	if(state.screenshot) meta[@"screenshot"] = UIImagePNGRepresentation(state.screenshot);
	NSData *metadata = [NSKeyedArchiver archivedDataWithRootObject:meta];
	[state.pasteboard addItems:@[@{kDragMetadataKey: metadata}]];
	
	// Figure out anchor point and locations
	CGPoint hitInView = [grec locationInView:initiator];
	CGPoint anchorPoint = CGPointMake(
		hitInView.x/initiator.frame.size.width,
		hitInView.y/initiator.frame.size.height
	);
	
	CGPoint initialLocation = [grec locationInView:_draggingContainer];
	CGPoint initialScreenLocation = [self convertLocalPointToScreenSpace:initialLocation];
	state.initialPositionInScreenSpace = initialScreenLocation;
	
	// Setup UI
	[self startDraggingWithState:state anchorPoint:anchorPoint initialPosition:initialLocation];
	
	// And tell other apps
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"startDragging",
		@"state": @{
			@"title": title ?: @"",
			@"subtitle": subtitle ?: @"",
			@"pasteboardName": state.pasteboard.name,
			@"uuid": state.operationIdentifier,
		},
		@"anchorPoint": NSStringFromCGPoint(anchorPoint),
		@"initialPosition": NSStringFromCGPoint(initialScreenLocation)
	}];
}

- (void)command:(CerfingConnection*)connection startDragging:(NSDictionary*)msg
{
	// Setup state that comes from Cerfing
	NSDictionary *stateD = msg[@"state"];
    SPDraggingState *state = [SPDraggingState new];

	state.title = [stateD[@"title"] length] > 0 ? stateD[@"title"] : nil;
	state.subtitle = [stateD[@"subtitle"] length] > 0 ? stateD[@"subtitle"] : nil;
	state.pasteboard = [UIPasteboard pasteboardWithName:stateD[@"pasteboardName"] create:NO];
	state.operationIdentifier = stateD[@"uuid"];
	
	
	CGPoint anchorPoint = CGPointFromString(msg[@"anchorPoint"]);
	CGPoint initialPosition = CGPointFromString(msg[@"initialPosition"]);
	state.initialPositionInScreenSpace = initialPosition;
	
	CGPoint initialLocalPosition = [self convertScreenPointToLocalSpace:initialPosition];
	
	// Setup state that comes from Pasteboard
	NSData *metadata = [[state.pasteboard dataForPasteboardType:kDragMetadataKey inItemSet:NULL] firstObject];
	NSDictionary *meta = [NSKeyedUnarchiver unarchiveObjectWithData:metadata]; // TODO: Use secure coding
	if([meta[@"uuid"] isEqual:state.operationIdentifier]) {
		state.proxyIcon = [UIImage imageWithData:meta[@"proxyIcon"]];
		state.screenshot = [UIImage imageWithData:meta[@"screenshot"]];
	} else {
		NSLog(@"Warning: Missing drag'n'drop metadata over auxilliary pasteboard");
	}
	
	// aaand go!
	[self startDraggingWithState:state anchorPoint:anchorPoint initialPosition:initialLocalPosition];
}

- (void)startDraggingWithState:(SPDraggingState*)state anchorPoint:(CGPoint)anchorPoint initialPosition:(CGPoint)position
{
	self.state = state;
	
    if(state.proxyIcon || !state.screenshot) {
        state.proxyView = [[SPDragProxyView alloc] initWithIcon:state.proxyIcon title:state.title subtitle:state.subtitle];
    } else {
        state.proxyView = [[UIImageView alloc] initWithImage:state.proxyIcon];
    }
	

    state.proxyView.alpha = 0;
    [UIView animateWithDuration:.2 animations:^{
        state.proxyView.alpha = state.proxyIcon ? 1 : 0.5;
    }];
    [_draggingContainer addSubview:state.proxyView];
    
    if(!state.proxyIcon) { // it's just a screenshot, position it correctly
        state.proxyView.layer.anchorPoint = anchorPoint;
    }
    state.proxyView.layer.position = position;
    
    _state.activeDropTargets = [_dropTargets.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(SPDropTarget *target, NSDictionary *bindings) {
		return [target.delegate dropTarget:target.view canAcceptDrag:state];
	}]];
	
    [self highlightDropTargets];
}

#pragma mark Continue dragging

- (void)continueDraggingFromGesture:(CGPoint)position
{
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"continueDragging",
		@"position": NSStringFromCGPoint([self convertLocalPointToScreenSpace:position]),
	}];
	[self _continueDragging:position];
}

- (void)command:(CerfingConnection*)connection continueDragging:(NSDictionary*)msg
{
	CGPoint position = CGPointFromString(msg[@"position"]);
	CGPoint localPosition = [self convertScreenPointToLocalSpace:position];
	
	[self _continueDragging:localPosition];
}

- (void)_continueDragging:(CGPoint)position
{
    _state.proxyView.layer.position = position;
    
    SPDropTarget *previousTarget = _state.hoveringTarget;
    _state.hoveringTarget = [self targetUnderFinger];
    if(_state.hoveringTarget != previousTarget) {
    
        previousTarget.highlight.hovering = NO;
        _state.hoveringTarget.highlight.hovering = YES;
        
        if(_state.springloadingTimer) {
            [_state.springloadingTimer invalidate]; _state.springloadingTimer = nil;
        }
        
        if ([_state.hoveringTarget canSpringload:_state]) {
            _state.springloadingTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringloadDelay target:self selector:@selector(springload) userInfo:nil repeats:NO];
        }
    }
    
    if([_state.hoveringTarget.delegate respondsToSelector:@selector(dropTarget:updateHighlight:forDrag:atPoint:)]) {
        CGPoint locationInWindow = _state.proxyView.layer.position;
        CGPoint p = [_state.hoveringTarget.view convertPoint:locationInWindow fromView:_state.proxyView.superview];

        [_state.hoveringTarget.delegate dropTarget:_state.hoveringTarget.view updateHighlight:_state.hoveringTarget.highlight forDrag:_state atPoint:p];
    }
}

#pragma mark Conclude dragging

// Finger has been lifted, conclude the dragging operation!
- (void)concludeDraggingFromGesture
{
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"concludeDragging",
	}];
	[self _concludeDragging];
}
- (void)command:(CerfingConnection*)conn concludeDragging:(NSDictionary*)dict
{
	[self _concludeDragging];
}
// This will either end up calling 'cancelDragging' or 'cleanUpDragging'
- (void)_concludeDragging
{
	// Another app will take care of the proper drag conclusion because the touch was in that app?
	if(![self _draggingIsWithinMyApp]) {
		// finishDragging will be called from either remote calling 'cancelDragging' or
		// 'remoteSideConcludedDragging'.
		DNDLog(@"Drag concluded at %@, which is outside of my bounds %@", NSStringFromCGPoint([self convertLocalPointToScreenSpace:_state.proxyView.layer.position]), NSStringFromCGRect([self localFrameInScreenSpace]));
		return;
	}
	DNDLog(@"Concluding dragging!");
	
    SPDropTarget *targetThatWasHit = [self targetUnderFinger];
    
    if (![_state.activeDropTargets containsObject:targetThatWasHit] || ![targetThatWasHit canDrop:_state]) {
        [self cancelDragging];
        return;
    }
    
    CGPoint locationInWindow = _state.proxyView.layer.position;
    CGPoint p = [targetThatWasHit.view convertPoint:locationInWindow fromView:_state.proxyView.superview];
    [targetThatWasHit.delegate dropTarget:targetThatWasHit.view acceptDrag:_state atPoint:p];
    
    __block int count = 0;
    dispatch_block_t completion = ^{
        if(++count == 2)
            [self cleanUpDragging];
    };
    [targetThatWasHit.highlight animateAcceptedDropWithCompletion:completion];
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _state.proxyView.transform = CGAffineTransformMakeScale(0, 0);
        _state.proxyView.alpha = 0;
    } completion:(id)completion];
}

#pragma mark Cancel dragging

// Animate indicating that the drag failed, across all apps.
- (void)cancelDragging
{
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"cancelDragging",
	}];
	[self _cancelDragging];
}
- (void)command:(CerfingConnection*)connection cancelDragging:(NSDictionary*)dict
{
	[self _cancelDragging];
}
- (void)_cancelDragging
{
    [self stopHighlightingDropTargets];
    [UIView animateWithDuration:.5 animations:^{
        _state.proxyView.layer.position = [self convertScreenPointToLocalSpace:_state.initialPositionInScreenSpace];
    } completion:^(BOOL finished) {
        [self _cleanUpDragging];
    }];
}

#pragma mark Clean up dragging

// Okay, this app (or another app that handled the touch lifting) has finished handling
// the drag operation. We can now clean up.
- (void)cleanUpDragging
{
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"completeDragging",
	}];
	[self _cleanUpDragging];
}

- (void)command:(CerfingConnection*)connection completeDragging:(NSDictionary*)dict
{
	[self _cleanUpDragging];
}

// Tear down and reset all dragging related state
- (void)_cleanUpDragging
{
    [_state.springloadingTimer invalidate];
    [_state.proxyView removeFromSuperview];
    [self stopHighlightingDropTargets];
	
	if(self.state.originalPasteboardContents)
		self.state.pasteboard.items = self.state.originalPasteboardContents;
	
    self.state = nil;
}



#pragma mark - Drawing

- (void)highlightDropTargets
{
    for(SPDropTarget *target in _state.activeDropTargets) {
        if(target.highlight)
            continue;
        
        // Make a drop target highlight
        target.highlight = [[SPDropHighlightView alloc] initWithFrame:target.view.bounds];
        target.highlight.springloadable = [target canSpringload:_state];
        target.highlight.droppable = [target canDrop:_state];

        target.highlight.alpha = 0;
        [target.view addSubview:target.highlight];
        [UIView animateWithDuration:.2 animations:^{
            target.highlight.alpha = 1;
        }];
    }
}

- (void)stopHighlightingDropTargets
{
    for(SPDropTarget *target in _state.activeDropTargets) {
        UIView *highlight = target.highlight;
        target.highlight = nil;
        [UIView animateWithDuration:.2 animations:^{
            highlight.alpha = 0;
        } completion:^(BOOL finished) {
            [highlight removeFromSuperview];
        }];
    }
}

#pragma mark - Etc

- (void)springload
{
    SPDropTarget *springloadingTarget = _state.hoveringTarget;
    
    CGPoint locationInWindow = _state.proxyView.layer.position;
    CGPoint p = [springloadingTarget.view convertPoint:locationInWindow fromView:_state.proxyView.superview];
    
    [springloadingTarget.highlight animateSpringloadWithCompletion:^{
        [springloadingTarget.delegate dropTarget:springloadingTarget.view springload:_state atPoint:p];
        
        _state.springloadingTimer = nil;
    }];
}

- (SPDropTarget*)targetUnderFinger
{
	for(UIWindow *window in [UIApplication sharedApplication].windows) {
		CGPoint locationInDragContainer = _state.proxyView.layer.position;
		CGPoint locationInWindow = [window convertPoint:locationInDragContainer fromWindow:_state.proxyView.window];
		
		UIView *view = [window hitTest:locationInWindow withEvent:nil];
		SPDropTarget *target = nil;
		do {
			target = objc_getAssociatedObject(view, kDropTargetKey);
			if (target)
				break;
			view = [view superview];
		} while(view && view != _draggingContainer);

		return target;
	}
	return nil;
}

- (CGRect)localFrameInScreenSpace
{
	return [self.draggingContainer convertRect:self.draggingContainer.bounds toCoordinateSpace:self.draggingContainer.screen.fixedCoordinateSpace];
}

- (BOOL)_draggingIsWithinMyApp
{
	CGPoint locationInDragContainer = _state.proxyView.layer.position;
	CGPoint locationInScreenSpace = [self convertLocalPointToScreenSpace:locationInDragContainer];

	BOOL isWithinApp = CGRectContainsPoint([self localFrameInScreenSpace], locationInScreenSpace);
	return isWithinApp;
}

@end

@implementation SPDraggingState
@end

@implementation SPDragSource
@end

@implementation SPDropTarget
- (BOOL)canSpringload:(id<SPDraggingInfo>)drag
{
    BOOL supportsSpringloading = [self.delegate respondsToSelector:@selector(dropTarget:springload:atPoint:)];
    BOOL supportsShould = [self.delegate respondsToSelector:@selector(dropTarget:shouldSpringload:)];
    BOOL shouldStartSpringloading = supportsSpringloading && (!supportsShould || [self.delegate dropTarget:self.view shouldSpringload:drag]);
    return shouldStartSpringloading;
}
- (BOOL)canDrop:(id<SPDraggingInfo>)drag
{
    BOOL supportsShouldDrop = [self.delegate respondsToSelector:@selector(dropTarget:shouldAcceptDrag:)];
    BOOL supportsDrop = [self.delegate respondsToSelector:@selector(dropTarget:acceptDrag:atPoint:)];
    BOOL shouldDrop = supportsDrop && (!supportsShouldDrop || [self.delegate dropTarget:self.view shouldAcceptDrag:drag]);
    return shouldDrop;
}
@end