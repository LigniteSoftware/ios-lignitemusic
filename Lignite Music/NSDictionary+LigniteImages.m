
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
	return @"title :)";
}

@end
