//
//  LMImageManager.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <PureLayout/PureLayout.h>
#import "LMImageManager.h"
#import "LMColour.h"

@interface LMImageManager()

@end

@implementation LMImageManager

+ (LMImageManager*)sharedImageManager {
	static LMImageManager *sharedImageManager;
	static dispatch_once_t token;
	dispatch_once(&token, ^{
		sharedImageManager = [self new];
	});
	return sharedImageManager;
}

/**
 Gets the key associated for an image permission. Should be used for NSUserDefaults and SDWebImage disk cache namespace.

 @param category The permission to get the key for.
 @return The category's key.
 */
+ (NSString*)keyForPermission:(LMImageManagerCategory)category {
	switch(category){
		case LMImageManagerCategoryAlbumImages:
			return @"LMImageManagerPermissionAlbumImages";
		case LMImageManagerCategoryArtistImages:
			return @"LMImageManagerPermissionAlbumImages";
	}
}

- (LMImageManagerPermissionStatus)permissionStatusForCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *categoryKey = [LMImageManager keyForPermission:category];
	
	LMImageManagerPermissionStatus permissionStatus = LMImageManagerPermissionStatusNotDetermined;
	
	if([userDefaults objectForKey:categoryKey]){
		permissionStatus = (LMImageManagerPermissionStatus)[userDefaults integerForKey:categoryKey];
	}
	
	return permissionStatus;
}

- (void)setPermissionStatus:(LMImageManagerPermissionStatus)status forCategory:(LMImageManagerCategory)category {
	NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
	NSString *permissionStatusKey = [LMImageManager keyForPermission:category];
	
	[userDefaults setInteger:(NSInteger)category forKey:permissionStatusKey];
	[userDefaults synchronize];
}

- (void)launchPermissionRequestOnView:(UIView*)view forCategory:(LMImageManagerCategory)category withCompletionHandler:(void(^)(LMImageManagerPermissionStatus permissionStatus))completionHandler {
	
	UIView *backgroundView = [UIView newAutoLayoutView];
	backgroundView.backgroundColor = [UIColor redColor];
	[view addSubview:backgroundView];
	
	[backgroundView autoPinEdgesToSuperviewEdges];
	
	UIView *paddingView = [UIView newAutoLayoutView];
	paddingView.backgroundColor = [UIColor orangeColor];
	[backgroundView addSubview:paddingView];
	
	[paddingView autoCenterInSuperview];
	[paddingView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:backgroundView withMultiplier:(9.0/10.0)];
	[paddingView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:backgroundView withMultiplier:(9.0/10.0)];
	
	UILabel *titleLabel = [UILabel newAutoLayoutView];
	titleLabel.backgroundColor = [UIColor yellowColor];
	titleLabel.numberOfLines = 0;
	titleLabel.textAlignment = NSTextAlignmentCenter;
	titleLabel.text = @"Title";
	titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:40.0f];
	[paddingView addSubview:titleLabel];
	
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	UILabel *contentsLabel = [UILabel newAutoLayoutView];
	contentsLabel.backgroundColor = [UIColor cyanColor];
	contentsLabel.numberOfLines = 0;
	contentsLabel.textAlignment = NSTextAlignmentLeft;
	contentsLabel.text = @"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Morbi non ex id mauris congue euismod ut id augue. Aenean nec pulvinar tortor. Nam pretium interdum est, vel consequat ante efficitur sed.\n\nPraesent pretium pharetra feugiat. Class aptent taciti sociosqu ad litora torquent per conubia nostra, per inceptos himenaeos.\n\nProin elementum aliquet mi vitae eleifend. In ornare commodo mauris sit amet imperdiet. Nullam ex magna, volutpat id tellus tristique, interdum eleifend massa.";
	contentsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
	[paddingView addSubview:contentsLabel];
	
	[contentsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:titleLabel withOffset:20];
	[contentsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[contentsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	
	UIButton *denyButton = [UIButton newAutoLayoutView];
	denyButton.backgroundColor = [LMColour darkLigniteRedColour];
	denyButton.layer.cornerRadius = 8.0f;
	denyButton.layer.masksToBounds = YES;
	[denyButton setTitle:@"Deny" forState:UIControlStateNormal];
	[denyButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:24.0f]];
	[paddingView addSubview:denyButton];
	
	[denyButton autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[denyButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[denyButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[denyButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:view withMultiplier:(0.5/8.0)];
	
	UIButton *acceptButton = [UIButton newAutoLayoutView];
	acceptButton.backgroundColor = [LMColour ligniteRedColour];
	acceptButton.layer.cornerRadius = 8.0f;
	acceptButton.layer.masksToBounds = YES;
	[acceptButton setTitle:@"Accept" forState:UIControlStateNormal];
	[acceptButton.titleLabel setFont:[UIFont fontWithName:@"HelveticaNeue" size:24.0f]];
	[paddingView addSubview:acceptButton];
	
	[acceptButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:denyButton withOffset:-10.0f];
	[acceptButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[acceptButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[acceptButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:view withMultiplier:(1.0/8.0)];
}

@end
