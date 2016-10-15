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

@interface LMTitleView() <LMListEntryDelegate, LMTableViewSubviewDelegate, LMMusicPlayerDelegate>

@property LMTableView *songListTableView;
@property NSMutableArray *itemArray;

@property NSInteger currentlyHighlighted;

@end

@implementation LMTitleView

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

- (id)prepareSubviewAtIndex:(NSUInteger)index {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.musicTitles.items objectAtIndex:index];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	return entry;
}

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
		for(int i = 0; i < amount; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
		}
	}
}

- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(height){
		return (1.0f/8.0f);
	}
	return 0.9;
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

- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 0.0f;
}

- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return YES;
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
	
	NSString *subtitle = [NSString stringWithFormat:@"%@ - %@", track.artist, track.albumTitle];
	
	return subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMMusicTrack *track = [self.musicTitles.items objectAtIndex:entry.collectionIndex];
	return [track albumArt];
}

- (void)setup {
	self.songListTableView = [[LMTableView alloc]init];
	self.songListTableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.songListTableView.amountOfItemsTotal = self.musicTitles.count;
	self.songListTableView.subviewDelegate = self;
	[self.songListTableView prepareForUse];
	[self addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self];
	[self.songListTableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.songListTableView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.songListTableView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	
	[self.musicPlayer addMusicDelegate:self];
	[self musicTrackDidChange:self.musicPlayer.nowPlayingTrack];
	[self musicPlaybackStateDidChange:self.musicPlayer.playbackState];
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
