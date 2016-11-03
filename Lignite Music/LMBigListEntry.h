//
//  LMBigListEntry.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/1/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMCollectionInfoView.h"
#import "LMControlBarView.h"

@class LMBigListEntry;

@protocol LMBigListEntryDelegate <NSObject>

/**
 Get the content subview for the big list entry, which is the main "image type" view which goes above the info view. Automatically has shadow applied behind it.

 @param bigListEntry The big list entry which requires the content view.
 @return The content view.
 */
- (id)contentSubviewForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 Get the content subview's height factorial (percentage) for the big list entry.

 @param bigListEntry The big list entry.
 @return The content factorial.
 */
- (float)contentSubviewHeightFactorialForBigListEntry:(LMBigListEntry*)bigListEntry;

/**
 Is called when the size to the big list entry changes. This should only happen when the UIControlBarView changes its size in portrait.

 @param newSize The new size.
 @param bigListEntry The big list entry.
 */
- (void)sizeChangedTo:(CGSize)newSize forBigListEntry:(LMBigListEntry*)bigListEntry;

@end

@interface LMBigListEntry : UIView

@property id<LMBigListEntryDelegate> entryDelegate;
@property id<LMCollectionInfoViewDelegate> infoDelegate;

- (void)setup;

@end
