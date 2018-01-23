//
//  LMApplication.m
//  Lignite Music
//
//  Created by Edwin Finch on 1/5/18.
//  Copyright © 2018 Lignite. All rights reserved.
//

#define MAX_IDLE_TIME 35.0f

#import "LMApplication.h"

@interface LMApplication()

/**
 The timer for detecting lack of user activity.
 */
@property NSTimer *idleTimer;

/**
 The delegates for receiving idle notifications.
 */
@property NSMutableArray *delegates;

@end

@implementation LMApplication

- (void)addDelegate:(id<LMApplicationIdleDelegate>)delegate {
	if(!self.delegates){
		self.delegates = [NSMutableArray new];
	}
	
	[self.delegates addObject:delegate];
}

- (void)removeDelegate:(id<LMApplicationIdleDelegate>)delegate {
	[self.delegates removeObject:delegate];
}

- (void)sendEvent:(UIEvent *)event {
	[super sendEvent:event];

	NSSet *allTouches = [event allTouches];
	if ([allTouches count] > 0) {
		UITouchPhase phase = ((UITouch *)[allTouches anyObject]).phase;
		if (phase == UITouchPhaseBegan || phase == UITouchPhaseEnded){
			[self resetIdleTimer];
		}
	}
}

- (void)resetIdleTimer {
	if (self.idleTimer) {
		[self.idleTimer invalidate];
	}
	
	self.idleTimer = [NSTimer scheduledTimerWithTimeInterval:MAX_IDLE_TIME
													  target:self
													selector:@selector(idleTimerExceeded)
													userInfo:nil
													 repeats:NO];
}

- (void)idleTimerExceeded {
	for(id<LMApplicationIdleDelegate> delegate in self.delegates){
		[delegate userInteractionBecameIdle];
	}
}

@end
