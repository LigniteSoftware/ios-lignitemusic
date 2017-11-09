//
//  InterfaceController.h
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <WatchKit/WatchKit.h>
#import <Foundation/Foundation.h>

@interface InterfaceController : WKInterfaceController

/**
 The title label.
 */
@property IBOutlet WKInterfaceLabel *titleLabel;

/**
 The subtitle label.
 */
@property IBOutlet WKInterfaceLabel *subtitleLabel;

/**
 The album art image.
 */
@property IBOutlet WKInterfaceImage *albumArtImage;

/**
 The image for the favourites heart.
 */
@property IBOutlet WKInterfaceImage *favouriteImage;

/**
 The group of the actual progress bar which is coloured red and contains the white grabber. Linked through an IBOutlet to provide to our LMWProgressSliderInfo instance, so it can handle the sizing to display progress.
 */
@property IBOutlet WKInterfaceGroup *progressBarGroup;

/**
 The container for the progress bar, which is also passed to the instance of LMWProgressSliderInfo to allow for resizing of the height of the progress bar. Shaded gray in the interface builder.
 */
@property IBOutlet WKInterfaceGroup *progressBarContainer;

/**
 The pan gesture changed for the progress bar. Should be passed right away to the LMWProgressSliderInfo instance.

 @param panGestureRecognizer The pan gesture object.
 */
- (IBAction)progressPanGesture:(WKPanGestureRecognizer*)panGestureRecognizer;

/**
 Writes a string to the title label.

 @param debugMessage The debug message to write.
 */
- (void)debug:(NSString*)debugMessage;

@end
