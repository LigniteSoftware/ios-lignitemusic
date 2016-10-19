//
//  LMCoreViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/5/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMAppDelegate.h"
#import "LMCoreViewController.h"
#import "LMMusicPlayer.h"
#import "LMAlbumView.h"
#import "LMNowPlayingView.h"
#import "LMBrowsingAssistantView.h"
#import "LMTitleView.h"
#import "LMSourceSelectorView.h"
#import "LMSource.h"
#import "LMExtras.h"

@interface LMCoreViewController () <LMMusicPlayerDelegate, LMSourceDelegate>

@property LMMusicPlayer *musicPlayer;

@property LMNowPlayingView *nowPlayingView;

@property LMAlbumView *albumView;
@property LMTitleView *titleView;

@property LMBrowsingAssistantView *browsingAssistant;
@property LMSourceSelectorView *sourceSelector;

@property NSArray<LMSource*> *sourcesForSourceSelector;

@property NSLayoutConstraint *topConstraint;

@property id currentSource;

@end

@implementation LMCoreViewController

- (void)musicPlaybackStateDidChange:(LMMusicPlaybackState)newState {
	NSLog(@"Got new playback state %d", newState);
}

- (void)musicTrackDidChange:(LMMusicTrack *)newTrack {
	NSLog(@"Got new track, title %@", newTrack.title);
}

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)pause {
	NSLog(@"Dude!");
	[self.musicPlayer pause];
}

- (void)play {
	NSLog(@"Dude");
	
	[NSTimer scheduledTimerWithTimeInterval:5.0
									 target:self
								   selector:@selector(pause)
								   userInfo:nil
									repeats:NO];
	
	NSArray *items = [self.musicPlayer queryCollectionsForMusicType:LMMusicTypePlaylists];
	NSLog(@"Got %lu items.", (unsigned long)items.count);
	
	int random = rand() % items.count;
	NSLog(@"%d", random);
	LMMusicTrackCollection *collection = [items objectAtIndex:random];
	[self.musicPlayer setNowPlayingCollection:collection];
	[self.musicPlayer setNowPlayingTrack:collection.representativeItem];
	[self.musicPlayer play];
}

- (void)openNowPlayingView {
	if(self.nowPlayingView){
		return;
	}
	
	self.nowPlayingView = [LMNowPlayingView new];
	self.nowPlayingView.translatesAutoresizingMaskIntoConstraints = NO;
	self.nowPlayingView.backgroundColor = [UIColor blueColor];
	self.nowPlayingView.rootViewController = self;
	[self.view addSubview:self.nowPlayingView];
	
	[self.nowPlayingView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	self.topConstraint = [self.nowPlayingView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.view withOffset:self.view.frame.size.height];
	[self.nowPlayingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.nowPlayingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	[self.nowPlayingView setup];
	
	[self.view layoutIfNeeded];
	self.topConstraint.constant = 0;
	[UIView animateWithDuration:0.5 delay:0.1
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:nil];
}

- (void)closeNowPlayingView {
	[self.view layoutIfNeeded];
	self.topConstraint.constant = self.view.frame.size.height*1.5;
	[UIView animateWithDuration:0.5 delay:0.05
		 usingSpringWithDamping:0.75 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self.view layoutIfNeeded];
						} completion:^(BOOL finished) {
							self.nowPlayingView = nil;
						}];
}

BOOL didAutomaticallyClose = NO;

- (void)openBrowsingAssistant {
	if(didAutomaticallyClose){
		[self.browsingAssistant open];
		didAutomaticallyClose = NO;
	}
}

- (void)closeBrowsingAssistant {
	didAutomaticallyClose = [self.browsingAssistant close];
}

- (void)sourceSelected:(LMSource *)source {
	NSLog(@"Selected source with title %@", source.title);
	
	int indexOfSource = -1;
	for(int i = 0; i < self.sourcesForSourceSelector.count; i++){
		LMSource *indexSource = [self.sourcesForSourceSelector objectAtIndex:i];
		if([source isEqual:indexSource]){
			indexOfSource = i;
			break;
		}
	}
	NSLog(@"The index is %d", indexOfSource);
	
	[self.currentSource setHidden:YES];
	
	switch(indexOfSource){
		case 0:
			self.albumView.hidden = NO;
			[self.albumView reloadSourceSelectorInfo];
			self.currentSource = self.albumView;
			if(self.albumView.showingDetailView){
				[self.browsingAssistant close];
			}
			break;
		case 1:
			self.titleView.hidden = NO;
			[self.titleView reloadSourceSelectorInfo];
			self.currentSource = self.titleView;
			break;
		case 2:
			
			break;
		default:
			NSLog(@"Unknown index of source %@.", source);
			break;
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
	NSLog(@"Loaded");
    // Do any additional setup after loading the view.
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	[self.musicPlayer addMusicDelegate:self];
	
	LMPebbleManager *pebbleManager = [LMPebbleManager sharedPebbleManager];
	[pebbleManager attachVolumeControlsToView:self.view];
	
	NSArray *sourceTitles = @[
							  @"Albums", @"Titles", @"Settings", @"Report Bug"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"Only for Pebble", @"Or send feedback"
								 ];
	LMIcon sourceIcons[] = {
		LMIconAlbums, LMIconTitles, LMIconSettings, LMIconBug
	};
	
	NSMutableArray *sources = [NSMutableArray new];
	
	for(int i = 0; i < sourceTitles.count; i++){
		NSString *subtitle = [sourceSubtitles objectAtIndex:i];
		LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
										 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
											 andIcon:sourceIcons[i]];
		source.delegate = self;
		[sources addObject:source];
	}
	
	self.sourcesForSourceSelector = [NSArray arrayWithArray:sources];
	
	self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
	self.sourceSelector.backgroundColor = [UIColor redColor];
	self.sourceSelector.sources = self.sourcesForSourceSelector;
	[self.view addSubview:self.sourceSelector];
	
	[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
	[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
	self.sourceSelector.bottomConstraint = [self.sourceSelector autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view withOffset:-WINDOW_FRAME.size.height*(0.9)];
	[self.sourceSelector autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	
	[self.sourceSelector setup];
	
	self.musicPlayer.sourceSelector = self.sourceSelector;

	self.albumView = [LMAlbumView newAutoLayoutView];
	self.albumView.rootViewController = self;
	[self.view addSubview:self.albumView];
	
	[self.albumView autoCenterInSuperview];
	[self.albumView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.albumView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	self.titleView = [LMTitleView newAutoLayoutView];
	self.titleView.backgroundColor = [UIColor redColor];
	//http://stackoverflow.com/questions/8424972/mpmediaitemcollection-whole-library
	MPMediaQuery *everything = [[MPMediaQuery alloc] init];
	NSArray *songs = [everything items];
	MPMediaItemCollection *mediaCollection = [MPMediaItemCollection collectionWithItems:songs];
	NSMutableArray* musicTracks = [[NSMutableArray alloc]init];
	
	NSMutableArray *musicCollection = [[NSMutableArray alloc]init];
	for(int itemIndex = 0; itemIndex < mediaCollection.items.count; itemIndex++){
		MPMediaItem *musicItem = [mediaCollection.items objectAtIndex:itemIndex];
		LMMusicTrack *musicTrack = [[LMMusicTrack alloc]initWithMPMediaItem:musicItem];
		[musicCollection addObject:musicTrack];
	}
	LMMusicTrackCollection *trackCollection = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:mediaCollection];
	[musicTracks addObject:trackCollection];

	self.titleView.musicTitles = [[LMMusicTrackCollection alloc]initWithItems:musicCollection basedOnSourceCollection:mediaCollection];
	[self.view addSubview:self.titleView];
	
	[self.titleView autoCenterInSuperview];
	[self.titleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view];
	[self.titleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view];
	
	[self.titleView setup];
	self.titleView.hidden = YES;
	
	self.browsingAssistant = [[LMBrowsingAssistantView alloc]initForAutoLayout];
	self.browsingAssistant.coreViewController = self;
	self.browsingAssistant.backgroundColor = [UIColor orangeColor];
	[self.view addSubview:self.browsingAssistant];
	[self.browsingAssistant setup];
	
 	self.browsingAssistant.textBackgroundConstraint = [self.browsingAssistant autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.view];
	[self.browsingAssistant autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.view];
	[self.browsingAssistant autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view];
	[self.browsingAssistant autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:0.225];
	
	UIView *temporaryWhiteView = [UIView newAutoLayoutView];
	temporaryWhiteView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:temporaryWhiteView];
	
	[temporaryWhiteView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.browsingAssistant];
	[temporaryWhiteView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.browsingAssistant];
	[temporaryWhiteView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.browsingAssistant];
	[temporaryWhiteView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.browsingAssistant];
	
	UILabel *easterEgg = [UILabel newAutoLayoutView];
	easterEgg.text = @"🎶 So baby pull me closer on the front screen of your iPhone ;) 🎶";
	easterEgg.textColor = [UIColor lightGrayColor];
	easterEgg.textAlignment = NSTextAlignmentCenter;
	easterEgg.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0f];
	[temporaryWhiteView addSubview:easterEgg];

	[easterEgg autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[easterEgg autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[easterEgg autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[easterEgg autoSetDimension:ALDimensionHeight toSize:16];
	
	UILabel *anotherEasterEgg = [UILabel newAutoLayoutView];
	anotherEasterEgg.text = @"Technically, you could pull this all the way up to the top of your screen if you tried hard enough. And on this view specifically, I set no limit on how high you could go. And in addition to that, this bottom white spacer matches the height of the mini player, so you could see the bottom of this view easier than seeing it hit the top. Papa bless, 祝你好運!";
	anotherEasterEgg.textColor = [UIColor lightGrayColor];
	anotherEasterEgg.textAlignment = NSTextAlignmentCenter;
	anotherEasterEgg.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:10.0f];
	anotherEasterEgg.numberOfLines = 0;
	[temporaryWhiteView addSubview:anotherEasterEgg];
	
	[anotherEasterEgg autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[anotherEasterEgg autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[anotherEasterEgg autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:easterEgg];
	[anotherEasterEgg autoSetDimension:ALDimensionHeight toSize:70];
	
	[self.view bringSubviewToFront:self.sourceSelector];
	
//	[NSTimer scheduledTimerWithTimeInterval:0.75
//									 target:self
//								   selector:@selector(openNowPlayingView)
//								   userInfo:nil
//									repeats:NO];
	
//	UITapGestureRecognizer *gesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(play)];
//	[self.view addGestureRecognizer:gesture];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
