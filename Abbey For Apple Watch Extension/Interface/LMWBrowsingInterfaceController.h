//
//  LMWBrowsingInterfaceController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 12/5/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface LMWBrowsingInterfaceController : WKInterfaceController

/**
 The group for loading image and label.
 */
@property IBOutlet WKInterfaceGroup *loadingGroup;

/**
 The loading image.
 */
@property IBOutlet WKInterfaceImage *loadingImage;

/**
 The label for loading.
 */
@property IBOutlet WKInterfaceLabel *loadingLabel;

/**
 The table for browsing music.
 */
@property IBOutlet WKInterfaceTable *browsingTable;

@end
