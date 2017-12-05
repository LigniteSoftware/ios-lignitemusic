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

@property BOOL setupAnimation;

@end

@implementation LMWBrowsingInterfaceController

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
		self.tableEntries = tableEntriesArray;
		
		NSInteger totalNumberOfRows = tableEntriesArray.count;
		totalNumberOfRows += 2;
		
		[self.browsingTable setNumberOfRows:totalNumberOfRows withRowType:@"BrowseRow"];
		
		
		LMWMusicBrowsingRowController *playAllRow = [self.browsingTable rowControllerAtIndex:0];
		[playAllRow.titleLabel setText:NSLocalizedString(@"ShuffleAll", nil)];
		[playAllRow.subtitleLabel setText:NSLocalizedString(@"69 tracks", nil)];
		[playAllRow.icon setImage:[UIImage imageNamed:@"icon_shuffle.png"]];
		
		
		LMWMusicBrowsingRowController *nextTracksRow = [self.browsingTable rowControllerAtIndex:tableEntriesArray.count + 1];
		[nextTracksRow.titleLabel setText:NSLocalizedString(@"NextTracks", nil)];
		[nextTracksRow.subtitleLabel setText:NSLocalizedString(@"", nil)];
		[nextTracksRow.icon setImage:[UIImage imageNamed:@"icon_shuffle.png"]];
		
		
		
		for (NSInteger i = 1; i < (tableEntriesArray.count + 1); i++) {
			LMWMusicBrowsingRowController *row = [self.browsingTable rowControllerAtIndex:i];

			LMWMusicTrackInfo *entryInfo = [tableEntriesArray objectAtIndex:i - 1];

			[row.titleLabel setText:entryInfo.title];
			[row.subtitleLabel setText:entryInfo.subtitle];

			row.associatedInfo = entryInfo;
		}
		
		[self setLoading:NO];
	});
}

- (NSArray<LMWMusicTrackInfo*>*)tableEntriesForResultsArray:(nonnull NSArray<NSDictionary*>*)resultsArray {
	NSMutableArray *tableEntriesMutableArray = [NSMutableArray new];
	
	for(NSDictionary *resultDictionary in resultsArray){
		LMWMusicTrackInfo *entry = [LMWMusicTrackInfo new];
		entry.title = [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryTitle];
		entry.subtitle = [resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntrySubtitle];
		entry.persistentID = (MPMediaEntityPersistentID)[[resultDictionary objectForKey:LMAppleWatchBrowsingKeyEntryPersistentID] longLongValue];
		[tableEntriesMutableArray addObject:entry];
	}
	
	return [NSArray arrayWithArray:tableEntriesMutableArray];
}

- (void)table:(WKInterfaceTable *)table didSelectRowAtIndex:(NSInteger)rowIndex {
	LMWMusicBrowsingRowController *row = [self.browsingTable rowControllerAtIndex:rowIndex];
	
	if(rowIndex == 0){
		[self setLoading:YES withLabel:NSLocalizedString(@"Shuffling", nil)];
//		[self popToRootController];
	}
	else if(rowIndex == (self.tableEntries.count + 1)){
		[self setLoading:YES];
	}
}

- (void)awakeWithContext:(id)context {
	NSDictionary *dictionaryContext = (NSDictionary*)context;
	
	[self setTitle:[dictionaryContext objectForKey:@"title"]];
	
	self.tableEntries = @[];
	[self.loadingLabel setText:NSLocalizedString(@"HangOn", nil)];
	
	
	[self setLoading:YES];
	
	
	self.companionBridge = [LMWCompanionBridge sharedCompanionBridge];
	[self.companionBridge requestTracksWithEntryInfo:nil
										forMusicType:LMMusicTypeAlbums
										replyHandler:^(NSDictionary<NSString *,id> *replyMessage) {
											NSLog(@"Got reply: %@", replyMessage);
											
											NSArray<LMWMusicTrackInfo*> *tableEntriesArray = [self tableEntriesForResultsArray:[replyMessage objectForKey:@"results"]];
											[self reloadBrowsingTableWithEntries:tableEntriesArray];
										}
										errorHandler:^(NSError *error) {
											NSLog(@"Error getting tracks: %@", error);
										}];
}

@end
