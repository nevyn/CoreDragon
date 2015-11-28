//
//  SPDraggingContainerView.m
//  DragNDropFeature
//
//  Created by Joachim Bengtsson on 2012-12-10.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "SPDraggingContainerWindow.h"

@implementation SPDraggingContainerWindow
- (instancetype)initWithFrame:(CGRect)frame
{
    if(!(self = [super initWithFrame:frame]))
        return nil;

    self.userInteractionEnabled = NO;
    self.backgroundColor = [UIColor clearColor];
    self.opaque = NO;
	self.windowLevel = UIWindowLevelStatusBar;
	
	self.rootViewController = [UIViewController new];
	self.rootViewController.view.backgroundColor = [UIColor clearColor];//[UIColor colorWithHue:0.4 saturation:1 brightness:1 alpha:0.2];

    return self;
}
@end
