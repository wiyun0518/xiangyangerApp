#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

typedef enum {
    kIAPPurchSuccess = 0,       // 购买成功
    kIAPPurchFailed = 1,        // 购买失败
    kIAPPurchCancle = 2,        // 取消购买
    KIAPPurchVerFailed = 3,     // 订单校验失败
    KIAPPurchVerSuccess = 4,    // 订单校验成功
    kIAPPurchNotArrow = 5,      // 不允许内购
}IAPPurchType;
typedef void (^IAPCompletionHandle)(IAPPurchType type,NSData *data);
@interface MAIAPManager : NSObject
@property (nonatomic, assign) BOOL MA_isBusy;
//开始购买
- (void)MA_startPurchWithID:(NSString *)purchID completeHandle:(IAPCompletionHandle)handle;
//恢复购买
- (void)MA_restoreTransactionWithCompleteHandle:(IAPCompletionHandle)handle;

- (void)MA_verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag Compl:(void(^)(NSDate *currentDate))compl;
- (BOOL)MA_verifyPurchaseWithPaymentTransaction:(SKPaymentTransaction *)transaction isTestServer:(BOOL)flag;
@end
