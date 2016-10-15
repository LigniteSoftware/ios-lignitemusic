//
//  LMIcon.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/15/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMAppIcon.h"

@implementation LMAppIcon

+ (NSString*)filenameForIcon:(LMIcon)icon {
	switch(icon){
		case LMIconPlay:
			return @"icon_play.png";
		case LMIconPause:
			return @"icon_pause.png";
		case LMIconRepeat:
			return @"icon_repeat_general.png";
		case LMIconRepeatOne:
			return @"icon_repeat_one.png";
		case LMIconShuffle:
			return @"icon_shuffle.png";
		case LMIconTripleHorizontalDots:
			return @"icon_triple_horizontal_dots.png";
		case LMIconSettings:
			return @"icon_settings.png";
		case LMIconTitles:
			return @"icon_titles.png";
		case LMIconAlbums:
			return @"icon_albums.png";
	}
}

+ (UIImage*)imageForIcon:(LMIcon)icon {
	return [UIImage imageNamed:[LMAppIcon filenameForIcon:icon]];
}

@end
