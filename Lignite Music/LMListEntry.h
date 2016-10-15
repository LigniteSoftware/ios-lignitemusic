//
//  LMListEntry.h
//  Lignite Music
//
//  Created by Edwin Finch on 9/29/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>

@class LMListEntry;

@protocol LMListEntryDelegate <NSObject>

- (void)tappedListEntry:(LMListEntry*)entry;
- (UIColor*)tapColourForListEntry:(LMListEntry*)entry;
- (NSString*)titleForListEntry:(LMListEntry*)entry;
- (NSString*)subtitleForListEntry:(LMListEntry*)entry;
- (UIImage*)iconForListEntry:(LMListEntry*)entry;

@end

@interface LMListEntry : UIView

- (void)reloadContents;

- (void)changeHighlightStatus:(BOOL)highlighted animated:(BOOL)animated;

- (void)setup;

- (id)initWithDelegate:(id)delegate;

/**
 The multiplier of how much to inset the icon within its background view. For example, 0.5 would inset the icon half way into the background view, centered.
 */
@property float iconInsetMultiplier;

/**
 The index of this LMListEntry in the collection its associated with.
 */
@property NSInteger collectionIndex;

/**
 Optional. Associated data with this LMListEntry.
 */
@property id associatedData;

@end
