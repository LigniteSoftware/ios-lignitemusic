//
//  LMQueueViewFlowLayout.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-12.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMQueueViewFlowLayout : UICollectionViewFlowLayout

/**
 When the user finishes interactively reordering the tracks, please call this.
 */
- (void)finishedInteractivelyMoving;

@end
