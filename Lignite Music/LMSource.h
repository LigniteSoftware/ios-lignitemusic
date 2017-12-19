//
//  LMSource.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>
#import "LMAppIcon.h"

@class LMSource;

@protocol LMSourceDelegate <NSObject>

/**
 A source was selected.

 @param source The source that was selected.
 */
- (void)sourceSelected:(LMSource*)source;

@end

@interface LMSource : NSObject

/**
 Creates an LMSource object with the specificed title, subtitle, and icon. Subtitle and icon may be nil.

 @param title    The title of the source, ie. "Titles"
 @param subtitle The subtitle of the source, ie. "Only for Pebble"
 @param icon     The LMIcon identifier of the icon associated with this source.

 @return The created source.
 */
+ (LMSource*)sourceWithTitle:(NSString*)title
				 andSubtitle:(NSString*)subtitle
					 andIcon:(LMIcon)icon;

/**
 The title of the source.
 */
@property NSString *title;

/**
 The subtitle of the source.
 */
@property NSString *subtitle;

/**
 The icon of the source.
 */
@property UIImage *icon;

/**
 The Lignite icon.
 */
@property LMIcon lmIcon;

/**
 The source's ID.
 */
@property uint8_t sourceID;

/**
 The delegate which should be called upon when this source is acted upon.
 */
@property id<LMSourceDelegate> delegate;

/**
 Whether or not this source is highlightable. If YES, the source will not be highlighted and will not be saved to defaults for the next user's load of the app. Default: NO
 */
@property BOOL shouldNotHighlight;

@end
