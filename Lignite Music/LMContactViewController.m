//
//  LMContactViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMContactViewController.h"
#import "LMScrollView.h"
#import "LMAppIcon.h"
#import "LMExtras.h"

@interface LMContactViewController ()

@property UILabel *thankYouLabel;

@property UILabel *descriptionLabel;

@end

@implementation LMContactViewController

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
	return NO;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.thankYouLabel = [UILabel newAutoLayoutView];
	self.thankYouLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width/414.0)*50.0f];
	self.thankYouLabel.text = NSLocalizedString(@"ContactHi", nil);
	self.thankYouLabel.textAlignment = NSTextAlignmentLeft;
	[self.view addSubview:self.thankYouLabel];
	
	[self.thankYouLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.thankYouLabel autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width*0.9];
	[self.thankYouLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:84];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width/414.0)*18.0f];
	self.descriptionLabel.text = NSLocalizedString(@"ContactDescription", nil);
	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
	self.descriptionLabel.numberOfLines = 0;
	[self.view addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.descriptionLabel autoSetDimension:ALDimensionWidth toSize:WINDOW_FRAME.size.width*0.9];
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.thankYouLabel withOffset:WINDOW_FRAME.size.width*0.05];
	
	NSMutableArray *contactButtonsArray = [NSMutableArray new];
	
	NSArray *contactButtonStrings = @[
									  @"ContactEmail", @"ContactTwitter", @"ContactWebsite"
									  ];
	LMIcon contactButtonIcons[] = {
		LMIconPaperPlane, LMIconTwitter, LMIconLink
	};
	
	
	for(int i = 0; i < contactButtonStrings.count; i++){
		UIView *viewToPinTo = (i == 0) ? self.descriptionLabel : [contactButtonsArray objectAtIndex:i-1];
		
		NSString *buttonString = NSLocalizedString([contactButtonStrings objectAtIndex:i], nil);
		UIImage *contactButtonIcon = [LMAppIcon imageForIcon:contactButtonIcons[i]];
		
		
		UIView *contactButton = [UIView newAutoLayoutView];
		contactButton.backgroundColor = [UIColor darkGrayColor];
		contactButton.layer.cornerRadius = WINDOW_FRAME.size.width/50;
		contactButton.layer.masksToBounds = YES;
		
		[self.view addSubview:contactButton];
		
		[contactButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[contactButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:0.9];
		[contactButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/10.0)];
		[contactButton autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:viewToPinTo withOffset:WINDOW_FRAME.size.height*((i == 0) ? 0.05 : 0.025)];
		
		
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
		
		
		UIView *contactDetailsView = [UIView newAutoLayoutView];
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
		contactStringLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:(WINDOW_FRAME.size.width/414.0)*22.0f];
		[contactDetailsView addSubview:contactStringLabel];
		
		[contactStringLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:contactIconView withOffset:WINDOW_FRAME.size.width*0.05];
		[contactStringLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	}
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
