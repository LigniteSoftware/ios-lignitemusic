//
//  LMMusicPickerController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMMusicPickerController.h"
#import "LMSourceSelectorView.h"
#import "LMTrackPickerController.h"

@interface LMMusicPickerController ()<LMSourceDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The view selector for the user to choose which view they want to take music from.
 */
@property LMSourceSelectorView *viewSelector;

@end

@implementation LMMusicPickerController

- (void)sourceSelected:(LMSource*)source {
	NSLog(@"Source selected %@", source.title);
	
	LMTrackPickerController *trackPickerController = [LMTrackPickerController new];
	
	switch(source.sourceID){
		case LMIconFavouriteBlackFilled:{
			trackPickerController.musicType = LMMusicTypeFavourites;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			break;
		}
		case LMIconArtists:{
			trackPickerController.musicType = LMMusicTypeArtists;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelArtists;
			break;
		}
		case LMIconAlbums:{
			trackPickerController.musicType = LMMusicTypeAlbums;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			break;
		}
		case LMIconTitles:{
			trackPickerController.musicType = LMMusicTypeTitles;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelSongs;
			break;
		}
		case LMIconGenres:{
			trackPickerController.musicType = LMMusicTypeGenres;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelArtists;
			break;
		}
		case LMIconCompilations:{
			trackPickerController.musicType = LMMusicTypeCompilations;
			trackPickerController.depthLevel = LMTrackPickerDepthLevelAlbums;
			break;
		}
	}
	
	trackPickerController.title = source.title;
	
	[self showViewController:trackPickerController sender:nil];
}

- (void)cancelSongSelection {
	NSLog(@"Cancel song selection");
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)saveSongSelection {
	NSLog(@"Save song selection");
	
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(@"SelectSongs", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelSongSelection)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil) style:UIBarButtonItemStyleDone target:self action:@selector(saveSongSelection)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	
	
	UILabel *selectSourceTitleLabel = [UILabel newAutoLayoutView];
	selectSourceTitleLabel.text = NSLocalizedString(@"SelectASource", nil);
	selectSourceTitleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
	selectSourceTitleLabel.textColor = [UIColor blackColor];
	[self.view addSubview:selectSourceTitleLabel];
	
	[selectSourceTitleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:88];
	[selectSourceTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[selectSourceTitleLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	
	NSArray *sourceTitles = @[
							  @"Favourites", @"Artists", @"Albums", @"Titles", @"Genres", @"Compilations"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @"", @"", @"", @"", @"", @"", @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconFavouriteBlackFilled, LMIconArtists, LMIconAlbums, LMIconTitles, LMIconGenres, LMIconCompilations
	};
	BOOL notHighlight[] = {
		NO, NO, NO, NO, NO, NO
	};
	
	
	NSMutableArray *sources = [NSMutableArray new];
	
	for(int i = 0; i < sourceTitles.count; i++){
		NSString *subtitle = [sourceSubtitles objectAtIndex:i];
		LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
										 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
											 andIcon:sourceIcons[i]];
		source.shouldNotHighlight = notHighlight[i];
		source.delegate = self;
		source.sourceID = sourceIcons[i];
		[sources addObject:source];
	}
	
	self.viewSelector = [LMSourceSelectorView newAutoLayoutView];
	self.viewSelector.backgroundColor = [UIColor redColor];
	self.viewSelector.sources = sources;
	[self.view addSubview:self.viewSelector];
	
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.viewSelector autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.viewSelector autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:selectSourceTitleLabel];
	
	[self.viewSelector setup];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

@end
