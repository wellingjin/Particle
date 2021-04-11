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

@property (nonatomic, assign) GLfloat elapsedSeconds;//从粒子发射到现在过去的时间


/// 添加一个粒子
/// @param aPosition 发射位置，刚开始出现的位置
/// @param lVelocity 发射初速度
/// @param aForce 发射力度
/// @param aSize 粒子大小
/// @param aDuration 粒子持续的时间
/// @param radius 运动半径
/// @param aVelocity 运动角速度
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)lVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
          fadeDurationSeconds:(NSTimeInterval)aDuration
                       radius:(CGFloat)radius
              angularVelocity:(CGFloat)aVelocity;

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
