//
//  LMSearch.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMSearch.h"
#import "LMMusicPlayer.h"

@implementation LMSearch

//http://stackoverflow.com/questions/21988253/nsstring-hasprefix-function-with-case-sensitivity
+ (BOOL)string:(NSString *)string hasPrefix:(NSString *)prefix caseInsensitive:(BOOL)caseInsensitive {
	if (!caseInsensitive)
		return [string hasPrefix:prefix];
	
	const NSStringCompareOptions options = NSAnchoredSearch|NSCaseInsensitiveSearch;
	NSRange prefixRange = [string rangeOfString:prefix
										options:options];
	return prefixRange.location == 0 && prefixRange.length > 0;
}

+ (NSArray<NSArray<MPMediaItemCollection*>*>*)searchResultsForString:(NSString*)searchString {
	NSCharacterSet *bannedCharacters = [NSCharacterSet characterSetWithCharactersInString:@"?!'\"&();:-/[]{}#%*_."];
	
	searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //Get rid of white space
	searchString = [[searchString componentsSeparatedByCharactersInSet:bannedCharacters] componentsJoinedByString:@" "]; //Get rid of banned characters and replace them with spaces
	searchString = [searchString stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceAndNewlineCharacterSet]]; //Get rid of white space again
	
	NSArray<NSString*> *associatedProperties = @[
								  MPMediaItemPropertyArtist,
								  MPMediaItemPropertyAlbumTitle,
								  MPMediaItemPropertyTitle,
								  MPMediaItemPropertyComposer,
								  MPMediaItemPropertyGenre
								  ];
	
	NSArray<NSNumber*> *associatedGroupings = @[
								 @(MPMediaGroupingArtist),
								 @(MPMediaGroupingAlbum),
								 @(MPMediaGroupingTitle),
								 @(MPMediaGroupingComposer),
								 @(MPMediaGroupingGenre)
								 ];
	
	NSMutableArray<NSArray<MPMediaItemCollection*>*> *searchResults = [NSMutableArray new];
	
	for(NSUInteger baseIndex = 0; baseIndex < associatedProperties.count; baseIndex++){
		MPMediaGrouping associatedMediaGrouping = [associatedGroupings[baseIndex] unsignedIntegerValue];

		MPMediaQuery *baseQuery = [MPMediaQuery new];
		baseQuery.groupingType = associatedMediaGrouping;
		
		NSArray<MPMediaItemCollection*>* collections = baseQuery.collections;
	
		NSMutableArray *collectionsWhichApply = [NSMutableArray new];
		
		for(NSUInteger collectionIndex = 0; collectionIndex < collections.count; collectionIndex++){
			MPMediaItemCollection *collection = [collections objectAtIndex:collectionIndex];
			MPMediaItem *representativeItem = collection.representativeItem;
			
			NSArray *propertiesToCheck = nil;
			switch(associatedMediaGrouping){
				case MPMediaGroupingArtist:
				case MPMediaGroupingComposer:
					propertiesToCheck = @[ MPMediaItemPropertyArtist ];
					break;
				default:
					propertiesToCheck = associatedProperties;
					break;
			}
			
			for(NSUInteger propertyIndex = 0; propertyIndex < propertiesToCheck.count; propertyIndex++){
				BOOL propertyFound = NO;
				
				NSString *completeProperty = [representativeItem valueForProperty:propertiesToCheck[propertyIndex]];
				NSArray *propertyWords = [completeProperty componentsSeparatedByString:@" "];
				
				for(NSUInteger propertyWordIndex = 0; propertyWordIndex < propertyWords.count; propertyWordIndex++){
					NSString *propertyWord = [propertyWords objectAtIndex:propertyWordIndex];
					
					if([LMSearch string:propertyWord hasPrefix:searchString caseInsensitive:YES]){
						[collectionsWhichApply addObject:collection];
						
						propertyFound = YES;
						break;
					}
				}
				
				if(propertyFound){
					break;
				}
				else{
					if([LMSearch string:completeProperty hasPrefix:searchString caseInsensitive:YES]){
						[collectionsWhichApply addObject:collection];
						break;
					}
				}
			}
		}
		
		NSLog(@"%@: %d results for %d", searchString, (int)collectionsWhichApply.count, (int)baseIndex);
		
		[searchResults addObject:collectionsWhichApply];
	}
	
	return [NSArray arrayWithArray:searchResults];
}

@end
