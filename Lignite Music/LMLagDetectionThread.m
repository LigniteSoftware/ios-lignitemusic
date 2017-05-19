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
		self.lagWarningLabel.text = @"Lag bitch";
		self.lagWarningLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:18.0f];
		self.lagWarningLabel.userInteractionEnabled = NO;
		self.lagWarningLabel.textAlignment = NSTextAlignmentCenter;
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
		[NSThread sleepForTimeInterval:0.4];
		if(self.pingTaskIsRunning){
			NSLog(@"Lag!!!");

			dispatch_async(dispatch_get_main_queue(), ^{
				if(![self.viewToDisplayAlertsOn.subviews containsObject:self.lagWarningLabel]){
					[self.viewToDisplayAlertsOn addSubview:self.lagWarningLabel];
					
					CGRect lagWarningLabelFrame = CGRectMake(0, 0, 0, 0);
					lagWarningLabelFrame.size.width = self.viewToDisplayAlertsOn.frame.size.width/3.0;
					lagWarningLabelFrame.origin.x = (self.viewToDisplayAlertsOn.frame.size.width/2.0) - (lagWarningLabelFrame.size.width/2.0);
					lagWarningLabelFrame.size.height = 24.0f;
					lagWarningLabelFrame.origin.y = (self.viewToDisplayAlertsOn.frame.size.height/2.0) - (lagWarningLabelFrame.size.height/2.0);
					
					self.lagWarningLabel.frame = lagWarningLabelFrame;
				}
				
				self.lagWarningLabel.hidden = NO;
				[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
					self.lagWarningLabel.hidden = YES;
				} repeats:NO];
			});
		}
		dispatch_semaphore_wait(self.semaphore, DISPATCH_TIME_FOREVER);
	}
}

@end
