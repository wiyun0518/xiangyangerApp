#import "MAIAPManager.h"
#import <StoreKit/StoreKit.h>
//#import "SVProgressHUD.h"
//#import "AFNetworking.h"

@interface MAIAPManager()<SKPaymentTransactionObserver,SKProductsRequestDelegate>
@property (nonatomic,strong) NSString *purchID;
@property (nonnull,strong) IAPCompletionHandle handle;
@property (strong, nonatomic)NSString *readString;


@end
@implementation MAIAPManager
#pragma mark - system lifecycle
- (instancetype)init{
    self = [super init];
    if (self) {
        
        [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    }
    return self;
}
- (void)dealloc{
    [[SKPaymentQueue defaultQueue] removeTransactionObserver:self];
}
#pragma mark - Public Method
- (void)MA_startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle{
//    [SVProgressHUD showProgress:-1 status:@"Loading"];
    if (purchID) {
        if ([SKPaymentQueue canMakePayments]) {
            self.purchID = purchID;
            self.handle = handle;
            NSSet *nsset = [NSSet setWithArray:@[purchID]];
            SKProductsRequest *request = [[SKProductsRequest alloc] initWithProductIdentifiers:nsset];
            request.delegate = self;
            self.MA_isBusy = YES;
            [request start];
        }else{
            [self MA_handleActionWithType:kIAPPurchNotArrow data:nil];
        }
    }
}

- (void) MA_restoreTransaction
{
//    [SVProgressHUD showWithStatus:@"Restore Transaction..."];
    self.MA_isBusy = YES;
    NSLog(@" 交易恢复处理");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
- (void)MA_restoreTransactionWithCompleteHandle:(IAPCompletionHandle)handle{
//    [SVProgressHUD showWithStatus:@"Restore Transaction..."];
    self.MA_isBusy = YES;
    self.handle = handle;
    NSLog(@" 交易恢复处理");
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}
#pragma mark - Private Method
- (void)MA_handleActionWithType:(IAPPurchType)type data:(NSData *)data{
    self.MA_isBusy = NO;
    if(self.handle){
        self.handle(type,data);
    }
}
- (void)MA_completeTransaction:(SKPaymentTransaction *)transaction{
    [self MA_verifyPurchaseWithPaymentTransaction:transaction isTestServer:NO Compl:^(NSDate *currentDate) {
    }];
}
- (void)MA_failedTransaction:(SKPaymentTransaction *)transaction{
    if (transaction.error.code != SKErrorPaymentCancelled) {
        [self MA_handleActionWithType:kIAPPurchFailed data:nil];
    }else{
        [self MA_handleActionWithType:kIAPPurchCancle data:nil];
    }
    [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
}
- (void)MA_verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag Compl:(void (^)(NSDate *))compl{
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if(!receipt){
        [self MA_handleActionWithType:KIAPPurchVerFailed data:nil];
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        return;
    }
    NSError *error;
    NSDictionary *requestContents = @{
                                      @"receipt-data": [receipt base64EncodedStringWithOptions:0],
                                      @"password":@"cae751d5eb754613afb88f8788345745"
                                      };
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents
                                                          options:0
                                                            error:&error];
    if (!requestData) {
        [self MA_handleActionWithType:KIAPPurchVerFailed data:nil];
        if (transaction) {
            [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
        }
        return;
    }
    NSString *serverString = @"https://buy.itunes.apple.com/verifyReceipt";
    if (flag) {
        serverString = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    NSURLSession *session = [NSURLSession sharedSession];
    [[session dataTaskWithRequest:storeRequest completionHandler:^(NSData * _Nullable data, NSURLResponse * _Nullable response, NSError * _Nullable error) {
        if (error) {
            [self MA_handleActionWithType:KIAPPurchVerFailed data:nil];
        } else {
            NSError *error;
            NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:data options:0 error:&error];
            if (!jsonResponse) {
                [self MA_handleActionWithType:KIAPPurchVerFailed data:nil];
            }
            NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
            if (status && [status isEqualToString:@"21007"]) {
                [self MA_verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES Compl:^(NSDate *currentDate) {
                }];
            }else if(status && [status isEqualToString:@"0"]){
//                NSDate *currentDate = [self MA_getCurrentDateFromResponse:jsonResponse];
//                NSDate *expiresDate = [self MA_expirationDateFromResponse:jsonResponse];
//                NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//                [userDefaults setObject:expiresDate forKey:@"expires_date"];
//                [userDefaults setObject:currentDate forKey:@"receipt_creation_date"];
//                [userDefaults synchronize];
//                if (currentDate&&expiresDate&&([[currentDate earlierDate:expiresDate] compare:currentDate]==NSOrderedSame)) {
//                    [self MA_handleActionWithType:KIAPPurchVerSuccess data:nil];
//                }else{
//                    [self MA_handleActionWithType:KIAPPurchVerFailed data:nil];
//                }
                
                [self MA_handleActionWithType:KIAPPurchVerSuccess data:nil];
            }else{
                [self MA_handleActionWithType:kIAPPurchFailed data:data];
            }
#if DEBUG
            NSLog(@"----验证结果 %@",jsonResponse);
#endif
        }
    }] resume];
    if (transaction) {
        [[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}
- (BOOL)MA_verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag{
    NSURL *recepitURL = [[NSBundle mainBundle] appStoreReceiptURL];
    NSData *receipt = [NSData dataWithContentsOfURL:recepitURL];
    if(!receipt){
        return NO;
    }
    NSError *error;
    NSDictionary *requestContents = @{@"receipt-data": [receipt base64EncodedStringWithOptions:0],@"password":@"f4af4ce7ba894417a30c2ee18314e4a8"};
    
    NSData *requestData = [NSJSONSerialization dataWithJSONObject:requestContents options:0 error:&error];
    if (!requestData) { 
        return NO;
    }
    NSString *serverString = @"https://buy.itunes.apple.com/verifyReceipt";
    if (flag) {
        serverString = @"https://sandbox.itunes.apple.com/verifyReceipt";
    }
    NSURL *storeURL = [NSURL URLWithString:serverString];
    NSMutableURLRequest *storeRequest = [NSMutableURLRequest requestWithURL:storeURL];
    [storeRequest setHTTPMethod:@"POST"];
    [storeRequest setHTTPBody:requestData];
    NSURLResponse *resp;
    NSError *sessionErr;
    NSData *backData = [self MA_sendSynchronousRequest:storeRequest returningResponse:&resp error:&sessionErr];
    if (sessionErr) {
        return NO;
    } else {
        NSError *error;
        NSDictionary *jsonResponse = [NSJSONSerialization JSONObjectWithData:backData options:0 error:&error];
        if (!jsonResponse) {
            return NO;
        }
        NSString *status = [NSString stringWithFormat:@"%@",jsonResponse[@"status"]];
        if (status && [status isEqualToString:@"21007"]) {
            return [self MA_verifyPurchaseWithPaymentTransaction:transaction isTestServer:YES];
        }else if(status && [status isEqualToString:@"0"]){
//
            
             [self MA_handleActionWithType:KIAPPurchVerSuccess data:nil];
        }else{
            return NO;
        }
    }
    return NO;
}
#pragma mark ----------> SKProductsRequestDelegate
- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
    NSArray *product = response.products;
    
    if([product count] <= 0){
#if DEBUG
        NSLog(@"--------------没有商品------------------");
#endif
        [self MA_handleActionWithType:kIAPPurchFailed data:nil];
        return;
    }
    SKProduct *p = nil;
    for(SKProduct *pro in product){
        if([pro.productIdentifier isEqualToString:self.purchID]){
            p = pro;
            break;
        }
    }
    
    NSString *price = @"";
    
    if ([p price] == NULL || [p price] == nil) {
        
        
    }else{
        price = [NSString stringWithFormat:@"%@",[p price]];
    }
    
    NSString *productStr = @"";
    
    if ([p productIdentifier] == NULL || [p productIdentifier] == nil) {
        
        
    }else{
        productStr = [NSString stringWithFormat:@"%@",[p productIdentifier]];
    }
    
//    [FBSDKAppEvents logEvent:FBSDKAppEventNameAddedToCart
//                  valueToSum:[[p price] floatValue]
//                  parameters:@{ FBSDKAppEventParameterNameCurrency    : @"USD",
//                                FBSDKAppEventParameterNameContentType : @"product",
//                                FBSDKAppEventParameterNameContent     : [NSString stringWithFormat:@"[{\"price\":%@, \"productIdentifier\": %@}]",price,productStr] } ];
    
    
#if DEBUG
    NSLog(@"productID:%@", response.invalidProductIdentifiers);
    NSLog(@"产品付费数量:%lu",(unsigned long)[product count]);
    NSLog(@"%@",[p description]);
    NSLog(@"%@",[p localizedTitle]);
    NSLog(@"%@",[p localizedDescription]);
    NSLog(@"%@",[p price]);
    NSLog(@"%@",[p productIdentifier]);
    NSLog(@"发送购买请求");
    
#endif
    SKPayment *payment = [SKPayment paymentWithProduct:p];
    [[SKPaymentQueue defaultQueue] addPayment:payment];
}
- (void)request:(SKRequest *)request didFailWithError:(NSError *)error{
#if DEBUG
    NSLog(@"------------------错误-----------------:%@", error);
#endif
    [self MA_handleActionWithType:kIAPPurchFailed data:nil];
}
- (void)requestDidFinish:(SKRequest *)request{
#if DEBUG
    NSLog(@"------------反馈信息结束-----------------");
#endif
}
#pragma mark --------> SKPaymentTransactionObserver
//队列操作后的回调
- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray<SKPaymentTransaction *> *)transactions{
    for (SKPaymentTransaction *tran in transactions) {
        switch (tran.transactionState) {
            case SKPaymentTransactionStatePurchased:
//                [SVProgressHUD showProgress:-1 status:@"Paying"];
                
                [self MA_completeTransaction:tran];
                break;
            case SKPaymentTransactionStatePurchasing:
                break;
            case SKPaymentTransactionStateRestored:
                [self MA_verifyPurchaseWithPaymentTransaction:tran isTestServer:NO];
                [[SKPaymentQueue defaultQueue] finishTransaction:tran];
                break;
            case SKPaymentTransactionStateFailed:
                [self MA_failedTransaction:tran];
                break;
            default:
                break;
        }
    }
}
//恢复购买结束回调
- (void) paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    [self MA_verifyPurchaseWithPaymentTransaction:nil isTestServer:NO Compl:^(NSDate *currentDate) {
    }];
}
//恢复购买失败
- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error{
    NSLog(@"xin:: restore fail...");
    [self MA_handleActionWithType:kIAPPurchFailed data:nil];
}
#pragma mark - date   setting
- (NSDate *)MA_expirationDateFromResponse:(NSDictionary *)jsonResponse{
    NSArray* receiptInfo = jsonResponse[@"latest_receipt_info"];
    if(receiptInfo){
        NSDictionary* lastReceipt = receiptInfo.lastObject;
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss VV";
        NSDate* expirationDate  = [formatter dateFromString:lastReceipt[@"expires_date"]];
        return expirationDate;
    } else {
        return nil;
    }
}
- (NSDate *)MA_getCurrentDateFromResponse:(NSDictionary *)jsonResponse{
    NSDictionary* receipt = jsonResponse[@"receipt"];
    if(receipt){
        NSDateFormatter* formatter = [[NSDateFormatter alloc] init];
        formatter.dateFormat = @"yyyy-MM-dd HH:mm:ss VV";
        NSDate* expirationDate  = [formatter dateFromString:receipt[@"request_date"]];
        return expirationDate;
    } else {
        return nil;
    }
}
#pragma mark - session sys
- (NSData *)MA_sendSynchronousRequest:(NSURLRequest *)request returningResponse:(NSURLResponse **)response error:(NSError **)error
{
    NSError __block *err = NULL;
    NSData __block *data;
    BOOL __block reqProcessed = false;
    NSURLResponse __block *resp;
    [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData * _Nullable _data, NSURLResponse * _Nullable _response, NSError * _Nullable _error) {
        resp = _response;
        err = _error;
        data = _data;
        reqProcessed = true;
    }] resume];
    while (!reqProcessed) {
        [NSThread sleepForTimeInterval:0];
    }
    *response = resp;
    *error = err;
    return data;
}


-(BOOL)MA_isBusy{
    
    return _MA_isBusy;
    
    
}



@end
