//
//  GLKAnimationManager.m
//  Particle
//
//  Created by welling on 2021/4/11.
//

#import "GLKAnimationManager.h"
#import "ParticleView.h"

@interface GLKAnimationManager () {
    CADisplayLink *_displayLink; //定时器
    ParticleView *_glkView;     //粒子view
    NSTimeInterval _timeSinceFirstResume; //第一次发送粒子的时间
    NSTimeInterval _lastTime; //上次发送粒子的时间
    NSUInteger _currentEmissionCount; //当前发射次数
}
    

@end
@implementation GLKAnimationManager

- (instancetype)initWithFrame:(CGRect)frame {
    if (self = [super init]) {
        _glkView = [[ParticleView alloc] initWithFrame:frame];
        _displayLink = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
        [_displayLink addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
        [_displayLink setPaused:YES];
        [self setupParams];
    }
    return self;
}

/// 初始化一些参数
- (void)setupParams {
    _totalEmissionCount = 0;
    _emissionGap = 1;
    _oneEmissionNum = 5;
    
}


- (UIView *)view {
    return _glkView;
}

/// 开始动画
- (void)startAnimation {
    if (_imageData) {
        [_glkView setImageData:_imageData];
    }else {
        [_glkView setImagePath:_imagePath];
    }
    _timeSinceFirstResume = [[NSDate date] timeIntervalSince1970];
    _lastTime = 0;
    _displayLink.paused = NO;
    [_glkView prepareEve];
}


- (void)step {
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] - _timeSinceFirstResume;
    _glkView.elapsedSeconds = currentTime;
    if (_totalEmissionCount > 0 && _currentEmissionCount >= _totalEmissionCount) { //已经达到发射次数
        [_glkView setNeedsDisplay];
        return;
    }
    if (currentTime - _lastTime > _emissionGap) {//达到间隔时间发射
        _lastTime = currentTime;
        _currentEmissionCount++;
        [self createParticle];
    }else {
        [_glkView setNeedsDisplay];
    }
    
    
}

- (void)createParticle {
    for(int i = 0; i < _oneEmissionNum; i++) {
        float x = 0.3;//0 + (float)random() / (float)RAND_MAX;
        float y = -1 + 2 * (float)random() / (float)RAND_MAX;
        float z = -0.5;//-1 + 1 * (float)random() / (float)RAND_MAX;
        CGFloat radius = y + 1.3;
        [_glkView
         addParticleAtPosition:GLKVector3Make(x, y, z)
         velocity:GLKVector3Make(0,0,0)
         force:GLKVector3Make(0.0f, 0.0f, 0.0f)
         size:50
         fadeDurationSeconds:10 radius:radius angularVelocity:3.14-y+1];
    }
}

- (void)dealloc {
    _displayLink.paused = YES;
    [_displayLink invalidate];
}
@end
