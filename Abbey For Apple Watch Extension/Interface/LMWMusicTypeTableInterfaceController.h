//
//  LMWMusicTypeTableInterfaceController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>

@interface LMWMusicTypeTableInterfaceController : WKInterfaceController

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
 The music types table.
 */
@property IBOutlet WKInterfaceTable *musicTypesTable;

@end
