//
//  LMThemePickerViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <PeekPop/PeekPop.h>
@import PeekPop;

#import "LMThemePickerViewController.h"
#import "LMViewController.h"
#import "NSTimer+Blocks.h"
#import "LMThemeEngine.h"
#import "LMThemeView.h"


@interface LMThemePickerViewController()<UICollectionViewDelegate, UICollectionViewDataSource, LMThemeViewDelegate, PeekPopPreviewingDelegate, LMLayoutChangeDelegate>

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

@end

@implementation LMThemePickerViewController

- (UINavigationItem*)navigationItem {
	UINavigationItem *navigationItem = [super navigationItem];
	
	navigationItem.title = NSLocalizedString(@"Theme", nil);
	
	return navigationItem;
}

- (void)themeView:(LMThemeView*)themeView selectedTheme:(LMTheme)theme {
	[[LMThemeEngine sharedThemeEngine] selectTheme:theme];
	
	NSLog(@"Theme selected %ld", (long)theme);
}

- (CGSize)collectionView:(UICollectionView*)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	CGFloat width = self.collectionView.frame.size.width/2.0;
	
	if([LMLayoutManager isiPad]){
		width = self.collectionView.frame.size.width / 4.0;
	}
	else if([LMLayoutManager isLandscape]){
		width = self.collectionView.frame.size.height / ([LMLayoutManager isiPhoneX] ? 2.25 : 2.0);
	}
	
	width -= (20);
	CGFloat height = width * 1.8;
	
	return CGSizeMake(width, height);
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
	return 7;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
						  cellForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ThemeCollectionViewIdentifier" forIndexPath:indexPath];
//	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
	
	cell.backgroundColor = [LMColour clearColour];
	cell.contentView.backgroundColor = [LMColour clearColour];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	LMThemeView *themeView = [LMThemeView newAutoLayoutView];
	themeView.theme = (LMTheme)indexPath.row;
	themeView.delegate = self;
	[cell.contentView addSubview:themeView];
	
	[themeView autoPinEdgesToSuperviewEdges];
	
	
	
	return cell;
}

- (UIViewController*)previewingContext:(PreviewingContext *)previewingContext
			 viewControllerForLocation:(CGPoint)location {
	
	NSIndexPath *cellIndexPath = [self.collectionView indexPathForItemAtPoint:location];
	UICollectionViewCell *cell = [self collectionView:self.collectionView cellForItemAtIndexPath:cellIndexPath];
	LMThemeView *themeView = nil;
	for(UIView *subview in cell.contentView.subviews){
		if([subview class] == [LMThemeView class]){
			themeView = (LMThemeView*)subview;
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
	imagePreviewViewController.context = themeView;
	
	UIImageView *screenshotView = [UIImageView newAutoLayoutView];
	screenshotView.image = [UIImage imageNamed:[NSString stringWithFormat:@"%@.png", themeView.themeKey]];
	screenshotView.contentMode = UIViewContentModeScaleAspectFit;
	[imagePreviewViewController.view addSubview:screenshotView];
	
	[screenshotView autoPinEdgesToSuperviewEdges];
	
	return imagePreviewViewController;
}

- (void)previewingContext:(PreviewingContext *)previewingContext
	 commitViewController:(UIViewController *)viewControllerToCommit {
	
	LMViewController *viewController = (LMViewController*)viewControllerToCommit;
	LMThemeView *themeView = (LMThemeView*)viewController.context;
	
	[[LMThemeEngine sharedThemeEngine] selectTheme:themeView.theme];
	
	[self.navigationController popToRootViewControllerAnimated:NO];
	
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

- (void)viewDidLoad {
    [super viewDidLoad];
	
	
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	

	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	flowLayout.sectionInset = UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 5.0f : 5.0f, 14, 20, 14);
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.allowsSelection = NO;
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ThemeCollectionViewIdentifier"];
	self.collectionView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.collectionView];
	

	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	NSArray *collectionViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewPortraitConstraints:collectionViewPortraitConstraints];
	
	NSArray *scrollViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:64];
		[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	}];
	[LMLayoutManager addNewLandscapeConstraints:scrollViewLandscapeConstraints];
	
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

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)dealloc {
	
}

@end
