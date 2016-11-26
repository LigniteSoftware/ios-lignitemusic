#import <PebbleKit/PebbleKit.h>
#import "LMPebbleMessageQueue.h"

@interface LMPebbleMessageQueue () {
    NSInteger failureCount;
}
- (void)sendRequest;
@end

@implementation LMPebbleMessageQueue

- (id)init
{
    self = [super init];
    if (self) {
        has_active_request = NO;
        queue = [[NSMutableArray alloc] init];
    }
    return self;
}

- (void)enqueue:(NSDictionary *)message {
    if(!self.watch) {
        //NSLog(@"No watch; discarding message.");
        return;
    }
    if(!message) return;
    @synchronized(queue) {
        NSLog(@"Enqueued message: %@", message);
        [queue addObject:message];
        [self sendRequest];
    }
}

- (void)sendRequest {
    @synchronized(queue) {
        if(has_active_request) {
            //NSLog(@"Request in flight, stalling.");
            return;
        }
        if([queue count] == 0) {
            //NSLog(@"Nothing in queue.");
            return;
        }
        if(![self.watch isConnected]) {
            NSLog(@"Watch isn't connected.");
            has_active_request = false;
            return;
        }
        //NSLog(@"Sending message.");
        has_active_request = YES;
        NSDictionary* message = [queue objectAtIndex:0];
        [self.watch appMessagesPushUpdate:message onSent:^(PBWatch *watch, NSDictionary *update, NSError *error) {
            if(!error) {
                [queue removeObjectAtIndex:0];
                failureCount = 0;
                //NSLog(@"Successfully pushed: %@", message);
            } else {
                NSLog(@"Send failed; will retransmit.");
                NSLog(@"Error: %@", error);
                sleep(1);
                if(++failureCount > 3) {
                    [queue removeAllObjects];
                    NSLog(@"Aborting.");
                }
            }
            has_active_request = NO;
            //NSLog(@"Next message.");
            [self sendRequest];
        }];
    }
}

@end
