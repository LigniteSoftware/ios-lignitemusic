//
//  LMPurchaseManager.h
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

/**
 The product identifier for lifetime access to the app.
 */
#define LMPurchaseManagerProductIdentifierLifetimeMusic @"lignite.io.music.LifetimeMusic"

/**
 The length of the whole app trial in seconds.
 */
//#define LMPurchaseManagerTrialLengthInSeconds 259200
#define LMPurchaseManagerTrialLengthInSeconds 10

typedef NSString LMPurchaseManagerProductIdentifier;

typedef enum {
	LMPurchaseManagerAppOwnershipStatusInTrial = 0, //The user is still within the 3 day trial period
	LMPurchaseManagerAppOwnershipStatusTrialExpired, //The user has run out of trial time and doesn't own the app at all
	LMPurchaseManagerAppOwnershipStatusPurchased, //The user has purchased the app
	LMPurchaseManagerAppOwnershipStatusLoggedInAsBacker //The user is a backer and is logged in
} LMPurchaseManagerAppOwnershipStatus;

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
- (void)appOwnershipStatusChanged:(LMPurchaseManagerAppOwnershipStatus)newOwnershipStatus;

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
 The amount of trial time remaining in seconds.

 @return The amount of trial time.
 */
- (NSTimeInterval)amountOfTrialTimeRemainingInSeconds;

/**
 Shows the purchase view controller on a certain view controller. Optionally presented so it can take over the whole screen.

 @param viewController The view controller to show the purchase view controller on top of.
 @param present Whether or not to present the purchase view controller.
 */
- (void)showPurchaseViewControllerOnViewController:(UIViewController*)viewController present:(BOOL)present;

/**
 The status of the user's ownership of the app.
 */
@property (readonly) LMPurchaseManagerAppOwnershipStatus appOwnershipStatus;

@end
