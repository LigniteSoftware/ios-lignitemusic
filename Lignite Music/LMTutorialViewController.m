//
//  LMTutorialViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/20/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <XCDYouTubeKit/XCDYouTubeKit.h>
#import <PureLayout/PureLayout.h>
#import <PeekPop/PeekPop.h>
#import <AVKit/AVKit.h>
@import PeekPop;

#import "LMTutorialViewController.h"
#import "LMGuideViewController.h"
#import "LMTutorialHeaderView.h"
#import "LMWarningBarView.h"
#import "LMViewController.h"
#import "NSTimer+Blocks.h"
#import "LMTutorialView.h"
#import "LMReachability.h"
#import "LMColour.h"


@interface LMTutorialViewController()<UICollectionViewDelegate, UICollectionViewDataSource, PeekPopPreviewingDelegate, LMLayoutChangeDelegate, LMTutorialViewDelegate, LMTutorialHeaderViewDelegate>

/**
 The collection view which displays the selection of themes.
 */
@property UICollectionView *collectionView;

/**
 For 3D touch.
 */
@property PeekPop *peekPop;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The warning for when users are on mobile data and are using the tutorial view.
 */
@property LMWarning *dataWarning;

/**
 The warning bar for letting users know tutorials are powered by YouTube.
 */
@property LMWarningBarView *warningBar;

@end

@implementation LMTutorialViewController

- (UINavigationItem*)navigationItem {
	UINavigationItem *navigationItem = [super navigationItem];
	
	navigationItem.title = NSLocalizedString(@"Tutorial", nil);
	
	return navigationItem;
}

- (void)tutorialViewSelected:(LMTutorialView *)tutorialView withYouTubeVideoURLString:(NSString *)youTubeVideoURLString {
	NSLog(@"Tapped tutorial with URL string %@", youTubeVideoURLString);
	
//	XCDYouTubeVideoPlayerViewController *videoPlayerViewController = [[XCDYouTubeVideoPlayerViewController alloc] initWithVideoIdentifier:youTubeVideoURLString];
//
//	[[NSNotificationCenter defaultCenter] addObserver:self
//											 selector:@selector(moviePlayerPlaybackDidFinish:)
//												 name:MPMoviePlayerPlaybackDidFinishNotification
//											   object:videoPlayerViewController.moviePlayer];
	
	
	AVPlayerViewController *playerViewController = [AVPlayerViewController new];
	[self presentViewController:playerViewController animated:YES completion:nil];

	__weak AVPlayerViewController *weakPlayerViewController = playerViewController;
	[[XCDYouTubeClient defaultClient] getVideoWithIdentifier:youTubeVideoURLString completionHandler:^(XCDYouTubeVideo * _Nullable video, NSError * _Nullable error) {
		if (video) {
			NSDictionary *streamURLs = video.streamURLs;
			NSURL *streamURL = streamURLs[XCDYouTubeVideoQualityHTTPLiveStreaming] ?: streamURLs[@(XCDYouTubeVideoQualityHD720)] ?: streamURLs[@(XCDYouTubeVideoQualityMedium360)] ?: streamURLs[@(XCDYouTubeVideoQualitySmall240)];
			weakPlayerViewController.player = [AVPlayer playerWithURL:streamURL];
			[weakPlayerViewController.player play];
		}
		else {
			[self dismissViewControllerAnimated:YES completion:nil];
		}
	}];
	
//	[self presentMoviePlayerViewControllerAnimated:videoPlayerViewController];
}

- (void)tutorialHeaderViewButtonTapped {
	NSLog(@"Header tapped, play intro tutorial videos");
	
	NSString *language = NSLocalizedString(@"LMLocalizationKey", nil);
	
	if([language isEqualToString:@"de"]){
		[self tutorialViewSelected:nil withYouTubeVideoURLString:@"CuAalEem5Cw"];
	}
	else{
		[self tutorialViewSelected:nil withYouTubeVideoURLString:@"0cXxGMC6bGE"];
	}
}

- (CGSize)collectionView:(UICollectionView*)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	if(indexPath.row == 0){ //Header view
		CGFloat width = self.collectionView.frame.size.width;
	
//		if([LMLayoutManager isiPad]){
//			width = MAX(;
//		}
//		else if([LMLayoutManager isLandscape]){
//			width = self.collectionView.frame.size.height / ([LMLayoutManager isiPhoneX] ? 2.25 : 2.0);
//		}
		
		width -= 28;
		
		CGFloat height = 0;
		
		if(LMLayoutManager.isiPad){
			height = (MIN(self.collectionView.frame.size.height, self.collectionView.frame.size.width) * (2.5/10.0));
		}
		else if(LMLayoutManager.isLandscape){
			height = width * ((LMLayoutManager.isiPhoneX ? 2.0 : 2.5)/10.0);
		}
		else{
			height = width * ((LMLayoutManager.isiPhoneX ? 6.5 : 5.0)/10.0);
		}
		
		if(LMLayoutManager.isExtraSmall){
			height += 35;
		}
		else if(self.wasPresented){
			height -= 30;
		}
		
		return CGSizeMake(width, height);
	}
	else{
		CGFloat width = self.collectionView.frame.size.width/3.0;
		
		if([LMLayoutManager isiPad]){
			width = self.collectionView.frame.size.width / 4.0;
		}
		else if([LMLayoutManager isLandscape]){
			width = self.collectionView.frame.size.width / 3.5;
		}
		
		width -= 20;
		CGFloat height = 0;
		
		if([LMLayoutManager isLandscape]){
			height = width * 1.3;
		}
		else{
			height = width * 1.8;
		}
		
		return CGSizeMake(width, height);
	}
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
	return LMTutorialViewAmountOfTutorialsKey + 1;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
						  cellForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"TutorialViewIdentifier" forIndexPath:indexPath];
	//	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
	
	cell.backgroundColor = [LMColour clearColour];
	cell.contentView.backgroundColor = [LMColour clearColour];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	if(indexPath.row == 0){
		LMTutorialHeaderView *tutorialHeaderView = [LMTutorialHeaderView newAutoLayoutView];
		tutorialHeaderView.delegate = self;
//		tutorialHeaderView.backgroundColor = [LMColour magentaColor];
		[cell.contentView addSubview:tutorialHeaderView];
		
		[tutorialHeaderView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-10];
		[tutorialHeaderView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[tutorialHeaderView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[tutorialHeaderView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	}
	else{
		NSArray *tutorialKeys = @[
								   LMTutorialViewTutorialKeyQueueManagement, LMTutorialViewTutorialKeyNormalPlaylists, LMTutorialViewTutorialKeyFavourites
								   ];
		
		LMTutorialView *tutorialView = [LMTutorialView newAutoLayoutView];
		tutorialView.tutorialKey = [tutorialKeys objectAtIndex:indexPath.row - 1];
		tutorialView.delegate = self;
		[cell.contentView addSubview:tutorialView];

		[tutorialView autoPinEdgesToSuperviewEdges];
	}
	
	
	
	return cell;
}

- (UIViewController*)previewingContext:(PreviewingContext *)previewingContext
			 viewControllerForLocation:(CGPoint)location {
	
	NSIndexPath *cellIndexPath = [self.collectionView indexPathForItemAtPoint:location];
	if(cellIndexPath.row == 0){
		return nil;
	}
	
	UICollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:cellIndexPath];
	LMTutorialView *tutorialView = nil;
	for(UIView *subview in cell.contentView.subviews){
		if([subview class] == [LMTutorialView class]){
			tutorialView = (LMTutorialView*)subview;
			break;
		}
	}
	
	UICollectionViewLayoutAttributes *layoutAttributes = [self.collectionView layoutAttributesForItemAtIndexPath:cellIndexPath];
	if(layoutAttributes){
		previewingContext.sourceRect = layoutAttributes.frame;
	}
	
	
	
	LMViewController *imagePreviewViewController = [LMViewController new];
	imagePreviewViewController.view = [UIView new];
	imagePreviewViewController.view.backgroundColor = [LMColour whiteColour];
	imagePreviewViewController.context = tutorialView;
	
	UIImageView *screenshotView = [UIImageView newAutoLayoutView];
	screenshotView.image = tutorialView.coverImage;
	screenshotView.contentMode = UIViewContentModeScaleAspectFit;
	[imagePreviewViewController.view addSubview:screenshotView];
	
	[screenshotView autoPinEdgesToSuperviewEdges];
	
	return imagePreviewViewController;
}

- (void)previewingContext:(PreviewingContext *)previewingContext
	 commitViewController:(UIViewController *)viewControllerToCommit {
	
	LMViewController *viewController = (LMViewController*)viewControllerToCommit;
	LMTutorialView *tutorialView = (LMTutorialView*)viewController.context;
	
	[tutorialView tapped];
	
//	[self.navigationController popToRootViewControllerAnimated:NO];
	
	NSLog(@"COMMIT %p!!!", viewControllerToCommit);
	
	//	[self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.collectionView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context){
		[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
			[self.collectionView reloadData];
			
			if([LMLayoutManager isiPhoneX]){
				[self notchPositionChanged:LMLayoutManager.notchPosition];
			}
		} repeats:NO];
	}];
}

- (void)notchPositionChanged:(LMNotchPosition)notchPosition {
	//	[self.layoutManager adjustRootViewSubviewsForLandscapeNavigationBar:self.view];
	
	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)self.collectionView.collectionViewLayout;
	flowLayout.sectionInset
	= UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 5.0f : 5.0f,
					   (notchPosition == LMNotchPositionLeft) ? 44 : 14.0f,
					   20.0f,
					   (notchPosition == LMNotchPositionRight) ? 44 : 14);
}

- (BOOL)isOnCellularData {
		return YES;
	
	LMReachability *reachability = [LMReachability reachabilityForInternetConnection];
	[reachability startNotifier];
	
	NetworkStatus status = [reachability currentReachabilityStatus];
	
	return status == ReachableViaWWAN;
}

- (void)reachabilityChanged:(NSNotification*)notification {
	[self.warningBar setWarning:[self isOnCellularData] ? self.dataWarning : nil];
}

- (void)close {
	[[NSUserDefaults standardUserDefaults] removeObjectForKey:LMGuideViewControllerUserWantsToViewTutorialKey];
	
	[self.navigationController dismissViewControllerAnimated:YES completion:nil];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	if(self.wasPresented){
		self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Done", nil)
																				style:UIBarButtonItemStyleDone
																			   target:self
																			   action:@selector(close)];
	}
		
	
	self.warningBar = [LMWarningBarView newAutoLayoutView];
	[self.view addSubview:self.warningBar];
	
	[self.warningBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.warningBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.warningBar autoSetDimension:ALDimensionHeight toSize:0.0f];
	
	if(@available(iOS 11, *)){
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.warningBar
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.view.safeAreaLayoutGuide
															  attribute:NSLayoutAttributeTop
															 multiplier:1.0f
															   constant:0.0f]];
	}
	else{
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.warningBar
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.topLayoutGuide
															  attribute:NSLayoutAttributeBottom
															 multiplier:1.0f
															   constant:0.0f]];
	}
	
	self.dataWarning = [LMWarning warningWithText:NSLocalizedString(@"TutorialViewOnDataWarning", nil) priority:LMWarningPriorityHigh];
	
	if([self isOnCellularData]){
		[self.warningBar setWarning:self.dataWarning];
	}
	
	[NSTimer scheduledTimerWithTimeInterval:3.0 block:^() {
		LMReachability* reach = [LMReachability reachabilityWithHostname:@"www.google.com"];
		reach.reachableOnWWAN = NO;
		
		[[NSNotificationCenter defaultCenter] addObserver:self
												 selector:@selector(reachabilityChanged:)
													 name:kReachabilityChangedNotification
												   object:nil];
		[reach startNotifier];
	} repeats:NO];
	
	
	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	flowLayout.sectionInset = UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 5.0f : 5.0f, 14, 20, 14);
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.allowsSelection = NO;
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"TutorialViewIdentifier"];
	self.collectionView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.collectionView];
	
	
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.collectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningBar];
	
	if(self.wasPresented){
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	}
	else{
		NSArray *collectionViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		}];
		[LMLayoutManager addNewPortraitConstraints:collectionViewPortraitConstraints];

		NSArray *scrollViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
			[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		}];
		[LMLayoutManager addNewLandscapeConstraints:scrollViewLandscapeConstraints];
	}
	
	//	if(@available(iOS 11, *)){
	//		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView
	//															  attribute:NSLayoutAttributeTop
	//															  relatedBy:NSLayoutRelationEqual
	//																 toItem:self.view.safeAreaLayoutGuide
	//															  attribute:NSLayoutAttributeTop
	//															 multiplier:1.0f
	//															   constant:0.0f]];
	//	}
	//	else{
	//		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.collectionView
	//															  attribute:NSLayoutAttributeTop
	//															  relatedBy:NSLayoutRelationEqual
	//																 toItem:self.topLayoutGuide
	//															  attribute:NSLayoutAttributeBottom
	//															 multiplier:1.0f
	//															   constant:0.0f]];
	//	}
	
	self.peekPop = [[PeekPop alloc] initWithViewController:self];
	PreviewingContext *previewingContext = [self.peekPop registerForPreviewingWithDelegate:self sourceView:self.collectionView];
	NSLog(@"Previewing context %p", previewingContext);
	
	if([LMLayoutManager isiPhoneX]){
		[self notchPositionChanged:LMLayoutManager.notchPosition];
	}
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (void)viewDidDisappear:(BOOL)animated {
	if(self.view.window == nil){
		[[NSNotificationCenter defaultCenter] removeObserver:self
														name:kReachabilityChangedNotification
													  object:nil];
	}
	
	[super viewDidDisappear:animated];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end

