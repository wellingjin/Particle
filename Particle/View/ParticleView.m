//
//  ParticleView.m
//  Particle
//
//  Created by welling on 2021/3/30.
//

#import "ParticleView.h"
#import <OpenGLES/EAGL.h>
#import <OpenGLES/ES2/gl.h>
#import "VertexAttribArrayBuffer.h"
static NSErrorDomain const gNSErrorDomainOpenGL = @"NSErrorDomainOpenGL";

typedef NS_ENUM(NSInteger, ErrorCode) {
    ErrorCodeContext = 101, //EAGLContext初始化失败
    ErrorCodeCompile = 102, //编译失败
    ErrorCodeLink = 103, //链接失败
};

//GLSL程序Uniform 参数
enum {
    WLMVPMatrix,    //MVP矩阵
    WLSamplers2D,   //Samplers2D纹理
    WLElapsedSeconds,   //耗时
    WLGravity,      //重力
    WLNumUniforms   //Uniforms个数
};
//用于定义粒子属性的类型
typedef struct {
    GLKVector3 emissionPosition;    //发射位置
    GLKVector3 emissionVelocity;    //发射速度
    GLKVector3 emissionForce;   //发射重力
    GLKVector2 size;            //发射大小
    GLKVector2 emissionTimeAndLife; //发射时间和寿命[出生时间,死亡时间]
    GLKVector2 radius;  //半径
}WLParticleAttributes;

@interface ParticleView () {
    
    EAGLContext *_context; //上下文
    GLuint _program;//程序
    GLint _uniforms[WLNumUniforms];//Uniforms数组
}

//纹理
@property (strong, nonatomic, readonly) GLKEffectPropertyTexture *texture2d0;

//变换
@property (strong, nonatomic, readonly) GLKEffectPropertyTransform *propertyTransform;

//是否更新粒子数据
@property (nonatomic, assign, readwrite) BOOL particleDataWasUpdated;

//重力
@property(nonatomic,assign)GLKVector3 gravity;

//顶点属性数组缓冲区
@property (strong, nonatomic, readwrite)VertexAttribArrayBuffer  *particleAttributeBuffer;

//粒子属性数据
@property (nonatomic, strong, readonly) NSMutableData *particleAttributesData;

@end

//属性标识符,主要是确定属性的位置
typedef enum {
    WLParticleEmissionPosition = 0,//粒子发射位置
    WLParticleEmissionVelocity,//粒子发射速度
    WLParticleEmissionForce,//粒子发射重力
    WLParticleSize,//粒子发射大小
    WLParticleEmissionTimeAndLife,//粒子发射时间和寿命
    WLRadius, //半径
} WLParticleAttrib;

@implementation ParticleView

- (UIView *)view {
    return self;
}
- (instancetype)initWithFrame:(CGRect)frame {
    _context = [[EAGLContext alloc] initWithAPI:kEAGLRenderingAPIOpenGLES2];
    if (!_context) {
        self = [super init];
        _error = [NSError errorWithDomain:gNSErrorDomainOpenGL code:ErrorCodeContext userInfo:@{@"errorInfo": @"EAGLContext 创建失败"}];
        return self;
    }
    if (self = [super initWithFrame:frame context:_context]) {
        
        self.backgroundColor = UIColor.yellowColor;
        self.drawableDepthFormat = GLKViewDrawableDepthFormat24; //使用深度缓冲区
        self.drawableColorFormat = GLKViewDrawableColorFormatRGBA8888;//颜色缓存区
        [self updateContext];
        
        //坐标变换的信息用于GLKit渲染效果。GLKEffectPropertyTransform类定义的属性进行渲染时的效果提供的坐标变换。
        _propertyTransform = [[GLKEffectPropertyTransform alloc] init];
        _particleAttributesData = [NSMutableData data];
        //开启深度测试
        glEnable(GL_DEPTH_TEST);
        
        //开启混合
        glEnable(GL_BLEND);
        
        //设置混合因子
        glBlendFunc(GL_SRC_ALPHA, GL_ONE_MINUS_SRC_ALPHA);
        
        float aspect = CGRectGetWidth(frame) / CGRectGetHeight(frame);
        self.propertyTransform.projectionMatrix =
        GLKMatrix4MakePerspective(
                                  GLKMathDegreesToRadians(85.0f),
                                  aspect,
                                  0.1f,
                                  20.0f);
        self.propertyTransform.modelviewMatrix =
        GLKMatrix4MakeLookAt(
                             0.0, 0.0, 1.0,   // Eye position
                             0.0, 0.0, 0.0,   // Look-at position
                             0.0, 1.0, 0.0);  // Up direction
    }
    return self;
    
}


- (void)setImageData:(NSData *)imageData {
    NSError *error;
    GLKTextureInfo *particleTexture = [GLKTextureLoader textureWithContentsOfData:imageData options:nil error:&error];
    [self loadTextureWithInfo:particleTexture];
}

- (void)setImagePath:(NSString *)imagePath {
    NSError *error;
    GLKTextureInfo *particleTexture = [GLKTextureLoader textureWithContentsOfFile:imagePath options:nil error:&error];
    [self loadTextureWithInfo:particleTexture];
}

- (void)loadTextureWithInfo:(GLKTextureInfo *)textureInfo {
    if (!_texture2d0) {
        _texture2d0 = [[GLKEffectPropertyTexture alloc] init];
    }
    
    //是否可用
    _texture2d0.enabled = YES;
    //命名纹理对象
    /*
     等价于:
     void glGenTextures (GLsizei n, GLuint *textures);
     //在数组textures中返回n个当期未使用的值，表示纹理对象的名称
     //零作为一个保留的纹理对象名，它不会被此函数当做纹理对象名称而返回
     */
    _texture2d0.name = textureInfo.name;
    _texture2d0.target = textureInfo.target;
    
    //纹理类型 默认值是glktexturetarget2d
    _texture2d0.target = GLKTextureTarget2D;
    //纹理用于计算其输出片段颜色的模式。看到GLKTextureEnvMode。
    /*
     GLKTextureEnvModeReplace,输出颜色设置为从纹理获取的颜色。忽略输入颜色
     GLKTextureEnvModeModulate, 默认!输出颜色是通过将纹理的颜色乘以输入颜色来计算的
     GLKTextureEnvModeDecal,输出颜色是通过使用纹理的alpha组件来混合纹理颜色和输入颜色来计算的。
     */
    _texture2d0.envMode = GLKTextureEnvModeReplace;
}


- (BOOL)createProgram {
    GLuint vertShader, fragShader;
    _program = glCreateProgram();
    NSString *vPath = [[NSBundle mainBundle] pathForResource:
                          @"PointParticleShader" ofType:@"vsh"]; //顶点着色器代码文件
    NSString *fPath = [[NSBundle mainBundle] pathForResource:
                          @"PointParticleShader" ofType:@"fsh"]; //片元着色器代码文件
    if (![self compileShader:&vertShader type:GL_VERTEX_SHADER file:vPath]) {
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to compile vertex shader: %@", vPath];
        _error = [NSError errorWithDomain:gNSErrorDomainOpenGL
                                     code:ErrorCodeCompile
                                 userInfo:@{@"errorInfo": errorMsg}];
        return NO;
    }
    if (![self compileShader:&fragShader type:GL_FRAGMENT_SHADER file:fPath]) {
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to compile fragment shader: %@", fPath];
        _error = [NSError errorWithDomain:gNSErrorDomainOpenGL code:ErrorCodeCompile userInfo:@{@"errorInfo": errorMsg}];
        return NO;
    }
    
    //将vertex shader 附加到程序.
    glAttachShader(_program, vertShader);
    
    //将fragment shader 附加到程序.
    glAttachShader(_program, fragShader);
    
    //位置
    glBindAttribLocation(_program, WLParticleEmissionPosition,
                         "a_emissionPosition");
    //速度
    glBindAttribLocation(_program, WLParticleEmissionVelocity,
                         "a_emissionVelocity");
    //重力
    glBindAttribLocation(_program, WLParticleEmissionForce,
                         "a_emissionForce");
    //大小
    glBindAttribLocation(_program, WLParticleSize,
                         "a_size");
    //持续时间、渐隐时间
    glBindAttribLocation(_program, WLParticleEmissionTimeAndLife,
                         "a_emissionAndDeathTimes");
    
    glBindAttribLocation(_program, WLRadius,
                         "a_radius");
    
    // Link program 失败
    if (![self linkProgram:_program]) {
        NSString *errorMsg = [NSString stringWithFormat:@"Failed to link program: %d", _program];
        _error = [NSError errorWithDomain:gNSErrorDomainOpenGL code:ErrorCodeLink userInfo:@{@"errorInfo": errorMsg}];
        
        //link识别,删除vertex shader\fragment shader\program
        if (vertShader) {
            glDeleteShader(vertShader);
            vertShader = 0;
        }
        if (fragShader) {
            glDeleteShader(fragShader);
            fragShader = 0;
        }
        if (_program) {
            glDeleteProgram(_program);
            _program = 0;
        }
        return NO;
    }
    // 获取uniform变量的位置.
    //MVP变换矩阵
    _uniforms[WLMVPMatrix] = glGetUniformLocation(_program,"u_mvpMatrix");
    //纹理
    _uniforms[WLSamplers2D] = glGetUniformLocation(_program,"u_samplers2D");
    //重力
    _uniforms[WLGravity] = glGetUniformLocation(_program,"u_gravity");
    //持续时间、渐隐时间
    _uniforms[WLElapsedSeconds] = glGetUniformLocation(_program,"u_elapsedSeconds");
    //使用完
    // 删除 vertex and fragment shaders.
    if (vertShader) {
        glDetachShader(_program, vertShader);
        glDeleteShader(vertShader);
    }
    if (fragShader) {
        glDetachShader(_program, fragShader);
        glDeleteShader(fragShader);
    }
    return YES;
}
- (BOOL)prepareEve {
    if (_program == 0) {//0就创建
        [self createProgram];
    }
    if (_program != 0) {
        //使用program
        glUseProgram(_program);
        // 计算MVP矩阵变化
        //投影矩阵 与 模式视图矩阵 相乘结果
        GLKMatrix4 modelViewProjectionMatrix = GLKMatrix4Multiply(self.propertyTransform.projectionMatrix,self.propertyTransform.modelviewMatrix);
        //将结果矩阵,通过unifrom传递
        /*
         glUniformMatrix4fv (GLint location, GLsizei count, GLboolean transpose, const GLfloat* value)
        参数1:location,要更改的uniforms变量的位置
        参数2:cout ,更改矩阵的个数
        参数3:transpose,指是否要转置矩阵,并将它作为uniform变量的值,必须为GL_FALSE
        参数4:value ,指向count个数的元素指针.用来更新uniform变量的值.
        */

        glUniformMatrix4fv(_uniforms[WLMVPMatrix], 1, 0,modelViewProjectionMatrix.m);
        
        // 一个纹理采样均匀变量
        /*
          glUniform1f(GLint location,  GLfloat v0);
         
         location:指明要更改的uniform变量的位置
         v0:指明在指定的uniform变量中要使用的新值
         */
        glUniform1i(_uniforms[WLSamplers2D], 0);
        
        //粒子物理值
        //重力
        /*
         void glUniform3fv(GLint location,  GLsizei count,  const GLfloat *value);
         参数列表：
         location:指明要更改的uniform变量的位置
         count:指明要更改的向量个数
         value:指明一个指向count个元素的指针，用来更新指定的uniform变量。
         
         */
        glUniform3fv(_uniforms[WLGravity], 1, self.gravity.v);
        
        //耗时
        glUniform1fv(_uniforms[WLElapsedSeconds], 1, &_elapsedSeconds);
        
        //粒子数据更新
        if(self.particleDataWasUpdated) {
            //缓存区为空,且粒子数据大小>0
            if(self.particleAttributeBuffer == nil && [self.particleAttributesData length] > 0) {
                // 顶点属性没有送到GPU
                //初始化缓存区
                /*
                  1.数据大小  sizeof(WLParticleAttributes)
                  2.数据个数 (int)[self.particleAttributesData length] /
                 sizeof(WLParticleAttributes)
                  3.数据源  [self.particleAttributesData bytes]
                  4.用途 GL_DYNAMIC_DRAW
                 */
                
                //数据大小
                GLsizeiptr size = sizeof(WLParticleAttributes);
                //个数
                int count = (int)[self.particleAttributesData length] /
                sizeof(WLParticleAttributes);
                
                self.particleAttributeBuffer =
                [[VertexAttribArrayBuffer alloc]
                 initWithAttribStride:size
                 numberOfVertices:count
                 bytes:[self.particleAttributesData bytes]
                 usage:GL_DYNAMIC_DRAW];
            }else {
                //如果已经开辟空间,则接收新的数据
                /*
                 1.数据大小 sizeof(WLParticleAttributes)
                 2.数据个数  (int)[self.particleAttributesData length] /
                 sizeof(WLParticleAttributes)
                 3.数据源 [self.particleAttributesData bytes]
                 */
                
                //数据大小
                GLsizeiptr size = sizeof(WLParticleAttributes);
                //个数
                int count = (int)[self.particleAttributesData length] /
                sizeof(WLParticleAttributes);
                
                [self.particleAttributeBuffer
                 reinitWithAttribStride:size
                 numberOfVertices:count
                 bytes:[self.particleAttributesData bytes]];
            }
            
            //恢复更新状态为NO
            self.particleDataWasUpdated = NO;
        }
        
        //准备顶点数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLParticleEmissionPosition
         numberOfCoordinates:3
         attribOffset:
         offsetof(WLParticleAttributes, emissionPosition)
         shouldEnable:YES];
        
        //准备粒子发射速度数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLParticleEmissionVelocity
         numberOfCoordinates:3
         attribOffset:
         offsetof(WLParticleAttributes, emissionVelocity)
         shouldEnable:YES];
        
        //准备重力数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLParticleEmissionForce
         numberOfCoordinates:3
         attribOffset:
         offsetof(WLParticleAttributes, emissionForce)
         shouldEnable:YES];
        
        //准备粒子size数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLParticleSize
         numberOfCoordinates:2
         attribOffset:
         offsetof(WLParticleAttributes, size)
         shouldEnable:YES];
        
        //准备粒子的持续时间和渐隐时间数据
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLParticleEmissionTimeAndLife
         numberOfCoordinates:2
         attribOffset:
         offsetof(WLParticleAttributes, emissionTimeAndLife)
         shouldEnable:YES];
        
        [self.particleAttributeBuffer
         prepareToDrawWithAttrib:WLRadius
         numberOfCoordinates:2
         attribOffset:
         offsetof(WLParticleAttributes, radius)
         shouldEnable:YES];
        
        //将所有纹理绑定到各自的单位
        /*
         void glActiveTexture(GLenum texUnit);
         
         该函数选择一个纹理单元，线面的纹理函数将作用于该纹理单元上，参数为符号常量GL_TEXTUREi ，i的取值范围为0~K-1，K是OpenGL实现支持的最大纹理单元数，可以使用GL_MAX_TEXTURE_UNITS来调用函数glGetIntegerv()获取该值
         
         可以这样简单的理解为：显卡中有N个纹理单元（具体数目依赖你的显卡能力），每个纹理单元（GL_TEXTURE0、GL_TEXTURE1等）都有GL_TEXTURE_1D、GL_TEXTURE_2D等
         */
        glActiveTexture(GL_TEXTURE0);
        
        //判断纹理标记是否为空,以及纹理是否可用
        if(0 != self.texture2d0.name && self.texture2d0.enabled) {
            //绑定纹理到纹理标记上
            //参数1:纹理类型
            //参数2:纹理名称
            glBindTexture(GL_TEXTURE_2D, self.texture2d0.name);
        } else {
            //绑定一个空的
            glBindTexture(GL_TEXTURE_2D, 0);
        }
    }
    return YES;
}
//获取粒子的属性值
- (WLParticleAttributes)particleAtIndex:(NSUInteger)anIndex
{
    
    //bytes:指向接收者内容的指针
    //获取粒子属性结构体内容
    const WLParticleAttributes *particlesPtr = (const WLParticleAttributes *)[self.particleAttributesData bytes];
    
    //获取属性结构体中的某一个指标
    return particlesPtr[anIndex];
}
//设置粒子的属性
- (void)setParticle:(WLParticleAttributes)aParticle
            atIndex:(NSUInteger)anIndex
{
    //mutableBytes:指向可变数据对象所包含数据的指针
    //获取粒子属性结构体内容
    WLParticleAttributes *particlesPtr = (WLParticleAttributes *)[self.particleAttributesData mutableBytes];
    
    //将粒子结构体对应的属性修改为新值
    particlesPtr[anIndex] = aParticle;
    
    //更改粒子状态! 是否更新
    self.particleDataWasUpdated = YES;
}
//添加一个粒子
- (void)addParticleAtPosition:(GLKVector3)aPosition
                     velocity:(GLKVector3)aVelocity
                        force:(GLKVector3)aForce
                         size:(float)aSize
              lifeSpanSeconds:(NSTimeInterval)aSpan
          fadeDurationSeconds:(NSTimeInterval)aDuration {
    //创建新的例子
    WLParticleAttributes newParticle;
    //设置相关参数(位置\速度\抛物线\大小\耗时)
    newParticle.emissionPosition = aPosition;
    newParticle.emissionVelocity = aVelocity;
    newParticle.emissionForce = aForce;
    newParticle.size = GLKVector2Make(aSize, aDuration);
    //向量(耗时,发射时长)
    newParticle.emissionTimeAndLife = GLKVector2Make(_elapsedSeconds, _elapsedSeconds + aSpan);
    newParticle.radius = GLKVector2Make(0.5,0.5);
    BOOL foundSlot = NO;
    
    //粒子个数
    const long count = self.numberOfParticles;
    
    //循环设置粒子到数组中
    for(int i = 0; i < count && !foundSlot; i++) {
        
        //获取当前旧的例子
        WLParticleAttributes oldParticle = [self particleAtIndex:i];
        
        //如果旧的例子的死亡时间 小于 当前时间
        //emissionTimeAndLife.y = elapsedSeconds + aspan
        if(oldParticle.emissionTimeAndLife.y < _elapsedSeconds) {
            //更新例子的属性
            [self setParticle:newParticle atIndex:i];
            
            //是否替换
            foundSlot = YES;
        }
    }
    
    //如果不替换
    if(!foundSlot) {
        //在particleAttributesData 拼接新的数据
        [self.particleAttributesData appendBytes:&newParticle
                                          length:sizeof(newParticle)];
        
        //粒子数据是否更新
        self.particleDataWasUpdated = YES;
    }
}

//获取粒子个数
- (NSUInteger)numberOfParticles {
    static long last;
    //总数据/粒子结构体大小
    long ret = [self.particleAttributesData length] / sizeof(WLParticleAttributes);
    
    //如果last != ret 表示粒子个数更新了
    if (last != ret) {
        //则修改last数量
        last = ret;
    }
    
    return ret;
}
- (void)drawRect:(CGRect)rect {
    glClearColor(0.5, 0.65, 0.8, 1);
    glClear(GL_COLOR_BUFFER_BIT|GL_DEPTH_BUFFER_BIT);
    [self prepareEve];
    //禁用深度缓冲区写入
    glDepthMask(GL_FALSE);
    
    //绘制
    /*
     1.模式
     2.开始的位置
     3.粒子个数
     */
    [self.particleAttributeBuffer drawArrayWithMode:GL_POINTS
                                   startVertexIndex:0 numberOfVertices:(int)self.numberOfParticles];
    //启用深度缓冲区写入
    glDepthMask(GL_TRUE);
}

/// 时刻保持当前上下文是对的
- (void)updateContext {
    if ([EAGLContext currentContext] != _context) {
        [EAGLContext setCurrentContext:_context];
    }
}

//编译shader
- (BOOL)compileShader:(GLuint *)shader
                 type:(GLenum)type
                 file:(NSString *)file {
    //状态
    //GLint status;
    //路径-C语言
    const GLchar *source;
    
    //从OC字符串中获取C语言字符串
    //获取路径
    source = (GLchar *)[[NSString stringWithContentsOfFile:file
                                                  encoding:NSUTF8StringEncoding error:nil] UTF8String];
    //判断路径
    if (!source) {
        return NO;
    }
    
    //创建shader-顶点\片元
    *shader = glCreateShader(type);
    
    //绑定shader
    glShaderSource(*shader, 1, &source, NULL);
   
    //编译Shader
    glCompileShader(*shader);
    
    //获取加载Shader的日志信息
    //日志信息长度
    GLint logLength;
    /*
     在OpenGL中有方法能够获取到 shader错误
     参数1:对象,从哪个Shader
     参数2:获取信息类别,
     GL_COMPILE_STATUS       //编译状态
     GL_INFO_LOG_LENGTH      //日志长度
     GL_SHADER_SOURCE_LENGTH //着色器源文件长度
     GL_SHADER_COMPILER  //着色器编译器
     参数3:获取长度
     */
    glGetShaderiv(*shader, GL_INFO_LOG_LENGTH, &logLength);
    
    //判断日志长度 > 0
    if (logLength > 0) {
        //创建日志字符串
        GLchar *log = (GLchar *)malloc(logLength);
       
        /*
         获取日志信息
         参数1:着色器
         参数2:日志信息长度
         参数3:日志信息长度地址
         参数4:日志存储的位置
         */
        glGetShaderInfoLog(*shader, logLength, &logLength, log);
       
        //打印日志信息
        _compileLog = [NSString stringWithFormat:@"Shader compile log:\n%s", log];
        //释放日志字符串
        free(log);
        return NO;
    }

    
    return YES;
}

//链接program
- (BOOL)linkProgram:(GLuint)prog {
    //状态
    //GLint status;
    //链接Programe
    glLinkProgram(prog);
    //打印链接program的日志信息
    GLint logLength;
    glGetProgramiv(prog, GL_INFO_LOG_LENGTH, &logLength);
    if (logLength > 0) {
        GLchar *log = (GLchar *)malloc(logLength);
        glGetProgramInfoLog(prog, logLength, &logLength, log);
        _compileLog = [NSString stringWithFormat:@"Program link log:\n%s", log];
        free(log);
        return NO;
    }
    return YES;
}
@end

