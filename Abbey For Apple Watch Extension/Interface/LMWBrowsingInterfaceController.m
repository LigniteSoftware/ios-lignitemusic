//
//  LMWBrowsingInterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 12/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWBrowsingInterfaceController.h"
#import "LMWMusicBrowsingRowController.h"
#import "LMWCompanionBridge.h"

@interface LMWBrowsingInterfaceController()

/**
 The companion bridge.
 */
@property LMWCompanionBridge *companionBridge;

/**
 The entries that are currently being displayed on the table. Empty array if none are being displayed.
 */
@property NSArray<LMWMusicTrackInfo*>* tableEntries;

/**
 The music type associated with this browse window.
 */
@property (readonly) LMMusicType musicType;
@property NSMutableArray<NSNumber*> *musicTypes;

@property NSMutableArray<NSNumber*> *selectedIndexes;
@property NSMutableArray<NSNumber*> *pageIndexes;
@property NSMutableArray<NSNumber*> *persistentIDs;

@property LMWMusicTrackInfo *entryInfo;

@property BOOL setupAnimation;
@property NSInteger previousIndex;

@property NSInteger indexOfFinalPage;
@property (readonly) BOOL isBeginningOfList;
@property (readonly) BOOL isEndOfList;

@property NSInteger indexOfCurrentPage;
@property NSMutableArray<NSArray<LMWMusicTrackInfo*>*> *pages;

@property NSInteger totalNumberOfEntries;
@property NSInteger amountOfUncachedEntries;
@property (readonly) NSInteger amountOfEntriesAheadOfCurrentPage;

@property NSInteger entriesOffset;

@end

@implementation LMWBrowsingInterfaceController

@synthesize musicType = _musicType;

- (LMMusicType)musicType {
	return (LMMusicType)[self.musicTypes.lastObject integerValue];
}

- (BOOL)isBeginningOfList {
	return (self.indexOfCurrentPage == 0);
}

- (BOOL)isEndOfList {
	if(self.indexOfFinalPage == -1){
		return NO;
	}
	return (self.indexOfCurrentPage == self.indexOfFinalPage);
}

- (NSInteger)amountOfEntriesAheadOfCurrentPage {
	if(self.indexOfFinalPage == -1){ //Index of last page has not been determined
		NSInteger amountOfEntriesAhead = 0;
		NSInteger amountOfPagesAheadToCount = ((self.pages.count - 1) - self.indexOfCurrentPage);
		for(NSInteger i = 0; i < amountOfPagesAheadToCount; i++){
			amountOfEntriesAhead += [self.pages objectAtIndex:(self.indexOfCurrentPage + i + 1)].count;
		}
		amountOfEntriesAhead += self.amountOfUncachedEntries;
		return amountOfEntriesAhead;
	}
	
	if(self.indexOfCurrentPage == self.indexOfFinalPage){ //Index of last page has been determined
		return 0;
	}
	
	NSInteger amountOfEntriesAhead = 0;
	NSInteger amountOfPagesAheadToCount = (self.indexOfFinalPage - self.indexOfCurrentPage);
	for(NSInteger i = 0; i < amountOfPagesAheadToCount; i++){
		amountOfEntriesAhead += [self.pages objectAtIndex:(self.indexOfCurrentPage + i + 1)].count;
	}
	return amountOfEntriesAhead;
}

- (void)setLoading:(BOOL)loading withLabel:(NSString*)label {
	[self.loadingGroup setHidden:!loading];
	
	[self.loadingLabel setText:label];
	
	if(loading){
		[self.browsingTable setNumberOfRows:0 withRowType:@"BrowseRow"];

		if(self.setupAnimation){
			[self.loadingImage startAnimating];
		}
		else{
			[self.loadingImage setImageNamed:@"Activity"];
			[self.loadingImage startAnimatingWithImagesInRange:NSMakeRange(0, 30)
													  duration:1.0
												   repeatCount:0];
			
			self.setupAnimation = YES;
		}
	}
	else{
		[self.loadingImage stopAnimating];
	}
}

- (void)setLoading:(BOOL)loading {
	[self setLoading:loading withLabel:NSLocalizedString(@"HangOn", nil)];
}

- (void)reloadBrowsingTableWithEntries:(NSArray<LMWMusicTrackInfo*>*)tableEntriesArray {
	[self.loadingLabel setText:NSLocalizedString(@"AlmostThere", nil)];
	
	dispatch_async(dispatch_get_main_queue(), ^{
		//Shuffle button only displays if titles or favourites are being displayed, and the list is longer than one track long.
		BOOL allowsShuffleAll = (self.musicType == LMMusicTypeTitles || self.musicType == LMMusicTypeFavourites)
			&& (self.pages.firstObject.count > 1);
		
		self.tableEntries = tableEntriesArray;
		
		NSInteger totalNumberOfRows = tableEntriesArray.count;
		totalNumberOfRows += (!self.isBeginningOfList) + (!self.isEndOfList) + allowsShuffleAll;
		
		[self.browsingTable setNumberOfRows:totalNumberOfRows withRowType:@"BrowseRow"];
		
		if(!self.isBeginningOfList){
			LMWMusicBrowsingRowController *previousTracksRow = [self.browsingTable rowControllerAtIndex:0];
			[previousTracksRow.titleLabel setText:NSLocalizedString(@"PreviousPage", nil)];
			
			[previousTracksRow.subtitleLabel setText:
			 [NSString stringWithFormat:
			  NSLocalizedString(@"LastX", nil), [self.pages objectAtIndex:self.indexOfCurrentPage - 1].count]
			 ];
			
			[previousTracksRow.icon setImage:[UIImage imageNamed:@"icon_left_arrow.png"]];
			
			previousTracksRow.isPreviousButton = YES;
		}
		
		if(allowsShuffleAll){
			LMWMusicBrowsingRowController *shuffleAllTracksRow = [self.browsingTable rowControllerAtIndex:!self.isBeginningOfList];
			[shuffleAllTracksRow.titleLabel setText:NSLocalizedString(@"ShuffleAll", nil)];
			
			[shuffleAllTracksRow.subtitleLabel setText:
			 [NSString stringWithFormat:
			  NSLocalizedString((self.totalNumberOfEntries == 1) ? @"XTrack" : @"XTracks", nil), self.totalNumberOfEntries]
			 ];
			
			[shuffleAllTracksRow.icon setImage:[UIImage imageNamed:@"icon_shuffle.png"]];
			
			shuffleAllTracksRow.isShuffleAllButton = YES;
		}
		
		self.entriesOffset = (!self.isBeginningOfList + allowsShuffleAll);
		
		if(!self.isEndOfList){
			LMWMusicBrowsingRowController *nextTracksRow =
				[self.browsingTable rowControllerAtIndex:tableEntriesArray.count + self.entriesOffset];
			
			[nextTracksRow.titleLabel setText:NSLocalizedString(@"NextPage", nil)];
			[nextTracksRow.subtitleLabel setText:[NSString stringWithFormat:NSLocalizedString(@"XLeft", nil), self.amountOfEntriesAheadOfCurrentPage]];
			[nextTracksRow.icon setImage:[UIImage imageNamed:@"icon_right_arrow.png"]];
			
			nextTracksRow.isNextButton = YES;
		}
		
		
		if(self.tableEntries.count == 0){
			[self.loadingImage setImage:[UIImage imageNamed:@"apple_watch_sad.png"]];
			[self.loadingLabel setText:NSLocalizedString(@"NothingHere", nil)];
		}
		else{
			for (NSInteger i = self.entriesOffset; i < (tableEntriesArray.count + self.entriesOffset); i++) {
				LMWMusicBrowsingRowController *row = [self.browsingTable rowControllerAtIndex:i];

				LMWMusicTrackInfo *entryInfo = [tableEntriesArray objectAtIndex:i - self.entriesOffset];

				[row.titleLabel setText:entryInfo.title];
				[row.subtitleLabel setText:entryInfo.subtitle];
				[row.icon setImage:entryInfo.albumArtNotCropped];

				row.associatedInfo = entryInfo;
			}
			
			[self setLoading:NO];
		}
	});
}

- (NSArray<LMWMusicTrackInfo*>*)tableEntriesForResultsArray:(nonnull NSArray<NSDictionary*>*)resultsArray {
	NSMutableArray *tableEntriesMutableArray = [NSMutableArray new];
	
	for(NSInteger i = 0; i < resultsArray.count; i++){
		NSDictionary *resultDictionary = [resultsArray objectAtIndex:i];
		LMWMusicTrackInfo *entry = [LMWMusicTrackInfo new];
		entry.title = [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryTitle];
		entry.subtitle = [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntrySubtitle];
		entry.persistentID = (MPMediaEntityPersistentID)[[resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryPersistentID] longLongValue];
		entry.indexInCollection = i + self.previousIndex + (self.previousIndex > 0);
		
//		entry.title = [NSString stringWithFormat:@"%d - %@", (int)entry.indexInCollection, [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryPersistentID]];
		
		UIImage *icon = nil;
		id iconData = [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryIcon];
		if(iconData){
			icon = [UIImage imageWithData:iconData];
			entry.albumArt = icon;
		}
		
		[tableEntriesMutableArray addObject:entry];
	}
	
	return [NSArray arrayWithArray:tableEntriesMutableArray];
}

- (void)handleTracksRequestWithReplyDictionary:(NSDictionary*)replyDictionary {
	BOOL isEndOfList = [[replyDictionary objectForKey:LMAppleWatchBrowsingKeyIsEndOfList] boolValue];
	
	self.totalNumberOfEntries = [[replyDictionary objectForKey:LMAppleWatchBrowsingKeyTotalNumberOfEntries] integerValue];
	
	if(isEndOfList){
		self.indexOfFinalPage = self.indexOfCurrentPage;
	}
	
	self.amountOfUncachedEntries = [[replyDictionary objectForKey:LMAppleWatchBrowsingKeyRemainingEntries] integerValue];
	
	NSArray<LMWMusicTrackInfo*> *tableEntriesArray = [self tableEntriesForResultsArray:[replyDictionary objectForKey:@"results"]];
	[self.pages addObject:tableEntriesArray];
	[self reloadBrowsingTableWithEntries:tableEntriesArray];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	LMWMusicBrowsingRowController *row = [self.browsingTable rowControllerAtIndex:rowIndex];
	
	if(row.isNextButton){
		[self setLoading:YES withLabel:NSLocalizedString(@"GettingNext", nil)];
		
		self.previousIndex = self.tableEntries.lastObject.indexInCollection;
		
		if(self.indexOfCurrentPage < (self.pages.count - 1)){ //Already cached
			self.indexOfCurrentPage++;
			
			[self reloadBrowsingTableWithEntries:[self.pages objectAtIndex:self.indexOfCurrentPage]];
		}
		else{ //Get next page from phone
			
//			if(self.entryInfo){
//				self.entryInfo.indexInCollection = self.tableEntries.lastObject.indexInCollection;
//			}
			
//			[self.selectedIndexes addObject:@(self.entryInfo.indexInCollection)];
			
			self.indexOfCurrentPage++;
			
			[self.pageIndexes removeLastObject];
			[self.pageIndexes addObject:@(self.indexOfCurrentPage)];
			
			[self.companionBridge requestTracksWithSelectedIndexes:self.selectedIndexes
												   withPageIndexes:self.pageIndexes
													 forMusicTypes:self.musicTypes
												 withPersistentIDs:self.persistentIDs
													  replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
														  [self handleTracksRequestWithReplyDictionary:replyMessage];
													  }
													  errorHandler:^(NSError *error) {
													NSLog(@"Error: %@", error);
													  }];
		}
	}
	else if(row.isPreviousButton){
		self.indexOfCurrentPage--;
		
		[self setLoading:YES];
		
		[self reloadBrowsingTableWithEntries:[self.pages objectAtIndex:self.indexOfCurrentPage]];
	}
	else if(row.isShuffleAllButton){
		[self setLoading:YES withLabel:NSLocalizedString(@"Shuffling", nil)];
		
		[self.companionBridge shuffleTracksWithSelectedIndexes:self.selectedIndexes
											   withPageIndexes:self.pageIndexes
												 forMusicTypes:self.musicTypes
											 withPersistentIDs:self.persistentIDs
												  replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
													  [self popToRootController];
												  }
												  errorHandler:^(NSError *error) {
													  NSLog(@"Error: %@", error);
												  }];
	}
	else{ //An actual entry :O
		LMWMusicTrackInfo *entryInfo = [self.tableEntries objectAtIndex:rowIndex-self.entriesOffset];
//		entryInfo.indexInCollection = -1;
		
		[self pushControllerWithName:@"BrowsingController" context:@{
																	 @"title": entryInfo.title,
																	 @"musicTypes": self.musicTypes,
																	 @"selectedIndexes": self.selectedIndexes,
																	 @"persistentIDs": self.persistentIDs,
																	 @"entryInfo": entryInfo
																	 }];
	}
}

- (void)awakeWithContext:(id)context {
	self.pages = [NSMutableArray new];
	
	self.indexOfCurrentPage = 0;
	self.indexOfFinalPage = -1;
	
	NSDictionary *dictionaryContext = (NSDictionary*)context;
	
	self.musicTypes = [NSMutableArray arrayWithArray:[dictionaryContext objectForKey:@"musicTypes"]];
	self.persistentIDs = [NSMutableArray arrayWithArray:[dictionaryContext objectForKey:@"persistentIDs"]];
	self.selectedIndexes = [NSMutableArray arrayWithArray:[dictionaryContext objectForKey:@"selectedIndexes"]];
	self.pageIndexes = [NSMutableArray arrayWithArray:[dictionaryContext objectForKey:@"pageIndexes"]];
	if(!self.selectedIndexes){
		self.selectedIndexes = [NSMutableArray new];
	}
	
	self.entryInfo = (LMWMusicTrackInfo*)[dictionaryContext objectForKey:@"entryInfo"];
	
	if(self.entryInfo){
		LMMusicType currentMusicType = LMMusicTypeTitles;
		switch(((LMMusicType) self.musicTypes.lastObject.integerValue)){
			case LMMusicTypeTitles:
			case LMMusicTypeFavourites:
				//Play track
				break;
			case LMMusicTypePlaylists:
			case LMMusicTypeAlbums:
			case LMMusicTypeCompilations:
				currentMusicType = LMMusicTypeTitles;
				break;
			case LMMusicTypeGenres:
			case LMMusicTypeArtists:
			case LMMusicTypeComposers:
				currentMusicType = LMMusicTypeAlbums;
				break;
		}
		[self.persistentIDs addObject:@(self.entryInfo.persistentID)];
		[self.musicTypes addObject:@(currentMusicType)];
		[self.selectedIndexes addObject:@(self.entryInfo.indexInCollection)];
	}
	else{
		[self.persistentIDs addObject:@(0)];
		[self.selectedIndexes addObject:@(-1)];
	}
	
	[self.pageIndexes addObject:@(0)];
	
	[self setTitle:[dictionaryContext objectForKey:@"title"]];
	
	self.tableEntries = @[];
	[self.loadingLabel setText:NSLocalizedString(@"HangOn", nil)];
	
	
	[self setLoading:YES];
	
	
	self.companionBridge = [LMWCompanionBridge sharedCompanionBridge];
	[self.companionBridge requestTracksWithSelectedIndexes:self.selectedIndexes
										   withPageIndexes:self.pageIndexes
											 forMusicTypes:self.musicTypes
										 withPersistentIDs:self.persistentIDs
											  replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
											NSLog(@"Got reply: %@", replyMessage);
											
											[self handleTracksRequestWithReplyDictionary:replyMessage];
											  }
											 errorHandler:^(NSError *error) {
											NSLog(@"Error getting tracks: %@", error);
											 }];
}

@end
