//
//  DNDTSecondViewController.m
//  DNDTest
//
//  Created by Nevyn Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTSecondViewController.h"
#import <CoreDragon/CoreDragon.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface DNDTSecondViewController () <DragonDelegate, DragonDropDelegate>
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
    
    [[DragonController sharedController] registerDragSource:label1 delegate:self];
    [[DragonController sharedController] registerDropTarget:label2 delegate:self];
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

	NSLog(@"Converted %@", NSStringFromCGRect([w convertRect:w.bounds toCoordinateSpace:w.screen.fixedCoordinateSpace]));
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView *)draggable
{
	[drag.pasteboard setValue:[(UILabel*)draggable text] forPasteboardType:(NSString*)kUTTypePlainText];
}

- (BOOL)dropTarget:(UIView *)droppable canAcceptDrag:(id<DragonInfo>)drag
{
	return [drag.pasteboard containsPasteboardTypes:@[(NSString*)kUTTypePlainText]];
}

- (void)dropTarget:(UIView *)droppable acceptDrag:(id<DragonInfo>)drag atPoint:(CGPoint)p
{
	[(UITextView*)droppable setText:[drag.pasteboard valueForPasteboardType:(NSString*)kUTTypePlainText]];
}
@end
