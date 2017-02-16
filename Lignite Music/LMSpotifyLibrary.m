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

@property CBLDatabase *database;

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
	NSLog(@"Hey");
	
	CBLManager *manager = [CBLManager sharedInstance];
	NSError *error = nil;
	self.database = [manager databaseNamed: @"library-cache" error: &error];
	if (!self.database) {
		NSLog(@"Error getting database, %@", error);
	}
	else{
		NSLog(@"Got database.");
		
		
	}
}

@end
