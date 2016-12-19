//
//  LMPurchaseManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The length of the whole app trial in seconds.
 */
//#define LMPurchaseManagerTrialLengthInSeconds 259200
#define LMPurchaseManagerTrialLengthInSeconds 10

typedef NSString LMPurchaseManagerProductIdentifier;

@protocol LMPurchaseManagerDelegate <NSObject>
@optional

/**
 The user purchased a product with a certain idenfier.

 @param productIdentifier The product identifier which links to the product purchased.
 */
- (void)userPurchasedProductWithIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier;

/**
 The user has run out of trial time.
 */
- (void)userHasRunOutOfTrialTime;

@end

@interface LMPurchaseManager : NSObject

/**
 Returns the application's shared purchase manager.

 @return The shared purchase manager.
 */
+ (LMPurchaseManager*)sharedPurchaseManager;

/**
 Adds a delegate to the list of delegates.

 @param delegate The delegate to add.
 */
- (void)addDelegate:(id<LMPurchaseManagerDelegate>)delegate;

/**
 Removes a delegate from the list of delegates.

 @param delegate The delegate to remove.
 */
- (void)removeDelegate:(id<LMPurchaseManagerDelegate>)delegate;

/**
 Returns whether or not a user owns a product with a certain identifier for that product.

 @param productIdentifier The product identifier to check for.
 @return Whether or not the user owns the product.
 */
- (BOOL)userOwnsProductWithIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier;

/**
 Starts the purchase product for a product with a certain identifier.

 @param productIdentifier The product identifier to start the purchase for.
 */
- (void)makePurchaseWithProductIdentifier:(LMPurchaseManagerProductIdentifier*)productIdentifier;

/**
 Whether or not the user is has access to the app. Should the user does not have access if they have run out of trial time and not purchased the app. Though, a user who is within the trial period or has purchased it does.
 */
@property (readonly) BOOL userHasAccessToTheApp;

@end
