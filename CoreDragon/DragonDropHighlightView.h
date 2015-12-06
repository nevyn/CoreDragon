#import <UIKit/UIKit.h>

@interface DragonDropHighlightView : UIView
@property(nonatomic) BOOL droppable;
@property(nonatomic) BOOL springloadable;

@property(nonatomic) BOOL hovering;

- (void)animateSpringloadWithCompletion:(dispatch_block_t)completion;
- (void)animateAcceptedDropWithCompletion:(dispatch_block_t)completion;
@end
