//
//  ViewController.m
//  SenceKitDemo
//
//  Created by canoe on 2019/3/20.
//  Copyright © 2019 canoe. All rights reserved.
//

#import "ViewController.h"
#import "XJoyStick/XJoyStick.h"
#import <AudioToolbox/AudioServices.h>

//动画的key
static NSString * const kAnimationIdleKey = @"idle";
static NSString * const kAnimationRunKey = @"run";
static NSString * const kAnimationDanceKey = @"dance";
static NSString * const kAnimationJumpKey = @"jump";

//将动画加载存储在字典中的key
static NSString * const kBoyIdleKey = @"boy_idle";
static NSString * const kBoyRunKey = @"boy_run";
static NSString * const kGirlRunKey = @"girl_run";
static NSString * const kBoyDanceKey = @"boy_dance";
static NSString * const kGirlDanceKey = @"girl_dance";
static NSString * const kBoyJumpKey = @"boy_jump";
static NSString * const kGirlJumpKey = @"girl_jump";

@interface ViewController ()<XJoystickDelegate>

@property(nonatomic, strong) SCNScene *scene;
@property(nonatomic,strong) SCNView *sceneView;
@property(nonatomic, strong) SCNNode *cameraNode;
@property(nonatomic, strong) SCNNode *girl;
@property(nonatomic, strong) SCNNode *boy;
@property(nonatomic, strong) SCNNode *currentRole;
@property(nonatomic, strong) SCNNode *pointNode;

@property(nonatomic, strong) NSMutableDictionary *animationDict;

@property (weak, nonatomic) IBOutlet UILabel *currentRoleLabel;

@end

@implementation ViewController

-(NSMutableDictionary *)animationDict
{
    if (!_animationDict) {
        _animationDict = [NSMutableDictionary dictionary];
    }
    return _animationDict;
}

- (void)viewDidLoad
{
    [super viewDidLoad];
    
    //获取3D场景
    SCNScene *scene = [SCNScene sceneNamed:@"art.scnassets/main.scn"];
    self.scene = scene;
    
    //女孩  从资源库中加载的方式
    SCNScene *girlScene = [SCNScene sceneNamed:@"art.scnassets/girl/girlIdle.dae"];
    SCNNode *girl = [SCNNode node];
    for (SCNNode *child in girlScene.rootNode.childNodes) {
        [girl addChildNode:child];
    }
    girl.position = SCNVector3Make(-250, 0, 0);
    self.girl = girl;
    [self.scene.rootNode addChildNode:girl];
    
    //男孩 直接从场景中加载的方式
    SCNNode *boy = [self.scene.rootNode childNodeWithName:@"boy" recursively:YES];
    self.boy = boy;
    
    //当前角色
    self.currentRole = self.girl;
    
    //加载动画资源
    [self loadAnimations];
    
    //人物默认设置成空闲
    [self idle];
    
    //设置View
    self.sceneView = [[SCNView alloc]initWithFrame:self.view.bounds];
    self.sceneView.backgroundColor = [UIColor blackColor];
    [self.view addSubview:self.sceneView];
    self.sceneView.scene = scene;
    self.sceneView.allowsCameraControl = NO;
    self.sceneView.showsStatistics = YES;
    [self.view sendSubviewToBack:self.sceneView];
    
    //相机
    SCNCamera *camera = [SCNCamera camera];
    camera.zFar = 2000;
    camera.zNear = 50;
    SCNNode *cameraNode = [SCNNode node];
    cameraNode.camera = camera;
    self.cameraNode = cameraNode;
    
    //设置相机位置
    [self allSceneCamera:nil];
    
    //相机跟随的节点，这个节点永远跟随当前的目标人物节点
    SCNNode *pointNode = [SCNNode node];
    pointNode.position = self.currentRole.position;
    self.pointNode = pointNode;
    [self.scene.rootNode addChildNode:pointNode];
    
    //控制器
    XJoyStick *joystick = [[XJoyStick alloc] initWithFrame:CGRectMake(40, 540, 100, 100)];
    [self.sceneView addSubview:joystick];
    joystick.delegate = self;
}


#pragma mark - 动画
//获取动画资源
-(CAAnimation *)animationWithAnimationKey:(NSString *)key SceneNamed:(NSString *)name animationIdentifier:(NSString *)identify {
    NSURL *sceneURL = [[NSBundle mainBundle] URLForResource:name withExtension:@"dae"];
    SCNSceneSource *source = [SCNSceneSource sceneSourceWithURL:sceneURL options:nil];
    CAAnimation *animation = [source entryWithIdentifier:identify withClass:[CAAnimation class]];
    [self.animationDict setObject:animation forKey:key];
    return animation;
}

//加载所有的动画资源
- (void)loadAnimations {
    //男生空闲
    CAAnimation *boyIdle = [self animationWithAnimationKey:kBoyIdleKey SceneNamed:@"art.scnassets/boy/boy_idleFixed" animationIdentifier:@"boy_idleFixed-1"];
    boyIdle.fadeInDuration = 0.2;    //淡入
    boyIdle.fadeOutDuration = 0.2;   //淡出
    
    //男生跑步
    CAAnimation *boyRun = [self animationWithAnimationKey:kBoyRunKey SceneNamed:@"art.scnassets/boy/boy_runFixed" animationIdentifier:@"boy_runFixed-1"];
    boyRun.fadeInDuration = 0.3;
    boyRun.fadeOutDuration = 0.5;
    
    //这里女生的资源包中已经包含了空闲动画，所以不需要再次添加女孩的空闲动画
    //女生跑步
    CAAnimation *girlRun = [self animationWithAnimationKey:kGirlRunKey SceneNamed:@"art.scnassets/girl/girl_runFixed" animationIdentifier:@"girl_runFixed-1"];
    girlRun.fadeInDuration = 0.3;
    girlRun.fadeOutDuration = 0.5;
    
    //男生跳舞
    CAAnimation *boyDance = [self animationWithAnimationKey:kBoyDanceKey SceneNamed:@"art.scnassets/boy/boy_danceFixed" animationIdentifier:@"boy_danceFixed-1"];
    boyDance.fadeInDuration = 0.3;
    boyDance.fadeOutDuration = 0.5;
    boyDance.repeatCount = 1;
    
    //女生跳舞
    CAAnimation *girlDance = [self animationWithAnimationKey:kGirlDanceKey SceneNamed:@"art.scnassets/girl/girl_danceFixed" animationIdentifier:@"girl_danceFixed-1"];
    girlDance.fadeInDuration = 0.3;
    girlDance.fadeOutDuration = 0.5;
    girlDance.repeatCount = 1;
    
    //男生跳
    CAAnimation *boyJump = [self animationWithAnimationKey:kBoyJumpKey SceneNamed:@"art.scnassets/boy/boy_jumpFixed" animationIdentifier:@"boy_jumpFixed-1"];
    boyJump.fadeInDuration = 0.1;
    boyJump.fadeOutDuration = 0.1;
    boyJump.speed = 1.3;
    boyJump.repeatCount = 1;
    
    //女生跳
    CAAnimation *girlJump = [self animationWithAnimationKey:kGirlJumpKey SceneNamed:@"art.scnassets/girl/girl_jumpFixed" animationIdentifier:@"girl_jumpFixed-1"];
    girlJump.fadeInDuration = 0.1;
    girlJump.fadeOutDuration = 0.1;
    girlJump.repeatCount = 1;
}

//休闲时的动画
- (void)idle {
    //设置男生休闲动画，女生资源包中已经包含，不需要手动设置
    [self.boy addAnimation:[self.animationDict objectForKey:kBoyIdleKey] forKey:kAnimationIdleKey];
}

/**
 开始播放动画

 @param key 动画key
 @param start 开始或者结束
 */
- (void)playAnimationWithAnimation:(CAAnimation *)animation animationKey:(NSString *)key isStart:(BOOL)start {
    if (start) {
        //如果一个动画在进行中开始另一个动画,那么删除掉除了空闲动画和当前的动画之外所有的动画
        for (NSInteger i = 0; i < self.currentRole.animationKeys.count; i++) {
            if (![self.currentRole.animationKeys[i] isEqualToString:kAnimationIdleKey] && ![self.currentRole.animationKeys[i] isEqualToString:key]) {
                [self.currentRole removeAnimationForKey:self.currentRole.animationKeys[i] fadeOutDuration:0.3];
                i--;
            }
        }
        
        if (![self.currentRole animationForKey:key]) {
            [self.currentRole addAnimation:animation forKey:key];
        }
    }else
    {
        [self.currentRole removeAnimationForKey:key fadeOutDuration:0.3];
    }
}

- (IBAction)dance:(UIButton *)sender {
    AudioServicesPlaySystemSound(1519);
    CAAnimation *animation;
    if ([self.currentRole isEqual:self.boy]) {
        animation = [self.animationDict objectForKey:kBoyDanceKey];
    }else {
        animation = [self.animationDict objectForKey:kGirlDanceKey];
    }
    [self playAnimationWithAnimation:animation animationKey:kAnimationDanceKey isStart:YES];
}

- (IBAction)jump:(UIButton *)sender {
    AudioServicesPlaySystemSound(1519);
    CAAnimation *animation;
    if ([self.currentRole isEqual:self.boy]) {
        animation = [self.animationDict objectForKey:kBoyJumpKey];
    }else {
        animation = [self.animationDict objectForKey:kGirlJumpKey];
    }
    [self playAnimationWithAnimation:animation animationKey:kAnimationJumpKey isStart:YES];
}

#pragma mark - 控制行走代理
- (void)joystick:(XJoyStick *)aJoystick didUpdate:(CGPoint)deltaFactor {
    //角色移动
    self.currentRole.position = SCNVector3Make(self.currentRole.position.x + deltaFactor.x * 5, 0, self.currentRole.position.z - deltaFactor.y * 5);
    //相机跟随的目标节点同时移动
    self.pointNode.position = self.currentRole.position;
    
    //角色朝向
    if (deltaFactor.x >= 0 && deltaFactor.y >= 0) {
        self.currentRole.rotation = SCNVector4Make(0, 1, 0, atan(deltaFactor.y / deltaFactor.x) + M_PI_2);
    }else if (deltaFactor.x <= 0 && deltaFactor.y >= 0) {
        self.currentRole.rotation = SCNVector4Make(0, 1, 0, atan(-deltaFactor.x / deltaFactor.y) + M_PI);
    }else if (deltaFactor.x <= 0 && deltaFactor.y <= 0) {
        self.currentRole.rotation = SCNVector4Make(0, 1, 0, atan(deltaFactor.y / deltaFactor.x) + M_PI + M_PI_2);
    }else {
        self.currentRole.rotation = SCNVector4Make(0, 1, 0, atan(- deltaFactor.x / deltaFactor.y));
    }
    
    //如果有跳跃动画，不进行跑步动画
    if ([self.currentRole animationForKey:kAnimationJumpKey]) {
        return;
    }
    
    CAAnimation *animation;
    if ([self.currentRole isEqual:self.boy]) {
        animation = [self.animationDict objectForKey:kBoyRunKey];
    }else {
        animation = [self.animationDict objectForKey:kGirlRunKey];
    }
    //开始跑步动画
    [self playAnimationWithAnimation:animation animationKey:kAnimationRunKey isStart:YES];
}

- (void)joystick:(XJoyStick *)aJoystick didEnd:(CGPoint)deltaFactor {
    //停止跑步动画
    [self playAnimationWithAnimation:nil animationKey:kAnimationRunKey isStart:NO];
}

#pragma mark - 镜头切换
- (IBAction)changeRole:(id)sender {
    //停止跑步动画
    [self playAnimationWithAnimation:nil animationKey:kAnimationRunKey isStart:NO];
    
    if ([self.currentRole isEqual: self.girl]) {
        self.currentRole = self.boy;
        self.currentRoleLabel.text = @"boy";
    }else
    {
        self.currentRole = self.girl;
        self.currentRoleLabel.text = @"girl";
    }
    self.pointNode.position = self.currentRole.position;
    [self cameraMove:nil];
}

//近景镜头
- (IBAction)cameraMove:(id)sender
{
    self.sceneView.allowsCameraControl = NO;
    [self.pointNode addChildNode:self.cameraNode];
    self.sceneView.pointOfView = self.cameraNode;
    self.cameraNode.constraints = nil;
    self.cameraNode.rotation = SCNVector4Make(1, 0, 0, - M_PI/6.0);
    self.cameraNode.position = SCNVector3Make(0, 400, 600);
}

- (IBAction)allSceneCamera:(id)sender {
    self.sceneView.allowsCameraControl = YES;
    [self.sceneView.scene.rootNode addChildNode:self.cameraNode];
    self.sceneView.pointOfView = self.cameraNode;
    self.cameraNode.position = SCNVector3Make(0, 400, 800);
    self.cameraNode.constraints = nil;
    self.cameraNode.rotation = SCNVector4Make(1, 0, 0, - M_PI/6.0);
}

@end
