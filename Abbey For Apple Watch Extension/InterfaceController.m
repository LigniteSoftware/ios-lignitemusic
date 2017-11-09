//
//  InterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchConnectivity/WatchConnectivity.h>
#import "InterfaceController.h"
#import "LMWProgressSliderInfo.h"
#import "LMWCompanionBridge.h"

@interface InterfaceController ()<LMWProgressSliderDelegate, LMWCompanionBridgeDelegate>

/**
 The info object for the progress slider.
 */
@property LMWProgressSliderInfo *progressSliderInfo;

/**
 The bridge for the companion.
 */
@property LMWCompanionBridge *companionBridge;

@end


@implementation InterfaceController


- (void)debug:(NSString*)debugMessage {
	[self.titleLabel setText:debugMessage];
}

- (void)companionDebug:(NSString *)debug {
	[self debug:debug];
}


- (void)musicTrackDidChange:(LMWMusicTrackInfo *)musicTrackInfo {
	[self.titleLabel setText:musicTrackInfo.title];
	[self.subtitleLabel setText:musicTrackInfo.subtitle];
	[self.albumArtImage setImage:musicTrackInfo.albumArt];
	[self.favouriteImage setImage:musicTrackInfo.isFavourite ? [UIImage imageNamed:@"icon_favourite_red.png"] : [UIImage imageNamed:@"icon_favourite_outlined_white.png"]];
}

- (void)albumArtDidChange:(UIImage*)albumArt {
	[self.albumArtImage setImage:albumArt];
}


- (void)progressSliderWithInfo:(LMWProgressSliderInfo *)progressSliderInfo slidToNewPositionWithPercentage:(CGFloat)percentage {
	[self.titleLabel setText:[NSString stringWithFormat:@"%.02f", percentage]];
}

- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer {
	[self.progressSliderInfo handleProgressPanGesture:panGestureRecognizer];
}



- (void)awakeWithContext:(id)context {
    [super awakeWithContext:context];
	[self setTitle:@"Abbey"];
	
	self.progressSliderInfo = [[LMWProgressSliderInfo alloc] initWithProgressBarGroup:self.progressBarGroup
																		  inContainer:self.progressBarContainer
																onInterfaceController:self];
	self.progressSliderInfo.delegate = self;
	
	
	self.companionBridge = [LMWCompanionBridge sharedCompanionBridge];
	[self.companionBridge addDelegate:self];
}

- (void)willActivate {
    [super willActivate];
	
	[self.titleLabel setText:@"Will activate"];
	
	[NSTimer scheduledTimerWithTimeInterval:1.0 repeats:NO block:^(NSTimer * _Nonnull timer) {
		[self.companionBridge askCompanionForNowPlayingTrackInfo];
		[self debug:@"asking"];
	}];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end



