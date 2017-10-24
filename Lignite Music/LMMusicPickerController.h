//
//  LMMusicPickerController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@protocol LMMusicPickerDelegate

//Protocol specs here

@end

@interface LMMusicPickerController : UIViewController

/**
 The collection of tracks currently chosen by the user. To prepopulate the picker with already selected tracks, set this before load.
 */
@property LMMusicTrackCollection *trackCollection;

@end
