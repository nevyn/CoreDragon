//
//  DNDTSecondViewController.m
//  DNDTest
//
//  Created by Joachim Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTSecondViewController.h"
#import <SPDragNDrop/SPDragnDrop.h>

@interface DNDTSecondViewController () <SPDragDelegate, SPDropDelegate>
{
    IBOutlet UIView *label1;
    IBOutlet UIView *label2;
}

@end


@implementation DNDTSecondViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"Second", @"Second");
        self.tabBarItem.image = [UIImage imageNamed:@"second"];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[SPDragNDropController sharedController] registerDragSource:label1 delegate:self];
    [[SPDragNDropController sharedController] registerDropTarget:label2 delegate:self];
}

- (void)viewDidAppear:(BOOL)animated
{
	[super viewDidAppear:animated];
	UIWindow *w = [[UIApplication sharedApplication] keyWindow];
	NSLog(@"Main screen bounds %@", NSStringFromCGRect([[UIScreen mainScreen] bounds]));
	NSLog(@"Main cspace bounds %@", NSStringFromCGRect([[[UIScreen mainScreen] coordinateSpace] bounds]));
	NSLog(@"Main native cspace bounds %@", NSStringFromCGRect([[[UIScreen mainScreen] fixedCoordinateSpace] bounds]));
	NSLog(@"Main window bounds %@", NSStringFromCGRect([w bounds]));
	NSLog(@"Main window bounds %@", NSStringFromCGPoint([w convertPoint:CGPointZero toWindow:nil]));
	NSLog(@"Status bar frame %@", NSStringFromCGRect([[UIApplication sharedApplication] statusBarFrame]));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (id)modelObjectForDraggable:(UIView*)draggable;
{
    return [(UILabel*)draggable text];
}

- (BOOL)droppable:(UIView*)droppable canAcceptModelObject:(id)modelObject
{
    return [modelObject isKindOfClass:[NSString class]];
}

- (void)droppable:(UIView*)droppable acceptDrop:(id)modelObject atPoint:(CGPoint)p;
{
    [(UITextView*)droppable setText:modelObject];
}

@end
