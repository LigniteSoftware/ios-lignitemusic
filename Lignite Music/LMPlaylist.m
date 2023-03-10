//
//  LMPlaylist.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#include <stdlib.h>

#import "LMPlaylist.h"
#import "LMMusicPlayer.h"
#import "LMPlaylistManager.h"

@interface LMPlaylist()

/**
 The enhanced music collection that has been cached so it does not have to be regenerated every time it's loaded.
 */
@property LMMusicTrackCollection *cachedEnhancedCollection;

@end

@implementation LMPlaylist

@synthesize trackCollection = _trackCollection;
@synthesize wantToHearMusicTypes = _wantToHearMusicTypes;
@synthesize wantToHearPersistentIDs = _wantToHearPersistentIDs;
@synthesize wantToHearTrackCollections = _wantToHearTrackCollections;
@synthesize dontWantToHearMusicTypes = _dontWantToHearMusicTypes;
@synthesize dontWantToHearPersistentIDs = _dontWantToHearPersistentIDs;
@synthesize dontWantToHearTrackCollections = _dontWantToHearTrackCollections;

- (NSDictionary*)dictionaryRepresentation {
	return [[LMPlaylistManager sharedPlaylistManager] playlistDictionaryForPlaylist:self];
}

- (NSDictionary*)wantToHearDictionary {
	return [self.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistWantToHearKey];
}

- (NSDictionary*)dontWantToHearDictionary {
	return [self.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistDontWantToHearKey];
}

- (NSArray<NSNumber*>*)wantToHearMusicTypes {
	NSArray<NSNumber*> *musicTypes = [[self wantToHearDictionary] objectForKey:LMEnhancedPlaylistMusicTypesKey];
	if(!musicTypes){
		return @[];
	}
	return musicTypes;
}

- (NSArray<NSNumber*>*)wantToHearPersistentIDs {
	NSArray<NSNumber*> *persistentIDs = [[self wantToHearDictionary] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	if(!persistentIDs){
		return @[];
	}
	return persistentIDs;
}


- (NSArray<NSNumber*>*)dontWantToHearMusicTypes {
	NSArray<NSNumber*> *musicTypes = [[self dontWantToHearDictionary] objectForKey:LMEnhancedPlaylistMusicTypesKey];
	if(!musicTypes){
		return @[];
	}
	return musicTypes;
}

- (NSArray<NSNumber*>*)dontWantToHearPersistentIDs {
	NSArray<NSNumber*> *persistentIDs = [[self dontWantToHearDictionary] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	if(!persistentIDs){
		return @[];
	}
	return persistentIDs;
}

- (NSArray<LMMusicTrackCollection*>*)wantToHearTrackCollections {
	NSMutableArray *musicTrackCollectionsMutableArray = [NSMutableArray new];
	
	NSArray *persistentIDsArray = [[self wantToHearDictionary] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	NSArray *musicTypesArray = [[self wantToHearDictionary] objectForKey:LMEnhancedPlaylistMusicTypesKey];
	
	for(NSInteger i = 0; i < persistentIDsArray.count; i++){
		MPMediaEntityPersistentID persistentID = [[persistentIDsArray objectAtIndex:i] longLongValue];
		LMMusicType musicType = (LMMusicType)[[musicTypesArray objectAtIndex:i] integerValue];
		
		if(musicType == LMMusicTypeFavourites){
			musicType = LMMusicTypeTitles;
		}
		
		NSArray<LMMusicTrackCollection*> *trackCollections = [[LMMusicPlayer sharedMusicPlayer] collectionsForPersistentID:persistentID forMusicType:musicType];
		
		NSMutableArray<LMMusicTrack*> *allTracksInTrackCollectionsArray = [NSMutableArray new];
		for(LMMusicTrackCollection *trackCollection in trackCollections){
			[allTracksInTrackCollectionsArray addObjectsFromArray:trackCollection.items];
		}
		[musicTrackCollectionsMutableArray addObject:[[LMMusicTrackCollection alloc] initWithItems:allTracksInTrackCollectionsArray]];
	}
	
	NSLog(@"Returning %d wanted items", (int)musicTrackCollectionsMutableArray.count);
	
	return [NSArray arrayWithArray:musicTrackCollectionsMutableArray];
}

- (NSArray<LMMusicTrackCollection*>*)dontWantToHearTrackCollections {
	NSMutableArray *musicTrackCollectionsMutableArray = [NSMutableArray new];
	
	NSArray *persistentIDsArray = [[self dontWantToHearDictionary] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	NSArray *musicTypesArray = [[self dontWantToHearDictionary] objectForKey:LMEnhancedPlaylistMusicTypesKey];
	
	for(NSInteger i = 0; i < persistentIDsArray.count; i++){
		MPMediaEntityPersistentID persistentID = [[persistentIDsArray objectAtIndex:i] longLongValue];
		LMMusicType musicType = (LMMusicType)[[musicTypesArray objectAtIndex:i] integerValue];
		
		if(musicType == LMMusicTypeFavourites){
			musicType = LMMusicTypeTitles;
		}
		
		NSArray<LMMusicTrackCollection*> *trackCollections = [[LMMusicPlayer sharedMusicPlayer] collectionsForPersistentID:persistentID forMusicType:musicType];
		
		NSMutableArray<LMMusicTrack*> *allTracksInTrackCollectionsArray = [NSMutableArray new];
		for(LMMusicTrackCollection *trackCollection in trackCollections){
			[allTracksInTrackCollectionsArray addObjectsFromArray:trackCollection.items];
		}
		[musicTrackCollectionsMutableArray addObject:[[LMMusicTrackCollection alloc] initWithItems:allTracksInTrackCollectionsArray]];
	}
	
	NSLog(@"Returning %d UNWANTED items for %@ and %@", (int)musicTrackCollectionsMutableArray.count, persistentIDsArray, musicTypesArray);
	
	return [NSArray arrayWithArray:musicTrackCollectionsMutableArray];
}

- (LMMusicTrackCollection*)trackCollection {
	if(self.enhanced){
		if(!self.cachedEnhancedCollection){
			[self regenerateEnhancedPlaylist];
		}
		return self.cachedEnhancedCollection;
	}
	
	return _trackCollection;
}

- (void)setTrackCollection:(LMMusicTrackCollection *)trackCollection {
	_trackCollection = trackCollection;
}

- (void)shuffleArray:(NSMutableArray*)array {
	NSUInteger count = [array count];
	if(count < 1){
		return;
	}
	for(NSUInteger i = 0; i < count - 1; ++i) {
		NSInteger remainingCount = count - i;
		NSInteger exchangeIndex = i + arc4random_uniform((u_int32_t)remainingCount);
		[array exchangeObjectAtIndex:i withObjectAtIndex:exchangeIndex];
	}
}

- (void)regenerateEnhancedPlaylist {
	NSAssert(self.enhanced, @"It is illegal to try and regenerate a playlist that's not enhanced. Prepare to get ass blasted. Oh wait, you already did, sucker.");
	
	NSLog(@"Regenerate me");
	
	NSArray<LMMusicTrackCollection*> *wantToHearTrackCollections = [self wantToHearTrackCollections];
	LMMusicTrackCollection *dontWantToHearTrackCollection = [LMMusicPlayer trackCollectionForArrayOfTrackCollections:[self dontWantToHearTrackCollections]];
	
	LMMusicTrackCollection *wantToHearTrackCollection = [LMMusicPlayer trackCollectionForArrayOfTrackCollections:wantToHearTrackCollections];
	NSMutableArray *finalTracksMutableArray = [NSMutableArray arrayWithArray:wantToHearTrackCollection.items];
	
	for(LMMusicTrack *dontWantToHearTrack in dontWantToHearTrackCollection.items){
		for(LMMusicTrack *wantToHearTrack in wantToHearTrackCollection.items){
			if(dontWantToHearTrack.persistentID == wantToHearTrack.persistentID){
				[finalTracksMutableArray removeObject:wantToHearTrack];
			}
		}
	}
	
	if(self.enhancedShuffleAll){
		[self shuffleArray:finalTracksMutableArray];
	}
	
	self.cachedEnhancedCollection = [[LMMusicTrackCollection alloc] initWithItems:finalTracksMutableArray];
}

- (instancetype)init {
	self = [super init];
	if(self){
		while(self.persistentID == 0){
			self.persistentID = arc4random() % 133769420;
		}
		self.title = @"";
	}
	return self;
}

@end
