//
//  LMQueueViewSeparatorLayoutAttributes.h
//  Lignite Music
//
//  Created by Edwin Finch on 2018-06-13.
//  Copyright © 2018 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface LMQueueViewSeparatorLayoutAttributes : UICollectionViewLayoutAttributes

/**
 The additional offset if this separator is for the very first row.
 */
@property CGFloat additionalOffset;

/**
 Whether or not this separator is the only item in the section.
 */
@property BOOL isOnlyItem;

/**
 Whether or not this separator is the last row in the section.
 */
@property BOOL isLastRow;

@end
