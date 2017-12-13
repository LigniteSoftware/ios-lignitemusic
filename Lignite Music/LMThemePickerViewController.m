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
#import "LMThemeEngine.h"
#import "LMThemeView.h"

@interface LMThemePickerViewController()<UICollectionViewDelegate, UICollectionViewDataSource, LMThemeViewDelegate, PeekPopPreviewingDelegate>

/**
 The collection view which displays the selection of themes.
 */
@property UICollectionView *collectionView;

/**
 For 3D touch.
 */
@property PeekPop *peekPop;

@end

@implementation LMThemePickerViewController

- (void)themeView:(LMThemeView*)themeView selectedTheme:(LMTheme)theme {
	[[LMThemeEngine sharedThemeEngine] selectTheme:theme];
	
	NSLog(@"Theme selected %ld", (long)theme);
}

- (CGSize)collectionView:(UICollectionView*)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	CGFloat width = self.collectionView.frame.size.width/2.0;
	width -= 10;
	CGFloat height = width * 1.8;
	
	return CGSizeMake(width, height);
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
	return 6;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
						  cellForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ThemeCollectionViewIdentifier" forIndexPath:indexPath];
//	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
	
	cell.backgroundColor = [LMColour clearColour];
	cell.contentView.backgroundColor = [LMColour clearColour];
	
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
	
	NSLog(@"COMMIT %p!!!", viewControllerToCommit);
	
//	[self.navigationController pushViewController:viewControllerToCommit animated:YES];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	

	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	flowLayout.sectionInset = UIEdgeInsetsMake(20, 0, 20, 0);
	
	self.collectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.collectionView.delegate = self;
	self.collectionView.dataSource = self;
	self.collectionView.allowsSelection = NO;
	[self.collectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ThemeCollectionViewIdentifier"];
	self.collectionView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.collectionView];
	
	[self.collectionView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.collectionView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64.0f];
	
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end