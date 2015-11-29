//
//  DNDTAppDelegate.m
//  DNDTest
//
//  Created by Joachim Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTAppDelegate.h"
#import "DNDTFirstViewController.h"
#import "DNDTSecondViewController.h"
#import <SPDragNDrop/SPDragNDrop.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface DNDTAppDelegate () <SPDropDelegate>
@end

@implementation DNDTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.tabBarController = (id)self.window.rootViewController;
    
    [[SPDragNDropController sharedController] registerDropTarget:self.tabBarController.tabBar delegate:self];
    return YES;
}
- (BOOL)dropTarget:(UIView *)droppable canAcceptDrag:(id<SPDraggingInfo>)drag
{
    return YES;
}

- (BOOL)dropTarget:(UIView *)droppable shouldSpringload:(id<SPDraggingInfo>)drag
{
    return YES;
}
- (void)dropTarget:(UIView *)droppable springload:(id<SPDraggingInfo>)drag atPoint:(CGPoint)p
{
    [self.tabBarController setSelectedIndex:(self.tabBarController.selectedIndex + 1) % 2];
}

@end
