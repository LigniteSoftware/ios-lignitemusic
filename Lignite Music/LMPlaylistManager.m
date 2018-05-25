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
#import "LMAlertViewController.h"
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

@synthesize userUnderstandsPlaylistCreation = _userUnderstandsPlaylistCreation;
@synthesize userUnderstandsPlaylistEditing = _userUnderstandsPlaylistEditing;
@synthesize playlistTrackCollections = _playlistTrackCollections;

/* Begin internal playlist management code */

- (NSArray<LMMusicTrackCollection*>*)playlistTrackCollections {
	NSMutableArray *musicTrackCollectionsArray = [NSMutableArray new];
	for(LMPlaylist *playlist in self.playlists){
		[musicTrackCollectionsArray addObject:playlist.trackCollection ? playlist.trackCollection : [[LMMusicTrackCollection alloc]initWithItems:@[]]];
	}
	return [NSArray arrayWithArray:musicTrackCollectionsArray];
}

- (LMPlaylist*)playlistForPersistentID:(long long)persistentID cached:(BOOL)cached {
	if(cached){
		NSArray<LMPlaylist*> *playlists = [self playlists];
		
		for(LMPlaylist *playlist in playlists){
			if(playlist.persistentID == persistentID){
				return playlist;
			}
		}
	}
	else{
		NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
		NSString *playlistKey = [NSString stringWithFormat:@"LMPlaylist:%lld", persistentID];
		NSDictionary *playlistDictionary = [userDefaults objectForKey:playlistKey];
		
//		NSLog(@"Loading %@", playlistKey);
		
		return [self playlistForPlaylistDictionary:playlistDictionary];
	}
	
	return nil;
}

- (LMPlaylist*)playlistForPersistentID:(long long)persistentID {
	return [self playlistForPersistentID:persistentID cached:YES];
}

- (LMPlaylist*)playlistForPlaylistDictionary:(NSDictionary*)playlistDictionary {
	LMPlaylist *playlist = [LMPlaylist new];
	
	playlist.title = [playlistDictionary objectForKey:@"title"];
	playlist.systemPersistentID = [[playlistDictionary objectForKey:@"systemPersistentID"] longLongValue];
	playlist.userPortedToLignitePlaylist = [[playlistDictionary objectForKey:@"portedToLignitePlaylist"] boolValue];
	playlist.persistentID = [[playlistDictionary objectForKey:@"persistentID"] longLongValue];
	playlist.enhancedShuffleAll = [[playlistDictionary objectForKey:@"enhancedShuffleAll"] longLongValue];
	
	playlist.enhancedConditionsDictionary = [playlistDictionary objectForKey:@"enhancedConditionsDictionary"];
	if(playlist.enhancedConditionsDictionary){
		playlist.enhanced = YES;
		[playlist regenerateEnhancedPlaylist];
	}
	
	if(!playlist.enhanced){
		NSMutableArray *trackMutableArray = [NSMutableArray new];
		NSArray *trackPersistentIDArray = [playlistDictionary objectForKey:@"trackCollectionPersistentIDs"];
		for(NSNumber *trackPersistentIDNumber in trackPersistentIDArray){
			MPMediaPropertyPredicate *predicate = [MPMediaPropertyPredicate predicateWithValue:trackPersistentIDNumber
																				   forProperty:MPMediaItemPropertyPersistentID];
			MPMediaQuery *query = [[MPMediaQuery alloc] init];
			[query addFilterPredicate: predicate];
			
			[trackMutableArray addObjectsFromArray:query.items];			
		}
		playlist.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:trackMutableArray];
	}
	
	playlist.image = [self.imageCache imageFromDiskCacheForKey:[NSString stringWithFormat:@"%lld", playlist.persistentID]];
	
	return playlist;
}

- (NSDictionary*)playlistDictionaryForPlaylist:(LMPlaylist*)playlist {
	NSMutableDictionary *mutableDictionary = [NSMutableDictionary new];
	
	NSMutableArray *songPersistentIDArray = [NSMutableArray new];
	if(!playlist.enhanced){
		for(LMMusicTrack *track in playlist.trackCollection.items){
			[songPersistentIDArray addObject:@(track.persistentID)];
		}
	}
	
	[mutableDictionary setObject:playlist.title forKey:@"title"];
	[mutableDictionary setObject:@(playlist.systemPersistentID) forKey:@"systemPersistentID"];
	[mutableDictionary setObject:@(playlist.userPortedToLignitePlaylist) forKey:@"portedToLignitePlaylist"];
	[mutableDictionary setObject:@(playlist.persistentID) forKey:@"persistentID"];
	[mutableDictionary setObject:[NSArray arrayWithArray:songPersistentIDArray] forKey:@"trackCollectionPersistentIDs"];
	[mutableDictionary setObject:@(playlist.enhancedShuffleAll) forKey:@"enhancedShuffleAll"];
	
	if(playlist.image){
		[self.imageCache storeImage:playlist.image forKey:[NSString stringWithFormat:@"%lld", playlist.persistentID] completion:nil];
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
	
	BOOL containsPlaylist = NO;
	
	for(NSInteger i = 0; i < self.playlists.count; i++){
		LMPlaylist *cachedPlaylist = [self.playlists objectAtIndex:i];
		if(cachedPlaylist.persistentID == playlist.persistentID){
			containsPlaylist = YES;
			break;
		}
	}
	
	if(!containsPlaylist){
		NSMutableArray *mutablePlaylistArray = [[NSMutableArray alloc]initWithArray:self.playlists];
		[mutablePlaylistArray addObject:playlist];
		self.playlists = [NSArray arrayWithArray:[mutablePlaylistArray
												  sortedArrayUsingDescriptors:@[
																				[self.musicPlayer alphabeticalSortDescriptorForSortKey:@"title"]
																				]]];
	}
	
//	NSLog(@"Saving playlist with title %@ persistentID %llu count %d", playlist.title, playlist.persistentID, (int)playlist.trackCollection.count);
	
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setObject:[self playlistDictionaryForPlaylist:playlist]
					 forKey:[self storageKeyForPlaylist:playlist]];
	if(!playlist.image){
		[self.imageCache removeImageForKey:[NSString stringWithFormat:@"%lld", playlist.persistentID] withCompletion:nil];
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
	self.playlists = [NSArray arrayWithArray:[mutablePlaylistArray
											  sortedArrayUsingDescriptors:@[
																	 [self.musicPlayer alphabeticalSortDescriptorForSortKey:@"title"]
																	 ]]];
}

- (void)reloadCachedPlaylists {
	NSMutableArray *playlistsMutableArray = [NSMutableArray new];
	
	if(self.playlists){ //Has already loaded once, internalizing will not overwrite anything with this catch.
		[self internalizeSystemPlaylists];
	}
		
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSArray *allKeys = [userDefaults dictionaryRepresentation].allKeys;
	for(NSString *key in allKeys){
		if([key containsString:@"LMPlaylist:"]){
//			NSLog(@"Loading %@", key);
			LMPlaylist *playlist = [self playlistForPlaylistDictionary:[userDefaults objectForKey:key]];
			[playlistsMutableArray addObject:playlist];
//			NSLog(@"Loaded %@ with title %@, %d songs", key, playlist.title, (int)playlist.trackCollection.count);
		}
	}
	
	self.playlists = [NSArray arrayWithArray:[playlistsMutableArray
											  sortedArrayUsingDescriptors:@[
																			[self.musicPlayer alphabeticalSortDescriptorForSortKey:@"title"]
																			]]];
}

- (LMPlaylist*)playlistForSystemPersistentID:(MPMediaEntityPersistentID)persistentID {
	for(LMPlaylist *playlist in self.playlists){
		if(playlist.systemPersistentID == persistentID){
			return playlist;
		}
	}
	return nil;
}

- (void)internalizeSystemPlaylists {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	
	MPMediaQuery *everyonesPlaylistsQuery = [MPMediaQuery playlistsQuery];
	NSArray *systemPlaylists = [everyonesPlaylistsQuery collections];
	
	for(MPMediaPlaylist *systemPlaylist in systemPlaylists) {
		MPMediaPlaylistAttribute attribute = systemPlaylist.playlistAttributes;
		
//		NSLog(@"%lld: %@", systemPlaylist.persistentID, [systemPlaylist valueForProperty:MPMediaPlaylistPropertyName]);
		
		if(attribute != MPMediaPlaylistAttributeSmart && attribute != MPMediaPlaylistAttributeGenius){ //We don't fuck with these
			LMPlaylist* playlistWithSystemPersistentID = [self playlistForSystemPersistentID:systemPlaylist.persistentID];
			if(!playlistWithSystemPersistentID && ![userDefaults objectForKey:[NSString stringWithFormat:@"deletedSystemPlaylist_%lld", systemPlaylist.persistentID]]){
				LMPlaylist *lignitePlaylist = [[LMPlaylist alloc]init];
				lignitePlaylist.title = systemPlaylist.name;
				lignitePlaylist.persistentID = random();
				lignitePlaylist.systemPersistentID = systemPlaylist.persistentID;
				lignitePlaylist.trackCollection = [[LMMusicTrackCollection alloc] initWithItems:systemPlaylist.items];
				[self savePlaylist:lignitePlaylist];
			}
			else if(playlistWithSystemPersistentID && !playlistWithSystemPersistentID.userPortedToLignitePlaylist){
//				NSLog(@"The playlist %@ (%lld) was an iTunes playlist, and was not ported, so we're gonna load the iTune's playlist's tracks.", playlistWithSystemPersistentID.title, playlistWithSystemPersistentID.persistentID);
				playlistWithSystemPersistentID.trackCollection = [[LMMusicTrackCollection alloc] initWithItems:systemPlaylist.items];
				[self savePlaylist:playlistWithSystemPersistentID];
			}
		}
	}
}

/*  End internal playlist management code */

/* Begin playlist management understanding code */

- (void)launchPlaylistManagementWarningWithCompletionHandler:(void(^)(void))completionHandler {
	LMAlertViewController *alertViewController = [LMAlertViewController new];
	alertViewController.titleText = NSLocalizedString(@"PlaylistManagementUnderstandingTitle", nil);
	alertViewController.bodyText = NSLocalizedString(@"PlaylistManagementUnderstandingBody", nil);
	alertViewController.checkboxText = NSLocalizedString(@"PlaylistManagementUnderstandingConfirmationCheckboxText", nil);
	alertViewController.checkboxMoreInformationText = NSLocalizedString(@"TapHereForMoreInformation", nil);
	alertViewController.checkboxMoreInformationLink = @"https://www.LigniteMusic.com/playlist_limitations";
	alertViewController.alertOptionColours = @[ [LMColour mainColourDark], [LMColour mainColour] ];
	alertViewController.alertOptionTitles = @[ NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"CreatePlaylist", nil) ];
	alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
		if(checkboxChecked){
			[self setUserUnderstandsPlaylistCreation:YES];
			
			completionHandler();
			
			NSLog(@"Cool, launch playlist creator");
		}
	};
	[self.navigationController presentViewController:alertViewController
											animated:YES
										  completion:nil];
}

- (void)launchPlaylistEditingWarningWithCompletionHandler:(void(^)(void))completionHandler {
	LMAlertViewController *alertViewController = [LMAlertViewController new];
	alertViewController.titleText = NSLocalizedString(@"ConvertPlaylistTitle", nil);
	alertViewController.bodyText = NSLocalizedString(@"ConvertPlaylistBody", nil);
	alertViewController.checkboxText = NSLocalizedString(@"ConvertPlaylistCheckboxText", nil);
	alertViewController.checkboxMoreInformationText = NSLocalizedString(@"TapHereForMoreInformation", nil);
	alertViewController.checkboxMoreInformationLink = @"https://www.LigniteMusic.com/playlist_limitations";
	alertViewController.alertOptionColours = @[ [LMColour mainColourDark], [LMColour mainColour] ];
	alertViewController.alertOptionTitles = @[ NSLocalizedString(@"Cancel", nil), NSLocalizedString(@"StartEditing", nil) ];
	alertViewController.completionHandler = ^(NSUInteger optionSelected, BOOL checkboxChecked) {
		if(checkboxChecked){
			[self setUserUnderstandsPlaylistEditing:YES];
			
			completionHandler();
			
			NSLog(@"Cool, launch playlist editor for playlist");
		}
	};
	[self.navigationController presentViewController:alertViewController
											animated:YES
										  completion:nil];
}

- (BOOL)userUnderstandsPlaylistCreation {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMUserUnderstandsPlaylistCreationKey]){
		return [userDefaults boolForKey:LMUserUnderstandsPlaylistCreationKey];
	}
	return NO;
}

- (void)setUserUnderstandsPlaylistCreation:(BOOL)userUnderstands {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:userUnderstands forKey:LMUserUnderstandsPlaylistCreationKey];
	[userDefaults synchronize];
}

- (BOOL)userUnderstandsPlaylistEditing {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	if([userDefaults objectForKey:LMUserUnderstandsPlaylistEditingKey]){
		return [userDefaults boolForKey:LMUserUnderstandsPlaylistEditingKey];
	}
	return NO;
}

- (void)setUserUnderstandsPlaylistEditing:(BOOL)userUnderstands {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	[userDefaults setBool:userUnderstands forKey:LMUserUnderstandsPlaylistEditingKey];
	[userDefaults synchronize];
}

/* End playlist management understanding code */


/* Begin initialization code */

- (instancetype)init {
	self = [super init];
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.imageCache = [[SDImageCache alloc] initWithNamespace:LMPlaylistManagerImageCacheNamespaceKey];
	
	[self reloadCachedPlaylists];

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
