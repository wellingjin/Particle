//
//  GLKAnimationManager.h
//  Particle
//
//  Created by welling on 2021/4/11.
//

#import <UIKit/UIKit.h>

NS_ASSUME_NONNULL_BEGIN

@interface GLKAnimationManager : NSObject

@property (nonatomic, assign) NSUInteger totalEmissionCount; //粒子发射次数，默认是0，无限发射
@property (nonatomic, assign) CGFloat emissionGap; //粒子发射间隔时间,单位秒，默认1s
@property (nonatomic, assign) NSUInteger oneEmissionNum; //一次发射多少颗粒子,默认5
@property (nonatomic, strong) NSData *imageData; //纹理图片数据，如果imageData和imagePath都有值，优先使用imageData
@property (nonatomic, copy) NSString *imagePath; //纹理图片路径，如果imageData和imagePath都有值，优先使用imageData

- (instancetype)initWithFrame:(CGRect)frame;
- (UIView *)view;

/// 开始动画
- (void)startAnimation;

@end

NS_ASSUME_NONNULL_END
