//
//  LMSpotifyLibrary.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>
#import "LMSpotifyLibrary.h"

@interface LMSpotifyLibrary()

/**
 The user's current library of tracks.
 */
@property CBLDatabase *libraryDatabase;


@property NSTimeInterval startTime;

@end

@implementation LMSpotifyLibrary

+ (instancetype)sharedLibrary {
	static LMSpotifyLibrary *sharedLibrary;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedLibrary = [self new];
		
		//Get the databases
		CBLManager *manager = [CBLManager sharedInstance];
		NSError *databaseFetchError = nil;
		
		sharedLibrary.libraryDatabase = [manager databaseNamed:@"library-tracks" error:&databaseFetchError];
		if(databaseFetchError || !sharedLibrary.libraryDatabase) {
			NSLog(@"Error getting a database, %@", databaseFetchError);
		}
		else{
			NSLog(@"Got all databases successfully.");
		}
		
		
		//Setup the views for querying
		CBLView *artistsView = [sharedLibrary.libraryDatabase viewNamed:@"artists"];
		[artistsView setMapBlock:MAPBLOCK({
			NSArray *artists = [doc objectForKey:@"artists"];
			for(NSDictionary *artist in artists){
				emit([artist objectForKey:@"id"], artist);
			}
		}) version:@"4"];
		
		CBLView *albumsView = [sharedLibrary.libraryDatabase viewNamed:@"albums"];
		[albumsView setMapBlock:MAPBLOCK({
			NSDictionary *album = [doc objectForKey:@"album"];
			emit([album objectForKey:@"id"], album);
		}) version:@"1"];
	});
	return sharedLibrary;
}

- (void)getUserLibraryWithNextURLString:(NSString*)nextURLString {
	if(nextURLString == nil){
		nextURLString = @"https://api.spotify.com/v1/me/tracks?limit=50&offset=0";
	}
	
	SPTAuth *authorization = [SPTAuth defaultInstance];
	SPTSession *spotifySession = authorization.session;
	
	if(spotifySession.isValid){
		NSLog(@"Session is valid (expires %@).", spotifySession.expirationDate);
		
		NSError *libraryError = nil;
		NSURLRequest *libraryRequest = [SPTRequest createRequestForURL:[NSURL URLWithString:nextURLString]
													   withAccessToken:spotifySession.accessToken
															httpMethod:@"GET"
																values:nil
													   valueBodyIsJSON:NO
												 sendDataAsQueryString:NO
																 error:&libraryError];
		
		[[SPTRequest sharedHandler] performRequest:libraryRequest callback:^(NSError *error, NSURLResponse *response, NSData *data) {
			if(error){
				NSLog(@"Error getting library JSON data: %@", error);
				return;
			}
			
			NSTimeInterval startTime = [[NSDate new] timeIntervalSince1970];
			
			NSLog(@"Got library JSON data (%@).", response);
			
			//Parse the JSON data into an NSDictionary
			NSError *jsonLibraryError = nil;
			NSDictionary *jsonLibrary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonLibraryError];
			
			if(jsonLibraryError){
				NSLog(@"Error parsing JSON data: %@.", jsonLibraryError);
				return;
			}
			
			NSLog(@"JSON library added at: %@", jsonLibrary);
			
			NSArray *jsonTracks = [jsonLibrary objectForKey:@"items"];
			
			for(NSDictionary *track in jsonTracks){
				NSMutableDictionary *newTrack = [NSMutableDictionary dictionaryWithDictionary:[track objectForKey:@"track"]];
				
				
				//Parse the time string from Spotify (ie. "2017-02-16T01:12:21Z"), which is at the root of the track object, and include it in the database object
				NSString *originalTimeString = [track objectForKey:@"added_at"];
				NSMutableString *fixedTimeString = [NSMutableString stringWithString:originalTimeString];
				[fixedTimeString replaceOccurrencesOfString:@"Z" withString:@"+0000" options:kNilOptions range:NSMakeRange(0, [originalTimeString length])];
				
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
				NSDate *timeAddedDate = [dateFormatter dateFromString:fixedTimeString];
				
				[newTrack setObject:@([timeAddedDate timeIntervalSince1970]) forKey:@"added_at"];
				
				
				//Save the track to the user's library database
				NSString *trackID = [newTrack objectForKey:@"id"];
				if(![self.libraryDatabase existingDocumentWithID:trackID]){ //Track document doesn't already exist
					CBLDocument *trackDatabaseDocument = [self.libraryDatabase documentWithID:trackID];
					NSError *trackDatabaseDocumentError = nil;
					if(![trackDatabaseDocument putProperties:newTrack error:&trackDatabaseDocumentError]) {
						NSLog(@"Error writing database document: %@", trackDatabaseDocumentError);
					}
					else{
						NSLog(@"Success writing database document (%@).", [trackDatabaseDocument.properties objectForKey:@"name"]);
					}
				}
			}
			
			NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
			
			NSLog(@"Took %f seconds to parse 50 items (URL %@).", endTime-startTime, nextURLString);
			
			NSString *nextURLFromJSONResponse = [jsonLibrary objectForKey:@"next"];
			NSLog(@"Next URL %@", [[nextURLFromJSONResponse class] description]);
			if(nextURLFromJSONResponse && [nextURLFromJSONResponse class] != [NSNull class]){
				[self getUserLibraryWithNextURLString:nextURLFromJSONResponse];
			}
			else{
				NSTimeInterval endTime = [[NSDate new] timeIntervalSince1970];
				NSLog(@"Done building user's library, took %f seconds.", endTime-self.startTime);
			}
		}];
	}
	else{
		NSLog(@"Session isn't valid, renewing.");
		
		[authorization renewSession:spotifySession callback:^(NSError *error, SPTSession *session) {
			if(error){
				NSLog(@"Error renewing session: %@", error);
				return;
			}
			
			authorization.session = session;
			
			[self buildDatabase];
		}];
	}
}

- (NSArray<LMMusicTrack*>*)musicTracks {
	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
	
	NSMutableArray *trackArray = [NSMutableArray new];
	
	NSError *queryError = nil;
	CBLQuery *query = [self.libraryDatabase createAllDocumentsQuery];
	query.allDocsMode = kCBLAllDocs;
	CBLQueryEnumerator *result = [query run:&queryError];
	if(queryError){
		NSLog(@"Error in querying all documents %@", queryError);
		return @[];
	}
	for(CBLQueryRow *row in result) {
		[trackArray addObject:row.document.properties];
	}
	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
	
	NSLog(@"Got all tracks (%ld) in %f seconds.", trackArray.count, endTime-startTime);

	return trackArray;
}

- (NSArray<LMMusicTrackCollection*>*)artists {
	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
	
	NSError *queryError = nil;
	CBLQuery *query = [[self.libraryDatabase viewNamed:@"artists"] createQuery];
	
	CBLQueryEnumerator* result = [query run:&queryError];
	if(queryError){
		NSLog(@"Error in querying: %@", queryError);
	}
	
	NSMutableArray *artistIDsArray = [NSMutableArray new];
	
	for (CBLQueryRow* row in result) {
		NSDictionary *artist = row.value;
		NSString *artistID = [artist objectForKey:@"id"];
		if(![artistIDsArray containsObject:artistID]){
			[artistIDsArray addObject:artistID];
		}
	}
	NSLog(@"Got %ld artists (%ld no dupes).", result.count, artistIDsArray.count);
	
	NSArray *allTracks = [self musicTracks];
	
	NSMutableArray *artistCollectionsArray = [NSMutableArray new];
	
	//Create a dictionary with a key representing every collection/array
	NSMutableDictionary *collectionsArrayDictionary = [NSMutableDictionary new];
	for(NSString *artistID in artistIDsArray){
		[collectionsArrayDictionary setObject:[NSMutableArray new] forKey:artistID];
	}
	
	//Loop through each music track in the complete library
	for(LMMusicTrack *musicTrack in allTracks){
		NSArray *artists = [musicTrack objectForKey:@"artists"];
		//Loop through that track's artists
		for(NSDictionary *artist in artists){
			//Add that track to the artist's list of songs
			NSMutableArray *tracksByThisArtist = [collectionsArrayDictionary objectForKey:[artist objectForKey:@"id"]];
			[tracksByThisArtist addObject:musicTrack];
		}
	}
	
	//For every key/artist ID in the collections array dictionary, add a collection with those items to the array of collections
	for(NSString *key in [collectionsArrayDictionary allKeys]){
		NSMutableArray *collectionArray = [collectionsArrayDictionary objectForKey:key];
		[artistCollectionsArray addObject:@{ @"items":collectionArray }];
	}
	
	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
	
	NSLog(@"Got artist collections in %f seconds.", endTime-startTime);
	
	return artistCollectionsArray;
//	return artistCollectionsArray;
}

- (NSArray<LMMusicTrackCollection*>*)albums {
	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
	
	NSError *queryError = nil;
	CBLQuery *query = [[self.libraryDatabase viewNamed:@"albums"] createQuery];
	
	CBLQueryEnumerator* result = [query run:&queryError];
	if(queryError){
		NSLog(@"Error in querying: %@", queryError);
	}
	
	NSMutableArray *albumIDsArray = [NSMutableArray new];
	
	for (CBLQueryRow* row in result) {
		NSDictionary *album = row.value;
		NSString *albumID = [album objectForKey:@"id"];
		if(![albumIDsArray containsObject:albumID]){
			[albumIDsArray addObject:albumID];
		}
	}
	NSLog(@"Got %ld albums (%ld no dupes).", result.count, albumIDsArray.count);
	
	NSArray *allTracks = [self musicTracks];
	
	NSMutableArray *albumCollectionsArray = [NSMutableArray new];
	
	//Create a dictionary with a key representing every collection/array
	NSMutableDictionary *collectionsArrayDictionary = [NSMutableDictionary new];
	for(NSString *albumID in albumIDsArray){
		[collectionsArrayDictionary setObject:[NSMutableArray new] forKey:albumID];
	}
	
	//Loop through each music track in the complete library
	for(LMMusicTrack *musicTrack in allTracks){
		//Get the album for that track
		NSDictionary *album = [musicTrack objectForKey:@"album"];
		//Add that track to the album's list of songs
		NSMutableArray *tracksByThisAlbum = [collectionsArrayDictionary objectForKey:[album objectForKey:@"id"]];
//		NSLog(@"Tracks %@", tracksByThisAlbum);
		[tracksByThisAlbum addObject:musicTrack];
	}
	
	//For every key/album ID in the collections array dictionary, add a collection with those items to the array of collections
	for(NSString *key in [collectionsArrayDictionary allKeys]){
		NSMutableArray *collectionArray = [collectionsArrayDictionary objectForKey:key];
		[albumCollectionsArray addObject:@{ @"items":collectionArray }];
	}
	
	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
	
	NSLog(@"Got album collections in %f seconds.", endTime-startTime);
	
//	return @[];
		return albumCollectionsArray;
}

- (void)buildDatabase {
//	self.startTime = [[NSDate new]timeIntervalSince1970];
//	[self getUserLibraryWithNextURLString:nil];
	
	
	
	
//	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
//
//	NSError *queryError = nil;
//	CBLQuery *query = [[self.libraryDatabase viewNamed:@"artists"] createQuery];
//	
//	CBLQueryEnumerator* result = [query run:&queryError];
//	if(queryError){
//		NSLog(@"Error in querying: %@", queryError);
//	}
//	
//	NSMutableArray *artistIDsArray = [NSMutableArray new];
//	
//	for (CBLQueryRow* row in result) {
//		NSDictionary *artist = row.value;
//		NSString *artistID = [artist objectForKey:@"id"];
//		if(![artistIDsArray containsObject:artistID]){
//			[artistIDsArray addObject:artistID];
////			NSLog(@"%ld: %@", artistIDsArray.count, [artist objectForKey:@"name"]);
//		}
//	}
//	NSLog(@"Got %ld items (%ld no dupes).", result.count, artistIDsArray.count);
//
//	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
//	
//	NSLog(@"Done %f seconds", endTime-startTime);
	
//	NSTimeInterval startTime = [[NSDate new]timeIntervalSince1970];
//	
//	NSError *queryError = nil;
//	CBLQuery *query = [self.libraryDatabase createAllDocumentsQuery];
//	query.allDocsMode = kCBLAllDocs;
//	CBLQueryEnumerator *result = [query run:&queryError];
//	if(queryError){
//		NSLog(@"Error in querying all documents %@", queryError);
//		return;
//	}
//	for(CBLQueryRow *row in result) {
//		NSLog(@"Got %@", row.documentID);
//	}
//	NSLog(@"Got %ld items.", result.count);
//	
//	NSTimeInterval endTime = [[NSDate new]timeIntervalSince1970];
//	
//	NSLog(@"Done %f seconds", endTime-startTime);
}

@end
