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
 The database of artists that the user has had in their library. Since artists are never removed from this database, there may be artists
 */
@property CBLDatabase *artistsDatabase;

/**
 The user's current library.
 */
@property CBLDatabase *tracksDatabase;

@end

@implementation LMSpotifyLibrary

+ (instancetype)sharedLibrary {
	static LMSpotifyLibrary *sharedLibrary;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedLibrary = [self new];
	});
	return sharedLibrary;
}

- (void)test {
	NSLog(@"Hey!");
	
	SPTAuth *authorization = [SPTAuth defaultInstance];
	SPTSession *spotifySession = authorization.session;
	
	if(spotifySession.isValid){
		NSLog(@"Session is valid (expires %@).", spotifySession.expirationDate);
		
		NSError *libraryError = nil;
		NSURLRequest *libraryRequest = [SPTYourMusic createRequestForCurrentUsersSavedTracksWithAccessToken:spotifySession.accessToken error:&libraryError];
		
		[[SPTRequest sharedHandler] performRequest:libraryRequest callback:^(NSError *error, NSURLResponse *response, NSData *data) {
			if(error){
				NSLog(@"Error getting library JSON data: %@", error);
				return;
			}
			
			NSLog(@"Got library JSON data (%@).", response);
			
			NSError *jsonLibraryError = nil;
			NSDictionary *jsonLibrary = [NSJSONSerialization JSONObjectWithData:data options:kNilOptions error:&jsonLibraryError];
			
			if(jsonLibraryError){
				NSLog(@"Error parsing JSON data: %@.", jsonLibraryError);
				return;
			}
			
			NSLog(@"JSON library added at: %@", jsonLibrary);
			
			NSArray *jsonTracks = [jsonLibrary objectForKey:@"items"];
			
			for(NSDictionary *track in jsonTracks){
				NSMutableDictionary *newTrack = [NSMutableDictionary dictionaryWithDictionary:track];
				
				NSString *originalTimeString = [track objectForKey:@"added_at"];
				NSMutableString *fixedTimeString = [NSMutableString stringWithString:originalTimeString];
				[fixedTimeString replaceOccurrencesOfString:@"Z" withString:@"+0000" options:kNilOptions range:NSMakeRange(0, [originalTimeString length])];
				
				NSDateFormatter *dateFormatter = [[NSDateFormatter alloc] init];
				[dateFormatter setDateFormat:@"yyyy-MM-dd'T'HH:mm:ssZ"];
				NSDate *timeAddedDate = [dateFormatter dateFromString:fixedTimeString];
				
				NSLog(@"Track %@ added at %@ (%f/%@)", [[track objectForKey:@"track"] objectForKey:@"name"], timeAddedDate, [timeAddedDate timeIntervalSince1970], originalTimeString);
				
				[newTrack setObject:@([timeAddedDate timeIntervalSince1970]) forKey:@"added_at"];

				NSLog(@"Track %@", newTrack);
				
//				NSLog(@"Time local %@, time UTC %@");
			}
		}];
		
//		CBLManager *manager = [CBLManager sharedInstance];
//		NSError *error = nil;
//		self.database = [manager databaseNamed: @"library-cache" error: &error];
//		if (!self.database) {
//			NSLog(@"Error getting database, %@", error);
//		}
//		else{
//			NSLog(@"Got database.");
//			
//			
//		}
	}
	else{
		NSLog(@"Session isn't valid, renewing.");
		
		[authorization renewSession:spotifySession callback:^(NSError *error, SPTSession *session) {
			if(error){
				NSLog(@"Error renewing session: %@", error);
				return;
			}
			
			authorization.session = session;
			
			[self test];
		}];
	}
}

@end
