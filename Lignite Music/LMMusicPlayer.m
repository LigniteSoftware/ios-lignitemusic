//
//  LMMusicPlayer.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMusicPlayer.h"

@interface LMMusicPlayer()

@property MPMusicPlayerController *systemMusicPlayer;

@end

@implementation LMMusicPlayer

- (instancetype)init {
	self = [super init];
	if(self){
		self.systemMusicPlayer = [MPMusicPlayerController systemMusicPlayer];
	}
	else{
		NSLog(@"Fatal error! Failed to create instance of LMMusicPlayer.");
	}
	return self;
}

- (void)skipToNextTrack {
	
}

- (void)skipToBeginning {
	
}

- (void)skipToPreviousItem {
	
}

- (void)setNowPlayingTrack:(LMMusicTrack*)nowPlayingTrack {
	if(self.playerType == LMMusicPlayerTypeSystemMusicPlayer){
		MPMediaItem *associatedMediaItem = nowPlayingTrack.sourceTrack;
		self.systemMusicPlayer.nowPlayingItem = associatedMediaItem;
	}
	self.nowPlayingTrack = nowPlayingTrack;
}

- (LMMusicTrack*)nowPlayingTrack {
	return self.nowPlayingTrack;
}

@end
