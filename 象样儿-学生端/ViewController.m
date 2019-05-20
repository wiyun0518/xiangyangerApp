  //
//  ViewController.m
//  象样儿-学生端
//
//  Created by 海海 on 2018/7/7.
//  Copyright © 2018年 海学明. All rights reserved.
//

#import "ViewController.h"
#import "WebChatPayH5VIew.h"
#import <ILiveSDK/ILiveLoginManager.h>
#import "LiveRoomViewController.h"
#import "MAIAPManager.h"
#import "SVProgressHUD.h"
//#import "AFNetworking.h"
//#import "LiveViewController.h"
//#import "LiveViewController+Audio.h"

#define KISIphoneX (CGSizeEqualToSize(CGSizeMake(375.f, 812.f), [UIScreen mainScreen].bounds.size) || CGSizeEqualToSize(CGSizeMake(812.f, 375.f), [UIScreen mainScreen].bounds.size))


#define SCREEN_WIDTH ([UIScreen mainScreen].bounds.size.width)

#define SCREEN_HEIGHT ([UIScreen mainScreen].bounds.size.height)

#import "ViewController.h"
#import <WebKit/WebKit.h>
#import "AppDelegate.h"
#import <StoreKit/StoreKit.h>
//#import <ILiveSDK/ILiveLoginManager.h>
//#import "CreateRoomViewController.h"
@interface ViewController ()<UIWebViewDelegate>
//苹果内购

@property (nonatomic,strong) MAIAPManager *iapManager;

@property (nonatomic ,strong)UIWebView *webView;

@property (strong, nonatomic) NSUserDefaults *defaults;

/*学生加入参数*/
@property (nonatomic ,copy)NSString *STaccountType;
@property (nonatomic ,copy)NSString *STindentifer;
@property (nonatomic ,copy)NSString *STsdkAppid;
@property (nonatomic ,copy)NSString *STuserSig;
@property (nonatomic ,copy)NSString *STroomid;

/*获取订单号*/
@property (nonatomic ,copy)NSString *out_trade_no;
@property (nonatomic ,copy)NSString *total_fee;
@property (nonatomic ,copy)NSString *status;
@property (nonatomic ,copy)NSString *pay_flag;//内购验证参数


//获取当前时间
@property (nonatomic ,strong)NSString *dateTime;

@property (nonatomic, strong) UIAlertController *alertCtrl;
//!< 提示框
@property (strong, nonatomic) UIButton *creatBtn;

@end

@implementation ViewController
- (UIStatusBarStyle)preferredStatusBarStyle {
    // 返回你所需要的状态栏样式
    return UIStatusBarStyleBlackTranslucent;
}
-(void)viewWillAppear:(BOOL)animated
{
    [super viewWillAppear:animated];
    //隐藏=YES,显示=NO; Animation:动画效果
    self.navigationController.navigationBar.hidden = YES;
    [[UIApplication sharedApplication] setStatusBarHidden:YES withAnimation:UIStatusBarAnimationNone];
}
- (void)viewDidLoad {
    
    [super viewDidLoad];
    
    _webView = [[UIWebView alloc] init];

    if (KISIphoneX) {
        _webView.frame = CGRectMake(0, -14, SCREEN_WIDTH, SCREEN_HEIGHT -40);
        NSLog(@"这是iPhone X");
        
    }else{
        _webView.frame =CGRectMake(0, 0, SCREEN_WIDTH, SCREEN_HEIGHT);
         NSLog(@"这是iPhone X吗");
    }
    self.webView.backgroundColor = [UIColor whiteColor];
    self.webView.backgroundColor = [UIColor colorWithRed:22.0/255 green:110.0/255 blue:163.0/255 alpha:1];
    
    [_webView loadRequest:[NSURLRequest requestWithURL:[NSURL URLWithString:@"http://app.xiangyanger.com/dstx_elearning_student/index.jsp"]]];
    http://app. xiangyanger.com/dstx_elearning_student/dsStudentController.do?login
    _webView.delegate = self;
    _webView.scrollView.bounces = NO;
    _webView.scrollView.scrollEnabled = YES;
    [self.view addSubview:_webView];
 
    // 检测音视频权限
    
    [self detectAuthorizationStatus];
    
}

//购买动作
- (void)purchaseAction {
    
    if (!_iapManager) {
        _iapManager = [[MAIAPManager alloc] init];
    }
    
    // iTunesConnect 苹果后台配置的产品ID
    [_iapManager MA_startPurchWithID:self.total_fee completeHandle:^(IAPPurchType type, NSData *data) {

        NSLog(@"%@,%u,当前的订单号是",self.out_trade_no,type);
      //   http://app.xiangyanger.com/dstx_elearning_student/wxNotifyController/payNotify
       
    //上传参数 接口地址http://app.xiangyanger.com/dstx_elearning_student/wxNotifyController/payNotify
        //上传参数
        
       if (type == kIAPPurchSuccess|| type ==KIAPPurchVerSuccess ) {
           
           self.status = @"SUCCESS";
           
        }else{
            self.status = @"FAIL";
           NSLog(@"购买失败");
       }
          [self postData];
        
    }];

}

- (BOOL)webView:(UIWebView *)webView shouldStartLoadWithRequest:(NSURLRequest *)request navigationType:(UIWebViewNavigationType)navigationType
{
    NSURL * url = [request URL];
    NSString * urlStr = [url absoluteString];
    NSLog(@"传入支付的url是%@",urlStr);
    //1.传入支付的url是https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx041738368435890b30bce4522156266981&package=1556452576&redirect_url=http%3A%2F%2Fapp.xiangyanger.com%2Fdstx_elearning_student%2FdsOrderController.do%3FpayAfter
    //2当字符串是以weixin://wap/pay"开头传入的url是
    /*所有的订单信息是：weixin://wap/pay?prepayid%3Dwx071011309308791ce24eaea30884513649&package=3817825352&noncestr=1546827296&sign=4c69ac3efec467593df43d451b86ffe7*/
    /*https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx1815072328345506dcf8ac432040905460&package=788455331&redirect_url=http%3A%2F%2Fapp.xiangyanger.com%2Fdstx_elearning_student%2FdsOrderController.do%3FpayAfter&out_trade_no=20190118030656867867&total_fee=2500*/
    
    /*恢复购买restore*/
    
    if (([urlStr rangeOfString:@"pay_flag=neigou"].location != NSNotFound)&&([urlStr rangeOfString:@"wx.tenpay.com"].location != NSNotFound )){
        
        NSLog(@"wx.tenpay.com此时的拦截URL是%@",urlStr);
        NSArray *params =[url.query componentsSeparatedByString:@"&"];
        NSLog(@"url.query是%@",url.query);
        
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
        for (NSString *paramStr in params) {
            NSArray *dicArray = [paramStr componentsSeparatedByString:@"="];
            if (dicArray.count > 1) {
                NSString *decodeValue = [dicArray[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [tempDic setObject:decodeValue forKey:dicArray[0]];
            }
        }
        self.pay_flag = tempDic[@"pay_flag"];
        self.out_trade_no = tempDic[@"out_trade_no"];
        self.total_fee = tempDic[@"total_fee"];
        NSLog(@"订单号是和金额是%@,%@",self.out_trade_no,self.total_fee);
        /*获取当前时间*/
        self.dateTime = [self getCurrenttime];
        NSLog(@"当前时间是%@",self.dateTime);

        //恢复购买
        
        [self restoreBtn];
        
        return NO;
    }
    if ([urlStr rangeOfString:@"wx.tenpay.com"].location != NSNotFound ) {
      
        NSLog(@"wx.tenpay.com此时的拦截URL是%@",urlStr);
        NSArray *params =[url.query componentsSeparatedByString:@"&"];
         NSLog(@"url.query是%@",url.query);
        
        NSMutableDictionary *tempDic = [NSMutableDictionary dictionary];
        for (NSString *paramStr in params) {
            NSArray *dicArray = [paramStr componentsSeparatedByString:@"="];
            if (dicArray.count > 1) {
                NSString *decodeValue = [dicArray[1] stringByReplacingPercentEscapesUsingEncoding:NSUTF8StringEncoding];
                [tempDic setObject:decodeValue forKey:dicArray[0]];
            }
        }
        
        self.out_trade_no = tempDic[@"out_trade_no"];
        self.total_fee = tempDic[@"total_fee"];
        NSLog(@"订单号是和金额是%@,%@",self.out_trade_no,self.total_fee);
        /*获取当前时间*/
        self.dateTime = [self getCurrenttime];
        NSLog(@"当前时间是%@",self.dateTime);

        /*此时的拦截URL是https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx071011309308791ce24eaea30884513649&package=3817825352&redirect_url=http%3A%2F%2Fapp.xiangyanger.com%2Fdstx_elearning_student%2FdsOrderController.do%3FpayAfter*/
      
/*1.iOS内购支付流程*/
        [self purchaseAction];
        
       
/*2.此处是微信支付流程*/
//        NSArray * array = [urlStr componentsSeparatedByString:@"redirect_url="];
//        WebChatPayH5VIew *h5View = [[WebChatPayH5VIew alloc] initWithFrame:CGRectMake(0, 0, 1, 1)];
/* newUrl是没有拼接redirect_url微信h5支付链接*/
//        [h5View loadingURL:array.firstObject withIsWebChatURL:NO];
//        [self.view addSubview:h5View];
        return NO;
    }
    

    //  NSLog(@"jieguos是什么呢%@",[url scheme]);
//   传入支付的url是https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx28143220465899add09a07280542651988&package=1131890293&redirect_url=http%3A%2F%2Fapp.xiangyanger.com%2Fdstx_elearning_student%2FdsOrderController.do%3FpayAfter
    https://wx.tenpay.com/cgi-bin/mmpayweb-bin/checkmweb?prepay_id=wx04174415432518857923d37e2928363283&package=1089376243&redirect_url=http%3A%2F%2Fapp.xiangyanger.com%2Fdstx_elearning_student%2FdsOrderController.do%3FpayAfter
//传入支付的url是weixin://wap/pay?prepayid%3Dwx28143220465899add09a07280542651988&package=1131890293&noncestr=1543386901&sign=34a7e22f85142c63302cb98aaac40e3c
    
 

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

        self.STaccountType = tempDic[@"accountType"];
        self.STindentifer = tempDic[@"indentifer"];
        self.STsdkAppid = tempDic[@"sdkAppid"];
        self.STuserSig = tempDic[@"userSig"];
        self.STroomid = tempDic[@"roomid"];

        // 初始化SDK
//        [[ILiveSDK getInstance] initSdk:[self.STsdkAppid  intValue] accountType:[self.STaccountType intValue]];
        NSLog(@"打印结果便是%@ %@ %@ %@ %@",self.STaccountType,self.STindentifer,self.STsdkAppid,self.STuserSig,self.STroomid);

        //加入房间

        [self joinroom];
        NSLog(@"包含了joinroom");

        return NO;
    }
    
    return YES;
}
//恢复购买
- (void)restoreBtn{
    
    if (!_iapManager) {
        _iapManager = [[MAIAPManager alloc] init];
    }
    [self.iapManager MA_restoreTransactionWithCompleteHandle:^(IAPPurchType type, NSData *data) {
        if (type == kIAPPurchSuccess|| type ==KIAPPurchVerSuccess ) {
            
            self.status = @"SUCCESS";
            [SVProgressHUD showWithStatus:@"Restore Success"];
            [self.defaults setObject:@"yes" forKey:@"isPay"];
            [SVProgressHUD dismiss];
            
            
        }else{
            self.status = @"FAIL";
            NSLog(@"购买失败");
        }
        [self postData1];
        
    }];
}

-(void)postData{
    
    NSString *out_trade_no = self.out_trade_no;
    NSString *total_fee = self.total_fee;
    NSString *time_end = self.dateTime;
    NSString *status = self.status;
    
    
    NSString *xmlStr = [NSString stringWithFormat:@"<?xml version='1.0' encoding='utf-8'?><xml><appid><![CDATA[wx5c5cf9d2bba9d747]]></appid><bank_type><![CDATA[CFT]]></bank_type><cash_fee><![CDATA[1]]></cash_fee><fee_type><![CDATA[CNY]]></fee_type><is_subscribe><![CDATA[N]]></is_subscribe><mch_id><![CDATA[1515042911]]></mch_id><nonce_str><![CDATA[1413295674]]></nonce_str><openid><![CDATA[ofb8d1EoXqodFwtLhokwPNoD9fn0]]></openid><out_trade_no><![CDATA[%@]]></out_trade_no><result_code><![CDATA[%@]]></result_code><return_code><![CDATA[%@]]></return_code><sign><![CDATA[DB2BF3C51556C890A57C720FC5F57A84]]></sign><time_end><![CDATA[%@]]></time_end><total_fee>%@</total_fee><trade_type><![CDATA[4]]></trade_type><transaction_id><![CDATA[4200000204201812047707944594]]></transaction_id></xml>",out_trade_no,status,status,time_end,total_fee];
    [self postxml:xmlStr];
}
-(void) postxml:(NSString*)vendor
{
    
    NSMutableURLRequest *request = [[NSMutableURLRequest alloc] init];
    [request setURL:[NSURL URLWithString:@"http://app.xiangyanger.com/dstx_elearning_student/wxNotifyController/payNotify"]];
    [request setHTTPMethod:@"POST"];//声明请求为POST请求
    //set headers
    NSString *contentType = [NSString stringWithFormat:@"text/xml"];//Content-Type数据类型设置xml类型
    [request addValue:contentType forHTTPHeaderField: @"Content-Type"];
    //create the body
    NSMutableData *postBody = [NSMutableData data];
    [postBody appendData:[vendor dataUsingEncoding:NSUTF8StringEncoding]];
    
    [request setHTTPBody:postBody];
    
    NSString *bodyStr = [[NSString alloc] initWithData:postBody  encoding:NSUTF8StringEncoding];
    NSLog(@"bodyStr: %@ ",bodyStr);
    
    //get response
    NSHTTPURLResponse* urlResponse = nil;
    NSError *error = [[NSError alloc] init];
    NSData *responseData = [NSURLConnection sendSynchronousRequest:request returningResponse:&urlResponse error:&error];
    NSString *result = [[NSString alloc] initWithData:responseData encoding:NSUTF8StringEncoding];
    NSLog(@"返回的结果是:Response Code: %ld", (long)[urlResponse statusCode]);
    if ([urlResponse statusCode] >= 200 && [urlResponse statusCode] < 300) {
        NSLog(@"Response: %@", result);
    }
}

- (void)postData1{
    
    NSString *out_trade_no = self.out_trade_no;
    NSString *total_fee = self.total_fee;
    NSString *time_end = self.dateTime;
    NSString *status = self.status;
    NSString *pay_flag = self.pay_flag;
    
    
    NSString *xmlStr = [NSString stringWithFormat:@"<?xml version='1.0' encoding='utf-8'?><xml><appid><![CDATA[wx5c5cf9d2bba9d747]]></appid><bank_type><![CDATA[CFT]]></bank_type><cash_fee><![CDATA[1]]></cash_fee><fee_type><![CDATA[CNY]]></fee_type><is_subscribe><![CDATA[N]]></is_subscribe><mch_id><![CDATA[1515042911]]></mch_id><nonce_str><![CDATA[1413295674]]></nonce_str><openid><![CDATA[ofb8d1EoXqodFwtLhokwPNoD9fn0]]></openid><out_trade_no><![CDATA[%@]]></out_trade_no><result_code><![CDATA[%@]]></result_code><return_code><![CDATA[%@]]></return_code><sign><![CDATA[DB2BF3C51556C890A57C720FC5F57A84]]></sign><time_end><![CDATA[%@]]></time_end><total_fee>%@</total_fee><trade_type><![CDATA[4]]></trade_type><transaction_id><![CDATA[4200000204201812047707944594]]></transaction_id><pay_flag><![CDATA[%@]]></pay_flag></xml>",out_trade_no,status,status,time_end,total_fee,pay_flag];
    [self postxml:xmlStr];
    
}
//join入直播间
- (void)joinroom{
    [[ILiveLoginManager getInstance] iLiveLogin:self.STindentifer sig:self.STuserSig succ:^{
        
        LiveRoomViewController *liveRoomVC = [[LiveRoomViewController alloc] init];
        
        // 2. 创建房间配置对象
        ILiveRoomOption *option = [ILiveRoomOption defaultHostLiveOption];
        option.imOption.imSupport = NO;
        // 不自动打开摄像头
        option.avOption.autoCamera = YES;
        // 不自动打开mic
        option.avOption.autoMic = YES;
        // 设置房间内音视频监听
        option.memberStatusListener = liveRoomVC;
        // 设置房间中断事件监听
        option.roomDisconnectListener = liveRoomVC;
        
        // 该参数代表进房之后使用什么规格音视频参数，参数具体值为客户在腾讯云实时音视频控制台画面设定中配置的角色名（例如：默认角色名为user, 可设置controlRole = @"user"）
        option.controlRole = @"user";
        
        // 3. 调用创建房间接口，传入房间ID和房间配置对象
        [[ILiveRoomManager getInstance] joinRoom:[self.STroomid  intValue]option:option succ:^{
            // 加入房间成功，跳转到房间页
//            [self presentViewController:liveRoomVC animated:YES completion:nil];
            [self.navigationController pushViewController:liveRoomVC animated:YES];
        } failed:^(NSString *module, int errId, NSString *errMsg) {
            // 加入房间失败
            NSLog(@"加入房间失败 errId:%d errMsg:%@",errId, errMsg);
        }];
        
    
    } failed:^(NSString *module, int errId, NSString *errMsg) {
        // 登录失败
        self.alertCtrl.title = @"加入失败";
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

#pragma mark - 获取当前时间
- (NSString *)getCurrenttime{
    //获取当前时间
    NSDate *date = [NSDate date];
    
    NSDateFormatter *formatter = [[NSDateFormatter alloc] init];
    
    [formatter setDateStyle:NSDateFormatterMediumStyle];
    
    [formatter setTimeStyle:NSDateFormatterShortStyle];
    
    [formatter setDateFormat:@"YYYYMMddHHmmss"];
    NSString *DateTime = [formatter stringFromDate:date];
    NSLog(@"当前时间是%@====当前时间是",DateTime);
    return DateTime;
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
