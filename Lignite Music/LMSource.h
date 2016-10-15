//
//  LMSource.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@class LMSource;

@protocol LMSourceDelegate <NSObject>

- (void)sourceSelected:(LMSource*)source;

@end

@interface LMSource : NSObject

/**
 Creates an LMSource based on a title, icon name (filename) and selector to be called back to.

 @param title    The title of the source, ie. "Albums".
 @param iconName The file name of the icon applied to this source, ie. "albums_icon.png"
 @param selector The selector that should be called when this source is selected.

 @return The created LMSource.
 */
+ (LMSource*)sourceWithTitle:(NSString*)title
				 andSubtitle:(NSString*)subtitle
				andIconNamed:(NSString*)iconName;

@property NSString *title;
@property NSString *subtitle;
@property NSString *iconName;
@property UIImage *icon;
@property id<LMSourceDelegate> delegate;

@end
