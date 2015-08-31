#import "SPDragNDropController.h"
#import <QuartzCore/QuartzCore.h>
#import <objc/runtime.h>
#import "SPDropHighlightView.h"
#import "SPDraggingContainerView.h"
#import "SPDragProxyView.h"
#import <CerfingMeshPipeTransport/CerfingMeshPipe.h>

@class SPDropTarget;

static const void *kDragSourceDelegateKey = &kDragSourceDelegateKey;
static const void *kDropTargetKey = &kDropTargetKey;
static const NSTimeInterval kSpringloadDelay = 1.3;

@interface SPDraggingState : NSObject
// Initial, transferrable state
@property(nonatomic,retain) UIImage *screenshot;
@property(nonatomic,copy) NSString *title;
@property(nonatomic,copy) NSString *subtitle;
@property(nonatomic,retain) UIView *proxyIcon;
@property(nonatomic,retain) id modelObject;

// During-drag state
@property(nonatomic,retain) UIView *dragInitiator; // the thing that was long-pressed
@property(nonatomic,retain) UIView *proxyView; // thing under finger
@property(nonatomic,retain) NSArray *activeDropTargets;
@property(nonatomic,retain) NSTimer *springloadingTimer;
@property(nonatomic,assign) SPDropTarget *hoveringTarget;
- (id<SPDragDelegate>)dragDelegate;
- (id)modelObject;
@end

@interface SPDropTarget : NSObject
@property(nonatomic,retain) UIView *view;
@property(nonatomic,retain) id<SPDropDelegate> delegate;
@property(nonatomic,retain) SPDropHighlightView *highlight;
- (BOOL)canSpringload:(id)modelObject;
- (BOOL)canDrop:(id)modelObject;
@end

@interface SPDragNDropController () <UIGestureRecognizerDelegate, CerfingConnectionDelegate>
{
    NSMutableSet *_dropTargets;
	CerfingMeshPipe *_cerfing;
}
@property(nonatomic,retain) SPDraggingState *state;
@property(nonatomic,retain) UILongPressGestureRecognizer *longPressGrec;
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
    
    _dropTargets = [NSMutableSet new];
	
	NSString *appName = [[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleDisplayName"] ?:
						[[NSBundle mainBundle] objectForInfoDictionaryKey:@"CFBundleName"] ?:
						[[NSProcessInfo processInfo] processName];
	
	_cerfing = [[CerfingMeshPipe alloc] initWithBasePort:23576 count:16 peerName:appName];
	_cerfing.delegate = self;
    
    return self;
}

- (void)dealloc
{
    [self.draggingContainer removeFromSuperview];
    self.draggingContainer = nil; // also uninstalls grec
}

#pragma mark - Dragging container

- (void)setDraggingContainer:(UIView *)draggingContainer
{
	_draggingContainer = draggingContainer;
	
	[self.longPressGrec.view removeGestureRecognizer:self.longPressGrec];
	if (self.draggingContainer) {
		self.longPressGrec = [[UILongPressGestureRecognizer alloc] initWithTarget:self action:@selector(dragGesture:)];
		self.longPressGrec.delegate = self;
		[self.draggingContainer.window addGestureRecognizer:self.longPressGrec];
	}
}

- (void)createDraggingContainerInWindow:(UIWindow*)window
{
    SPDraggingContainerView *container = [[SPDraggingContainerView alloc] init];
    [container installOnWindow:window];
    self.draggingContainer = container;
}

#pragma mark - Registration

- (void)registerDragSource:(UIView *)draggable delegate:(id<SPDragDelegate>)delegate
{
    objc_setAssociatedObject(draggable, kDragSourceDelegateKey, delegate, OBJC_ASSOCIATION_ASSIGN);
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
        if([target.delegate droppable:target.view canAcceptModelObject:_state.modelObject]) {
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

- (BOOL)gestureRecognizerShouldBegin:(UIGestureRecognizer *)grec
{
    return [self sourceUnderFinger:grec] != nil;
}

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer
{
    return _state != nil;
}

- (void)dragGesture:(UILongPressGestureRecognizer*)grec
{
    if(grec.state == UIGestureRecognizerStateBegan) {
        UIView *initiator = [self sourceUnderFinger:grec];
        [self startDraggingWithInitiator:initiator event:grec];
    } else if(grec.state == UIGestureRecognizerStateChanged) {
        [self continueDraggingFromGesture:[grec locationInView:_draggingContainer]];
    } else if(grec.state == UIGestureRecognizerStateEnded) {
        [self concludeDraggingFromGesture];
    } else if(grec.state == UIGestureRecognizerStateCancelled) {
        [self cancelDragging];
    }
}

#pragma mark Start dragging

- (void)startDraggingWithInitiator:(UIView*)initiator event:(UIGestureRecognizer*)grec
{
    NSAssert(_state == nil, @"Drag operation is already started");
    id<SPDragDelegate> delegate = objc_getAssociatedObject(initiator, kDragSourceDelegateKey);
    id modelObject = [delegate modelObjectForDraggable:initiator];

    SPDraggingState *state = [SPDraggingState new];
	state.modelObject = modelObject;
    state.dragInitiator = initiator;
    
    NSString *title = nil, *subtitle = nil;
    state.proxyIcon = [self.proxyIconDelegate dragController:self iconViewForModelObject:modelObject getTitle:&title getSubtitle:&subtitle];
	state.title = title;
	state.subtitle = subtitle;
	if(!state.proxyIcon)
		state.screenshot = screenshotForView(initiator);
	
	CGPoint hitInView = [grec locationInView:initiator];
	CGPoint anchorPoint = CGPointMake(
		hitInView.x/initiator.frame.size.width,
		hitInView.y/initiator.frame.size.height
	);
	
	CGPoint initialLocation = [grec locationInView:initiator];
	
	[self startDraggingWithState:state anchorPoint:anchorPoint initialLocation:initialLocation];
	
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"startDragging",
		@"state": @{
			@"title": title ?: @"",
			@"subtitle": subtitle ?: @"",
		},
		@"anchorPoint": NSStringFromCGPoint(anchorPoint),
		@"initialLocation": NSStringFromCGPoint(initialLocation),
	}];
}

- (void)command:(CerfingConnection*)connection startDragging:(NSDictionary*)msg
{
	NSDictionary *stateD = msg[@"state"];
    SPDraggingState *state = [SPDraggingState new];

	state.title = [stateD[@"title"] length] > 0 ? stateD[@"title"] : nil;
	state.subtitle = [stateD[@"subtitle"] length] > 0 ? stateD[@"subtitle"] : nil;
	
	[self startDraggingWithState:state anchorPoint:CGPointFromString(msg[@"anchorPoint"]) initialLocation:CGPointFromString(msg[@"initialLocation"])];
}

- (void)startDraggingWithState:(SPDraggingState*)state anchorPoint:(CGPoint)anchorPoint initialLocation:(CGPoint)location
{
	self.state = state;
	
    if(state.proxyIcon || !state.screenshot) {
        state.proxyView = [[SPDragProxyView alloc] initWithIconView:state.proxyIcon title:state.title subtitle:state.subtitle];
    } else {
        state.proxyView = [[UIImageView alloc] initWithImage:state.screenshot];
    }
	

    state.proxyView.alpha = 0;
    [UIView animateWithDuration:.2 animations:^{
        state.proxyView.alpha = state.proxyIcon ? 1 : 0.5;
    }];
    [_draggingContainer addSubview:state.proxyView];
    
    if(!state.proxyIcon) { // it's just a screenshot, position it correctly
        state.proxyView.layer.anchorPoint = anchorPoint;
    }
    state.proxyView.layer.position = location;
    
    _state.activeDropTargets = [_dropTargets.allObjects filteredArrayUsingPredicate:[NSPredicate predicateWithBlock:^(SPDropTarget *target, NSDictionary *bindings) {
        return [target.delegate droppable:target.view canAcceptModelObject:state.modelObject];
	}]];
	
    [self highlightDropTargets];
}

#pragma mark Continue dragging

- (void)continueDraggingFromGesture:(CGPoint)position
{
	[_cerfing broadcastDict:@{
		kCerfingCommand: @"continueDragging",
		@"position": NSStringFromCGPoint(position),
	}];
	[self _continueDragging:position];
}

- (void)command:(CerfingConnection*)connection continueDragging:(NSDictionary*)msg
{
	[self _continueDragging:CGPointFromString(msg[@"position"])];
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
        
        if ([_state.hoveringTarget canSpringload:_state.modelObject]) {
            _state.springloadingTimer = [NSTimer scheduledTimerWithTimeInterval:kSpringloadDelay target:self selector:@selector(springload) userInfo:nil repeats:NO];
        }
    }
    
    if([_state.hoveringTarget.delegate respondsToSelector:@selector(droppable:updateHighlight:forDragOf:atPoint:)]) {
        CGPoint locationInWindow = _state.proxyView.layer.position;
        CGPoint p = [_state.hoveringTarget.view convertPoint:locationInWindow fromView:_state.proxyView.superview];

        [_state.hoveringTarget.delegate droppable:_state.hoveringTarget.view updateHighlight:_state.hoveringTarget.highlight forDragOf:_state.modelObject atPoint:p];
    }
}

#pragma mark Conclude dragging

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
- (void)_concludeDragging
{
	// Another app will take care of the proper drag conclusion?
	if(![self _draggingIsWithinMyApp]) {
		[self finishDragging];
		return;
	}
	
    SPDropTarget *targetThatWasHit = [self targetUnderFinger];
    
    if (![targetThatWasHit canDrop:_state.modelObject]) {
        [self cancelDragging];
        return;
    }
    
    CGPoint locationInWindow = _state.proxyView.layer.position;
    CGPoint p = [targetThatWasHit.view convertPoint:locationInWindow fromView:_state.proxyView.superview];
    [targetThatWasHit.delegate droppable:targetThatWasHit.view acceptDrop:_state.modelObject atPoint:p];
    
    __block int count = 0;
    dispatch_block_t completion = ^{
        if(++count == 2)
            [self finishDragging];
    };
    [targetThatWasHit.highlight animateAcceptedDropWithCompletion:completion];
    [UIView animateWithDuration:.3 delay:0 options:UIViewAnimationOptionCurveEaseIn animations:^{
        _state.proxyView.transform = CGAffineTransformMakeScale(0, 0);
        _state.proxyView.alpha = 0;
    } completion:(id)completion];
}

#pragma mark Cancel dragging

// Animate indicating that the drag failed
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
        CGPoint initiationPointInWindow = [_draggingContainer convertPoint:_state.dragInitiator.layer.position fromView:_state.dragInitiator.superview];
        _state.proxyView.layer.position = initiationPointInWindow;
    } completion:^(BOOL finished) {
        [self finishDragging];
    }];
}

#pragma mark Util - Finish dragging

// Tear down and reset all dragging related state
- (void)finishDragging
{
    [_state.springloadingTimer invalidate];
    [_state.proxyView removeFromSuperview];
    [self stopHighlightingDropTargets];
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
        target.highlight.springloadable = [target canSpringload:_state.modelObject];
        target.highlight.droppable = [target canDrop:_state.modelObject];

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
        [springloadingTarget.delegate droppable:springloadingTarget.view springload:_state.modelObject atPoint:p];
        
        _state.springloadingTimer = nil;
    }];
}

- (UIView*)sourceUnderFinger:(UIGestureRecognizer*)grec
{
    CGPoint locationInWindow = [grec locationInView:_draggingContainer.window];
    UIView *view = [_draggingContainer.window hitTest:locationInWindow withEvent:nil];
    id<SPDragDelegate> delegate = nil;
    do {
        delegate = objc_getAssociatedObject(view, kDragSourceDelegateKey);
        if (delegate)
            break;
        view = [view superview];
    } while(view && view != _draggingContainer);
    
    return delegate ? view : nil;
}

- (SPDropTarget*)targetUnderFinger
{
    CGPoint locationInWindow = _state.proxyView.layer.position;
    UIView *view = [_draggingContainer.window hitTest:locationInWindow withEvent:nil];
    SPDropTarget *target = nil;
    do {
        target = objc_getAssociatedObject(view, kDropTargetKey);
        if (target)
            break;
        view = [view superview];
    } while(view && view != _draggingContainer);

    return target;
}

- (BOOL)_draggingIsWithinMyApp
{
	#warning TODO
	return YES;
}

@end

@implementation SPDraggingState
- (id)modelObject
{
    return [self.dragDelegate modelObjectForDraggable:self.dragInitiator];
}

- (id<SPDragDelegate>)dragDelegate
{
    return objc_getAssociatedObject(self.dragInitiator, kDragSourceDelegateKey);
}
@end

@implementation SPDropTarget
- (BOOL)canSpringload:(id)modelObject
{
    BOOL supportsSpringloading = [self.delegate respondsToSelector:@selector(droppable:springload:atPoint:)];
    BOOL supportsShould = [self.delegate respondsToSelector:@selector(droppable:shouldSpringload:)];
    BOOL shouldStartSpringloading = supportsSpringloading && (!supportsShould || [self.delegate droppable:self.view shouldSpringload:modelObject]);
    return shouldStartSpringloading;
}
- (BOOL)canDrop:(id)modelObject
{
    BOOL supportsShouldDrop = [self.delegate respondsToSelector:@selector(droppable:shouldAcceptDrop:)];
    BOOL supportsDrop = [self.delegate respondsToSelector:@selector(droppable:acceptDrop:atPoint:)];
    BOOL shouldDrop = supportsDrop && (!supportsShouldDrop || [self.delegate droppable:self.view shouldAcceptDrop:modelObject]);
    return shouldDrop;
}
@end