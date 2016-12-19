//
//  LMPurchaseManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <SecureNSUserDefaults/NSUserDefaults+SecureAdditions.h>
#import <StoreKit/StoreKit.h>
#import "LMPurchaseManager.h"

/**
 The product identifier for lifetime access to the app.
 */
#define LMPurchaseManagerProductIdentifierLifetimeMusic @"lignite.io.music.LifetimeMusic"

/**
 The key for storing the start time of the trial.
 */
#define LMPurchaseManagerTrialStartTimeKey @"LMPurchaseManagerTrialStartTimeKey"

@interface LMPurchaseManager() <SKPaymentTransactionObserver, SKProductsRequestDelegate>

/**
 The array of delegates.
 */
@property NSMutableArray<id<LMPurchaseManagerDelegate>> *delegatesArray;

/**
 The user defaults.
 */
@property NSUserDefaults *userDefaults;

@end

@implementation LMPurchaseManager

@synthesize userHasAccessToTheApp = _userHasAccessToTheApp;


/*
 General code
 */

+ (id)sharedPurchaseManager {
	static LMPurchaseManager *sharedPurchaseManager;
	static dispatch_once_t token;
	
	dispatch_once(&token, ^{
		sharedPurchaseManager = [self new];
		sharedPurchaseManager.userDefaults = [NSUserDefaults standardUserDefaults];
	});
	
	return sharedPurchaseManager;
}

- (void)addDelegate:(id<LMPurchaseManagerDelegate>)delegate {
	[self.delegatesArray addObject:delegate];
}

- (void)removeDelegate:(id<LMPurchaseManagerDelegate>)delegate {
	[self.delegatesArray removeObject:delegate];
}



/*
 End general code and begin purchase management code
 */

- (void)completePurchaseForProductIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	for(id<LMPurchaseManagerDelegate> delegate in self.delegatesArray){
		[delegate userPurchasedProductWithIdentifier:productIdentifier];
	}
}

- (BOOL)userOwnsProductWithIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	BOOL ownsProduct = NO;
	
	if([self.userDefaults secretObjectForKey:productIdentifier]){
		ownsProduct = [self.userDefaults secretBoolForKey:productIdentifier];
	}
	
	return ownsProduct;
}

- (void)makePurchaseWithProductIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	NSLog(@"[LMPurchaseManager]: User wants to make purchase for product identifier '%@'.", productIdentifier);
	
	if([SKPaymentQueue canMakePayments]){
		NSLog(@"[LMPurchaseManager]: User is able to make payments.");
		
		SKProductsRequest *productsRequest = [[SKProductsRequest alloc] initWithProductIdentifiers:[NSSet setWithObject:productIdentifier]];
		productsRequest.delegate = self;
		
		[productsRequest start];
	}
	else{
		NSLog(@"[LMPurchaseManager]: User cannot make payments, likely due to parental controls.");
	}
}

- (void)productsRequest:(SKProductsRequest *)request didReceiveResponse:(SKProductsResponse *)response{
	for(SKProduct *product in response.products){
		NSLog(@"[LMPurchaseManager]: Valid product '%@', beginning process.", product.productIdentifier);
		
		[self purchaseProduct:product];
	}
	
	if(response.products.count == 0){
		NSLog(@"[LMPurchaseManager]: No valid products available.");
	}
}

- (void)purchaseProduct:(SKProduct *)product{
	SKPayment *payment = [SKPayment paymentWithProduct:product];
	
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	[[SKPaymentQueue defaultQueue] addPayment:payment];
}

- (void)restorePurchases {
	NSLog(@"[LMPurchaseManager]: Beginning restore process.");
	
	[[SKPaymentQueue defaultQueue] addTransactionObserver:self];
	[[SKPaymentQueue defaultQueue] restoreCompletedTransactions];
}

- (void)paymentQueueRestoreCompletedTransactionsFinished:(SKPaymentQueue *)queue{
	NSLog(@"[LMPurchaseManager]: Got %lu restored transactions.", (unsigned long)queue.transactions.count);
	
	for(SKPaymentTransaction *transaction in queue.transactions){
		if(transaction.transactionState == SKPaymentTransactionStateRestored){
			NSLog(@"[LMPurchaseManager]: Purchase fully restored.");
			
			[self completePurchaseForProductIdentifier:transaction.payment.productIdentifier];

			[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
			break;
		}
	}
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions{
	for(SKPaymentTransaction *transaction in transactions){
		switch(transaction.transactionState){
			case SKPaymentTransactionStatePurchasing:
				NSLog(@"[LMPurchaseManager]: User is working on their purchase.");
				break;
			case SKPaymentTransactionStatePurchased: {
				NSLog(@"[LMPurchaseManager]: User made their purchase!");
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				
				[self completePurchaseForProductIdentifier:transaction.payment.productIdentifier];
				break;
			}
			case SKPaymentTransactionStateRestored:
				NSLog(@"[LMPurchaseManager]: User restored their purchase.");
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			case SKPaymentTransactionStateFailed:
				if(transaction.error.code == SKErrorPaymentCancelled){
					NSLog(@"[LMPurchaseManager]: User cancelled their purchase.");
				}
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				break;
			case SKPaymentTransactionStateDeferred:
				NSLog(@"[LMPurchaseManager]: User was deferred");
				break;
		}
	}
}



/*
 End purchase code and begin ownership code
 */

- (BOOL)userHasAccessToTheApp {
	//First check whether or not they own the app
	if([self userOwnsProductWithIdentifier:LMPurchaseManagerProductIdentifierLifetimeMusic]){
		NSLog(@"The user has already purchased the app.");
		return YES;
	}
	
	//Otherwise check their remaining trial time
	NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
	if([self.userDefaults secretObjectForKey:LMPurchaseManagerTrialStartTimeKey]){
		startTime = [self.userDefaults secretDoubleForKey:LMPurchaseManagerTrialStartTimeKey];
	}
	NSLog(@"The user's start of trial time was on %@.", [NSDate dateWithTimeIntervalSince1970:startTime]);
	
	NSTimeInterval currentTime = [[NSDate new]timeIntervalSince1970];
	
	NSTimeInterval timeDifferenceSinceStartOfTrial = currentTime-startTime;
	if(timeDifferenceSinceStartOfTrial > LMPurchaseManagerTrialLengthInSeconds){
		NSLog(@"The user is out of trial time.");
		return NO;
	}
	
	NSLog(@"The user is within the trial timeframe with %f seconds left.", (LMPurchaseManagerTrialLengthInSeconds-timeDifferenceSinceStartOfTrial));
	return YES;
}

@end
