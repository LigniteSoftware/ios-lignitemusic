//
//  LMTitleView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTitleView.h"
#import "LMTableView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMOperationQueue.h"
#import "LMMusicPlayer.h"
#import "LMExtras.h"

@interface LMTitleView() <LMListEntryDelegate, LMTableViewSubviewDataSource, LMMusicPlayerDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMTableView *songListTableView;
@property NSMutableArray *itemArray;
@property NSMutableArray *itemIconArray;

@property NSInteger currentlyHighlighted;

@property LMOperationQueue *queue;

@end

@implementation LMTitleView

- (void)reloadSourceSelectorInfo {
	if(self.hidden){
		return;
	}
	
	NSString *collectionString = NSLocalizedString(self.musicTitles.count == 1 ? @"Title" : @"Titles", nil);
	
	[self.musicPlayer setSourceTitle:collectionString];
	[self.musicPlayer setSourceSubtitle:[NSString stringWithFormat:@"%ld %@", (long)self.musicTitles.count, collectionString]];
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	LMListEntry *highlightedEntry = nil;
	int newHighlightedIndex = -1;
	for(int i = 0; i < self.musicTitles.count; i++){
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:i];
		LMListEntry *entry = [self listEntryForIndex:i];
		LMMusicTrack *entryTrack = entry.associatedData;
		
		if(entryTrack.persistentID == newTrack.persistentID){
			highlightedEntry = entry;
		}
		
		if(track.persistentID == newTrack.persistentID){
			newHighlightedIndex = i;
		}
	}
	
//	NSLog(@"New highlighted %d previous %ld", newHighlightedIndex, (long)self.currentlyHighlighted);
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(![previousHighlightedEntry isEqual:highlightedEntry] || highlightedEntry == nil){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
		//BOOL updateNowPlayingStatus = self.currentlyHighlighted == -1;
		self.currentlyHighlighted = newHighlightedIndex;
//		if(updateNowPlayingStatus){
//			[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
//		}
	}
	
	if(highlightedEntry){
		[highlightedEntry changeHighlightStatus:YES animated:YES];
	}
}

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {

}

- (void)rebuildTrackCollection {
	MPMediaQuery *everything = [[MPMediaQuery alloc] init];
	NSArray *songs = [everything items];
	MPMediaItemCollection *mediaCollection = [MPMediaItemCollection collectionWithItems:songs];
	NSMutableArray* musicTracks = [[NSMutableArray alloc]init];
	
	NSMutableArray *musicCollection = [[NSMutableArray alloc]init];
	for(int itemIndex = 0; itemIndex < mediaCollection.items.count; itemIndex++){
		MPMediaItem *musicItem = [mediaCollection.items objectAtIndex:itemIndex];
		LMMusicTrack *musicTrack = [[LMMusicTrack alloc]initWithMPMediaItem:musicItem];
		[musicCollection addObject:musicTrack];
	}
	LMMusicTrackCollection *trackCollection = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:mediaCollection];
	[musicTracks addObject:trackCollection];
	
	self.musicTitles = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:mediaCollection];
	self.songListTableView.totalAmountOfObjects = self.musicTitles.count;
	[self reloadSourceSelectorInfo];
}

- (void)musicLibraryDidChange {
	[self rebuildTrackCollection];
	
	[self.songListTableView reloadSubviewData];
	
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.musicTitles.items objectAtIndex:index];
	
	if(!entry.queue){
		entry.queue = [[LMOperationQueue alloc] init];
	}
	
	[entry.queue cancelAllOperations];
	
	NSBlockOperation *operation = [NSBlockOperation blockOperationWithBlock:^{
		LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
		UIImage *albumArt = [track albumArt];
		
		NSInteger indexToInsert = (index % self.itemArray.count);
		
		[self.itemIconArray removeObjectAtIndex:indexToInsert];
		[self.itemIconArray insertObject:albumArt ? albumArt : [LMAppIcon imageForIcon:LMIconAlbums] atIndex:indexToInsert];
		
		entry.invertIconOnHighlight = albumArt == nil;
		
		//[self.itemIconArray object]
//		NSLog(@"%@ %ld %ld", albumArt, self.itemIconArray.count, indexToInsert);
		
		dispatch_async(dispatch_get_main_queue(), ^{
			if(operation.cancelled){
				NSLog(@"Rejecting.");
				return;
			}
			
			[entry reloadContents];
			
			//	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
			//	return [track albumArt];
		});
	}];
	
	[entry.queue addOperation:operation];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	
	return entry;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
		self.itemIconArray = [NSMutableArray new];
		for(int i = 0; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
			
			//Quick hack to make sure that the items in the array are non nil
			[self.itemIconArray addObject:@""];
		}
	}
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	return WINDOW_FRAME.size.height/8.0;
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *indexEntry = [self.itemArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.itemArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView *)tableView {
	return 10; //TODO: Fix this
}

- (void)tappedListEntry:(LMListEntry*)entry{
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
		
	//	NSLog(@"Tapped list entry with artist %@", self.albumCollection.representativeItem.artist);
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = entry.collectionIndex;
	
	if(self.musicPlayer.nowPlayingCollection != self.musicTitles){
		[self.musicPlayer stop];
		[self.musicPlayer setNowPlayingCollection:self.musicTitles];
	}
	self.musicPlayer.autoPlay = YES;
	
	[self.musicPlayer setNowPlayingTrack:track];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	
	return track.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	
	NSString *subtitle = [NSString stringWithFormat:@"%@", track.artist ? track.artist : NSLocalizedString(@"UnknownArtist", nil)];
	if(track.albumTitle){
		subtitle = [subtitle stringByAppendingString:[NSString stringWithFormat:@" - %@", track.albumTitle]];
	}
	
	return subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	NSInteger actualIndex = entry.collectionIndex % self.itemArray.count;
	
	if(self.itemIconArray.count < 9){
		return nil;
	}
	if([[self.itemIconArray objectAtIndex:actualIndex] isEqual:@""]){
		return nil;
	}
	UIImage *image = [self.itemIconArray objectAtIndex:actualIndex];
	return image;
}

- (void)setup {
	[self rebuildTrackCollection];
	
	self.songListTableView = [LMTableView newAutoLayoutView];
	self.songListTableView.totalAmountOfObjects = self.musicTitles.count;
	self.songListTableView.subviewDataSource = self;
	self.songListTableView.shouldUseDividers = YES;
	self.songListTableView.averageCellHeight = (WINDOW_FRAME.size.height/10);
	[self addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdgesToSuperviewEdges];
	
	[self.songListTableView reloadSubviewData];
		
	[self.musicPlayer addMusicDelegate:self];
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	}
	else{
		NSLog(@"Error creating LMTitleView");
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
