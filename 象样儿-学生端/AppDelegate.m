//
//  AppDelegate.m
//  象样儿-学生端
//
//  Created by 海海 on 2018/7/7.
//  Copyright © 2018年 海学明. All rights reserved.
//

#import "AppDelegate.h"
#import <ILiveSDK/ILiveSDK.h>
#import "ViewController.h"
//static  const int kSDKAppID = 1400102667;
//static  const int kAccountType = 29179;
#define ShowAppId       @"1400118575"

#define ShowAccountType @"29179"
@interface AppDelegate ()

@end

@implementation AppDelegate


- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {
    [[UIApplication sharedApplication] setStatusBarStyle:UIStatusBarStyleBlackTranslucent];
//    [[UIApplication sharedApplication].sta
    
    ViewController *vc = [[ViewController alloc] init];
    UINavigationController *naV = [[UINavigationController alloc]initWithRootViewController:vc];
    self.window.rootViewController = naV;
    
    [self.window makeKeyAndVisible];
// 初始化SDK
//    [[ILiveSDK getInstance] initSdk:[self.ShowAppId intValue] accountType:[self.ShowAccountType intValue]];
    [[ILiveSDK getInstance] initSdk:[ShowAppId intValue] accountType:[ShowAccountType intValue]];
    return YES;
}


- (BOOL)application:(UIApplication *)app openURL:(NSURL *)url options:(NSDictionary<UIApplicationOpenURLOptionsKey,id> *)options{
    NSString *urlStr = [NSString stringWithFormat:@"%@",url];
    if ([urlStr rangeOfString:@"app.xiangyanger.com"].location != NSNotFound) {
        
    }
    return YES;
}



- (void)applicationWillResignActive:(UIApplication *)application {
    // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
    // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
}


- (void)applicationDidEnterBackground:(UIApplication *)application {
    // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
    // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
}


- (void)applicationWillEnterForeground:(UIApplication *)application {
    // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
}


- (void)applicationDidBecomeActive:(UIApplication *)application {
    // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
}


- (void)applicationWillTerminate:(UIApplication *)application {
    // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
}


@end
