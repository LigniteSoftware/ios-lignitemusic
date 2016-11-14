//
//  LMGenreView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/13/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMGenreView.h"
#import "LMMusicPlayer.h"
#import "LMBrowsingView.h"

@interface LMGenreView()

@property LMBrowsingView *browsingView;

@end

@implementation LMGenreView

- (void)reloadSourceSelectorInfo {
	[self.browsingView reloadSourceSelectorInfo];
}

- (void)setup {
	self.browsingView = [LMBrowsingView newAutoLayoutView];
	
	self.browsingView.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeGenres];
	self.browsingView.musicType = LMMusicTypeGenres;
	[self addSubview:self.browsingView];
	
	[self.browsingView autoPinEdgesToSuperviewEdges];
	
	[self.browsingView setup];
}

@end
