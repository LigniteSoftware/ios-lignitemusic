//
//  LMContactViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMContactViewController.h"
#import "LMLayoutManager.h"
#import "LMScrollView.h"
#import "LMAppIcon.h"
#import "LMExtras.h"

@interface LMContactViewController ()

@property UILabel *thankYouLabel;

@property UILabel *descriptionLabel;

@end

@implementation LMContactViewController
@dynamic view;

- (void)sendEmail {
	NSString *recipients = [NSString stringWithFormat:@"mailto:contact@lignite.io"];
	
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:recipients] options:@{} completionHandler:^(BOOL success) {
		NSLog(@"Done %d", success);
	}];
}

- (void)openTwitter {
	NSURL *twitterURL = [NSURL URLWithString:@"twitter://user?screen_name=WeAreLignite"];
	NSURL *websiteURL = [NSURL URLWithString:@"https://www.twitter.com/WeAreLignite"];
	BOOL canOpenTwitterURL = [[UIApplication sharedApplication] canOpenURL:twitterURL];
	[[UIApplication sharedApplication] openURL:canOpenTwitterURL ? twitterURL : websiteURL];
}

- (void)openWebsite {
	NSURL *websiteURL = [NSURL URLWithString:@"https://www.lignite.io/"];
	[[UIApplication sharedApplication] openURL:websiteURL];
}

- (BOOL)prefersStatusBarHidden {
	return NO || [LMLayoutManager sharedLayoutManager].isLandscape;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	NSLog(@"Shit's %ld", (long)[LMLayoutManager sharedLayoutManager].currentLayoutClass);
	
	CGFloat scaleFactorToUse = ([LMLayoutManager sharedLayoutManager].isLandscape ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width);
	
	self.thankYouLabel = [UILabel newAutoLayoutView];
	self.thankYouLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(scaleFactorToUse/414.0)*45.0f];
	self.thankYouLabel.text = NSLocalizedString(@"ContactHi", nil);
	self.thankYouLabel.textAlignment = NSTextAlignmentLeft;
	[self.view addSubview:self.thankYouLabel];
	
	[self.view beginAddingNewPortraitConstraints];
	[self.thankYouLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.thankYouLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(9.0/10.0)];
	[self.thankYouLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:84];
	
	[self.view beginAddingNewLandscapeConstraints];
	[self.thankYouLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/2.5)];
	[self.thankYouLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.thankYouLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(scaleFactorToUse/414.0)*18.0f];
	self.descriptionLabel.adjustsFontSizeToFitWidth = YES;
	self.descriptionLabel.text = NSLocalizedString(@"ContactDescription", nil);
	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
	self.descriptionLabel.numberOfLines = 0;
	self.descriptionLabel.minimumScaleFactor = 0.1;
	[self.view addSubview:self.descriptionLabel];
	
	[self.view beginAddingNewPortraitConstraints];
	[self.descriptionLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.descriptionLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(9.0/10.0)];
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel withOffset:scaleFactorToUse*0.05];
	
	[self.view beginAddingNewLandscapeConstraints];
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel];
	[self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.thankYouLabel];
	[self.descriptionLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.thankYouLabel];
	[self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:20];
	
	[self.view endAddingNewConstraints];
	
	
	NSMutableArray *contactButtonsArray = [NSMutableArray new];
	
	NSArray *contactButtonStrings = @[
									  @"ContactEmail", @"ContactTwitter", @"ContactWebsite"
									  ];
	LMIcon contactButtonIcons[] = {
		LMIconPaperPlane, LMIconTwitter, LMIconLink
	};
	
	
	for(int i = 0; i < contactButtonStrings.count; i++){
		LMView *viewToPinTo = (i == 0) ? self.descriptionLabel : [contactButtonsArray objectAtIndex:i-1];
		
		NSString *buttonString = NSLocalizedString([contactButtonStrings objectAtIndex:i], nil);
		UIImage *contactButtonIcon = [LMAppIcon imageForIcon:contactButtonIcons[i]];
		
		
		LMView *contactButton = [LMView newAutoLayoutView];
		contactButton.backgroundColor = [UIColor darkGrayColor];
		contactButton.layer.cornerRadius = scaleFactorToUse/50;
		contactButton.layer.masksToBounds = YES;
		
		[self.view addSubview:contactButton];
		
		[self.view beginAddingNewPortraitConstraints];
		[contactButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[contactButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.9];
		[contactButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/10.0)];
		[contactButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:viewToPinTo withOffset:WINDOW_FRAME.size.height*((i == 0) ? 0.05 : 0.025)];
		
		[self.view beginAddingNewLandscapeConstraints];
		[contactButton autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.descriptionLabel withOffset:20];
		[contactButton autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.view withOffset:-20];
		[contactButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/10.0)];
		[contactButton autoPinEdge:ALEdgeBottom toEdge:((i == 0) ? ALEdgeBottom : ALEdgeTop) ofView:((i == 0) ? self.view : viewToPinTo) withOffset:(i == 0) ? -74 : -10];
		
		[self.view endAddingNewConstraints];
		
		UITapGestureRecognizer *tapGesture;
		
		switch(i){
			case 0: //Email
				tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sendEmail)];
				break;
			case 1: //Twitter
				tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openTwitter)];
				break;
			case 2: //Website
				tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(openWebsite)];
				break;
		}
		
		[contactButton addGestureRecognizer:tapGesture];
		
		
		LMView *contactDetailsView = [LMView newAutoLayoutView];
		//			contactDetailsView.backgroundColor = [UIColor orangeColor];
		[contactButton addSubview:contactDetailsView];
		
		[contactDetailsView autoCenterInSuperview];
		[contactDetailsView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:contactButton withMultiplier:(3.0/4.0)];
		[contactDetailsView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:contactButton];
		
		
		UIImageView *contactIconView = [UIImageView newAutoLayoutView];
		contactIconView.image = contactButtonIcon;
		contactIconView.contentMode = UIViewContentModeScaleAspectFit;
		//			contactIconView.backgroundColor = [UIColor greenColor];
		[contactDetailsView addSubview:contactIconView];
		
		[contactIconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
		[contactIconView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		[contactIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:contactDetailsView withMultiplier:(1.25/3.0)];
		[contactIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:contactDetailsView withMultiplier:(1.25/3.0)];
		
		[contactButtonsArray addObject:contactButton];
		
		
		UILabel *contactStringLabel = [UILabel newAutoLayoutView];
		contactStringLabel.textColor = [UIColor whiteColor];
		contactStringLabel.text = buttonString;
		contactStringLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(scaleFactorToUse/414.0)*22.0f];
//		contactStringLabel.adjustsFontSizeToFitWidth = YES;
		contactStringLabel.textAlignment = NSTextAlignmentLeft;
//		contactStringLabel.numberOfLines = 1;
//		contactStringLabel.minimumScaleFactor = 0.01;
		[contactDetailsView addSubview:contactStringLabel];
		
//		[contactDetailsView beginAddingNewPortraitConstraints];
		[contactStringLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:contactIconView withOffset:scaleFactorToUse*0.05];
		[contactStringLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:contactButton withOffset:-10];
		[contactStringLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	
//		[contactDetailsView beginAddingNewLandscapeConstraints];
//		[contactStringLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:contactIconView withOffset:30];
//		[contactStringLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:contactButton withOffset:-30];
//		[contactStringLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
		
		[contactDetailsView endAddingNewConstraints];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [LMView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
