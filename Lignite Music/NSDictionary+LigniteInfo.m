//
//  NSDictionary+LigniteInfo.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "NSDictionary+LigniteInfo.h"

@implementation NSDictionary (LigniteInfo)

- (NSString*)titleForMusicType:(uint8_t)musicType {
	return @"title here :)";
}

- (BOOL)variousArtists {
	return YES;
}

- (BOOL)variousGenres {
	return YES;
}

- (NSUInteger)numberOfAlbums {
	return 69;
}

- (LMMusicTrack*)representativeItem {
	return [self.items objectAtIndex:0];
}

- (NSArray*)items {
	return [self objectForKey:@"items"];
}

- (NSInteger)trackCount {
	return [self.items count];
}

@end
