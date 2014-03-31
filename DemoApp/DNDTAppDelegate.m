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

@interface DNDTAppDelegate () <SPDropDelegate, SPDragProxyIconDelegate>
@end

@implementation DNDTAppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions
{
    self.window = [[UIWindow alloc] initWithFrame:[[UIScreen mainScreen] bounds]];
    
    self.tabBarController = [[UITabBarController alloc] init];
    self.tabBarController.viewControllers = @[[DNDTFirstViewController new], [DNDTSecondViewController new]];
    
    self.window.rootViewController = self.tabBarController;
    [self.window makeKeyAndVisible];
    [[SPDragNDropController sharedController] createDraggingContainerInWindow:self.window];
    
    [[SPDragNDropController sharedController] registerDropTarget:self.tabBarController.tabBar delegate:self];
    [[SPDragNDropController sharedController] setProxyIconDelegate:self];
    return YES;
}

- (BOOL)droppable:(UIView*)droppable canAcceptModelObject:(id)modelObject;
{
    return YES;
}

- (BOOL)droppable:(UIView*)droppable shouldSpringload:(id)modelObject
{
    return YES;
}
- (void)droppable:(UIView*)droppable springload:(id)modelObject atPoint:(CGPoint)p
{
    [self.tabBarController setSelectedIndex:abs(self.tabBarController.selectedIndex - 1)];
}

- (UIView*)dragController:(SPDragNDropController*)dragndrop iconViewForModelObject:(id)modelObject getTitle:(NSString**)title getSubtitle:(NSString**)subtitle
{
    *title = modelObject;
    return [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"testimage"]];
}


@end
