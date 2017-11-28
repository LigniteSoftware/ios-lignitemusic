//
//  LMWMusicTypeRowController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <WatchKit/WatchKit.h>

@interface LMWMusicTypeRowController : NSObject

/**
 The title of the music type.
 */
@property IBOutlet WKInterfaceLabel *titleLabel;

/**
 The icon of the music type.
 */
@property IBOutlet WKInterfaceImage *icon;

/**
 The dictionary of info on the music type.
 */
@property NSDictionary *musicTypeDictionary;

@end
