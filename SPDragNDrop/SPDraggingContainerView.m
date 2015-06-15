//
//  SPDraggingContainerView.m
//  DragNDropFeature
//
//  Created by Joachim Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "SPDraggingContainerView.h"

@implementation SPDraggingContainerView
- (id)init
{
    if(!(self = [super initWithFrame:CGRectZero]))
        return nil;

    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
	self.layer.zPosition = 1000;
    
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(applicationDidChangeStatusBarOrientationNotification:) 
                                                 name:UIApplicationDidChangeStatusBarOrientationNotification
                                               object:nil];
    return self;
}

- (void)installOnWindow:(UIWindow*)window
{
    [window addSubview:self];
    
    /*__weak __typeof(self) weakSelf = self;
    SPAddDependency(self, @"window", @[SPD_PAIR(window, frame), SPS_KEYPATH(window, subviews)], ^{
        weakSelf.frame = window.frame;
        [window bringSubviewToFront:weakSelf];
    });*/
	// FIXME
	// TODO: Gonna make a secondary UIWindow with a rootViewController that takes
	// care of transforms etc. Should remove need for DraggingContainer.
}

- (void)dealloc
{
    [[NSNotificationCenter defaultCenter] removeObserver:self];
}

- (void)applicationDidChangeStatusBarOrientationNotification:(NSNotification*)notification;
{
    CGFloat radians = 0.f;
    switch ([[UIApplication sharedApplication] statusBarOrientation])
    {
        case UIInterfaceOrientationPortrait:
        default:
            break;
        case UIInterfaceOrientationPortraitUpsideDown:
            radians = M_PI;
            break;
        case UIInterfaceOrientationLandscapeLeft:
            radians = M_PI+M_PI_2;
            break;
        case UIInterfaceOrientationLandscapeRight:
            radians = M_PI_2;
            break;
    }
    [UIView animateWithDuration:[[UIApplication sharedApplication] statusBarOrientationAnimationDuration]
                     animations:^{
                         [self setTransform:CGAffineTransformMakeRotation(radians)];
                     }];
}

@end
