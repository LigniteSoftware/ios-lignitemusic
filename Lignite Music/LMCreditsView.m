//
//  LMCreditsView.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/25/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMCreditsView.h"
#import "LMScrollView.h"
#import "LMAppIcon.h"
#import "LMColour.h"

@interface LMCreditsView()

/**
 Whether or not constraints have been setup yet.
 */
@property BOOL didSetupConstraints;

/**
 The root scroll view of the credits view.
 */
@property LMScrollView *scrollView;

/**
 The image view for Philipp and I's photo together :)
 */
@property UIImageView *philippAndEdwinView;

/**
 The big "Thank you!" title label.
 */
@property UILabel *thankYouLabel;
	
/**
 The thanks for your support description label.
 */
@property UILabel *thanksForYourSupportLabel;

/**
 The signatures view which goes above the thank you label.
 */
@property UIImageView *signaturesView;

@end

@implementation LMCreditsView

- (instancetype)init {
	self = [super init];
	if(self) {
		self.backgroundColor = [UIColor orangeColor];
	}
	return self;
}

- (void)creditLinks {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.lignitemusic.com/licenses/"]];
}

- (void)layoutSubviews {
	[super layoutSubviews];
	
	if(!self.didSetupConstraints){
		self.didSetupConstraints = YES;
				
		self.scrollView = [LMScrollView newAutoLayoutView];
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
		
		
//		self.signaturesView = [UIImageView newAutoLayoutView];
//		self.signaturesView.image = [UIImage imageNamed:@"signatures.png"];
//		self.signaturesView.contentMode = UIViewContentModeScaleToFill;
//		[self.scrollView addSubview:self.signaturesView];
//		
//		[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
//		[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-self.frame.size.width*0.10];
//		float scaleFactor = 0.75;
//		[self.signaturesView autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*scaleFactor];
//		[self.signaturesView autoSetDimension:ALDimensionHeight toSize:self.frame.size.width*0.296*scaleFactor];
		

		self.thankYouLabel = [UILabel newAutoLayoutView];
		self.thankYouLabel.font = [UIFont fontWithName:@"HoneyScript-SemiBold" size:(self.frame.size.width/414.0)*75.0f];
		self.thankYouLabel.text = NSLocalizedString(@"ThankYou", nil);
		self.thankYouLabel.textAlignment = NSTextAlignmentCenter;
		[self.scrollView addSubview:self.thankYouLabel];
		
		[self.thankYouLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width];
		[self.thankYouLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.philippAndEdwinView withOffset:-self.frame.size.width*0.10];
		
		self.thanksForYourSupportLabel = [UILabel newAutoLayoutView];
		self.thanksForYourSupportLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(self.frame.size.width/414.0)*18.0f];
		self.thanksForYourSupportLabel.text = NSLocalizedString(@"ThankYouDescription", nil);
		self.thanksForYourSupportLabel.textAlignment = NSTextAlignmentLeft;
		self.thanksForYourSupportLabel.numberOfLines = 0;
		[self.scrollView addSubview:self.thanksForYourSupportLabel];
		
		[self.thanksForYourSupportLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.thanksForYourSupportLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*0.9];
		[self.thanksForYourSupportLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel withOffset:self.frame.size.width*0.05];
		
		
		self.signaturesView = [UIImageView newAutoLayoutView];
		self.signaturesView.image = [UIImage imageNamed:@"signatures.png"];
		self.signaturesView.contentMode = UIViewContentModeScaleToFill;
		[self.scrollView addSubview:self.signaturesView];
		
		[self.signaturesView autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.signaturesView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thanksForYourSupportLabel withOffset:self.frame.size.width*0.05];
		float scaleFactor = 0.75;
		[self.signaturesView autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*scaleFactor];
		[self.signaturesView autoSetDimension:ALDimensionHeight toSize:self.frame.size.width*0.296*scaleFactor];
		
		
		NSMutableArray *textLabelsArray = [NSMutableArray new];
		
		NSArray *textKeys = @[
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
							  @"LibraryReachabilityDescription",
							  
							  @"Icons",
							  @"IconsDescription"
	    ];
		float textFontSizes[] = {
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
			
			34.0,
			20.0
		};
		BOOL textFontIsBoldOptions[] = {
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
			
			NO,
			NO
		};

		//I would comment this better but honestly we don't have time
		
		//Goes through and detects which artists have icons and creates a row of icons
		//Does not adapt for more than 8 in a row
		
		for(int i = 0; i < textKeys.count; i++){
			BOOL isFirst = (i == 0);
			
			UILabel *previousLabelToAttachTo = isFirst ? self.signaturesView : [textLabelsArray lastObject];
			
			NSString *text = NSLocalizedString([textKeys objectAtIndex:i], nil);
			float fontSize = textFontSizes[i];
			
			float actualFontSize = (self.frame.size.width/414.0)*fontSize;
			
			BOOL textFontIsBold = textFontIsBoldOptions[i];
			
			UILabel *textLabel = [UILabel newAutoLayoutView];
			textLabel.text = text;
			textLabel.font = [UIFont fontWithName:textFontIsBold ? @"HelveticaNeue-Bold" : @"HelveticaNeue-Light" size:actualFontSize];
			textLabel.numberOfLines = 0;
			textLabel.textAlignment = NSTextAlignmentLeft;
			[self.scrollView addSubview:textLabel];
			
			[textLabel autoSetDimension:ALDimensionWidth toSize:self.frame.size.width*0.90];
			[textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[textLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousLabelToAttachTo withOffset:self.frame.size.width*(i == 0 ? 0.05 : 0.035)];
			
			[textLabelsArray addObject:textLabel];
		}
		
		NSArray *artistsArray = @[
								  @"Freepik",
								  @"Minh Hoang",
								  @"Hanan",
								  @"EpicCoders",
								  @"Nikita Golubev",
								  @"Eugene Pavovsky",
								  @"Eleonor Wang",
								  @"Madebyoliver",
								  @"Vectors Market",
								  @"Dario Ferrando",
								  @"Retinaicons",
								  @"Elegant Themes",
								  @"Gregor Cresnar"
								  ];
		
		NSArray *artistImagesArray = @[
									   @[
										   @(LMIconArtists), @(LMIconLookAndFeel),
										   @(LMIconRepeat), @(LMIconRepeatOne),
										   @(LMIconSettings)
										   ], //@"Freepik"
									   
									   @[
										   @(LMIconShuffle)
										   ], //@"Minh Hoang"
									   
									   @[
										   @(LMIconAbout)
										   ], //@"Hanan"
									   
									   @[
										   @(LMIconBrowse)
										   ], //@"EpicCoders"
									   
									   @[
										   @(LMIconComposers)
										   ], //@"Nikita Golubev"
									   
									   @[
										   
										   ], //@"Eugene Pavovsky"
									   
									   @[
										   
										   ], //@"Eleonor Wang"
									   
									   @[
										   @(LMIconPaperPlane), @(LMIconCloudDownload), @(LMIconLink)
										   ], //@"Madebyoliver"
									   
									   @[
										   
										   ], //@"Vectors Market"
									   
									   @[
										   @(LMIconPlaylists), @(LMIconTitles)
										   ],	//@"Dario Ferrando"
									   
									   @[
										   
										   ], //@"Retinaicons"
									   
									   @[
										   @(LMIconTwitter)
										   ], //@"Elegant Themes"
									   
									   @[
										   @(LMIconSearch)
										   ] //@"Gregor Cresnar"
									   
									   ];
		
		//We don't have the luxury of time to automatically adapt
		NSArray *invertIconArray = @[
									   @[
										   @(NO), @(NO),
										   @(NO), @(NO),
										   @(NO)
										   ], //@"Freepik"
									   
									   @[
										   @(NO)
										   ], //@"Minh Hoang"
									   
									   @[
										   @(NO)
										   ], //@"Hanan"
									   
									   @[
										   @(NO)
										   ], //@"EpicCoders"
									   
									   @[
										   @(NO)
										   ], //@"Nikita Golubev"
									   
									   @[
										   
										   ], //@"Eugene Pavovsky"
									   
									   @[
										   
										   ], //@"Eleonor Wang"
									   
									   @[
										   @(YES), @(NO), @(YES)
										   ], //@"Madebyoliver"
									   
									   @[
										   
										   ], //@"Vectors Market"
									   
									   @[
										   @(NO), @(NO)
										   ],	//@"Dario Ferrando"
									   
									   @[
										   
										   ], //@"Retinaicons"
									   
									   @[
										   @(YES)
										   ], //@"Elegant Themes"
									   
									   @[
										   @(YES)
										   ] //@"Gregor Cresnar"
									   ];
		
		NSMutableArray *artistLabelsArray = [NSMutableArray new];
		NSMutableArray *artistIconsArray = [NSMutableArray new];
		
		for(int i = 0; i < artistsArray.count; i++){
			NSString *artistName = [artistsArray objectAtIndex:i];
			NSArray *artistIcons = [artistImagesArray objectAtIndex:i];
			
			if(artistIcons.count > 0){
				UIView *viewToPinTopTo = artistIconsArray.count > 0 ? [[artistIconsArray lastObject] objectAtIndex:0] : [textLabelsArray lastObject];
				
				UILabel *artistLabel = [UILabel newAutoLayoutView];
				artistLabel.text = artistName;
				artistLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:(self.frame.size.width/414.0)*20.0f];
				artistLabel.textAlignment = NSTextAlignmentLeft;
				artistLabel.textColor = [UIColor blackColor];
				[self.scrollView addSubview:artistLabel];
				
				[artistLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:viewToPinTopTo withOffset:i == 0 ? self.frame.size.height*0.025 : self.frame.size.height*0.01];
				[artistLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:viewToPinTopTo];
				
				for(int iconIndex = 0; iconIndex < artistIcons.count; iconIndex++){
					BOOL isFirstIcon = iconIndex == 0;
					
					NSMutableArray *iconObjectArray;
					if(isFirstIcon){
						iconObjectArray = [NSMutableArray new];
						[artistIconsArray addObject:iconObjectArray];
					}
					else{
						iconObjectArray = [artistIconsArray objectAtIndex:artistLabelsArray.count];
					}
					
					UIView *viewToPinIconTopTo = isFirstIcon ? artistLabel : [iconObjectArray lastObject];
					UIImage *icon = [LMAppIcon imageForIcon:(LMIcon)[[artistIcons objectAtIndex:iconIndex] integerValue]];
					BOOL shouldInvert = [[[invertIconArray objectAtIndex:i] objectAtIndex:iconIndex] boolValue];
					
					if(shouldInvert){
						icon = [LMAppIcon invertImage:icon];
					}
					
					UIImageView *iconView = [UIImageView newAutoLayoutView];
					iconView.contentMode = UIViewContentModeScaleAspectFit;
					iconView.image = icon;
					[self.scrollView addSubview:iconView];
					
					[iconView autoPinEdge:ALEdgeLeading toEdge:isFirstIcon ? ALEdgeLeading : ALEdgeTrailing ofView:viewToPinIconTopTo withOffset:isFirstIcon ? 0 : 10];
					[iconView autoPinEdge:ALEdgeTop toEdge:isFirstIcon ? ALEdgeBottom : ALEdgeTop ofView:viewToPinIconTopTo];
					[iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(1.0/8.0)];
					[iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(1.0/10.0)];
					
					[iconObjectArray addObject:iconView];
				}
				
				[artistLabelsArray addObject:artistLabel];
			}
		}
		
		UILabel *creditsLinkButton = [UILabel newAutoLayoutView];
		creditsLinkButton.text = NSLocalizedString(@"CreditsLicenses", nil);
		creditsLinkButton.textAlignment = NSTextAlignmentCenter;
		creditsLinkButton.numberOfLines = 0;
		creditsLinkButton.layer.masksToBounds = YES;
		creditsLinkButton.layer.cornerRadius = 10.0;
		creditsLinkButton.backgroundColor = [LMColour ligniteRedColour];
		creditsLinkButton.textColor = [UIColor whiteColor];
		creditsLinkButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
		creditsLinkButton.userInteractionEnabled = YES;
		[self.scrollView addSubview:creditsLinkButton];
		
		[creditsLinkButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:[[artistIconsArray lastObject] lastObject] withOffset:10];
		[creditsLinkButton autoSetDimension:ALDimensionWidth toSize:self.frame.size.width * 0.9];
		[creditsLinkButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[creditsLinkButton autoSetDimension:ALDimensionHeight toSize:self.frame.size.height/8.0];
		
		UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(creditLinks)];
		[creditsLinkButton addGestureRecognizer:tapGesture];
	}
}

@end
