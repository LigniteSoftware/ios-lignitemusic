//
//  LMSourceSelector.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSourceSelectorView.h"
#import "LMButton.h"
#import "LMCircleView.h"
#import "LMLabel.h"
#import "LMTableView.h"
#import "LMListEntry.h"
#import "LMColour.h"
#import "LMExtras.h"
#import "LMSettings.h"

@interface LMSourceSelectorView() <LMButtonDelegate, LMTableViewSubviewDelegate, LMListEntryDelegate>

@property UIVisualEffectView *blurredBackgroundView;

@property UIView *contentShadowView;
@property UIView *contentBackgroundView;
@property UILabel *chooseYourViewLabel;

@property LMCircleView *sourceSelectorButtonBackgroundView;
@property LMButton *sourceSelectorButton;

@property UIView *currentSourceLabelBackgroundView, *detailInfoLabelBackgroundView;
@property LMLabel *currentSourceLabel, *detailInfoLabel;

@property LMTableView *viewsTableView;
@property NSMutableArray *itemArray;

@property NSInteger currentlyHighlighted;

@property CGPoint originalPoint, currentPoint;
@property BOOL setupGesture;

@property NSLayoutConstraint *blurConstraint;

@end

@implementation LMSourceSelectorView

- (void)setSourceTitle:(NSString*)title {
	if(self.currentSourceLabel){
		self.currentSourceLabel.text = title;
	}
}

- (void)setSourceSubtitle:(NSString*)subtitle {
	if(self.detailInfoLabel){
		self.detailInfoLabel.text = subtitle;
	}
}

- (id)prepareSubviewAtIndex:(NSUInteger)index {
	LMListEntry *entry = [self.itemArray objectAtIndex:index % self.itemArray.count];
	entry.collectionIndex = index;
	entry.associatedData = [self.sources objectAtIndex:index];
	
	[entry changeHighlightStatus:self.currentlyHighlighted == entry.collectionIndex animated:NO];
	
	[entry reloadContents];
	return entry;
}

- (void)totalAmountOfSubviewsRequired:(NSUInteger)amount forTableView:(LMTableView *)tableView {
	if(!self.itemArray){
		self.itemArray = [NSMutableArray new];
		for(int i = 0; i < amount; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.iconInsetMultiplier = (1.0/3.0);
			listEntry.iconPaddingMultiplier = (3.0/4.0);
			listEntry.invertIconOnHighlight = YES;
			[listEntry setup];
			[self.itemArray addObject:listEntry];
		}
		
		NSUserDefaults *settings = [NSUserDefaults standardUserDefaults];
		NSInteger lastSourceOpened = 0;
		if([settings objectForKey:LMSettingsKeyLastOpenedSource]){
			lastSourceOpened = [settings integerForKey:LMSettingsKeyLastOpenedSource];
		}
		
		[self tappedListEntry:[self.itemArray objectAtIndex:lastSourceOpened]];
	}
}

- (float)sizingFactorialRelativeToWindowForTableView:(LMTableView *)tableView height:(BOOL)height {
	if(height){
		return (1.0f/8.0f);
	}
	return 0.9;
}

- (LMListEntry*)listEntryForIndex:(NSInteger)index {
	if(index == -1){
		return nil;
	}
	
	LMListEntry *entry = nil;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *indexEntry = [self.itemArray objectAtIndex:i];
		if(indexEntry.collectionIndex == index){
			entry = indexEntry;
			break;
		}
	}
	return entry;
}

- (int)indexOfListEntry:(LMListEntry*)entry {
	int indexOfEntry = -1;
	for(int i = 0; i < self.itemArray.count; i++){
		LMListEntry *subviewEntry = (LMListEntry*)[self.itemArray objectAtIndex:i];
		if([entry isEqual:subviewEntry]){
			indexOfEntry = i;
			break;
		}
	}
	return indexOfEntry;
}

- (float)topSpacingForTableView:(LMTableView *)tableView {
	return 0.0f;
}

- (BOOL)dividerForTableView:(LMTableView *)tableView {
	return YES;
}

- (void)setCurrentSourceWithIndex:(NSInteger)index {
	LMListEntry *entry = [self listEntryForIndex:index];
	
	LMSource *source = [self.sources objectAtIndex:index];
	
	[source.delegate sourceSelected:source];
	
	if(source.shouldNotSelect){
		return;
	}
	
	NSLog(@"Source image %@", source.icon);
	
	[self.sourceSelectorButton setImage:[LMAppIcon invertImage:source.icon]];
	
	LMListEntry *previousHighlightedEntry = [self listEntryForIndex:self.currentlyHighlighted];
	if(previousHighlightedEntry){
		[previousHighlightedEntry changeHighlightStatus:NO animated:YES];
	}
	
	[entry changeHighlightStatus:YES animated:YES];
	self.currentlyHighlighted = index;
	
	[self moveContentsUp];
	
	NSUserDefaults *defaults = [NSUserDefaults standardUserDefaults];
	[defaults setInteger:index forKey:LMSettingsKeyLastOpenedSource];
}

- (void)tappedListEntry:(LMListEntry*)entry{
	[self setCurrentSourceWithIndex:entry.collectionIndex];
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour ligniteRedColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.title;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.subtitle;
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	LMSource *source = [self.sources objectAtIndex:entry.collectionIndex];
	return source.icon;
}

- (void)moveContentsUp {
	[[self superview] layoutIfNeeded];
	self.bottomConstraint.constant = -(self.frame.size.height*0.9);
	self.blurConstraint.constant = -self.frame.size.height;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y-(self.frame.size.height*0.9));
	[UIView animateWithDuration:1.0 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
							[[self superview] layoutIfNeeded];
						} completion:nil];
}

- (void)moveContentsDown {
	[[self superview] layoutIfNeeded];
	self.bottomConstraint.constant = 0;
	self.blurConstraint.constant = 0;
	self.currentPoint = self.originalPoint;
	[UIView animateWithDuration:1.0 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
							[[self superview] layoutIfNeeded];
						} completion:nil];
}

- (IBAction)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.frame.origin;
		self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y-(self.frame.size.height*0.9));
		
//		NSLog(@"Set original point to %@", NSStringFromCGPoint(self.originalPoint));
	}
	
	float totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
//	NSLog(@"%f", totalTranslation);
	
	if(totalTranslation > 0){
		self.bottomConstraint.constant = sqrt(totalTranslation);
	}
	else if(totalTranslation < -(self.frame.size.height*0.9)){
		self.bottomConstraint.constant = (-(self.frame.size.height*0.9))-sqrt(-(((self.frame.size.height*0.9))+totalTranslation));
	}
	else{
		self.bottomConstraint.constant = totalTranslation;
	}
	
	[[self superview] layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		//NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
//		NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		
		if(((self.originalPoint.y-self.currentPoint.y) < 0) || (translation.y >= 0)){
			[self moveContentsDown];
		}
		else if(((self.originalPoint.y-self.currentPoint.y) > (self.frame.size.height*0.9)) || (translation.y < 0)){
			[self moveContentsUp];
		}
	} 
}

- (void)clickedButton:(LMButton *)button {
	if(self.bottomConstraint.constant == 0){
		[self moveContentsUp];
	}
	else{
		[self moveContentsDown];
	}
}

- (void)layoutSubviews {
	self.contentShadowView.backgroundColor = [UIColor clearColor];
	self.contentShadowView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.contentShadowView.layer.shadowOpacity = 0.25;
	self.contentShadowView.layer.shadowRadius = self.sourceSelectorButtonBackgroundView.shadowRadius;
	self.contentShadowView.layer.shadowOffset = CGSizeMake(0, self.contentShadowView.layer.shadowRadius/2);
	self.contentShadowView.layer.shadowPath = [UIBezierPath bezierPathWithRoundedRect:self.contentBackgroundView.bounds cornerRadius:10].CGPath;
	
	[super layoutSubviews];
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	self.currentlyHighlighted = -1;
		
	UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
	self.blurredBackgroundView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
	self.blurredBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	
	[self addSubview:self.blurredBackgroundView];
	
	[self.blurredBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	self.blurConstraint = [self.blurredBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:WINDOW_FRAME.size.height];
	[self.blurredBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.blurredBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	self.contentBackgroundView = [UIView newAutoLayoutView];
	self.contentBackgroundView.backgroundColor = [UIColor whiteColor];
	self.contentBackgroundView.layer.masksToBounds = YES;
	self.contentBackgroundView.layer.cornerRadius = 10.0;
	[self addSubview:self.contentBackgroundView];
	
	[self.contentBackgroundView autoCenterInSuperview];
	[self.contentBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.9];
	[self.contentBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:0.85];
	
	self.contentShadowView = [UIView newAutoLayoutView];
	[self addSubview:self.contentShadowView];
	
	[self.contentShadowView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.contentBackgroundView];
	[self.contentShadowView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.contentBackgroundView];
	[self.contentShadowView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.contentBackgroundView];
	[self.contentShadowView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.contentBackgroundView];
	
	[self insertSubview:self.contentBackgroundView aboveSubview:self.contentShadowView];
	
	self.chooseYourViewLabel = [UILabel newAutoLayoutView];
	//self.chooseYourViewLabel.backgroundColor = [UIColor yellowColor];
	self.chooseYourViewLabel.textAlignment = NSTextAlignmentCenter;
	self.chooseYourViewLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:20.0f];
	self.chooseYourViewLabel.textColor = [UIColor blackColor];
	self.chooseYourViewLabel.text = NSLocalizedString(@"ChooseYourView", nil);
	[self.contentBackgroundView addSubview:self.chooseYourViewLabel];
	
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
	[self.chooseYourViewLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.chooseYourViewLabel autoSetDimension:ALDimensionHeight toSize:40];
	
	self.sourceSelectorButtonBackgroundView = [LMCircleView newAutoLayoutView];
	[self addSubview:self.sourceSelectorButtonBackgroundView];
	
	//Center of the background view goes on the bottom of the content view
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.sourceSelectorButtonBackgroundView
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self.contentBackgroundView
													 attribute:NSLayoutAttributeBottom
													multiplier:1.0
													  constant:-5]];
	[self.sourceSelectorButtonBackgroundView autoAlignAxisToSuperviewAxis:ALAxisVertical];
	float sizeMultiplier = (1.0/10.0)/1.25;
	[self.sourceSelectorButtonBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:sizeMultiplier];
	[self.sourceSelectorButtonBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self withMultiplier:sizeMultiplier];
	
	[self insertSubview:self.contentBackgroundView aboveSubview:self.sourceSelectorButtonBackgroundView];
	
	self.sourceSelectorButton = [LMButton newAutoLayoutView];
	self.sourceSelectorButton.userInteractionEnabled = YES;
	self.sourceSelectorButton.delegate = self;
	[self addSubview:self.sourceSelectorButton];
	
//	[self insertSubview:self.sourceSelectorButton aboveSubview:self.contentBackgroundView];
	
	[self.sourceSelectorButton autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.sourceSelectorButtonBackgroundView];
	[self.sourceSelectorButton autoAlignAxis:ALAxisVertical toSameAxisOfView:self.sourceSelectorButtonBackgroundView];
	[self.sourceSelectorButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.sourceSelectorButtonBackgroundView withMultiplier:0.85];
	[self.sourceSelectorButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.sourceSelectorButtonBackgroundView withMultiplier:0.85];
	
	[self.sourceSelectorButton setupWithImageMultiplier:0.5];
	//[self.sourceSelectorButton setImage:[LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconAlbums]]];
	
	UIPanGestureRecognizer *moveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
	[self.sourceSelectorButton addGestureRecognizer:moveRecognizer];
	
	self.currentSourceLabelBackgroundView = [UIView newAutoLayoutView];
	[self.contentBackgroundView addSubview:self.currentSourceLabelBackgroundView];
	
	[self.currentSourceLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.currentSourceLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.currentSourceLabelBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.sourceSelectorButtonBackgroundView];
	[self.currentSourceLabelBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.sourceSelectorButtonBackgroundView];
	
	self.detailInfoLabelBackgroundView = [UIView newAutoLayoutView];
	[self.contentBackgroundView addSubview:self.detailInfoLabelBackgroundView];
	
	[self.detailInfoLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.detailInfoLabelBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.detailInfoLabelBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.sourceSelectorButtonBackgroundView];
	[self.detailInfoLabelBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.sourceSelectorButtonBackgroundView];
	
	self.currentSourceLabel = [LMLabel newAutoLayoutView];
	self.currentSourceLabel.text = @"No Source";
	self.currentSourceLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:50.0f];
	[self.currentSourceLabelBackgroundView addSubview:self.currentSourceLabel];
	
	float widthMultiplier = 0.8;
	float heightMultiplier = 0.7;
	
	[self.currentSourceLabel autoCenterInSuperview];
	[self.currentSourceLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.currentSourceLabelBackgroundView withMultiplier:widthMultiplier];
	[self.currentSourceLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceLabelBackgroundView withMultiplier:heightMultiplier];
	
	self.detailInfoLabel = [LMLabel newAutoLayoutView];
	self.detailInfoLabel.textAlignment = NSTextAlignmentRight;
	self.detailInfoLabel.text = @"Waiting...";
	self.detailInfoLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
	[self.detailInfoLabelBackgroundView addSubview:self.detailInfoLabel];
	
	[self.detailInfoLabel autoCenterInSuperview];
	[self.detailInfoLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.detailInfoLabelBackgroundView withMultiplier:widthMultiplier];
	[self.detailInfoLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.detailInfoLabelBackgroundView withMultiplier:heightMultiplier];
	
	self.viewsTableView = [[LMTableView alloc]init];
	self.viewsTableView.translatesAutoresizingMaskIntoConstraints = NO;
	self.viewsTableView.amountOfItemsTotal = self.sources.count;
	self.viewsTableView.subviewDelegate = self;
	self.viewsTableView.dividerColour = [UIColor blackColor];
	[self.viewsTableView prepareForUse];
	[self addSubview:self.viewsTableView];
	
	[self.viewsTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.chooseYourViewLabel];
	[self.viewsTableView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.sourceSelectorButtonBackgroundView];
	[self.viewsTableView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.contentBackgroundView];
	[self.viewsTableView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.contentBackgroundView];
	
	NSLog(@"Setup!!!");
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
