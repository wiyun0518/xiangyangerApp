//
//  ViewController.m
//  教师端
//
//  Created by 海海 on 2018/7/5.
//  Copyright © 2018年 海学明. All rights reserved.
//

#import "ViewController.h"
#import <ILiveSDK/ILiveSDK.h>
#import <ILiveSDK/ILiveLoginManager.h>
#import "LiveRoomViewController.h"
//#import "LiveViewController.h"
//#import "LiveViewController+Audio.h"
#define KISIphoneX (CGSizeEqualToSize(CGSizeMake(375.f, 812.f), [UIScreen mainScreen].bounds.size) || CGSizeEqualToSize(CGSizeMake(812.f, 375.f), [UIScreen mainScreen].bounds.size))
#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "AppDelegate.h"
//#import <ILiveSDK/ILiveLoginManager.h>
//#import "CreateRoomViewController.h"
@interface ViewController ()<UIWebViewDelegate>
/*老师参数*/
@property (nonatomic ,strong)UIWebView *webView;
@property (nonatomic ,copy)NSString *accountType;
@property (nonatomic ,copy)NSString *indentifer;
@property (nonatomic ,copy)NSString *sdkAppid;
@property (nonatomic ,copy)NSString *userSig;
@property (nonatomic ,copy)NSString *roomid;
/*学生加入参数*/

@property (nonatomic ,copy)NSString *STaccountType;
@property (nonatomic ,copy)NSString *STindentifer;
@property (nonatomic ,copy)NSString *STsdkAppid;
@property (nonatomic ,copy)NSString *STuserSig;
@property (nonatomic ,copy)NSString *STroomid;
@property (weak, nonatomic) IBOutlet UITextField *userIDTF;
@property (weak, nonatomic) IBOutlet UITextField *userSigTF;
@property (nonatomic, strong) UIAlertController *alertCtrl;
//!< 提示框
@property (strong, nonatomic) UIButton *creatBtn;

@property (nonatomic,assign)AppDelegate *appDelegate;
@end

@implementation ViewController
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //隐藏=YES,显示=NO; Animation:动画效果
//    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
//    self.navigationController.navigationBar.hidden = YES;
}
- (void)viewDidLoad {
    [super viewDidLoad];
    
      [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
    _webView = [[UIWebView alloc]init];
    if (KISIphoneX) {
        _webView.frame = CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT -40);
        NSLog(@"这是iPhone X");
    }else{
        _webView.frame =CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
        NSLog(@"这是iPhone X吗");
    }

    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://app.xiangyanger.com/dstx_elearning_teacher/teachersLoginController.do?login"]]];
//    http://193.112.164.129:8080/dstx_elearning_teacher/teachersLoginController.do?login
   
    _webView.delegate = self;
    
    _webView.scrollView.bounces = NO;
    _webView.scrollView.scrollEnabled = YES;
    [self.view addSubview:_webView];
    // 检测音视频权限
    [self detectAuthorizationStatus];
    
}
- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL * url = [request URL];
    NSString * urlStr = [url absoluteString];
    
    //    NSLog(@"jieguos是什么呢%@",[url scheme]);
    if ([urlStr  containsString:@"jxaction://creatroom?"]) {
        NSLog(@"%@",url);
        NSLog(@";;;;;%@",url.query);
        
        NSArray *params =[url.query componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
        for (NSString *paramStr in params) {
            NSArray *dicArray = [paramStr componentsSeparatedByString:@"="];
            if (dicArray.count > 1) {
                NSString *decodeValue = [dicArray[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [tempDic setObject:decodeValue forKey:dicArray[0]];
            }
        }
        
        self.accountType = tempDic[@"accountType"];
        self.indentifer = tempDic[@"indentifer"];
        self.sdkAppid = tempDic[@"sdkAppid"];
        self.userSig = tempDic[@"userSig"];
        self.roomid = tempDic[@"roomid"];

        //注册SDK
//        [[ILiveSDK getInstance] initSdk:[self.sdkAppid intValue] accountType:[self.accountType intValue]];
        NSLog(@"打印结果便是%@ %@ %@ %@ %@",self.accountType,self.indentifer,self.sdkAppid,self.userSig,self.roomid);
        [self creatRoom];
        
        NSLog(@"tempDic:%@",tempDic);
        return NO;
    }else if ([urlStr containsString:@"jxaction://joinroom?"]){
        NSLog(@"%@",url);
        NSLog(@";;;;;%@",url.query);
        
        NSArray *params =[url.query componentsSeparatedByString:@"&"];
        
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
        for (NSString *paramStr in params) {
            NSArray *dicArray = [paramStr componentsSeparatedByString:@"="];
            if (dicArray.count > 1) {
                NSString *decodeValue = [dicArray[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [tempDic setObject:decodeValue forKey:dicArray[0]];
            }
        }
      
     
        return NO;
    }
    
    return YES;
}

- (void)creatRoom{
    [[ILiveLoginManager getInstance] iLiveLogin:self.indentifer sig:self.userSig succ:^{
        
        // 登录成功，跳转到创建房间页
        // 1. 创建live房间页面
        LiveRoomViewController *liveRoomVC = [[LiveRoomViewController alloc] init];
        
        // 2. 创建房间配置对象
        ILiveRoomOption *option = [ILiveRoomOption defaultHostLiveOption];
        option.imOption.imSupport = NO;
        // 设置房间内音视频监听
        option.memberStatusListener = liveRoomVC;
        // 设置房间中断事件监听
        option.roomDisconnectListener = liveRoomVC;
        
        // 该参数代表进房之后使用什么规格音视频参数，参数具体值为客户在腾讯云实时音视频控制台画面设定中配置的角色名（例如：默认角色名为user, 可设置controlRole = @"user"）
        //    option.controlRole = #腾讯云控制台配置的角色名#;
        option.controlRole =@"Master";
        
        // 3. 调用创建房间接口，传入房间ID和房间配置对象
        [[ILiveRoomManager getInstance] createRoom:[self.roomid intValue] option:option succ:^{
            // 创建房间成功，跳转到房间页
            [self.navigationController pushViewController:liveRoomVC animated:YES];
//             [self presentViewController:liveRoomVC animated:YES completion:nil];
//             [self.navigationController pushViewController:liveRoomVC animated:YES];
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            // 创建房间失败
            self.alertCtrl.title = @"创建房间失败";
            self.alertCtrl.message = [NSString stringWithFormat:@"errId:%d errMsg:%@",errId, errMsg];
            [self presentViewController:self.alertCtrl animated:YES completion:nil];
        }];
        
        //        CreateRoomViewController *createRoomVC = [[CreateRoomViewController alloc] init];
        //        [self.navigationController pushViewController:createRoomVC animated:YES];
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        // 登录失败
        self.alertCtrl.title = @"创建房间失败";
        self.alertCtrl.message = [NSString stringWithFormat:@"errId:%d errMsg:%@",errId, errMsg];
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
    }];
    
}
#pragma mark - Custom Method
// 检测音视频权限
- (void)detectAuthorizationStatus {
    // 检测是否有摄像头权限
    AVAuthorizationStatus statusVideo = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeVideo];
    if (statusVideo == AVAuthorizationStatusRestricted || statusVideo == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取摄像头权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
        return;
    } else if (statusVideo == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeVideo completionHandler:^(BOOL granted) {
            
        }];
    }
    
    // 检测是否有麦克风权限
    AVAuthorizationStatus statusAudio = [AVCaptureDevice authorizationStatusForMediaType:AVMediaTypeAudio];
    if (statusAudio == AVAuthorizationStatusRestricted || statusAudio == AVAuthorizationStatusDenied) {
        self.alertCtrl.message = @"获取麦克风权限失败，请前往隐私-麦克风设置里面打开应用权限";
        [self presentViewController:self.alertCtrl animated:YES completion:nil];
        return;
    } else if (statusAudio == AVAuthorizationStatusNotDetermined) {
        [AVCaptureDevice requestAccessForMediaType:AVMediaTypeAudio completionHandler:^(BOOL granted) {
            
        }];
    }
}

#pragma mark - Accessor
- (UIAlertController *)alertCtrl {
    if (!_alertCtrl) {
        _alertCtrl = [UIAlertController alertControllerWithTitle:nil message:nil preferredStyle:UIAlertControllerStyleAlert];
        UIAlertAction *action = [UIAlertAction actionWithTitle:@"确定" style:UIAlertActionStyleCancel handler:^(UIAlertAction * _Nonnull action) {
            
        }] ;
        [_alertCtrl addAction:action];
    }
    return _alertCtrl;
}
//- (void)sendJoinRoomMsg
//{
//    ILVLiveCustomMessage *msg = [[ILVLiveCustomMessage alloc] init];
//    msg.type = ILVLIVE_IMTYPE_C2C;
//    msg.cmd = (ILVLiveIMCmd)AVIMCMD_EnterLive;
//    //    msg.recvId = [[ILiveRoomManager getInstance] getIMGroupId];
//
//    [[TILLiveManager getInstance] sendCustomMessage:msg succ:^{
//        NSLog(@"succ");
//    } failed:^(NSString *module, int errId, NSString *errMsg) {
//        NSLog(@"fail");
//    }];
//}
//
//- (void)setSelfInfo
//{
//    __weak typeof(self) ws = self;
//    [[TIMFriendshipManager sharedInstance] GetSelfProfile:^(TIMUserProfile *profile) {
//        //        ws.selfProfile = profile;
//    } fail:^(int code, NSString *msg) {
//        NSLog(@"GetSelfProfile fail");
//        //        ws.selfProfile = nil;
//    }];
//}




@end
