//
//  ViewController.m
//  Particle
//
//  Created by welling on 2021/3/30.
//

#import "ViewController.h"
#import "ParticleView.h"

@interface ViewController () {
    ParticleView *_glkView;
    NSTimeInterval _timeSinceFirstResume;
    NSTimeInterval _lastTime;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _glkView = [[ParticleView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:_glkView];
    [self createParticle];
    [_glkView prepareEve];
//    for (int i =0; i< 3;i++) {
////        float x = (int)random() % 10 * 0.1;
//
//    }
     _timeSinceFirstResume = [[NSDate date] timeIntervalSince1970];
     _lastTime = 0;
//    [_glkView addParticleAtPosition:GLKVector3Make(-0.1, 0, -0)
//                           velocity:GLKVector3Make(1,1,1)
//                              force:GLKVector3Make(0.0f, 0.0f, 0.0f)
//                               size:1
//                    lifeSpanSeconds:100
//                fadeDurationSeconds:100];
//    [_glkView addParticleAtPosition:GLKVector3Make(0.1, 0, -0)
//                           velocity:GLKVector3Make(1,1,1)
//                              force:GLKVector3Make(0.0f, 0.0f, 0.0f)
//                               size:1
//                    lifeSpanSeconds:100
//                fadeDurationSeconds:100];
//    [_glkView addParticleAtPosition:GLKVector3Make(0.1, 0.1, 0)
//                           velocity:GLKVector3Make(1,1,1)
//                              force:GLKVector3Make(0.0f, 0.0f, 0.0f)
//                               size:1
//                    lifeSpanSeconds:100
//                fadeDurationSeconds:100];
//    [_glkView addParticleAtPosition:GLKVector3Make(-0.1, 0.2, 0)
//                           velocity:GLKVector3Make(1,1,1)
//                              force:GLKVector3Make(0.0f, 0.0f, 0.0f)
//                               size:1
//                    lifeSpanSeconds:100
//                fadeDurationSeconds:100];
    
    //初始化使用定时器
    CADisplayLink *link = [CADisplayLink displayLinkWithTarget:self selector:@selector(step)];
    //设置时间间隔（CADisplayLink 默认每秒运行60次）该属性设置伟60代码1s
//    link.frameInterval = 60.0;
    [link addToRunLoop:[NSRunLoop mainRunLoop] forMode:NSDefaultRunLoopMode];
    //定时器暂停
//    link.paused = YES;
//    //定时器继续
//    link.paused = NO;
//    //定时器销毁
//    [link invalidate];
}
- (void)step {
    static int count = 0;
    
    
    NSTimeInterval currentTime = [[NSDate date] timeIntervalSince1970] - _timeSinceFirstResume;
    _glkView.elapsedSeconds = currentTime;
    if (currentTime - _lastTime > 1) {
        if (count > 5) {
//            [_glkView setNeedsDisplay];
//            return;
        }
        _lastTime = currentTime;
        count++;
        [self createParticle];
    }else {
        [_glkView setNeedsDisplay];
    }
    
    
}

- (void)createParticle {
    
    //重力
//    self.particleEffect.gravity = GLKVector3Make(0.0f,0, -5);
    
    //一次创建多少个粒子
    int n = 5;
    
    for(int i = 0; i < n; i++)
    {
        //X轴速度
        float randomXVelocity = -0.1f + 0.2f *(float)random() / (float)RAND_MAX;
        
        //Y轴速度
        float randomZVelocity = 0.1f + 0.2f * (float)random() / (float)RAND_MAX;
        float x = 0.5f + 1 * (float)random() / (float)RAND_MAX;
        float y = -1 + 2 * (float)random() / (float)RAND_MAX;
        float randomR = (int)random() %2==0?0.3:0.1;
        CGFloat radius = randomR;
//        _glkView.radius = radius;
        [_glkView
         addParticleAtPosition:GLKVector3Make(0.3, y, -0.1)
         velocity:GLKVector3Make(
                                 randomXVelocity,
                                 randomZVelocity,
                                 randomZVelocity)
         force:GLKVector3Make(0.0f, 0.0f, 0.0f)
         size:120
         lifeSpanSeconds:10
         fadeDurationSeconds:5];
    }
}

@end
