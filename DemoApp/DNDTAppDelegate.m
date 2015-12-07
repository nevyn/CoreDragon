//
//  DNDTAppDelegate.m
//  DNDTest
//
//  Created by Nevyn Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTAppDelegate.h"
#import "DNDTFirstViewController.h"
#import "DNDTSecondViewController.h"
#import <CoreDragon/CoreDragon.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface DNDTAppDelegate () <SPDropDelegate>
@end

@implementation DNDTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
	self.tabBarController = (id)self.window.rootViewController;
	
	// Must be called when the app starts, or drag'n'drop won't work.
	[[DragonController sharedController] enableLongPressDraggingInWindow:self.window];
	
	// Enable spring-loading on the tab bar.
    [[DragonController sharedController] registerDropTarget:self.tabBarController.tabBar delegate:self];
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
