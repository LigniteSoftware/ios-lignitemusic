//
//  LMBrowsingAssistantView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/14/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingAssistantView.h"
#import "LMMiniPlayerView.h"
#import "LMColour.h"
#import "LMAppIcon.h"
#import "LMMusicPlayer.h"
#import "LMSource.h"
#import "LMLabel.h"
#import "LMSourceSelectorView.h"
#import "LMLabel.h"
#import "LMButton.h"
//#import "LMGrabberView.h"

@interface LMBrowsingAssistantView()<LMButtonDelegate, LMSourceSelectorDelegate, LMSearchBarDelegate, UIGestureRecognizerDelegate>

@property LMMusicPlayer *musicPlayer;

@property UIView *selectorBackgroundView;
@property NSLayoutConstraint *selectorPositionConstraint;

//@property LMGrabberView *grabberView;

@property CGPoint originalPoint, currentPoint;

@property LMMiniPlayerView *miniPlayerView;
@property NSLayoutConstraint *miniPlayerBottomConstraint, *browsingBarBottomConstraint;

@property int8_t currentlySelectedTab;
@property int8_t previouslySelectedTab;

@property NSMutableArray *tabViews;
@property NSArray<LMSource*>* sourcesForTabs;

@property LMSourceSelectorView *sourceSelector;
@property NSLayoutConstraint *sourceSelectorPositionConstraint;

@property UIView *currentSourceBackgroundView;
@property LMLabel *currentSourceLabel;
@property LMLabel *currentSourceDetailLabel;
@property LMButton *currentSourceButton;
	
@property BOOL openedSourceSelectorFromShortcut;

@property CGFloat previousKeyboardHeight;

@end

@implementation LMBrowsingAssistantView

- (BOOL)gestureRecognizer:(UIGestureRecognizer *)gestureRecognizer shouldRecognizeSimultaneouslyWithGestureRecognizer:(UIGestureRecognizer *)otherGestureRecognizer {
	NSLog(@"%@ and %@", gestureRecognizer, otherGestureRecognizer);
	
	return YES;
}

- (void)sourceTitleChangedTo:(NSString *)title {
	self.currentSourceLabel.text = title;
}

- (void)sourceSubtitleChangedTo:(NSString *)subtitle {
	self.currentSourceDetailLabel.text = subtitle;
}

- (BOOL)open {
	if(self.selectorPositionConstraint.constant == 0){
		return NO;
	}
	
	NSLog(@"Open browsing assistant");
	
	[self layoutIfNeeded];
	self.selectorPositionConstraint.constant = 0;
	self.currentPoint = self.originalPoint;
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
	
	[self.delegate heightRequiredChangedTo:self.selectorBackgroundView.frame.size.height+self.currentSourceBackgroundView.frame.size.height forBrowsingView:self];
	
	return YES;
}

- (BOOL)close {
	if(self.selectorPositionConstraint.constant == self.frame.size.height){
		return NO;
	}
	
	NSLog(@"Close browsing assistant");
	
	if(self.currentlySelectedTab == LMBrowsingAssistantTabView){
		[self closeSourceSelectorAndOpenPreviousTab:YES];
	}
	
	[self layoutIfNeeded];
	self.selectorPositionConstraint.constant = self.frame.size.height;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.selectorPositionConstraint.constant);
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];

	[self.delegate heightRequiredChangedTo:self.currentSourceBackgroundView.frame.size.height forBrowsingView:self];
	
	return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.selectorBackgroundView.frame.origin;
		self.currentPoint = self.selectorBackgroundView.frame.origin;
	}
	CGFloat totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
	NSLog(@"%f", totalTranslation);
	
	if(totalTranslation < 0){ //Moving upward
		self.selectorPositionConstraint.constant = -sqrt(-totalTranslation);
	}
	else{ //Moving downward
		self.selectorPositionConstraint.constant = totalTranslation;
	}
	
	[self layoutIfNeeded];
	
	if(recognizer.state == UIGestureRecognizerStateEnded){
		//NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		self.currentPoint = CGPointMake(self.currentPoint.x, self.originalPoint.y + totalTranslation);
		
		//		NSLog(@"Dick is not a bone %@", NSStringFromCGPoint(self.currentPoint));
		
		if((translation.y >= 0)){
			[self close];
		}
		else if((translation.y < 0)){
			[self open];
		}
	}
	else if(recognizer.state == UIGestureRecognizerStateBegan){
		[self.delegate heightRequiredChangedTo:LMBrowsingAssistantViewDynamicHeight forBrowsingView:self];
	}
}
	
- (void)swipeUp {
	NSLog(@"Swipe up");
//	[self.coreViewController openNowPlayingView];
}
	
- (void)swipeDown {
	if(self.browsingBar.isInSearchMode){
		return;
	}
	
	[self close];
}

- (BOOL)sourceSelectorIsOpen {
	return self.sourceSelectorPositionConstraint.constant < 1;
}

- (void)moveSourceSelectorToPosition:(float)position {
	[self layoutIfNeeded];
	
	self.sourceSelectorPositionConstraint.constant = position;
	
	[UIView animateWithDuration:1.0
						  delay:0.10
		 usingSpringWithDamping:0.7
		  initialSpringVelocity:0.0
						options:0
					 animations:^{
						 [self layoutIfNeeded];
					 } completion:nil];
}

- (void)heightOfCurrentElementChangedTo:(CGFloat)newHeight {
	[self.delegate heightRequiredChangedTo:WINDOW_FRAME.size.height/8.0 + newHeight forBrowsingView:self];
}

- (void)closeSourceSelectorAndOpenPreviousTab:(BOOL)openPreviousTab {
	[self moveSourceSelectorToPosition:WINDOW_FRAME.size.height];
	
	NSLog(@"Move to position");
	
	if(openPreviousTab){
		[self selectSource:self.previouslySelectedTab];
	}
	
	if(self.openedSourceSelectorFromShortcut){
		self.openedSourceSelectorFromShortcut = NO;
		[self close];
	}
}

- (void)openSourceSelector {
	[self moveSourceSelectorToPosition:0.0];
}

- (void)setMiniPlayerOpen:(BOOL)open {
	NSLog(@"%d open mini", open);
	[self layoutIfNeeded];
	
	self.miniPlayerBottomConstraint.constant = open ? 0 : self.miniPlayerView.frame.size.height;
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)setBrowsingBarOpen:(BOOL)open {
	[self layoutIfNeeded];
	
	self.browsingBarBottomConstraint.constant = open ? 0 : self.browsingBar.frame.size.height;
	[UIView animateWithDuration:0.5 animations:^{
		[self layoutIfNeeded];
	}];
}

- (void)selectSource:(LMBrowsingAssistantTab)sourceSelectedIndex {
	//Reject invalid sources
	if(sourceSelectedIndex > LMBrowsingAssistantTabView){
		return;
	}
	
	if(sourceSelectedIndex == self.currentlySelectedTab && sourceSelectedIndex != LMBrowsingAssistantTabView){
		return;
	}
	
	self.originalPoint = CGPointMake(0, 0);
	
	[self setMiniPlayerOpen:NO];
	[self setBrowsingBarOpen:NO];
	
	//Perform the action associated with tab to implement the new tab selection
	switch(sourceSelectedIndex){
		case LMBrowsingAssistantTabMiniplayer: {
			[self heightOfCurrentElementChangedTo:WINDOW_FRAME.size.height/5.0];
			[self setMiniPlayerOpen:YES];
			break;
		}
		case LMBrowsingAssistantTabView: {
			if([self sourceSelectorIsOpen]){
				NSLog(@"Closing");
				[self closeSourceSelectorAndOpenPreviousTab:NO];
				[self heightOfCurrentElementChangedTo:0];
			}
			else{
				NSLog(@"Opening");
				[self heightOfCurrentElementChangedTo:0]; //Quick hack to make sure the little bit of the splash doesn't appear
				[self openSourceSelector];
				[self heightOfCurrentElementChangedTo:WINDOW_FRAME.size.height/8.0 * 7.0];
			}
			break;
		}
		case LMBrowsingAssistantTabBrowse: {
			[self heightOfCurrentElementChangedTo:WINDOW_FRAME.size.height/15.0];
			
			[self setBrowsingBarOpen:YES];
			break;
		}
	}
	
	UIView *backgroundView = [self.tabViews objectAtIndex:sourceSelectedIndex];
	
	//If tapped again on source thing
	if(sourceSelectedIndex == LMBrowsingAssistantTabView && sourceSelectedIndex == self.currentlySelectedTab){
		return; //Stop the tab from being changed
	}
	
	//Animate the tabs
	[UIView animateWithDuration:0.10 animations:^{
		backgroundView.backgroundColor = [UIColor whiteColor];
		
		UIImageView *currentIconView;
		LMLabel *currentTextLabel;
		
		for(int i = 0; i < backgroundView.subviews.count; i++){
			id subview = [backgroundView.subviews objectAtIndex:i];
			if([[[subview class] description] isEqualToString:@"UIImageView"]){
				currentIconView = subview;
			}
			else{
				currentTextLabel = subview;
			}
		}
		
		currentIconView.image = [LMAppIcon invertImage:currentIconView.image];
		currentTextLabel.textColor = [UIColor blackColor];
		
		if(self.currentlySelectedTab > -1){
			UIView *previouslySelectedView = [self.tabViews objectAtIndex:self.currentlySelectedTab];
			previouslySelectedView.backgroundColor = [LMColour ligniteRedColour];
			
			UIImageView *iconView;
			LMLabel *textLabel;
			
			for(int i = 0; i < previouslySelectedView.subviews.count; i++){
				id subview = [previouslySelectedView.subviews objectAtIndex:i];
				if([[[subview class] description] isEqualToString:@"UIImageView"]){
					iconView = subview;
				}
				else{
					textLabel = subview;
				}
			}
			
			iconView.image = [LMAppIcon invertImage:iconView.image];
			textLabel.textColor = [UIColor whiteColor];
		}
		
		self.previouslySelectedTab = self.currentlySelectedTab;
		self.currentlySelectedTab = sourceSelectedIndex;
	}];
	
	if(sourceSelectedIndex != LMBrowsingAssistantTabView && self.sourceSelectorPositionConstraint.constant < 10.0){
		[self closeSourceSelectorAndOpenPreviousTab:NO];
	}
}

- (void)sourceTapped:(UITapGestureRecognizer*)tapGesture {
	UIView *viewTapped = tapGesture.view;
	
	uint8_t viewTappedIndex = [self.tabViews indexOfObject:viewTapped];
	
	if(viewTappedIndex == LMBrowsingAssistantTabView){
		self.openedSourceSelectorFromShortcut = NO;
	}
	
	[self selectSource:viewTappedIndex];
}

- (void)shitpost {
	[self selectSource:LMBrowsingAssistantTabBrowse];
}

- (void)setCurrentSourceIcon:(UIImage*)icon {
	UIView *sourceBackgroundView = [self.tabViews objectAtIndex:LMBrowsingAssistantTabView];
	UIImageView *iconView;
	for(int i = 0; i < sourceBackgroundView.subviews.count; i++){
		id subview = [sourceBackgroundView.subviews objectAtIndex:i];
		if([[[subview class] description] isEqualToString:@"UIImageView"]){
			iconView = subview;
		}
	}
	iconView.image = icon;
	
	[self.currentSourceButton setImage:icon];
}

- (void)clickedButton:(LMButton *)button {
	NSLog(@"Spoooooked");
	self.openedSourceSelectorFromShortcut = YES;
	[self open];
	[self selectSource:LMBrowsingAssistantTabView];
//	[self openSourceSelector];
}

- (void)searchTermChangedTo:(NSString *)searchTerm {
	[self.searchBarDelegate searchTermChangedTo:searchTerm];
}

- (void)searchDialogOpened:(BOOL)opened withKeyboardHeight:(CGFloat)keyboardHeight {
	[self.searchBarDelegate searchDialogOpened:opened withKeyboardHeight:keyboardHeight];
}

- (void)layoutSubviews {
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;

		self.backgroundColor = [UIColor clearColor];
	
		NSArray *sourceTitles = @[
								  @"Browse", @"Miniplayer", @"View"
								  ];
		NSArray *sourceSubtitles = @[
									 @"", @"", @""
									 ];
		LMIcon sourceIcons[] = {
			LMIconBrowse, LMIconMiniplayer, LMIconGenres
		};
		BOOL shouldInvertIcon[] = {
			YES, NO, YES
		};
		
		NSMutableArray *sources = [NSMutableArray new];
		
		for(int i = 0; i < sourceTitles.count; i++){
			NSString *subtitle = [sourceSubtitles objectAtIndex:i];
			LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
											 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
												 andIcon:sourceIcons[i]];
			if(shouldInvertIcon[i]){
				source.icon = [LMAppIcon invertImage:source.icon];
			}
			[sources addObject:source];
		}
		
		self.sourcesForTabs = [NSArray arrayWithArray:sources];
		
		
		
		self.currentSourceBackgroundView = [UIView newAutoLayoutView];
		self.currentSourceBackgroundView.backgroundColor = [UIColor purpleColor];
		[self addSubview:self.currentSourceBackgroundView];
		
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.currentSourceBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.currentSourceBackgroundView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/14.0];
		
		self.currentSourceBackgroundView.backgroundColor = [UIColor whiteColor];
		self.currentSourceBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.currentSourceBackgroundView.layer.shadowOpacity = 0.25f;
		self.currentSourceBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
		self.currentSourceBackgroundView.layer.masksToBounds = NO;
		self.currentSourceBackgroundView.layer.shadowRadius = 5;
		
		
		self.currentSourceButton = [LMButton newAutoLayoutView];
		self.currentSourceButton.delegate = self;
		[self.currentSourceBackgroundView addSubview:self.currentSourceButton];
		
		[self.currentSourceButton autoCenterInSuperview];
		[self.currentSourceButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:0.8];
		[self.currentSourceButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:0.8];
		
		[self.currentSourceButton setupWithImageMultiplier:0.525];
		
		[self.currentSourceButton setImage:[LMAppIcon imageForIcon:LMIconPlaylists]];
		
		
		
		self.currentSourceLabel = [LMLabel newAutoLayoutView];
		self.currentSourceLabel.text = @"Text post please ignore";
		[self.currentSourceBackgroundView addSubview:self.currentSourceLabel];
		
		[self.currentSourceLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:10];
		[self.currentSourceLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.currentSourceButton withOffset:-10];
		[self.currentSourceLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/2.0)];
		[self.currentSourceLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		self.currentSourceDetailLabel = [LMLabel newAutoLayoutView];
		self.currentSourceDetailLabel.text = @"You didn't ignore it";
		self.currentSourceDetailLabel.textAlignment = NSTextAlignmentRight;
		[self.currentSourceBackgroundView addSubview:self.currentSourceDetailLabel];
		
		[self.currentSourceDetailLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
		[self.currentSourceDetailLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.currentSourceButton withOffset:10];
		[self.currentSourceDetailLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/2.0)];
		[self.currentSourceDetailLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		
		
		UISwipeGestureRecognizer *swipeUpOnCurrentSourceGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(open)];
		swipeUpOnCurrentSourceGesture.direction = UISwipeGestureRecognizerDirectionUp;
		[self.currentSourceBackgroundView addGestureRecognizer:swipeUpOnCurrentSourceGesture];
		
		UITapGestureRecognizer *tapOnCurrentSourceGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(open)];
		[self.currentSourceBackgroundView addGestureRecognizer:tapOnCurrentSourceGesture];
		

		
		self.selectorBackgroundView = [UIView newAutoLayoutView];
		self.selectorBackgroundView.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.selectorBackgroundView];
		
		NSLog(@"Loading browsing");
		
		self.selectorPositionConstraint = [self.selectorBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
		[self.selectorBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.selectorBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		[self.selectorBackgroundView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/8.0];
		
		UIView *whiteViewForAnimation = [UIView newAutoLayoutView]; //For when the view slightly bounces up
		whiteViewForAnimation.backgroundColor = [UIColor whiteColor];
		[self addSubview:whiteViewForAnimation];
		
		[whiteViewForAnimation autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.selectorBackgroundView];
		[whiteViewForAnimation autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[whiteViewForAnimation autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[whiteViewForAnimation autoSetDimension:ALDimensionHeight toSize:100];
		
		
		
		self.tabViews = [NSMutableArray new];
		
		for(int i = 0; i < self.sourcesForTabs.count; i++){
			LMSource *source = [self.sourcesForTabs objectAtIndex:i];
			
			BOOL isFirst = (i == 0);
			
			UIView *leadingView = isFirst ? self.selectorBackgroundView : [self.tabViews objectAtIndex:i-1];
			
			UIView *sourceTabBackgroundView = [UIView newAutoLayoutView];
			sourceTabBackgroundView.backgroundColor = [LMColour ligniteRedColour];
			[self.selectorBackgroundView addSubview:sourceTabBackgroundView];
			
			UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sourceTapped:)];
			[sourceTabBackgroundView addGestureRecognizer:tapGesture];
			
			[sourceTabBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:leadingView withOffset:!isFirst];
			[sourceTabBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.selectorBackgroundView withMultiplier:(1.0/(float)self.sourcesForTabs.count)];
			[sourceTabBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTop];
			[sourceTabBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
			
			[self.tabViews addObject:sourceTabBackgroundView];
			
			LMLabel *textLabel = [LMLabel newAutoLayoutView];
			textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:60.0f];
			textLabel.text = [source.title uppercaseString];
			textLabel.textColor = [UIColor whiteColor];
			textLabel.textAlignment = NSTextAlignmentCenter;
			[sourceTabBackgroundView addSubview:textLabel];
			
			[textLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
			[textLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
			[textLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:sourceTabBackgroundView withOffset:-2];
			[textLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.selectorBackgroundView withMultiplier:(1.0/6.0)];
			
			UIImageView *iconView = [UIImageView newAutoLayoutView];
			iconView.image = source.icon;
			iconView.contentMode = UIViewContentModeScaleAspectFit;
			[sourceTabBackgroundView addSubview:iconView];
			
			[iconView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
			[iconView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:textLabel withOffset:-10];
			[iconView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:sourceTabBackgroundView withMultiplier:(3.0/10.0)];
		}
		
		
		
		self.browsingBar = [LMBrowsingBar newAutoLayoutView];
		self.browsingBar.searchBarDelegate = self;
		self.browsingBar.letterTabDelegate = self.letterTabBarDelegate;
		[self addSubview:self.browsingBar];
		
		self.browsingBarBottomConstraint = [self.browsingBar autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.selectorBackgroundView];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.browsingBar autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.browsingBar autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/15.0];
		
		
		
		self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
		[self addSubview:self.miniPlayerView];
		
		self.miniPlayerBottomConstraint = [self.miniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.selectorBackgroundView withOffset:WINDOW_FRAME.size.height/5.0];
		[self.miniPlayerView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[self.miniPlayerView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[self.miniPlayerView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/5.0];
		
		[self.miniPlayerView setup];
		
		
		UISwipeGestureRecognizer *swipeUpGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(swipeUp)];
		swipeUpGesture.direction = UISwipeGestureRecognizerDirectionUp;
		[self.miniPlayerView addGestureRecognizer:swipeUpGesture];
		
		self.miniPlayerView.backgroundColor = [UIColor whiteColor];
		self.miniPlayerView.layer.shadowColor = [UIColor blackColor].CGColor;
		self.miniPlayerView.layer.shadowOpacity = 0.25f;
		self.miniPlayerView.layer.shadowOffset = CGSizeMake(0, 0);
		self.miniPlayerView.layer.masksToBounds = NO;
		self.miniPlayerView.layer.shadowRadius = 5;
		
		
		
		self.sourceSelector = [LMSourceSelectorView newAutoLayoutView];
		self.sourceSelector.backgroundColor = [UIColor redColor];
		self.sourceSelector.sources = self.sourcesForSourceSelector;
		self.sourceSelector.delegate = self;
		[self addSubview:self.sourceSelector];
		
		[self.sourceSelector autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
		[self.sourceSelector autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
		self.sourceSelectorPositionConstraint = [self.sourceSelector autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self withOffset:WINDOW_FRAME.size.height];
		[self.sourceSelector autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self];
		
		self.musicPlayer.sourceSelector = self.sourceSelector;
		
		[self.sourceSelector setup];
		
		
//		self.grabberView = [LMGrabberView newAutoLayoutView];
//		self.grabberView.backgroundColor = [LMColour ligniteRedColour];
//		self.grabberView.layer.masksToBounds = YES;
//		[self addSubview:self.grabberView];
//		CGFloat tabHeight = TAB_HEIGHT;
//		
//		[self.grabberView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.browsingBar];
//		[self.grabberView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/6.0)];
//		[self.grabberView autoSetDimension:ALDimensionHeight toSize:tabHeight];
//		[self.grabberView autoAlignAxisToSuperviewAxis:ALAxisVertical];
//		
//		
//		UIPanGestureRecognizer *moveRecognizer = [[UIPanGestureRecognizer alloc]initWithTarget:self action:@selector(handlePan:)];
//		moveRecognizer.delegate = self;
//		[self.grabberView addGestureRecognizer:moveRecognizer];
		
//		[self insertSubview:self.browsingBar aboveSubview:self.grabberView];
		
		[self insertSubview:self.selectorBackgroundView aboveSubview:self.miniPlayerView];
		
		[self insertSubview:self.sourceSelector aboveSubview:self.miniPlayerView];
		[self insertSubview:self.sourceSelector belowSubview:self.selectorBackgroundView];
		
//		UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(close)];
//		swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
//		[self addGestureRecognizer:swipeDownGesture];
		
		[self selectSource:LMBrowsingAssistantTabBrowse];
		
	//	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(close) userInfo:nil repeats:NO];
	}
	
	[super layoutSubviews];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.currentlySelectedTab = -1;
		self.previouslySelectedTab = -1;
	}
	else{
		NSLog(@"Error creating browsing assistant");
	}
	return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
