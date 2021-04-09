
attribute vec3 a_emissionPosition; //位置
attribute vec3 a_emissionVelocity; //速度
attribute vec3 a_emissionForce;    //受力
attribute vec2 a_size;             //大小 和 Fade持续时间  size = GLKVector2Make(aSize, aDuration);
attribute vec2 a_emissionAndDeathTimes; //发射时间 和 消失时间
attribute vec2     a_radius; //半径

// UNIFORMS
uniform highp mat4      u_mvpMatrix;      //变换矩阵
uniform sampler2D       u_samplers2D[1];  //纹理
uniform highp vec3      u_gravity;        //重力
uniform highp float     u_elapsedSeconds; //当前时间


// Varyings
varying lowp float      v_particleOpacity;   //粒子透明度


void main()
{
    
    //流逝时间
    highp float elapsedTime = u_elapsedSeconds - a_emissionAndDeathTimes.x;
    
    // 质量假设是1.0 加速度 = 力 (a = f/m)
    // v = v0 + at : v 是当前速度; v0 是初速度;
    //               a 是加速度; t 是时间
    //a_emissionForce 受力,u_gravity 重力
    
    //求速度velocity
    highp vec3 velocity = a_emissionVelocity +
    ((a_emissionForce + u_gravity) * elapsedTime);
    
    // s = s0 + 0.5 * (v0 + v) * t
    //                              s 当前位置
    //                              s0 初始位置
    //                              v0 初始速度
    //                              v 当前速度
    //                              t 是时间
    
    // 运算是对向量运算，相当于分别求出x、y、z的位置，再综合
    //求粒子的受力后的位置 = a_emissionPosition(原始位置) + 0.5 * (速度+加速度) * 流逝时间

//    highp vec3 untransformedPosition = a_emissionPosition +
//    0.5 * (a_emissionVelocity + velocity) * elapsedTime;
    float remainTime = a_emissionAndDeathTimes.y - u_elapsedSeconds;
    float r = a_radius.x;
    float newR = -(r + elapsedTime);//a_emissionPosition.y * r / a_radius.y + a_radius.y;
    float v = 3.14/6.0;
    mat3 myMat3 = mat3(newR*sin(v*elapsedTime), 0, 0,
                       0, 1, 0.0,
                       0, 0.0, newR*cos(v*elapsedTime));
    
    highp vec3 untransformedPosition = a_emissionPosition*myMat3;
//    untransformedPosition.y =  untransformedPosition.y + elapsedTime*0.2;
    //得出点的位置
    gl_Position = u_mvpMatrix * vec4(untransformedPosition, 1.0);
//    gl_Position = vec4(0.5,0,0,1);
    gl_PointSize = a_size.x / gl_Position.z;
//    gl_PointSize = 100.0;//gl_Position.w;
    
    // 消失时间减去当前时间，得到当前的寿命； 除以Fade持续时间，当剩余时间小于Fade时间后，得到一个从1到0变化的值
    // 如果这个值小于0，则取0
    
    float keepTime = max(a_size.y, 0.00001);
    v_particleOpacity = max(0.0, min(1.0,remainTime /keepTime));
}
