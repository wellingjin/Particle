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

@property (nonatomic, assign) GLfloat elapsedSeconds;//耗时


- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration;

- (UIView *)view;

- (instancetype)initWithFrame:(CGRect)frame;

/// 准备环境
- (BOOL)prepareEve;

/// 通过data设置纹理图片
/// @param imageData 纹理图片data
- (void)setImageData:(NSData *)imageData;

/// 通过文件路径设置纹理图片
/// @param imagePath 图片路径
- (void)setImagePath:(NSString *)imagePath;

#pragma --调试信息--
@property (nonatomic, strong, readonly) NSError *error; //错误信息
@property (nonatomic, strong, readonly) NSString *compileLog; //GLSL的编译信息
@end

NS_ASSUME_NONNULL_END
