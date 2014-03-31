//
//  DNDTFirstViewController.m
//  DNDTest
//
//  Created by Joachim Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "DNDTFirstViewController.h"
#import <SPDragNDrop/SPDragNDrop.h>

@interface DNDTFirstViewController () <SPDragDelegate, SPDropDelegate>
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
    
    [[SPDragNDropController sharedController] registerDragSource:label1 delegate:self];
    [[SPDragNDropController sharedController] registerDropTarget:label2 delegate:self];
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
