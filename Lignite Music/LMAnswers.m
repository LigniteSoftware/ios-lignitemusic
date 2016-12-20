//
//  LMAnswers.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/20/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMAnswers.h"
#import "LMSettings.h"

@implementation LMAnswers

+ (void)logSignUpWithMethod:(nullable NSString *)signUpMethodOrNil
					success:(nullable NSNumber *)signUpSucceededOrNil
		   customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil{
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logSignUpWithMethod:signUpMethodOrNil
					   success:signUpSucceededOrNil
			  customAttributes:customAttributesOrNil];
}

+ (void)logLoginWithMethod:(nullable NSString *)loginMethodOrNil
				   success:(nullable NSNumber *)loginSucceededOrNil
		  customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logLoginWithMethod:loginMethodOrNil
					  success:loginSucceededOrNil
			 customAttributes:customAttributesOrNil];
}

+ (void)logShareWithMethod:(nullable NSString *)shareMethodOrNil
			   contentName:(nullable NSString *)contentNameOrNil
			   contentType:(nullable NSString *)contentTypeOrNil
				 contentId:(nullable NSString *)contentIdOrNil
		  customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logShareWithMethod:shareMethodOrNil
				  contentName:contentNameOrNil
				  contentType:contentTypeOrNil
					contentId:contentIdOrNil
			 customAttributes:customAttributesOrNil];
}

+ (void)logInviteWithMethod:(nullable NSString *)inviteMethodOrNil
		   customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	[super logInviteWithMethod:inviteMethodOrNil
			 customAttributes:customAttributesOrNil];
}

+ (void)logPurchaseWithPrice:(nullable NSDecimalNumber *)itemPriceOrNil
					currency:(nullable NSString *)currencyOrNil
					 success:(nullable NSNumber *)purchaseSucceededOrNil
					itemName:(nullable NSString *)itemNameOrNil
					itemType:(nullable NSString *)itemTypeOrNil
					  itemId:(nullable NSString *)itemIdOrNil
			customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logPurchaseWithPrice:itemPriceOrNil
					   currency:currencyOrNil
						success:purchaseSucceededOrNil
					   itemName:itemNameOrNil
					   itemType:itemTypeOrNil
						 itemId:itemIdOrNil
			   customAttributes:customAttributesOrNil];
}

+ (void)logLevelStart:(nullable NSString *)levelNameOrNil
	 customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logLevelStart:levelNameOrNil
		customAttributes:customAttributesOrNil];
}

+ (void)logLevelEnd:(nullable NSString *)levelNameOrNil
			  score:(nullable NSNumber *)scoreOrNil
			success:(nullable NSNumber *)levelCompletedSuccesfullyOrNil
   customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logLevelEnd:levelNameOrNil
				 score:scoreOrNil
			   success:levelCompletedSuccesfullyOrNil
	  customAttributes:customAttributesOrNil];
}

+ (void)logAddToCartWithPrice:(nullable NSDecimalNumber *)itemPriceOrNil
					 currency:(nullable NSString *)currencyOrNil
					 itemName:(nullable NSString *)itemNameOrNil
					 itemType:(nullable NSString *)itemTypeOrNil
					   itemId:(nullable NSString *)itemIdOrNil
			 customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logAddToCartWithPrice:itemPriceOrNil
						currency:currencyOrNil
						itemName:itemNameOrNil
						itemType:itemTypeOrNil
						  itemId:itemIdOrNil
				customAttributes:customAttributesOrNil];
}

+ (void)logStartCheckoutWithPrice:(nullable NSDecimalNumber *)totalPriceOrNil
						 currency:(nullable NSString *)currencyOrNil
						itemCount:(nullable NSNumber *)itemCountOrNil
				 customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
}

+ (void)logRating:(nullable NSNumber *)ratingOrNil
	  contentName:(nullable NSString *)contentNameOrNil
	  contentType:(nullable NSString *)contentTypeOrNil
		contentId:(nullable NSString *)contentIdOrNil
 customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logRating:ratingOrNil
		 contentName:contentNameOrNil
		 contentType:contentTypeOrNil
		   contentId:contentIdOrNil
	customAttributes:customAttributesOrNil];
}


+ (void)logContentViewWithName:(nullable NSString *)contentNameOrNil
				   contentType:(nullable NSString *)contentTypeOrNil
					 contentId:(nullable NSString *)contentIdOrNil
			  customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logContentViewWithName:contentNameOrNil
					  contentType:contentTypeOrNil
						contentId:contentIdOrNil
				 customAttributes:customAttributesOrNil];
}

+ (void)logSearchWithQuery:(nullable NSString *)queryOrNil
		  customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logSearchWithQuery:queryOrNil
			 customAttributes:customAttributesOrNil];
}

+ (void)logCustomEventWithName:(NSString *)eventName
			  customAttributes:(nullable ANS_GENERIC_NSDICTIONARY(NSString *, id) *)customAttributesOrNil {
	
	if([LMSettings userHasOptedOutOfTracking]){
		return;
	}
	
	[super logCustomEventWithName:eventName
				 customAttributes:customAttributesOrNil];
}

@end
