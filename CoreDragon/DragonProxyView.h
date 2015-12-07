//
//  SPDraggingProxyView.h
//  DragNDropFeature
//
//  Created by Nevyn Bengtsson on 2012-12-14.
//  Copyright (c) 2012 Spotify. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface DragonProxyView : UIView
- (instancetype)initWithIcon:(UIImage*)icon title:(NSString*)title subtitle:(NSString*)subtitle;
@end

@interface DragonScreenshotProxyView : UIImageView
- (instancetype)initWithScreenshot:(UIImage *)screenshot;
@end
