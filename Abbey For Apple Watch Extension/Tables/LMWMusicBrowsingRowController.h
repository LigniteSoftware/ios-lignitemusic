//
//  LMWMusicBrowsingRowController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>
#import "LMWMusicTrackInfo.h"

@interface LMWMusicBrowsingRowController : NSObject

/**
 The title of the music track or entry in the music browsing list.
 */
@property IBOutlet WKInterfaceLabel *titleLabel;

/**
 The title of the music track or entry in the music browsing list.
 */
@property IBOutlet WKInterfaceLabel *subtitleLabel;

/**
 The icon of the music track or entry in the music browsing list.
 */
@property IBOutlet WKInterfaceImage *icon;

/**
 The track or entry info associated with this row.
 */
@property LMWMusicTrackInfo *associatedInfo;

/**
 Whether or not this row is for viewing next tracks.
 */
@property BOOL isNextButton;

/**
 Whether or not this row is for viewing previous tracks.
 */
@property BOOL isPreviousButton;

/**
 Whether or not this row is the button that'll let the user shuffle all the tracks in the list.
 */
@property BOOL isShuffleAllButton;

@end
