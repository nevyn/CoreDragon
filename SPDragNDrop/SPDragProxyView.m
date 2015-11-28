//
//  SPDraggingProxyView.m
//  DragNDropFeature
//
//  Created by Joachim Bengtsson on 2012-12-14.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import "SPDragProxyView.h"
#import <QuartzCore/QuartzCore.h>

@interface SPDragProxyView ()
{
    UIView *_iconContainer;
    UIView *_icon;
    UIImageView *_actionIcon;
    
    UIView *_titleContainer;
    UILabel *_titleLabel;
}

@end

@implementation SPDragProxyView
- (id)initWithIcon:(UIImage*)icon title:(NSString*)title subtitle:(NSString*)subtitle
{
    if(!(self = [super initWithFrame:(CGRect){.size=icon.size}]))
        return nil;
    
    UIFont *titleFont = [UIFont boldSystemFontOfSize:16];
    CGSize iconSize = CGSizeMake(80, 80);
    CGSize labelSize = [title sizeWithFont:titleFont];
    static const CGFloat iconCornerRadius = 10.;
    static const CGFloat labelCornerRadius = 5.;
    static const CGFloat margin = 12;
    static const CGFloat textContainerYMargin = 2;
    static const CGFloat textContainerXMargin = 4;
    
    _icon = [[UIImageView alloc] initWithImage:icon];
    _icon.frame = (CGRect){.size=iconSize};
    _icon.autoresizingMask = UIViewAutoresizingFlexibleWidth|UIViewAutoresizingFlexibleHeight;
    _icon.layer.cornerRadius = iconCornerRadius;
    _icon.layer.masksToBounds = YES;

    _iconContainer = [[UIView alloc] initWithFrame:(CGRect){.size=iconSize}];
    _iconContainer.layer.cornerRadius = iconCornerRadius;
    _iconContainer.layer.borderColor = [UIColor colorWithWhite:0 alpha:.4].CGColor;
    _iconContainer.layer.shadowOpacity = .5;
    _iconContainer.layer.shadowOffset = CGSizeMake(0, 3);
    [_iconContainer addSubview:_icon];
    [self addSubview:_iconContainer];
    
    _titleContainer = [[UIView alloc] initWithFrame:CGRectMake(iconSize.width + margin, iconSize.height/2. - labelSize.height/2. - textContainerYMargin, labelSize.width + textContainerXMargin*2, labelSize.height + textContainerYMargin*2)];
    _titleContainer.layer.shadowOpacity = .5;
    _titleContainer.layer.shadowOffset = CGSizeMake(0, 3);
    _titleContainer.layer.cornerRadius = labelCornerRadius;
    _titleContainer.backgroundColor = [UIColor colorWithRed:0.268 green:0.314 blue:0.792 alpha:1.000];
    
    _titleLabel = [[UILabel alloc] initWithFrame:(CGRect){.size=labelSize, .origin = {textContainerXMargin,textContainerYMargin}}];
    _titleLabel.text = title;
    _titleLabel.font = titleFont;
    _titleLabel.textColor = [UIColor colorWithRed:0.946 green:0.951 blue:0.946 alpha:1.000];
    _titleLabel.backgroundColor = [UIColor clearColor];
    [_titleContainer addSubview:_titleLabel];
    [self addSubview:_titleContainer];
    
    _actionIcon = [[UIImageView alloc] initWithImage:[UIImage imageNamed:@"dragndrop-add"]];
    _actionIcon.frame = CGRectMake(70, 10, 20, 20);
    _actionIcon.layer.shadowOpacity = .5;
    _actionIcon.layer.shadowOffset = CGSizeMake(0, 3);
    [self addSubview:_actionIcon];
    
    self.frame = CGRectMake(0, 0, CGRectGetMaxX(_titleContainer.bounds), CGRectGetMaxY(_iconContainer.bounds));
    
    self.layer.anchorPoint = CGPointMake(45./CGRectGetMaxX(self.frame), 0.8);
    
    return self;
}

@end
