//
//  LMCreditsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/25/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCreditsView.h"

@interface LMCreditsView()

/**
 Whether or not constraints have been setup yet.
 */
@property BOOL didSetupConstraints;

/**
 The root scroll view of the credits view.
 */
@property UIScrollView *scrollView;

/**
 The image view for Philipp and I's photo together :)
 */
@property UIImageView *philippAndEdwinView;

/**
 The big "Thank you!" title label.
 */
@property UILabel *thankYouLabel;

@end

@implementation LMCreditsView

- (instancetype)init {
	self = [super init];
	if(self) {
		self.backgroundColor = [UIColor orangeColor];
	}
	return self;
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didSetupConstraints){
		self.didSetupConstraints = YES;
		
		self.scrollView = [UIScrollView newAutoLayoutView];
		self.scrollView.backgroundColor = [UIColor whiteColor];
		[self addSubview:self.scrollView];
		
		[self.scrollView autoPinEdgesToSuperviewEdges];
		
		
		self.philippAndEdwinView = [UIImageView newAutoLayoutView];
		self.philippAndEdwinView.image = [UIImage imageNamed:@"onboarding_us.png"];
		self.philippAndEdwinView.contentMode = UIViewContentModeScaleToFill;
		self.philippAndEdwinView.backgroundColor = [UIColor purpleColor];
		[self.scrollView addSubview:self.philippAndEdwinView];
		
		[self.philippAndEdwinView autoPinEdgeToSuperviewEdge:ALEdgeTop];
		[self.philippAndEdwinView autoSetDimension:ALDimensionWidth toSize:self.frame.size.width];
		[self.philippAndEdwinView autoSetDimension:ALDimensionHeight toSize:0.88*self.frame.size.width];
		
		
		self.thankYouLabel = [UILabel newAutoLayoutView];
		self.thankYouLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
		self.thankYouLabel.text = NSLocalizedString(@"ThankYou", nil);
		self.thankYouLabel.textAlignment = NSTextAlignmentCenter;
		[self.scrollView addSubview:self.thankYouLabel];
		
		[self.thankYouLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width];
		[self.thankYouLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-self.frame.size.width*0.10];

		
		NSMutableArray *textLabelsArray = [NSMutableArray new];
		
		NSArray *textKeys = @[@"ThankYouDescription",
							  
							  @"KickstarterBackers",
							  
							  @"RankLigniteLover",
							  @"RankLigniteLoverPeople",
							  
							  @"RankSuperSupporters",
							  @"RankSuperSupportersPeople",
							  
							  @"RankLigniteMusicInfluencers",
							  @"RankLigniteMusicInfluencersPeople",
							  
							  @"RankBetaAccess",
							  @"RankBetaAccessPeople",
							  
							  @"RankEarlyBird",
							  @"RankEarlyBirdPeople",
							  
							  @"RankSuperEarlyBird",
							  @"RankSuperEarlyBirdPeople",
							  
							  @"RankLigniteSupporter",
							  @"RankLigniteSupporterPeople",
							  
							  @"LastFMAPI",
							  @"LastFMAPIDescription",
							  
							  @"OpenSourceLibraries",
							  @"OpenSourceLibrariesLicensing",
							  
							  @"LibraryYYImage",
							  @"LibraryYYImageDescription",
							  
							  @"LibrarySDWebImage",
							  @"LibrarySDWebImageDescription",
							  
							  @"LibraryImageMagick",
							  @"LibraryImageMagickDescription",
							  
							  @"LibraryPebbleKit",
							  @"LibraryPebbleKitDescription",
							  
							  @"LibraryPureLayout",
							  @"LibraryPureLayoutDescription",
							  
							  @"LibraryMBProgressHUD",
							  @"LibraryMBProgressHUDDescription",
							  
							  @"LibraryMarqueeLabel",
							  @"LibraryMarqueeLabelDescription",
							  
							  @"LibraryReachability",
							  @"LibraryReachabilityDescription"
	    ];
		float textFontSizes[] = {
			20.0,
			
			34.0,

			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
		
			20.0,
			20.0,
		
			20.0,
			20.0,
		
			20.0,
			20.0,
		
			20.0,
			20.0,
			
			34.0,
			20.0,
			
			34.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
			
			20.0,
			20.0,
		};
		BOOL textFontIsBoldOptions[] = {
			NO,
			
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
		
			YES,
			NO,
		
			YES,
			NO,
		
			YES,
			NO,
		
			YES,
			NO,
		
			YES,
			NO,
			
			NO,
			NO,
			
			NO,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
			
			YES,
			NO,
		};

		for(int i = 0; i < textKeys.count; i++){
			UILabel *previousLabelToAttachTo = (i == 0) ? self.thankYouLabel : [textLabelsArray lastObject];
			
			NSString *text = NSLocalizedString([textKeys objectAtIndex:i], nil);
			float fontSize = textFontSizes[i];
			BOOL textFontIsBold = textFontIsBoldOptions[i];
			
			UILabel *textLabel = [UILabel newAutoLayoutView];
			textLabel.text = text;
			textLabel.font = [UIFont fontWithName:textFontIsBold ? @"HelveticaNeue-Bold" : @"HelveticaNeue-Light" size:fontSize];
			textLabel.numberOfLines = 0;
			textLabel.textAlignment = NSTextAlignmentJustified;
			[self.scrollView addSubview:textLabel];
			
			[textLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*0.90];
			[textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[textLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabelToAttachTo withOffset:self.frame.size.width*0.035];
			
			[textLabelsArray addObject:textLabel];
		}
		
		[self.scrollView setContentSize:CGSizeMake(self.frame.size.width, self.frame.size.height*5)];
	}
}

@end
