//
//  ViewController.m
//  Particle
//
//  Created by welling on 2021/3/30.
//

#import "ViewController.h"
#import "GLKAnimationManager.h"

@interface ViewController () {
    GLKAnimationManager *_animationManager;
}

@end

@implementation ViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    _animationManager = [[GLKAnimationManager alloc] initWithFrame:self.view.bounds];
    NSString *path = [[NSBundle bundleForClass:[self class]]
                      pathForResource:@"bubble" ofType:@"png"];
    NSData *imageData = [NSData dataWithContentsOfFile:path];
    _animationManager.imageData = imageData;
    _animationManager.oneEmissionNum = 20;
    _animationManager.totalEmissionCount = 0;
    _animationManager.emissionGap = 0.8;
    [self.view addSubview:_animationManager.view];
    [_animationManager startAnimation];

      
}



@end
