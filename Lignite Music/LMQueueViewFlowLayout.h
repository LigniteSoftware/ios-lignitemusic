//
//  LMQueueViewFlowLayout.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-12.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

#define QUEUE_NEAR_HEADER_ENTRY_SPACING 10.0f

@interface LMQueueViewFlowLayout : UICollectionViewFlowLayout

/**
 The changes that have been made to sections during interactive reordering.
 */
@property NSArray<NSNumber*> *sectionDifferences;

/**
 When the user finishes interactively reordering the tracks, please call this.
 */
- (void)finishedInteractivelyMoving;

@end
