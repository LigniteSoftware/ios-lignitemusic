//
//  ComplicationController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "ComplicationController.h"

@interface ComplicationController ()

@end

@implementation ComplicationController

#pragma mark - Timeline Configuration

- (void)getSupportedTimeTravelDirectionsForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimeTravelDirections directions))handler {
	
    handler(CLKComplicationTimeTravelDirectionForward | CLKComplicationTimeTravelDirectionBackward);
}

- (void)getTimelineStartDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
	
    handler(nil);
}

- (void)getTimelineEndDateForComplication:(CLKComplication *)complication withHandler:(void(^)(NSDate * __nullable date))handler {
	
    handler(nil);
}

- (void)getPrivacyBehaviorForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationPrivacyBehavior privacyBehavior))handler {
	
    handler(CLKComplicationPrivacyBehaviorShowOnLockScreen);
}

#pragma mark - Timeline Population

- (void)getCurrentTimelineEntryForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTimelineEntry * __nullable))handler {
	
	[self getLocalizableSampleTemplateForComplication:complication withHandler:^(CLKComplicationTemplate * _Nullable template) {
		
		CLKComplicationTimelineEntry *timelineEntry = [CLKComplicationTimelineEntry entryWithDate:[NSDate date]
																			 complicationTemplate:template];
		
		// Call the handler with the current timeline entry
		handler(timelineEntry);
	}];
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication beforeDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
	
	[self getLocalizableSampleTemplateForComplication:complication withHandler:^(CLKComplicationTemplate * _Nullable template) {
		
		CLKComplicationTimelineEntry *timelineEntry = [CLKComplicationTimelineEntry entryWithDate:[NSDate date]
																			 complicationTemplate:template];
		
		// Call the handler with the timeline entries prior to the given date
		handler(@[ timelineEntry ]);
	}];
}

- (void)getTimelineEntriesForComplication:(CLKComplication *)complication afterDate:(NSDate *)date limit:(NSUInteger)limit withHandler:(void(^)(NSArray<CLKComplicationTimelineEntry *> * __nullable entries))handler {
	
	[self getLocalizableSampleTemplateForComplication:complication withHandler:^(CLKComplicationTemplate * _Nullable template) {
		
		CLKComplicationTimelineEntry *timelineEntry = [CLKComplicationTimelineEntry entryWithDate:[NSDate date]
																			 complicationTemplate:template];
		
		// Call the handler with the timeline entries after to the given date
		handler(@[ timelineEntry ]);
	}];
}

#pragma mark - Placeholder Templates

- (void)getLocalizableSampleTemplateForComplication:(CLKComplication *)complication withHandler:(void(^)(CLKComplicationTemplate * __nullable complicationTemplate))handler {
	
	switch(complication.family){
		//https://docs-assets.developer.apple.com/published/ceab34dcca/75b82ad7-b493-40df-b8cf-9789ba8580c4.png
		case CLKComplicationFamilyCircularSmall:
		//https://docs-assets.developer.apple.com/published/ceab34dcca/75b82ad7-b493-40df-b8cf-9789ba8580c4.png
		case CLKComplicationFamilyModularSmall: {
			CLKComplicationTemplateCircularSmallSimpleText *template = [CLKComplicationTemplateCircularSmallSimpleText new];
			
			template.textProvider = [CLKTextProvider textProviderWithFormat:@"Lignite"];
			
			handler(template);
			break;
		}
		//https://docs-assets.developer.apple.com/published/ace3f7d1c9/5c22c7cd-94b9-4594-9526-5dd35ff44c9e.png
		case CLKComplicationFamilyUtilitarianSmallFlat:
		//https://docs-assets.developer.apple.com/published/c5a3bdc689/c31cf732-8c31-4e23-9280-a8af646aea31.png
		case CLKComplicationFamilyUtilitarianSmall: {
			CLKComplicationTemplateUtilitarianSmallFlat *template = [CLKComplicationTemplateUtilitarianSmallFlat new];
			
			template.textProvider = [CLKTextProvider textProviderWithFormat:@"Lignite"];
			template.imageProvider = [CLKImageProvider imageProviderWithOnePieceImage:[UIImage imageNamed:@"Complication"]];
			
			handler(template);
			break;
		}
		//https://docs-assets.developer.apple.com/published/722cecf8bb/d001ca54-d48e-4a70-96cd-ae17812e3c1f.png
		case CLKComplicationFamilyUtilitarianLarge: {
			CLKComplicationTemplateModularSmallSimpleText *template = [CLKComplicationTemplateModularSmallSimpleText new];
			
			template.textProvider = [CLKTextProvider textProviderWithFormat:@"Lignite Music"];
			
			handler(template);
			break;
		}
			
			
			
		/*
		 Unsupported complications
		 */
			
		//https://docs-assets.developer.apple.com/published/ace3f7d1c9/473fb9b9-7b43-4533-b5a6-daeb36a9c499.png
		case CLKComplicationFamilyExtraLarge:
		//https://docs-assets.developer.apple.com/published/c055f1def3/2688879b-430b-4592-b1f2-dfec716046b6.png
		case CLKComplicationFamilyModularLarge:
			handler(nil);
			break;
	}
}

@end
