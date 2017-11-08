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

@interface InterfaceController ()<LMWProgressSliderDelegate, WCSessionDelegate>

/**
 The info object for the progress slider.
 */
@property LMWProgressSliderInfo *progressSliderInfo;

@end


@implementation InterfaceController

- (void)session:(WCSession *)session activationDidCompleteWithState:(WCSessionActivationState)activationState error:(nullable NSError *)error {

	[self.titleLabel setText:[NSString stringWithFormat:@"%d", activationState]];
	[self.subtitleLabel setText:error.description];
}

- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message {
	[self.titleLabel setText:[message objectForKey:@"title"]];
}

/** Called on the delegate of the receiver when the sender sends a message that expects a reply. Will be called on startup if the incoming message caused the receiver to launch. */
- (void)session:(WCSession *)session didReceiveMessage:(NSDictionary<NSString *, id> *)message replyHandler:(void(^)(NSDictionary<NSString *, id> *replyMessage))replyHandler {
	
	[self.titleLabel setText:[message objectForKey:@"title"]];
	
	replyHandler(@{ @"whats":@"up" });
}

- (void)session:(WCSession *)session didReceiveMessageData:(NSData *)messageData {
	NSDictionary *myDictionary = (NSDictionary*)[NSKeyedUnarchiver unarchiveObjectWithData:messageData];
	[self.titleLabel setText:[myDictionary objectForKey:@"title"]];
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
	
	if ([WCSession isSupported]) {
		WCSession* session = [WCSession defaultSession];
		session.delegate = self;
		[session activateSession];
	}
	
	self.progressSliderInfo = [[LMWProgressSliderInfo alloc] initWithProgressBarGroup:self.progressBarGroup
																		  inContainer:self.progressBarContainer
																onInterfaceController:self];
	self.progressSliderInfo.delegate = self;
}

- (void)willActivate {
    [super willActivate];
}

- (void)didDeactivate {
    [super didDeactivate];
}

@end



