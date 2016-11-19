//
//  LMArtistView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMArtistView.h"
#import "LMBrowsingView.h"

@interface LMArtistView ()

@property LMBrowsingView *browsingView;

@property BOOL loaded;

@end

@implementation LMArtistView

- (void)reloadSourceSelectorInfo {
	[self.browsingView reloadSourceSelectorInfo];
}

- (void)setup {
	self.browsingView = [LMBrowsingView newAutoLayoutView];
	self.browsingView.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeArtists];
	self.browsingView.musicType = LMMusicTypeArtists;
	[self addSubview:self.browsingView];
	
	[self.browsingView autoPinEdgesToSuperviewEdges];
	
	[self.browsingView setup];
}

@end
