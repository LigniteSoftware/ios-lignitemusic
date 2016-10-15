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

@property NSString *title;
@property NSString *subtitle;
@property NSString *iconName;
@property UIImage *icon;
@property id<LMSourceDelegate> delegate;

@end
