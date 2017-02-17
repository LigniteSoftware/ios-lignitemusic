
//
//  NSDictionary+LigniteImages.m
//  Lignite Music
//
//  Created by Edwin Finch on 2/16/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "NSDictionary+LigniteImages.h"
#import "LMAppIcon.h"

@implementation NSDictionary (LigniteImages)

- (UIImage*)albumArt {
	return [self uncorrectedAlbumArt];
}

- (UIImage*)uncorrectedAlbumArt {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
}

- (UIImage*)artistImage {
	return [LMAppIcon imageForIcon:LMIconNoAlbumArt75Percent];
}

- (LMMusicTrackPersistentID)persistentID {
	return 0;
}

- (LMMusicTrackPersistentID)albumPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)artistPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)composerPersistentID {
	return 0;
}

- (LMMusicTrackPersistentID)genrePersistentID {
	return 0;
}

- (NSTimeInterval)playbackDuration {
	return 60;
}

- (NSString*)title {
	return [self objectForKey:@"name"];
}

- (NSString*)artist {
	NSArray *artists = [self objectForKey:@"artists"];
	NSMutableString *artistsString = [NSMutableString stringWithFormat:@""];
	
	for(NSDictionary *artist in artists){
		NSString *artistName = [artist objectForKey:@"name"];
		[artistsString appendString:[NSString stringWithFormat:@"%@, ", artistName]];
	}
	
	return [artistsString stringByReplacingCharactersInRange:NSMakeRange([artistsString length]-2, 2) withString:@""];
}

- (NSString*)albumTitle {
	return [[self objectForKey:@"album"] objectForKey:@"name"];
}

- (NSString*)composer {
	return @"composer :)";
}

- (NSString*)genre {
	return @"genre :)";
}

@end
