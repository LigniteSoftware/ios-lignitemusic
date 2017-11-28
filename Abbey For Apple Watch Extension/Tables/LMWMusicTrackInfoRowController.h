//
//  LWMMusicTrackInfoRowController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/9/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface LMWMusicTrackInfoRowController : NSObject

/**
 The title of the track info row.
 */
@property IBOutlet WKInterfaceLabel *titleLabel;

/**
 The subtitle of the track info row.
 */
@property IBOutlet WKInterfaceLabel *subtitleLabel;

/**
 The number of the track info row.
 */
@property IBOutlet WKInterfaceLabel *number;

@end
