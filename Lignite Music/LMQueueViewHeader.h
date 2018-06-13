//
//  LMQueueViewHeader.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-05-26.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMView.h"

@class LMQueueViewHeader;

@protocol LMQueueViewHeaderDelegate <NSObject>
@required

- (UIImage*)iconForHeader:(LMQueueViewHeader*)header;
- (NSString*)titleForHeader:(LMQueueViewHeader*)header;
- (NSString*)subtitleForHeader:(LMQueueViewHeader*)header;

@end

@interface LMQueueViewHeader : UICollectionReusableView

/**
 The delegate for this header.
 */
@property id<LMQueueViewHeaderDelegate> delegate;

/**
 Whether or not this header is for previous tracks.
 */
@property BOOL isForPreviousTracks;

/**
 Whether or not to display white text. NO for black text.
 */
@property BOOL whiteText;
@property BOOL previouslyUsingWhiteText; //For temporary state storage between animations

/**
 Reloads the queue view header with its new contents.
 */
- (void)reload;

@end
