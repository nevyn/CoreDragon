#import "DragonDropHighlightView.h"
#import <QuartzCore/QuartzCore.h>

@implementation DragonDropHighlightView

- (id)initWithFrame:(CGRect)frame
{
    if(!(self = [super initWithFrame:frame]))
        return nil;
    
    self.layer.borderWidth = 2.;
    self.layer.cornerRadius = 6;
    
    self.userInteractionEnabled = NO;
    
    return self;
}

- (void)setDroppable:(BOOL)droppable
{
	_droppable = droppable;
	[self restyle];
}

- (void)setSpringloadable:(BOOL)springloadable
{
	_springloadable = springloadable;
	[self restyle];
}

- (void)setHovering:(BOOL)hovering
{
	_hovering = hovering;
	[self restyle];
}

- (void)restyle
{
    [UIView animateWithDuration:.2 animations:^{
        if(!self.hovering) {
            if(!self.springloadable) {
                self.backgroundColor = [UIColor clearColor];
                self.layer.borderColor = [UIColor clearColor].CGColor;
            } else {
                self.backgroundColor = [UIColor colorWithRed:0.441 green:0.442 blue:1.000 alpha:0.110];
                self.layer.borderColor = [UIColor clearColor].CGColor;
            }
        } else { // is hovering
            if(!self.springloadable || self.droppable) {
                self.backgroundColor = [UIColor colorWithRed:0.351 green:0.416 blue:1.000 alpha:0.650];
                self.layer.borderColor = [UIColor colorWithRed:0.243 green:0.222 blue:1.000 alpha:0.920].CGColor;
            } else {
                self.layer.borderColor = [UIColor colorWithRed:0.562 green:0.615 blue:0.890 alpha:0.650].CGColor;
                // Marching ants here
            }
        }
    }];
}

- (void)_blink:(dispatch_block_t)completion
{
    UIColor *oldBg = self.backgroundColor;
    [UIView animateWithDuration:.1 animations:^{
        self.backgroundColor = [UIColor clearColor];
    } completion:^(BOOL finished) {
        [UIView animateWithDuration:.1 animations:^{
            self.backgroundColor = oldBg;
        } completion:(id)completion];
    }];
}

- (void)animateSpringloadWithCompletion:(dispatch_block_t)completion
{
    [self _blink:^{
        [self _blink:completion];
    }];
}

- (void)animateAcceptedDropWithCompletion:(dispatch_block_t)completion
{
    if(completion)
        completion();
}
@end
