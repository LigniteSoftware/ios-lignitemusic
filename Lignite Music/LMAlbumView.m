//
//  LMAlbumViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/26/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAlbumView.h"
#import "LMBrowsingView.h"

@interface LMAlbumView ()

@property BOOL loaded;

@end

@implementation LMAlbumView

- (void)reloadSourceSelectorInfo {
	[self.browsingView reloadSourceSelectorInfo];
}

- (void)layoutSubviews {
	NSLog(@"Changed to! %@", NSStringFromCGRect(self.frame));
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.browsingView = [LMBrowsingView newAutoLayoutView];
		self.browsingView.musicTrackCollections = [[LMMusicPlayer sharedMusicPlayer] queryCollectionsForMusicType:LMMusicTypeAlbums];
		self.browsingView.musicType = LMMusicTypeAlbums;
		self.browsingView.rootViewController = self.coreViewController;
		[self addSubview:self.browsingView];
		
		[self.browsingView autoPinEdgesToSuperviewEdges];
		
		[self.browsingView setup];
	}
}

@end
