
#import <Foundation/Foundation.h>
#import <StoreKit/StoreKit.h>

#import "NSData+Base64.h"

#import "SKProduct+LocalizedPrice.h"

@class InAppPurchase;

@protocol InAppPurchaseDelegate <NSObject>
@required
    // called when load function fails for some reason
    -(void)InAppPurchase:(InAppPurchase*)inAppPurchase onLoadFailedWithError:(NSString*)error;

    // called when app store request fails for some reason. error description is in error
    -(void)InAppPurchase:(InAppPurchase*)inAppPurchase onRequestFailedWithError:(NSError*)error;

    // called as result of load function - returns which products are valid and info about them in validProducts. invalid product id's returned in inValidProducts
    // validProducts is array of NSDictionary (strings, can be NSNull):
    //"id" - product ID
    // "title" - product title  from appstore
    // "description" - product description from appstore
    // "price" - localized product price from appstore
    -(void)InAppPurchase:(InAppPurchase*)inAppPurchase listOfValidProducts:(NSArray*)validProducts listOfInvalidProducts:(NSArray*)inValidProducts;


    // called when transaction state is updated. transaction contains:
    // "state" - state of the transaction. can be "", "PaymentTransactionStatePurchased", "PaymentTransactionStateFailed" or PaymentTransactionStateRestored ,
    // "errorCode" - NSNumber with integer error code,
    // "error" - NSString with error description,
    // "transactionIdentifier" - NSString identifier of the transaction,
    // "productId" - NSString product ID
    // "transactionDate" - NSNumber with double value of timeIntervalSince1970
    -(void)InAppPurchase:(InAppPurchase*)inAppPurchase onTransactionUpdated:(NSDictionary*)transaction;


    // called if restoring purchases failed
    -(void)InAppPurchase:(InAppPurchase*)inAppPurchase restoreCompletedTransactionsFailedWithError:(NSError *)error;

    // called if restoring purchases succeeded
    -(void)InAppPurchaseFinishedRestoringCompletedTransactions:(InAppPurchase*)inAppPurchase;
@end



@interface InAppPurchase : NSObject <SKPaymentTransactionObserver> 

    @property (nonatomic,retain) NSMutableDictionary *products;//key is NSString* - name of a product and value is SKProduct* for this product
    @property (nonatomic,retain) NSMutableDictionary *retainer;//just to retain objects - add it to this list
    @property (nonatomic,retain) id<InAppPurchaseDelegate> delegate;

    // designated initializer
    -(id)initWithDelegate:(id<InAppPurchaseDelegate>)delegate;// setup the inAppPurchase - call it before anything else

    - (void)load: (NSArray*)productIDs;//Request product data for the given productIDs (array of NSString*).

    - (void)purchase:(NSString*)identifier quantity:(NSInteger)quantity;

    - (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions;
    - (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error;
    - (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue;

@end


@interface BatchProductsRequestDelegate : NSObject <SKProductsRequestDelegate>

    @property (nonatomic,retain) InAppPurchase* inAppPurchase;

@end;
