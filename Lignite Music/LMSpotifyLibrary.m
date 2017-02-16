//
//  LMSpotifyLibrary.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <CouchbaseLite/CouchbaseLite.h>
#import "LMSpotifyLibrary.h"
#import "Spotify.h"

@interface LMSpotifyLibrary()

/**
 The user's current library of tracks.
 */
@property CBLDatabase *tracksDatabase;

/**
 The database of albums which are in the user's library.
 */
@property CBLDatabase *albumsDatabase;

/**
 The database of artists that the user has in their library.
 */
@property CBLDatabase *artistsDatabase;

@end

@implementation LMSpotifyLibrary

+ (instancetype)sharedLibrary {
	static LMSpotifyLibrary *sharedLibrary;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedLibrary = [self new];
		
		CBLManager *manager = [CBLManager sharedInstance];
		NSError *databaseFetchError = nil;
		sharedLibrary.tracksDatabase = [manager databaseNamed: @"library-tracks" error: &databaseFetchError];
		sharedLibrary.albumsDatabase = [manager databaseNamed: @"library-albums" error: &databaseFetchError];
		sharedLibrary.artistsDatabase = [manager databaseNamed: @"library-artists" error: &databaseFetchError];
		if(databaseFetchError || (!sharedLibrary.tracksDatabase || !sharedLibrary.albumsDatabase || !sharedLibrary.artistsDatabase)) {
			NSLog(@"Error getting a database, %@", databaseFetchError);
		}
		else{
			NSLog(@"Got all databases successfully.");
		}
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
				
				
				//Save the track to the tracks database
				NSString *trackID = [newTrack objectForKey:@"id"];
				if(![self.tracksDatabase existingDocumentWithID:trackID]){ //Track document doesn't already exist
					CBLDocument *trackDatabaseDocument = [self.tracksDatabase documentWithID:trackID];
					NSError *trackDatabaseDocumentError = nil;
					if(![trackDatabaseDocument putProperties:newTrack error:&trackDatabaseDocumentError]) {
						NSLog(@"Error writing database document: %@", trackDatabaseDocumentError);
					}
					else{
						NSLog(@"Success writing database document (%@).", [trackDatabaseDocument.properties objectForKey:@"name"]);
					}
				}
				
				
				//Save the artists that are in the track to the artists database
				NSArray *jsonArtists = [newTrack objectForKey:@"artists"];
				for(NSDictionary *artist in jsonArtists){
					NSLog(@"Artist %@", [artist objectForKey:@"name"]);
					
					NSString *artistID = [artist objectForKey:@"id"];
					if(![self.artistsDatabase existingDocumentWithID:artistID]){ //Artist document doesn't already exist
						CBLDocument *artistDatabaseDocument = [self.artistsDatabase documentWithID:artistID];
						NSError *artistDatabaseDocumentError = nil;
						if(![artistDatabaseDocument putProperties:artist error:&artistDatabaseDocumentError]) {
							NSLog(@"Error writing artist database document: %@", artistDatabaseDocumentError);
						}
						else{
							NSLog(@"Success writing artist database document (%@).", [artistDatabaseDocument.properties objectForKey:@"name"]);
						}
					}
				}
				
				
				//Save the album to the albums database
				NSDictionary *album = [newTrack objectForKey:@"album"];
				NSString *albumID = [album objectForKey:@"id"];
				if(![self.albumsDatabase existingDocumentWithID:albumID]){ //Album document doesn't already exist
					CBLDocument *albumDatabaseDocument = [self.albumsDatabase documentWithID:albumID];
					NSError *albumDatabaseDocumentError = nil;
					if(![albumDatabaseDocument putProperties:album error:&albumDatabaseDocumentError]) {
						NSLog(@"Error writing album database document: %@", albumDatabaseDocumentError);
					}
					else{
						NSLog(@"Success writing album database document (%@).", [albumDatabaseDocument.properties objectForKey:@"name"]);
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
				NSLog(@"Done building user's library.");
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

- (void)buildDatabase {
	[self getUserLibraryWithNextURLString:nil];
}

@end
