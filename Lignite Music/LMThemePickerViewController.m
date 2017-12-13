//
//  LMThemePickerViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/12/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMThemePickerViewController.h"
#import "LMThemeEngine.h"
#import "LMThemeView.h"

@interface LMThemePickerViewController()<UICollectionViewDelegate, UICollectionViewDataSource>

/**
 The collection view which displays the selection of themes.
 */
@property UICollectionView *collectionView;

@end

@implementation LMThemePickerViewController

- (CGSize)collectionView:(UICollectionView*)collectionView
				  layout:(UICollectionViewLayout*)collectionViewLayout
  sizeForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	CGFloat width = self.collectionView.frame.size.width/2.0;
	width -= 10;
	CGFloat height = width * 1.8;
	
	return CGSizeMake(width, height);
}

- (NSInteger)collectionView:(UICollectionView*)collectionView numberOfItemsInSection:(NSInteger)section {
	return 5;
}

- (__kindof UICollectionViewCell*)collectionView:(UICollectionView*)collectionView
						  cellForItemAtIndexPath:(NSIndexPath*)indexPath {
	
	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ThemeCollectionViewIdentifier" forIndexPath:indexPath];
//	UICollectionViewFlowLayout *flowLayout = (UICollectionViewFlowLayout*)collectionView.collectionViewLayout;
	
	LMThemeView *themeView = [LMThemeView newAutoLayoutView];
	[cell.contentView addSubview:themeView];
	
	[themeView autoPinEdgesToSuperviewEdges];
	
	
	
	return cell;
}

- (void)viewDidLoad {
    [super viewDidLoad];

	UICollectionViewFlowLayout *flowLayout = [UICollectionViewFlowLayout new];
	flowLayout.sectionInset = UIEdgeInsetsMake(0, 0, 20, 0);
	
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
	
	[self.collectionView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:84.0f];
	
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
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
