//
//  ParticleView.h
//  Particle
//
//  Created by welling on 2021/3/30.
//

#import <UIKit/UIKit.h>
#import <GLKit/GLKit.h>
#import <GLKit/GLKView.h>
NS_ASSUME_NONNULL_BEGIN

@interface ParticleView : GLKView

@property (nonatomic,assign) GLfloat elapsedSeconds;//耗时

- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

- (UIView *)view;

- (instancetype)initWithFrame:(CGRect)frame;

- (BOOL)prepareEve;

@end

NS_ASSUME_NONNULL_END
