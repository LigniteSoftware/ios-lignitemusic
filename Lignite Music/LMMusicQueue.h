//
//  LMMusicQueue.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>

@protocol LMMusicQueueDelegate <NSObject>



@end

@interface LMMusicQueue : NSObject

- (void)rebuildQueue;

/**
 The shared music queue.

 @return The music queue that is shared across the app.
 */
+ (LMMusicQueue*)sharedMusicQueue;

@end
