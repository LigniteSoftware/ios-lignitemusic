//
//  LMWMusicTrackInfo.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/8/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWMusicTrackInfo.h"

@interface LMWMusicTrackInfo()

/**
 The album art to be stored if set by an external source. Otherwise, the album art variable will return the app icon.
 */
@property UIImage *storedAlbumArt;

@end

@implementation LMWMusicTrackInfo

@synthesize albumArt = _albumArt;

- (UIImage*)albumArtNotCropped {
	if(self.storedAlbumArt){
		return self.storedAlbumArt;
	}
	
	return [UIImage imageNamed:@"watch_no_cover_art_not_cropped"];
}

- (UIImage*)albumArt {
	if(self.storedAlbumArt){
		return self.storedAlbumArt;
	}
	
	return [UIImage imageNamed:@"watch_no_cover_art"];
}

- (void)setAlbumArt:(UIImage *)albumArt {
	self.storedAlbumArt = albumArt;
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.indexInCollection = -1;
	}
	return self;
}

@end
