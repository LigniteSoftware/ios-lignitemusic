//
//  LMTrackInfoView.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/6/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTrackInfoView.h"
#import "LMLayoutManager.h"
#import "NSTimer+Blocks.h"
#import "LMSettings.h"

@interface LMTrackInfoView()<LMLayoutChangeDelegate>

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 Whether or not the info view did its initial reload, which is sometimes required when first laying out as font sizes get fucked up.
 */
@property BOOL didInitialReload;

@end

@implementation LMTrackInfoView

@synthesize titleText = _titleText;
@synthesize artistText = _artistText;
@synthesize albumText = _albumText;
@synthesize textColour = _textColour;

- (void)traitCollectionDidChange:(UITraitCollection *)previousTraitCollection {
	NSTextAlignment newTextAlignment = self.layoutManager.isLandscape ? NSTextAlignmentLeft : NSTextAlignmentCenter;
	if(self.miniplayer){
		newTextAlignment = NSTextAlignmentLeft;
	}
	self.titleLabel.textAlignment = newTextAlignment;
	self.artistLabel.textAlignment = newTextAlignment;
	self.albumLabel.textAlignment = newTextAlignment;
}

- (void)reload {
	for(UIView *subview in self.subviews){
		[subview removeFromSuperview];
	}
	
	self.didLayoutConstraints = NO;
	[self setNeedsLayout];
	[self layoutIfNeeded];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self reload];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	}];
}

- (NSString*)titleText {
	return _titleText;
}

- (void)setTitleText:(NSString *)titleText {
	_titleText = titleText;
	
	if(self.titleLabel){
		self.titleLabel.text = titleText;
	}
}

- (NSString*)artistText {
	return _artistText;
}

- (void)setArtistText:(NSString *)artistText {
	_artistText = artistText;
	
	if(self.artistLabel){
		self.artistLabel.text = artistText;
	}
}

- (NSString*)albumText {
	return _albumText;
}

- (void)setAlbumText:(NSString *)albumText {
	_albumText = albumText;
	
	if(self.albumLabel){
		self.albumLabel.text = albumText;
	}
}

- (UIColor*)textColour {
	return _textColour;
}

- (void)setTextColour:(UIColor *)textColour {
	_textColour = textColour;
	
	if(self.didLayoutConstraints){
		self.titleLabel.textColor = textColour;
		self.artistLabel.textColor = textColour;
		self.albumLabel.textColor = textColour;
	}
}

- (void)layoutSubviews {
//	self.backgroundColor = [UIColor yellowColor];
	
	if(!self.didLayoutConstraints){
		self.didLayoutConstraints = YES;
		
		self.titleLabel = [MarqueeLabel newAutoLayoutView];
		self.artistLabel = [MarqueeLabel newAutoLayoutView];
		self.albumLabel = [MarqueeLabel newAutoLayoutView];
		
		if(!self.titleText){
			self.titleText = @"";
		}
		if(!self.artistText){
			self.artistText = @"";
		}
		if(!self.albumText){
			self.albumText = @"";
		}
		
	//	self.titleLabel.layoutMargins = UIEdgeInsetsMake(0, -4, 0, -4);
		
		const CGFloat heightMultipliers[] = {
			(1.0/(self.miniplayer ? 2.5 : 3.0)), (1.0/4.0), (1.0/5.0)
		};
		NSArray *labels = @[
			self.titleLabel, self.artistLabel, self.albumLabel
		];
		NSArray *texts = @[
			self.titleText, self.artistText, self.albumText
		];
		
		for(int i = 0; i < 3; i++){
			BOOL isFirst = (i == 0);
			
			MarqueeLabel *label = [labels objectAtIndex:i];
			MarqueeLabel *previousLabel = isFirst ? [labels objectAtIndex:0] : [labels objectAtIndex:i-1];
			
			label.fadeLength = 10;
			label.leadingBuffer = 0;
			label.trailingBuffer = 50;
			
//			label.backgroundColor = [UIColor colorWithRed:(0.2*i)+0.3 green:0 blue:0 alpha:1.0];
//			NSLog(@"Frame %@ multiplier %f total %f", NSStringFromCGRect(self.frame), heightMultipliers[i], self.frame.size.height*heightMultipliers[i]);
			label.font = [LMMarqueeLabel fontToFitHeight:self.frame.size.height*heightMultipliers[i]];
//			label.font = [UIFont fontWithName:label.font.fontName size:label.font.pointSize/3.0];
			label.text = [texts objectAtIndex:i];
			label.textAlignment = self.textAlignment;
			label.textColor = self.textColour;
			label.labelize = ![LMSettings scrollingText];
			[self addSubview:label];
			
			if(self.frame.size.width == 0 || !self.didInitialReload){
				[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
					[self reload];
				} repeats:NO];
				
				self.didInitialReload = YES;
			}
//			else{
//				NSLog(@"Building for frame %@. Fontsize %f. Miniplayer %d.", NSStringFromCGRect(self.frame), label.font.pointSize, self.miniplayer);
//			}
			
			[label autoPinEdge:ALEdgeTop toEdge:isFirst ? ALEdgeTop : ALEdgeBottom ofView:isFirst ? self : previousLabel withOffset:isFirst ? -label.layoutMargins.top : 2];
			[label autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self];
			[label autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self];
			[label setContentHuggingPriority:UILayoutPriorityRequired forAxis:UILayoutConstraintAxisHorizontal];
			[label setContentCompressionResistancePriority:UILayoutPriorityDefaultLow forAxis:UILayoutConstraintAxisHorizontal];
			
			//Update alignments
			[self traitCollectionDidChange:nil];
		}
	}
		
	[super layoutSubviews];
	
	[NSTimer scheduledTimerWithTimeInterval:5.0 block:^{
		BOOL labelize = ![LMSettings scrollingText];
		
		if(labelize == self.titleLabel.labelize){
			return;
		}
		
		NSArray *slabels = @[
							self.titleLabel, self.artistLabel, self.albumLabel
							];
		
		for(int i = 0; i < 3; i++){
			MarqueeLabel *label = [slabels objectAtIndex:i];
			label.labelize = labelize;
		}
	} repeats:YES];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.textColour = [UIColor blackColor];
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
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
