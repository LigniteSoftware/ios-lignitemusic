//
//  LMLagDetectionThread.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/20/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMLagDetectionThread.h"
#import "NSTimer+Blocks.h"

@interface LMLagDetectionThread()

/**
 Whether or not the ping task is currently running.
 */
@property BOOL pingTaskIsRunning;

/**
 The dispatch semaphore (whatever that is, lol.)
 */
@property dispatch_semaphore_t semaphore;

/**
 The label for the lag warning.
 */
@property UILabel *lagWarningLabel;

/**
 How much lag has occurred for the certain interval.
 */
@property NSTimeInterval intervalOfLag;

/**
 The timer which hides the lag label after a second of being displayed.
 */
@property NSTimer *hideLabelTimer;

@end

@implementation LMLagDetectionThread

- (instancetype)init {
	self = [super init];
	if(self){
		self.pingTaskIsRunning = NO;
		self.semaphore = dispatch_semaphore_create(0);
		
		self.lagWarningLabel = [UILabel new];
		self.lagWarningLabel.backgroundColor = [UIColor redColor];
		self.lagWarningLabel.textColor = [UIColor whiteColor];
		self.lagWarningLabel.text = @"🤙 n i c e  m e m e 🤙";
		self.lagWarningLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:30.0f];
		self.lagWarningLabel.userInteractionEnabled = NO;
		self.lagWarningLabel.textAlignment = NSTextAlignmentCenter;
		
		self.lagDelayInSeconds = 0.4;
		self.enabled = YES;
	}
	return self;
}

- (void)main {
	while(!self.cancelled){
		self.pingTaskIsRunning = YES;
		dispatch_async(dispatch_get_main_queue(), ^{
			self.pingTaskIsRunning = NO;
			dispatch_semaphore_signal(self.semaphore);
		});
		[NSThread sleepForTimeInterval:self.lagDelayInSeconds];
		if(self.pingTaskIsRunning && self.enabled){ //Lag detected, and the thread is enabled to display alerts.
			dispatch_async(dispatch_get_main_queue(), ^{
				if(![self.viewToDisplayAlertsOn.subviews containsObject:self.lagWarningLabel]){
					[self.viewToDisplayAlertsOn addSubview:self.lagWarningLabel];
					
					CGRect lagWarningLabelFrame = CGRectMake(0, 0, 0, 0);
					lagWarningLabelFrame.size.width = self.viewToDisplayAlertsOn.frame.size.width/1.5;
					lagWarningLabelFrame.origin.x = (self.viewToDisplayAlertsOn.frame.size.width/2.0) - (lagWarningLabelFrame.size.width/2.0);
					lagWarningLabelFrame.size.height = 40.0f;
					lagWarningLabelFrame.origin.y = (self.viewToDisplayAlertsOn.frame.size.height/2.0) - (lagWarningLabelFrame.size.height/2.0);
					
					self.lagWarningLabel.frame = lagWarningLabelFrame;
				}
				
				self.intervalOfLag += self.lagDelayInSeconds;
				
				if(self.intervalOfLag > 0.15){
					self.lagWarningLabel.hidden = NO;
					self.lagWarningLabel.text = [NSString stringWithFormat:@"Lagged for %.02fs", self.intervalOfLag];
				}
					
				[self.hideLabelTimer invalidate];
				
				self.hideLabelTimer = [NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
					self.lagWarningLabel.hidden = YES;
					self.intervalOfLag = 0.0;
				} repeats:NO];
			});
		}
		dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	}
}

@end
