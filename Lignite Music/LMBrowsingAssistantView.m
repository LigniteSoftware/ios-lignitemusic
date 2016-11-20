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
#import "LMExtras.h"
#import "LMLabel.h"
#import "LMButton.h"

@interface LMBrowsingAssistantView()<LMButtonDelegate, LMSourceSelectorDelegate>

@property LMMusicPlayer *musicPlayer;

@property UIView *selectorBackgroundView;
@property NSLayoutConstraint *selectorPositionConstraint;

@property UIView *grabberView;
@property UIImageView *grabberImageView;

@property LMMiniPlayerView *miniPlayerView;

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

@end

@implementation LMBrowsingAssistantView

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
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];
	
	[self.delegate heightRequiredChangedTo:self.selectorBackgroundView.frame.size.height+self.miniPlayerView.frame.size.height forBrowsingView:self];
	
	return YES;
}

- (BOOL)close {
	if(self.textBackgroundConstraint.constant == self.frame.size.height){
		return NO;
	}
	
	NSLog(@"Close browsing assistant");
	
	if(self.currentlySelectedTab == 1){
		[self closeSourceSelector];
	}

	
	[self layoutIfNeeded];
	self.selectorPositionConstraint.constant = self.frame.size.height;
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[self layoutIfNeeded];
						} completion:nil];

	[self.delegate heightRequiredChangedTo:self.currentSourceBackgroundView.frame.size.height forBrowsingView:self];
	
	return YES;
}
	
- (void)swipeUp {
	[self.coreViewController openNowPlayingView];
}
	
- (void)swipeDown {
	[self close];
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

- (void)heightOfCurrentElementChangedTo:(float)newHeight {
	[self.delegate heightRequiredChangedTo:WINDOW_FRAME.size.height/8.0 + newHeight forBrowsingView:self];
}

- (void)closeSourceSelector {
	[self moveSourceSelectorToPosition:WINDOW_FRAME.size.height];
	[self selectSource:self.previouslySelectedTab];
}

- (void)openSourceSelector {
	[self moveSourceSelectorToPosition:0];
}

- (void)selectSource:(uint8_t)sourceSelectedIndex {
	if(sourceSelectedIndex == self.currentlySelectedTab){
		return;
	}
	
	//Perform the action associated with tab to implement the new tab selection
	switch(sourceSelectedIndex){
		case 0:{
			[self heightOfCurrentElementChangedTo:WINDOW_FRAME.size.height/5];
			break;
		}
		case 1:{
			[self openSourceSelector];
			self.previouslySelectedTab = self.currentlySelectedTab;
			
			[self heightOfCurrentElementChangedTo:WINDOW_FRAME.size.height/8 * 7];
			break;
		}
	}
	
	UIView *backgroundView = [self.tabViews objectAtIndex:sourceSelectedIndex];
	
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
		
		self.currentlySelectedTab = sourceSelectedIndex;
	}];
	
	if(sourceSelectedIndex != 1 && self.sourceSelectorPositionConstraint.constant < 10){
		[self closeSourceSelector];
	}
}

- (void)sourceTapped:(UITapGestureRecognizer*)tapGesture {
	UIView *viewTapped = tapGesture.view;
	
	uint8_t viewTappedIndex = [self.tabViews indexOfObject:viewTapped];
	
	[self selectSource:viewTappedIndex];
}

- (void)shitpost {
	[self.delegate heightRequiredChangedTo:WINDOW_FRAME.size.height/3 forBrowsingView:self];
}

- (void)setCurrentSourceIcon:(UIImage*)icon {
	UIView *sourceBackgroundView = [self.tabViews objectAtIndex:1];
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
	[self open];
}

- (void)setup {
	self.backgroundColor = [UIColor clearColor];
	
	NSArray *sourceTitles = @[
							  @"Miniplayer", @"View"
							  ];
	NSArray *sourceSubtitles = @[
								 @"", @""
								 ];
	LMIcon sourceIcons[] = {
		LMIconMiniplayer, LMIconGenres
	};
	BOOL notSelect[] = {
		NO, NO
	};
	BOOL shouldInvertIcon[] = {
		NO, YES
	};
	
	NSMutableArray *sources = [NSMutableArray new];
	
	for(int i = 0; i < sourceTitles.count; i++){
		NSString *subtitle = [sourceSubtitles objectAtIndex:i];
		LMSource *source = [LMSource sourceWithTitle:NSLocalizedString([sourceTitles objectAtIndex:i], nil)
										 andSubtitle:[subtitle isEqualToString:@""]  ? nil : NSLocalizedString(subtitle, nil)
											 andIcon:sourceIcons[i]];
		source.shouldNotSelect = notSelect[i];
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
	[self.currentSourceLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/3.0)];
	[self.currentSourceLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	
	self.currentSourceDetailLabel = [LMLabel newAutoLayoutView];
	self.currentSourceDetailLabel.text = @"You didn't ignore it";
	self.currentSourceDetailLabel.textAlignment = NSTextAlignmentRight;
	[self.currentSourceBackgroundView addSubview:self.currentSourceDetailLabel];
	
	[self.currentSourceDetailLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:10];
	[self.currentSourceDetailLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.currentSourceButton withOffset:10];
	[self.currentSourceDetailLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.currentSourceBackgroundView withMultiplier:(1.0/3.0)];
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
		
		UIImageView *iconView = [UIImageView newAutoLayoutView];
		iconView.image = source.icon;
		iconView.contentMode = UIViewContentModeScaleAspectFit;
		[sourceTabBackgroundView addSubview:iconView];
		
		[iconView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
		[iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[iconView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
		[iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:sourceTabBackgroundView withMultiplier:(6.0/10.0)];
		
		LMLabel *textLabel = [LMLabel newAutoLayoutView];
		textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:60.0f];
		textLabel.text = [source.title uppercaseString];
		textLabel.textColor = [UIColor whiteColor];
		textLabel.textAlignment = NSTextAlignmentCenter;
		[sourceTabBackgroundView addSubview:textLabel];
		
		[textLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:sourceTabBackgroundView withOffset:10];
		[textLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:sourceTabBackgroundView withOffset:-10];
		[textLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:sourceTabBackgroundView withOffset:-2];
		[textLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.selectorBackgroundView withMultiplier:(1.0/6.0)];
	}
	
	
	
	self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
	[self addSubview:self.miniPlayerView];
	
	[self.miniPlayerView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.selectorBackgroundView];
	[self.miniPlayerView autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width];
	[self.miniPlayerView autoSetDimension:ALDimensionHeight toSize:WINDOW_FRAME.size.height/5];
	
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
	
	
	
	[self insertSubview:self.selectorBackgroundView aboveSubview:self.miniPlayerView];
	
	[self insertSubview:self.sourceSelector aboveSubview:self.miniPlayerView];
	[self insertSubview:self.sourceSelector belowSubview:self.selectorBackgroundView];
	
	UISwipeGestureRecognizer *swipeDownGesture = [[UISwipeGestureRecognizer alloc]initWithTarget:self action:@selector(close)];
	swipeDownGesture.direction = UISwipeGestureRecognizerDirectionDown;
	[self addGestureRecognizer:swipeDownGesture];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(shitpost) userInfo:nil repeats:NO];

//	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(close) userInfo:nil repeats:NO];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.currentlySelectedTab = -1;
		self.previouslySelectedTab = 0;
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
