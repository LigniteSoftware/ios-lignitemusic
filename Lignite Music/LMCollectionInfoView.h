//
//  LMCollectionInfoView.h
//  Lignite Music
//
//  Created by Edwin Finch on 11/2/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@class LMCollectionInfoView;
@class LMBigListEntry;

@protocol LMCollectionInfoViewDelegate <NSObject>

/**
 Gets the title for the info view. Must not be nil. Centered at the top of the info view.

 @param infoView The info view.
 @return The title.
 */
- (NSString*)titleForInfoView:(LMCollectionInfoView*)infoView;

/**
 Gets the text which will align left to this info view. Must not be nil. If image and right text to not exist, this will center itself.

 @param infoView The info view.
 @return The left aligned text.
 */
- (NSString*)leftTextForInfoView:(LMCollectionInfoView*)infoView;

/**
 Gets the text which will align right to this info view. If nil, middle image and this text will not be displayed.

 @param infoView The info view.
 @return The right aligned text.
 */
- (NSString*)rightTextForInfoView:(LMCollectionInfoView*)infoView;

/**
 The centre image for the info view. The text aligns to each side of this. If nil, and right text exists, a line will be drawn with a UILabel.

 @param infoView The info view.
 @return The image which to put in.
 */
- (UIImage*)centreImageForInfoView:(LMCollectionInfoView*)infoView;

@end

@interface LMCollectionInfoView : UIView

/**
 The delegate for loading data.
 */
@property id<LMCollectionInfoViewDelegate> delegate;

/**
 The big list entry associated with this collection info view.
 */
@property LMBigListEntry *associatedBigListEntry;

/**
 Whether or not to keep it in large mode. If YES, it will increase the size of the title over the contents below title. Default is YES.
 */
@property BOOL largeMode;

/**
 The text alignment to use.
 */
@property NSTextAlignment textAlignment;

/**
 Setup all of the views with the current collection as provided by the delegate.
 */
- (void)reloadData;

@end
