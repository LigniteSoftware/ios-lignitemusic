//
//  LMMusicTrack.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "LMMusicTrack.h"

@implementation LMMusicTrack

- (instancetype)initWithMPMediaItem:(MPMediaItem*)item {
	self = [super init];
	if(self) {
		self.title = item.title;
		self.artist = item.artist;
		self.albumTitle = item.albumTitle;
		self.genre = item.genre;
		
		self.playbackDuration = item.playbackDuration;
		
		self.sourceTrack = item;
	}
	else{
		NSLog(@"Error creating LMMusicTrack with MPMediaItem %@!", item);
	}
	return self;
}

@end
