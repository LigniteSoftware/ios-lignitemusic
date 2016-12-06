//
//  LMPlaylistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/9/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistView.h"
#import "LMMusicPlayer.h"
#import "LMBrowsingView.h"

@interface LMPlaylistView()

@end

@implementation LMPlaylistView

- (void)reloadSourceSelectorInfo {
	[self.browsingView reloadSourceSelectorInfo];
}

- (void)setup {
	self.browsingView = [LMBrowsingView newAutoLayoutView];
	
	self.browsingView.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypePlaylists];
	self.browsingView.musicType = LMMusicTypePlaylists;
	self.browsingView.rootViewController = self.coreViewController;
	[self addSubview:self.browsingView];
	
	[self.browsingView autoPinEdgesToSuperviewEdges];
	
	[self.browsingView setup];
}

@end
