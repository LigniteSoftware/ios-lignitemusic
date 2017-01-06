//
//  LMIcon.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <Foundation/Foundation.h>

@interface LMAppIcon : NSObject

typedef enum {
	LMIconPlay = 0,
	LMIconPause,
	LMIconRepeat,
	LMIconRepeatOne,
	LMIconShuffle,
	LMIconTripleHorizontalDots,
	LMIconSettings,
	LMIconTitles,
	LMIconAlbums,
	LMIconPlaylists,
	LMIconGenres,
	LMIconArtists,
	LMIconComposers,
	LMIconCompilations,
	LMIconBug,
	LMIconNoAlbumArt,
	LMIconNoAlbumArt75Percent,
	LMIconNoAlbumArt50Percent,
	LMIconSource,
	LMIconBrowse,
	LMIconMiniplayer,
	LMIconLookAndFeel,
	LMIconAbout,
	LMIconCloudDownload,
	LMIconForwardArrow,
	LMIconPebbles,
	LMIconFunctionality,
	LMIconPaperPlane,
	LMIconLink,
	LMIconTwitter,
	LMIconXCross,
	LMIconSearch,
	LMIconAToZ,
	LMIconGrabRectangle,
	LMIconHamburger,
	LMIconAirPlay,
	LMIconBack,
	LMIconWhiteCheckmark,
	LMIconGreenCheckmark,
	LMIconBuy,
	LMIconKickstarter,
	LMIconDownArrow,
	LMIconUpArrow,
	LMIconNoSearchResults
} LMIcon;

/**
 The filename for an icon. Should be used for system-required icon loading.

 @param icon The icon to get the filename for.

 @return The filename for the icon.
 */
+ (NSString*)filenameForIcon:(LMIcon)icon;

/**
 Returns a UIImage which is associated with the LMIcon asked for. The UIImage is not modified in any way.

 @param icon The icon requested.

 @return The UIImage of the icon requested. nil if the icon has not yet been set within the codebase.
 */
+ (UIImage*)imageForIcon:(LMIcon)icon;

/**
 Invert an image.

 @param image The image to invert.

 @return The inverted image.
 */
+ (UIImage*)invertImage:(UIImage*)image;

@end
