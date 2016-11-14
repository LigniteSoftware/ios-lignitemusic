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

@interface LMBrowsingAssistantView()

@property LMMusicPlayer *musicPlayer;

@property UIView *currentElementBackgroundView, *selectorBackgroundView;

@property UIView *grabberView;
@property UIImageView *grabberImageView;

@property LMMiniPlayerView *miniPlayerView;

@property CGPoint originalPoint, currentPoint;

@property int8_t currentlySelectedTab;

@property NSMutableArray *tabViews;
@property NSArray *sourcesForSourceSelector;

@end

@implementation LMBrowsingAssistantView

- (BOOL)open {
	if(self.textBackgroundConstraint.constant == 0){
		return NO;
	}
	
	NSLog(@"Open browsing assistant");
	
	[[self superview] layoutIfNeeded];
	self.textBackgroundConstraint.constant = 0;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y);
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[[self superview] layoutIfNeeded];
						} completion:nil];
	
	return YES;
}

- (BOOL)close {
	int squadGoals = self.currentElementBackgroundView.frame.size.height-10;
	if(self.textBackgroundConstraint.constant == squadGoals){
		return NO;
	}
	
	NSLog(@"Close browsing assistant");
	
	[[self superview] layoutIfNeeded];
	self.textBackgroundConstraint.constant = squadGoals;
	self.currentPoint = CGPointMake(self.originalPoint.x, self.originalPoint.y + self.textBackgroundConstraint.constant);
	[UIView animateWithDuration:0.5 delay:0
		 usingSpringWithDamping:0.6 initialSpringVelocity:0.0f
						options:0 animations:^{
							[[self superview] layoutIfNeeded];
						} completion:nil];
	
	return YES;
}

- (void)handlePan:(UIPanGestureRecognizer *)recognizer {
	CGPoint translation = [recognizer translationInView:self];
	
	if(self.originalPoint.y == 0){
		self.originalPoint = self.frame.origin;
		self.currentPoint = self.frame.origin;
	}
	float totalTranslation = translation.y + (self.currentPoint.y-self.originalPoint.y);
	
//	NSLog(@"%f", totalTranslation);
	
	if(totalTranslation < 0){
		self.textBackgroundConstraint.constant = -sqrt(-totalTranslation);
	}
	else{
		self.textBackgroundConstraint.constant = totalTranslation;
	}
	
	[[self superview] layoutIfNeeded];
	
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
}
	
- (void)swipeUp {
	[self.coreViewController openNowPlayingView];
}
	
- (void)swipeDown {
	[self close];
}

- (void)selectSource:(uint8_t)sourceSelectedIndex {
	UIView *backgroundView = [self.tabViews objectAtIndex:sourceSelectedIndex];
	
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
}

- (void)sourceTapped:(UITapGestureRecognizer*)tapGesture {
	UIView *viewTapped = tapGesture.view;
	
	uint8_t viewTappedIndex = [self.tabViews indexOfObject:viewTapped];
	
	[self selectSource:viewTappedIndex];
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
		LMIconPlay, LMIconGenres
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
	
	self.sourcesForSourceSelector = [NSArray arrayWithArray:sources];
	
	self.selectorBackgroundView = [UIView newAutoLayoutView];
	self.selectorBackgroundView.backgroundColor = [UIColor orangeColor];
	[self addSubview:self.selectorBackgroundView];
	
	NSLog(@"Loading browsing");
	
	[self.selectorBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self];
	[self.selectorBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
	[self.selectorBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
	[self.selectorBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:0.135];
	
	self.tabViews = [NSMutableArray new];
	
	for(int i = 0; i < self.sourcesForSourceSelector.count; i++){
		LMSource *source = [self.sourcesForSourceSelector objectAtIndex:i];
		
		BOOL isFirst = (i == 0);
		
		UIView *leadingView = isFirst ? self.selectorBackgroundView : [self.tabViews objectAtIndex:i-1];
		
		UIView *sourceTabBackgroundView = [UIView newAutoLayoutView];
		sourceTabBackgroundView.backgroundColor = [LMColour ligniteRedColour];
		[self.selectorBackgroundView addSubview:sourceTabBackgroundView];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sourceTapped:)];
		[sourceTabBackgroundView addGestureRecognizer:tapGesture];
		
		[sourceTabBackgroundView autoPinEdge:ALEdgeLeading toEdge:isFirst ? ALEdgeLeading : ALEdgeTrailing ofView:leadingView];
		[sourceTabBackgroundView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.selectorBackgroundView withMultiplier:(1.0/(float)self.sourcesForSourceSelector.count)];
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
	
	self.currentElementBackgroundView = [UIView newAutoLayoutView];
	self.currentElementBackgroundView.backgroundColor = [UIColor blueColor];
	[self addSubview:self.currentElementBackgroundView];
	
	[self.currentElementBackgroundView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.selectorBackgroundView];
	[self.currentElementBackgroundView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.selectorBackgroundView];
	[self.currentElementBackgroundView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.selectorBackgroundView];
	[self.currentElementBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:/*(2.0/3.0)**/(2.0/10.0)];

	self.miniPlayerView = [LMMiniPlayerView newAutoLayoutView];
	[self.currentElementBackgroundView addSubview:self.miniPlayerView];
	
	[self.miniPlayerView autoPinEdgesToSuperviewEdges];
	
	[self.miniPlayerView setup];

	self.currentElementBackgroundView.translatesAutoresizingMaskIntoConstraints = NO;
	self.currentElementBackgroundView.backgroundColor = [UIColor whiteColor];
	self.currentElementBackgroundView.layer.shadowColor = [UIColor blackColor].CGColor;
	self.currentElementBackgroundView.layer.shadowOpacity = 0.25f;
	self.currentElementBackgroundView.layer.shadowOffset = CGSizeMake(0, 0);
	self.currentElementBackgroundView.layer.masksToBounds = NO;
	self.currentElementBackgroundView.layer.shadowRadius = 5;
	
	[self insertSubview:self.selectorBackgroundView aboveSubview:self.currentElementBackgroundView];
	
//	[NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(close) userInfo:nil repeats:NO];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
		
		self.currentlySelectedTab = -1;
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
