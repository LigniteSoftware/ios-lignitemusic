//
//  LMPurchaseManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <SecureNSUserDefaults/NSUserDefaults+SecureAdditions.h>
#import "LMPurchaseManager.h"
#import "LMPurchaseViewController.h"
#import "LMAnswers.h"

/**
 The key for storing the start time of the trial.
 */
#define LMPurchaseManagerTrialStartTimeKey @"AppleLibraryAccessPermission" //Disguise the contents

/**
 The interval of time in seconds for the purchase manager to check if the user has run out of time in their trial.
 */
#define LMPurchaseManagerTrialTimeCheckIntervalInSeconds 30.0

@interface LMPurchaseManager() <SKPaymentTransactionObserver, SKProductsRequestDelegate>

/**
 The array of delegates.
 */
@property NSMutableArray<id<LMPurchaseManagerDelegate>> *delegatesArray;

/**
 The user defaults.
 */
@property NSUserDefaults *userDefaults;

/**
 The timer for checking for the trial.
 */
@property NSTimer *trialCheckTimer;

/**
 The product currently being purchased.
 */
@property SKProduct *currentlyPurchasingProduct;

@end

@implementation LMPurchaseManager

@synthesize appOwnershipStatus = _appOwnershipStatus;


/*
 General code
 */

+ (LMPurchaseManager*)sharedPurchaseManager {
	static LMPurchaseManager *sharedPurchaseManager;
	static dispatch_once_t token;
	
	dispatch_once(&token, ^{
		sharedPurchaseManager = [self new];
		sharedPurchaseManager.delegatesArray = [NSMutableArray new];
		sharedPurchaseManager.userDefaults = [NSUserDefaults standardUserDefaults];
		sharedPurchaseManager.trialCheckTimer = [NSTimer scheduledTimerWithTimeInterval:LMPurchaseManagerTrialTimeCheckIntervalInSeconds
																				 target:sharedPurchaseManager
																			   selector:@selector(checkTrialTimeRemaining)
																			   userInfo:nil
																				repeats:YES];
		
		//Fire it after only 3 seconds to ensure no massive gap between launch and check
		[NSTimer scheduledTimerWithTimeInterval:3
										 target:sharedPurchaseManager
									   selector:@selector(checkTrialTimeRemaining)
									   userInfo:nil
										repeats:NO];
		
//		[sharedPurchaseManager.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialEmail];
//		[sharedPurchaseManager.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialPassword];
//		[sharedPurchaseManager.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialSessionToken];
		
		NSLog(@"The user currently has %f seconds left.", [sharedPurchaseManager amountOfTrialTimeRemainingInSeconds]);
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

- (NSString*)keyForProductIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	if([productIdentifier isEqualToString:LMPurchaseManagerProductIdentifierLifetimeMusic]){
		return LMPurchaseManagerProductKeyLifetimeMusic;
	}
	return @"AppleUnknownDeviceMetric";
}

- (void)completePurchaseForProductIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	//Alert delegates which are subscribed to appOwnershipStatusChanged: that the app ownership has changed to purchased
	if([productIdentifier isEqualToString:LMPurchaseManagerProductIdentifierLifetimeMusic]){
		for(id<LMPurchaseManagerDelegate> delegate in self.delegatesArray){
			if([delegate respondsToSelector:@selector(appOwnershipStatusChanged:)]){
				[delegate appOwnershipStatusChanged:LMPurchaseManagerAppOwnershipStatusPurchased];
			}
		}

	}
	
	[self.userDefaults setSecretBool:YES forKey:[self keyForProductIdentifier:productIdentifier]];
}

- (BOOL)userOwnsProductWithIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	BOOL ownsProduct = NO;
	
	NSString *productKey = [self keyForProductIdentifier:productIdentifier];
	
	if([self.userDefaults secretObjectForKey:productKey]){
		ownsProduct = [self.userDefaults secretBoolForKey:productKey];
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
		
		self.currentlyPurchasingProduct = product;
		
//		[LMAnswers logStartCheckoutWithPrice:product.price
//								  currency:product.priceLocale.currencyCode
//								 itemCount:@(1)
//						  customAttributes:@{ @"ProductIdentifier":product.productIdentifier }];
		
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

- (NSString*)productTypeForIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier {
	if([productIdentifier isEqualToString:LMPurchaseManagerProductIdentifierLifetimeMusic]){
		return @"Essential";
	}
	return @"Unknown";
}

- (void)paymentQueue:(SKPaymentQueue *)queue updatedTransactions:(NSArray *)transactions {
	for(SKPaymentTransaction *transaction in transactions){
		NSString *productIdentifier = transaction.payment.productIdentifier;
		SKPaymentTransactionState transactionState = transaction.transactionState;
		
		for(id<LMPurchaseManagerDelegate> delegate in self.delegatesArray){
			if([delegate respondsToSelector:@selector(transactionStateChangedTo:forProductWithIdentifier:)]){
				[delegate transactionStateChangedTo:transactionState
						   forProductWithIdentifier:productIdentifier];
			}
		}
	
		switch(transactionState){
			case SKPaymentTransactionStatePurchasing:
				NSLog(@"[LMPurchaseManager]: User is working on their purchase.");
				break;
			case SKPaymentTransactionStatePurchased: {
				NSLog(@"[LMPurchaseManager]: User made their purchase!");
				
				[[SKPaymentQueue defaultQueue] finishTransaction:transaction];
				
				[self completePurchaseForProductIdentifier:productIdentifier];
				
//				[LMAnswers logPurchaseWithPrice:self.currentlyPurchasingProduct.price
//									 currency:self.currentlyPurchasingProduct.priceLocale.currencyCode
//									  success:@YES
//									 itemName:self.currentlyPurchasingProduct.localizedTitle
//									 itemType:[self productTypeForIdentifier:productIdentifier]
//									   itemId:productIdentifier
//							 customAttributes:@{}];
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

- (NSTimeInterval)amountOfTrialTimeRemainingInSeconds {
	NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
		
	if([self.userDefaults secretObjectForKey:LMPurchaseManagerTrialStartTimeKey]){
		startTime = [self.userDefaults secretDoubleForKey:LMPurchaseManagerTrialStartTimeKey];
	}
	else{
		[self.userDefaults setSecretDouble:startTime forKey:LMPurchaseManagerTrialStartTimeKey];
		[self.userDefaults synchronize];
	}
	NSLog(@"The user's start of trial time was on %@.", [NSDate dateWithTimeIntervalSince1970:startTime]);
	
	NSTimeInterval currentTime = [[NSDate new] timeIntervalSince1970];
	
	NSTimeInterval timeDifferenceSinceStartOfTrial = currentTime-startTime;
	
	return (LMPurchaseManagerTrialLengthInSeconds-timeDifferenceSinceStartOfTrial);
}

- (LMPurchaseManagerAppOwnershipStatus)appOwnershipStatus {
//	NSLog(@"Checking ownership status...");
	//First check whether or not they own the app
	if([self userOwnsProductWithIdentifier:LMPurchaseManagerProductIdentifierLifetimeMusic]){
//		NSLog(@"The user has already purchased the app.");
		return LMPurchaseManagerAppOwnershipStatusPurchased;
	}
	
	//Then check if they're logged in as a backer
	if([self.userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialEmail]
	   && [self.userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialPassword]
	   && [self.userDefaults secretObjectForKey:LMPurchaseManagerKickstarterLoginCredentialSessionToken]){
		
//		NSLog(@"User is a backer.");
		
		return LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker;
	}
	
	//Then check their trial time
	NSTimeInterval amountOfTrialTimeRemaining = [self amountOfTrialTimeRemainingInSeconds];
	if(amountOfTrialTimeRemaining < 0){
//		NSLog(@"The user is out of trial time.");
		return LMPurchaseManagerAppOwnershipStatusTrialExpired;
	}
	
//	NSLog(@"The user is within the trial timeframe with %f seconds left.", amountOfTrialTimeRemaining);
	return LMPurchaseManagerAppOwnershipStatusInTrial;
}

- (void)checkTrialTimeRemaining {
//	NSLog(@"Checking trial time.");
	
	//If they already have access to the app, kill the constant checks for the trial ending.
	if(self.appOwnershipStatus == LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker
	   || self.appOwnershipStatus == LMPurchaseManagerAppOwnershipStatusPurchased){
		return;
	}
	
	NSTimeInterval amountOfTrialTimeRemaining = [self amountOfTrialTimeRemainingInSeconds];
	if(amountOfTrialTimeRemaining < 0){
		NSLog(@"The user is now out of trial time.");
		for(id<LMPurchaseManagerDelegate>delegate in self.delegatesArray){
			if([delegate respondsToSelector:@selector(appOwnershipStatusChanged:)]){
				[delegate appOwnershipStatusChanged:LMPurchaseManagerAppOwnershipStatusTrialExpired];
			}
		}
		[self.trialCheckTimer invalidate];
		self.trialCheckTimer = nil;
	}
	else{
//		NSLog(@"The user is still within the trial window.");
	}
}

- (void)showPurchaseViewControllerOnViewController:(UIViewController*)viewController present:(BOOL)present {
	LMPurchaseViewController *purchaseViewController  = [LMPurchaseViewController new];
	
	purchaseViewController.wasPresented = present;
	
	if(present) {
		[viewController presentViewController:purchaseViewController animated:YES completion:nil];
	}
	else{
		[viewController showViewController:purchaseViewController sender:self];
	}
}



/*
 End ownership code and begin backer code
 */

- (void)setBackerDetailsWithEmail:(NSString*)email password:(NSInteger)password sessionToken:(NSString*)sessionToken {
	if(password < 0){ //Logout
//		NSLog(@"Clearing details.");
		[self.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialEmail];
		[self.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialPassword];
		[self.userDefaults removeObjectForKey:LMPurchaseManagerKickstarterLoginCredentialSessionToken];
	}
	else{
//		NSLog(@"Setting details to secret defaults %@. (%@, %d, %@)", self.userDefaults, email, (int)password, sessionToken);
		[self.userDefaults setSecretObject:email forKey:LMPurchaseManagerKickstarterLoginCredentialEmail];
		[self.userDefaults setSecretInteger:password forKey:LMPurchaseManagerKickstarterLoginCredentialPassword];
		[self.userDefaults setSecretObject:sessionToken forKey:LMPurchaseManagerKickstarterLoginCredentialSessionToken];
	}
	
	[self.userDefaults synchronize];
	
	LMPurchaseManagerAppOwnershipStatus ownershipStatus = [self appOwnershipStatus];
	
	for(id<LMPurchaseManagerDelegate>delegate in self.delegatesArray){
		if([delegate respondsToSelector:@selector(appOwnershipStatusChanged:)]){
			[delegate appOwnershipStatusChanged:ownershipStatus];
		}
	}
}

- (void)logoutBacker {
	[self setBackerDetailsWithEmail:nil password:-1 sessionToken:nil];
}

@end
