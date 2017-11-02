//
//  LMPlaylistManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/18/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistManager.h"
#import "NSTimer+Blocks.h"
#import "LMAlertView.h"
#import "LMColour.h"
@import SDWebImage;

@interface LMPlaylistManager()

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The image cache for storing images.
 */
@property SDImageCache *imageCache;

/**
 An array of persistent IDs representing playlists that used to be system playlists, that were deleted by the user. This array is used to prevent the readding of those playlists to the app upon playlist manager initialization.
 */
@property NSArray<NSNumber*> *deletedSystemPlaylistPersistentIDs;

@end

@implementation LMPlaylistManager

@synthesize userUnderstandsPlaylistManagement = _userUnderstandsPlaylistManagement;
@synthesize playlistTrackCollections = _playlistTrackCollections;

/* Begin internal playlist management code */

- (NSArray<LMMusicTrackCollection*>*)playlistTrackCollections {
	NSMutableArray *musicTrackCollectionsArray = [NSMutableArray new];
	for(LMPlaylist *playlist in self.playlists){
		[musicTrackCollectionsArray addObject:playlist.trackCollection ? playlist.trackCollection : [[LMMusicTrackCollection alloc]initWithItems:@[]]];
	}
	return [NSArray arrayWithArray:musicTrackCollectionsArray];
}

- (LMPlaylist*)playlistForPlaylistDictionary:(NSDictionary*)playlistDictionary {
	LMPlaylist *playlist = [LMPlaylist new];
	
	playlist.title = [playlistDictionary objectForKey:@"title"];
	playlist.systemPersistentID = [[playlistDictionary objectForKey:@"systemPersistentID"] longLongValue];
	playlist.persistentID = [[playlistDictionary objectForKey:@"persistentID"] longLongValue];
	
	NSMutableArray *trackMutableArray = [NSMutableArray new];
	NSArray *trackPersistentIDArray = [playlistDictionary objectForKey:@"trackCollectionPersistentIDs"];
	for(NSNumber *trackPersistentIDNumber in trackPersistentIDArray){
		MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:trackPersistentIDNumber
																			   forProperty:MPMediaItemPropertyPersistentID];
		MPMediaQuery *query = [[MPMediaQuery alloc] init];
		[query addFilterPredicate: predicate];
		
		[trackMutableArray addObjectsFromArray:query.items];
		
		NSLog(@"%@ Got %@", playlist.title, query.items.firstObject.title);
	}
	playlist.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:trackMutableArray];
	
	playlist.image = [self.imageCache imageFromDiskCacheForKey:[NSString stringWithFormat:@"%lld", playlist.persistentID]];
	playlist.enhancedConditionsDictionary = [playlistDictionary objectForKey:@"enhancedConditionsDictionary"];
	if(playlist.enhancedConditionsDictionary){
		playlist.enhanced = YES;
		[playlist regenerateEnhancedPlaylist];
	}
	
	return playlist;
}

- (NSDictionary*)playlistDictionaryForPlaylist:(LMPlaylist*)playlist {
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
	
	NSMutableArray *songPersistentIDArray = [NSMutableArray new];
	for(LMMusicTrack *track in playlist.trackCollection.items){
		[songPersistentIDArray addObject:@(track.persistentID)];
	}
	
	[mutableDictionary setObject:playlist.title forKey:@"title"];
	[mutableDictionary setObject:@(playlist.systemPersistentID) forKey:@"systemPersistentID"];
	[mutableDictionary setObject:@(playlist.persistentID) forKey:@"persistentID"];
	[mutableDictionary setObject:[NSArray arrayWithArray:songPersistentIDArray] forKey:@"trackCollectionPersistentIDs"];
	
	if(playlist.image){
		[self.imageCache storeImage:playlist.image forKey:[NSString stringWithFormat:@"%lld", playlist.persistentID]];
	}
	if(playlist.enhanced && playlist.enhancedConditionsDictionary){
		[mutableDictionary setObject:playlist.enhancedConditionsDictionary forKey:@"enhancedConditionsDictionary"];
	}
	
	return [NSDictionary dictionaryWithDictionary:mutableDictionary];
}

- (NSString*)storageKeyForPlaylist:(LMPlaylist*)playlist {
	return [NSString stringWithFormat:@"LMPlaylist:%lld", playlist.persistentID];
}

- (void)savePlaylist:(LMPlaylist*)playlist {
	if(playlist.persistentID == 0){
		NSLog(@"Warning: playlist persistent ID was 0!");
		playlist.persistentID = random();
	}
	
	if(![self.playlists containsObject:playlist]){
		NSMutableArray *mutablePlaylistArray = [[NSMutableArray alloc]initWithArray:self.playlists];
		[mutablePlaylistArray addObject:playlist];
		self.playlists = [NSArray arrayWithArray:mutablePlaylistArray];
	}
	
	NSLog(@"Saving playlist with title %@ persistentID %llu", playlist.title, playlist.persistentID);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[self playlistDictionaryForPlaylist:playlist]
					 forKey:[self storageKeyForPlaylist:playlist]];
	if(!playlist.image){
		[self.imageCache removeImageForKey:[NSString stringWithFormat:@"%lld", playlist.persistentID]];
	}
	[userDefaults synchronize];
	
	//Tell someone the playlists updated
}

- (void)deletePlaylist:(LMPlaylist*)playlist {
	NSLog(@"Deleting playlist with title %@ and persistent ID of %llu", playlist.title, playlist.persistentID);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if(playlist.systemPersistentID > 0){
		[userDefaults setBool:YES forKey:[NSString stringWithFormat:@"deletedSystemPlaylist_%lld", playlist.systemPersistentID]];
	}
	[userDefaults removeObjectForKey:[self storageKeyForPlaylist:playlist]];
	[userDefaults synchronize];
	
	NSMutableArray *mutablePlaylistArray = [[NSMutableArray alloc]initWithArray:self.playlists];
	[mutablePlaylistArray removeObject:playlist];
	self.playlists = [NSArray arrayWithArray:mutablePlaylistArray];
}

- (void)loadPlaylists {
	NSMutableArray *playlistsMutableArray = [NSMutableArray new];
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *allKeys = [userDefaults dictionaryRepresentation].allKeys;
	for(NSString *key in allKeys){
		if([key containsString:@"LMPlaylist:"]){
			NSLog(@"Loading %@", key);
			[playlistsMutableArray addObject:[self playlistForPlaylistDictionary:[userDefaults objectForKey:key]]];
		}
	}
	
	self.playlists = [NSArray arrayWithArray:playlistsMutableArray];
}

- (BOOL)playlistExistsWithSystemPersistentID:(MPMediaEntityPersistentID)persistentID {
	for(LMPlaylist *playlist in self.playlists){
		if(playlist.systemPersistentID == persistentID){
			return YES;
		}
	}
	return NO;
}

- (void)internalizeSystemPlaylists {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	MPMediaQuery *everyonesPlaylistsQuery = [MPMediaQuery playlistsQuery];
	NSArray *systemPlaylists = [everyonesPlaylistsQuery collections];
	
	for(MPMediaPlaylist *systemPlaylist in systemPlaylists) {
		MPMediaPlaylistAttribute attribute = systemPlaylist.playlistAttributes;
		
		NSLog(@"%lld: %@", systemPlaylist.persistentID, [systemPlaylist valueForProperty:MPMediaPlaylistPropertyName]);
		
		if(attribute != MPMediaPlaylistAttributeSmart && attribute != MPMediaPlaylistAttributeGenius){ //We don't fuck with these
			if(![self playlistExistsWithSystemPersistentID:systemPlaylist.persistentID] && ![userDefaults objectForKey:[NSString stringWithFormat:@"deletedSystemPlaylist_%lld", systemPlaylist.persistentID]]){
				LMPlaylist *lignitePlaylist = [[LMPlaylist alloc]init];
				lignitePlaylist.title = systemPlaylist.name;
				lignitePlaylist.persistentID = random();
				lignitePlaylist.systemPersistentID = systemPlaylist.persistentID;
				lignitePlaylist.trackCollection = [[LMMusicTrackCollection alloc] initWithItems:systemPlaylist.items];
				[self savePlaylist:lignitePlaylist];
			}
		}
	}
}

/*  End internal playlist management code */

/* Begin playlist management understanding code */

- (void)launchPlaylistManagementWarningOnView:(UIView*)view withCompletionHandler:(void(^)(void))completionHandler {
	LMAlertView *alertView = [LMAlertView newAutoLayoutView];
	
	alertView.title = NSLocalizedString(@"PlaylistManagementUnderstandingTitle", nil);
	alertView.body = NSLocalizedString(@"PlaylistManagementUnderstandingBody", nil);
	alertView.alertOptionColours = @[ [LMColour ligniteRedColour] ];
	alertView.alertOptionTitles = @[ NSLocalizedString(@"IUnderstand", nil) ];
	
	[alertView launchOnView:view withCompletionHandler:^(NSUInteger optionSelected) {
		[self setUserUnderstandsPlaylistManagement:YES];
		
		completionHandler();
		
		NSLog(@"Cool, launch playlist creator");
	}];
}

- (BOOL)userUnderstandsPlaylistManagement {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMUserUnderstandsPlaylistManagementKey]){
		return [userDefaults boolForKey:LMUserUnderstandsPlaylistManagementKey];
	}
	return NO;
}

- (void)setUserUnderstandsPlaylistManagement:(BOOL)userUnderstandsPlaylistManagement {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:userUnderstandsPlaylistManagement forKey:LMUserUnderstandsPlaylistManagementKey];
	[userDefaults synchronize];
}

/* End playlist management understanding code */


/* Begin initialization code */

- (instancetype)init {
	self = [super init];
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.imageCache = [[SDImageCache alloc] initWithNamespace:LMPlaylistManagerImageCacheNamespaceKey];
	
	[self loadPlaylists];

	[self internalizeSystemPlaylists];
	
	NSLog(@"Done, got %d playlists.", (int)self.playlists.count);
	
	return self;
}

+ (LMPlaylistManager*)sharedPlaylistManager {
	static LMPlaylistManager *sharedPlaylistManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedPlaylistManager = [self new];
	});
	return sharedPlaylistManager;
}

/* End initialization code */

@end
