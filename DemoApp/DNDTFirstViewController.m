//
//  DNDTFirstViewController.m
//  DNDTest
//
//  Created by Nevyn Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTFirstViewController.h"
#import <CoreDragon/CoreDragon.h>
#import <MobileCoreServices/UTCoreTypes.h>

@interface DNDTFirstViewController () <DragonDelegate, DragonDropDelegate>
{
    IBOutlet UIView *label1;
    IBOutlet UIView *label2;
}

@end

@implementation DNDTFirstViewController

- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil
{
    self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil];
    if (self) {
        self.title = NSLocalizedString(@"First", @"First");
        self.tabBarItem.image = [UIImage imageNamed:@"first"];
    }
    return self;
}
							
- (void)viewDidLoad
{
    [super viewDidLoad];
    
    [[DragonController sharedController] registerDragSource:label1 delegate:self];
    [[DragonController sharedController] registerDropTarget:label2 delegate:self];
}

- (void)didReceiveMemoryWarning
{
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)beginDragOperation:(id<DragonInfo>)drag fromView:(UIView *)draggable
{
	NSString *text = [(UILabel*)draggable text];
    drag.title = text;
    drag.draggingIcon = [UIImage imageNamed:@"testimage"];

	[drag.pasteboard setValue:text forPasteboardType:(NSString*)kUTTypePlainText];
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
