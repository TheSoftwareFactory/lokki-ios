
#import "InAppPurchase.h"

#define NILABLE(obj) ((obj) != nil ? (NSObject *)(obj) : (NSObject *)[NSNull null])

#ifdef DEBUG
    static BOOL g_debugLogEnabled = YES;
#else 
    static BOOL g_debugLogEnabled = NO;
#endif

#define DLog(fmt, ...) { \
    if (g_debugLogEnabled) \
        NSLog((@"InAppPurchase[objc]: " fmt), ##__VA_ARGS__); \
}

// To avoid compilation warning, declare JSONKit and SBJson's
// category methods without including their header files.
@interface NSArray (StubsForSerializers)
- (NSString *)JSONString;
- (NSString *)JSONRepresentation;
@end

// Helper category method to choose which JSON serializer to use.
@interface NSArray (JSONSerialize)
- (NSString *)JSONSerialize;
@end

@implementation NSArray (JSONSerialize)
- (NSString *)JSONSerialize {
    return [self respondsToSelector:@selector(JSONString)] ? [self JSONString] : [self JSONRepresentation];
}
@end

@implementation InAppPurchase


-(id)initWithDelegate:(id<InAppPurchaseDelegate>)delegate {
    self = [super init];
    self.products = [[NSMutableDictionary alloc] init];
    self.retainer = [[NSMutableDictionary alloc] init];
    self.delegate = delegate;
    [[SKPaymentQueue defaultQueue] addTransactionObserver:self];
    return self;
}

/**
 * Request product data for the given productIds.
 */
- (void) load: (NSArray*)productIDs
{
	DLog(@"Getting products data");

    if ((unsigned long)[productIDs count] == 0) {
        DLog(@"Empty array");
        [self.delegate InAppPurchase:self onLoadFailedWithError:@"Empty list"];
        return;
    }

    if (![[productIDs objectAtIndex:0] isKindOfClass:[NSString class]]) {
        DLog(@"Not an array of NSString");
        [self.delegate InAppPurchase:self onLoadFailedWithError:@"Not an array of NSString"];
        return;
    }
    
    NSSet *productIdentifiers = [NSSet setWithArray:productIDs];
    DLog(@"Set has %li elements", (unsigned long)[productIdentifiers count]);
    for (NSString *item in productIdentifiers) {
        DLog(@" - %@", item);
    }
    SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:productIdentifiers];

    BatchProductsRequestDelegate* delegate = [[BatchProductsRequestDelegate alloc] init];
    productsRequest.delegate = delegate;
    delegate.inAppPurchase  = self;

    self.retainer[@"productsRequest"] = productsRequest;
    self.retainer[@"productsRequestDelegate"] = delegate;

    DLog(@"Starting product request...");
    [productsRequest start];
    DLog(@"Product request started");
}

- (void)purchase:(NSString*)identifier quantity:(NSInteger)quantity
{
	DLog(@"About to do IAP with ID: %@ and quantity: %d", identifier, (int)quantity);

    SKMutablePayment *payment = [SKMutablePayment paymentWithProduct:[self.products objectForKey:identifier]];
    payment.quantity = quantity;
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void) restoreCompletedTransactions
{
    [[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

// SKPaymentTransactionObserver methods
// called when the transaction status is updated
//
- (void)paymentQueue:(SKPaymentQueue*)queue updatedTransactions:(NSArray*)transactions
{
	NSString *state, *error, *transactionIdentifier, *transactionDate, *productId;//*transactionReceipt
	NSInteger errorCode;

    for (SKPaymentTransaction *transaction in transactions)
    {
		error = state = transactionIdentifier = transactionDate = productId = @"";
        //transactionReceipt = @"";
		errorCode = 0;
        DLog(@"Payment transaction updated:");

        switch (transaction.transactionState)
        {
			case SKPaymentTransactionStatePurchasing:
				DLog(@"Purchasing...");
				continue;

            case SKPaymentTransactionStatePurchased:
				state = @"PaymentTransactionStatePurchased";
				transactionIdentifier = transaction.transactionIdentifier;
				//transactionReceipt = [[transaction transactionReceipt] base64EncodedString];
                transactionDate = [NSString stringWithFormat:@"%f", transaction.transactionDate.timeIntervalSince1970];
				productId = transaction.payment.productIdentifier;
                break;

			case SKPaymentTransactionStateFailed:
				state = @"PaymentTransactionStateFailed";
				error = transaction.error.localizedDescription;
				errorCode = transaction.error.code;
				DLog(@"Error %d %@", (int)errorCode, error);
                break;

			case SKPaymentTransactionStateRestored:
				state = @"PaymentTransactionStateRestored";
				transactionIdentifier = transaction.originalTransaction.transactionIdentifier;
				//transactionReceipt = [[transaction transactionReceipt] base64EncodedString];
                transactionDate = [NSString stringWithFormat:@"%f", transaction.transactionDate.timeIntervalSince1970];
				productId = transaction.originalTransaction.payment.productIdentifier;
                break;

            default:
				DLog(@"Invalid state");
                continue;
        }
		DLog(@"State: %@", state);
        NSDictionary* dict = @{
            @"state" : NILABLE(state),
            @"errorCode" : [NSNumber numberWithInt:(int)errorCode],
            @"error" : NILABLE(error),
            @"transactionIdentifier" : NILABLE(transactionIdentifier),
            @"productId" : NILABLE(productId),
            @"transactionDate" : [NSNumber numberWithDouble:transaction.transactionDate.timeIntervalSince1970]
            //@"transactionReceipt" : NILABLE(transactionReceipt)
        };
        DLog(@"Sending to delegate: %@", dict);
        [self.delegate InAppPurchase:self onTransactionUpdated:dict];
		[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
    }
}

- (void)paymentQueue:(SKPaymentQueue *)queue restoreCompletedTransactionsFailedWithError:(NSError *)error
{
    DLog(@"restoreCompletedTransactionsFailedWithError: %@", error);
    [self.delegate InAppPurchase:self restoreCompletedTransactionsFailedWithError:error];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue
{
    DLog(@"paymentQueueRestoreCompletedTransactionsFinished");
    [self.delegate InAppPurchaseFinishedRestoringCompletedTransactions:self];
}

@end

/**
 * Receives product data for multiple productIds and passes arrays of
 * js objects containing these data to a single callback method.
 */
@implementation BatchProductsRequestDelegate

- (void)productsRequest:(SKProductsRequest*)request didReceiveResponse:(SKProductsResponse*)response {

    DLog(@"productsRequest: didReceiveResponse:");
    NSMutableArray *validProducts = [NSMutableArray array];
    DLog(@"Has %li validProducts", (unsigned long)[response.products count]);
	for (SKProduct *product in response.products) {
        DLog(@" - %@: %@", product.productIdentifier, product.localizedTitle);
        [validProducts addObject:
         [NSDictionary dictionaryWithObjectsAndKeys:
          NILABLE(product.productIdentifier),    @"id",
          NILABLE(product.localizedTitle),       @"title",
          NILABLE(product.localizedDescription), @"description",
          NILABLE(product.localizedPrice),       @"price",
          nil]];
        [self.inAppPurchase.products setObject:product forKey:[NSString stringWithFormat:@"%@", product.productIdentifier]];
    }

    [self.inAppPurchase.delegate InAppPurchase:self.inAppPurchase listOfValidProducts:validProducts listOfInvalidProducts:response.invalidProductIdentifiers];
    

    // For some reason, the system needs to send more messages to the productsRequestDelegate after this.
    // However, it doesn't retain it which causes a crash!
    // That's why we need keep references to the productsRequest[Delegate] objects...
    // It's no big thing anyway, and it's a one time thing.
    // [self.plugin.retainer removeObjectForKey:@"productsRequest"];
    // [self.plugin.retainer removeObjectForKey:@"productsRequestDelegate"];
}

- (void)request:(SKRequest *)request didFailWithError:(NSError *)error
{
    DLog(@"In-App Store unavailable (ERROR %i)", (int)error.code);
    DLog(@"%@", [error localizedDescription]);
    [self.inAppPurchase.delegate InAppPurchase:self.inAppPurchase onRequestFailedWithError:error];
}

@end
