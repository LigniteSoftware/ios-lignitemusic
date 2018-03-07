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
			return @"icon_play";
		case LMIconPause:
			return @"icon_pause";
		case LMIconRepeat:
			return @"icon_repeat_general";
		case LMIconRepeatOne:
			return @"icon_repeat_one";
		case LMIconShuffle:
			return @"icon_shuffle";
		case LMIconSettings:
			return @"icon_settings";
		case LMIconTitles:
			return @"icon_titles";
		case LMIconAlbums:
			return @"icon_albums";
		case LMIconPlaylists:
			return @"icon_playlists";
		case LMIconGenres:
			return @"icon_genres";
		case LMIconArtists:
			return @"icon_artists";
		case LMIconComposers:
			return @"icon_composers";
		case LMIconCompilations:
			return @"icon_compilations";
		case LMIconBug:
			return @"icon_bug";
		case LMIconNoAlbumArt50Percent:
			return @"icon_no_cover_art_50";
		case LMIconNoAlbumArt75Percent:
			return @"icon_no_cover_art_75";
		case LMIconNoAlbumArt:
			return @"icon_no_cover_art";
		case LMIconSource:
			return @"icon_source";
		case LMIconBrowse:
			return @"icon_browse";
		case LMIconMiniplayer:
			return @"icon_miniplayer";
		case LMIconLookAndFeel:
			return @"icon_look_and_feel";
		case LMIconAbout:
			return @"icon_about";
		case LMIconCloudDownload:
			return @"icon_download";
		case LMIconForwardArrow:
			return @"icon_arrow_forward";
		case LMIconFunctionality:
			return @"icon_functionality";
		case LMIconPaperPlane:
			return @"icon_paper_plane";
		case LMIconTwitter:
			return @"icon_twitter";
		case LMIconLink:
			return @"icon_link";
		case LMIconXCross:
			return @"icon_x_cross";
		case LMIconSearch:
			return @"icon_search";
		case LMIconAirPlay:
			return @"icon_airplay";
		case LMIconWhiteCheckmark:
			return @"icon_white_checkmark";
		case LMIconBuy:
			return @"icon_buy";
		case LMIconHamburger:
			return @"icon_hamburger";
		case LMIconDownArrow:
			return @"icon_down_arrow";
		case LMIconNoSearchResults:
			return @"icon_no_search_results";
        case LMIconLibraryAccess:
            return @"icon_library_access";
		case LMIconiOSBack:
			return @"icon_ios_back";
		case LMIcon3DotsHorizontal:
			return @"icon_3_dots_horizontal";
		case LMIcon3DotsVertical:
			return @"icon_3_dots_vertical";
		case LMIconAddToQueue:
			return @"icon_add_track_to_queue";
		case LMIconRemoveFromQueue:
			return @"icon_remove_track_from_queue";
		case LMIconFavouriteHUD:
			return @"icon_favourite_hud";
		case LMIconFavouriteRedFilled:
			return @"icon_favourite_red";
		case LMIconFavouriteWhiteFilled:
			return @"icon_favourite_white";
		case LMIconFavouriteBlackFilled:
			return @"icon_favourite_black";
		case LMIconFavouriteRedOutline:
			return @"icon_favourite_outlined_red";
		case LMIconFavouriteWhiteOutline:
			return @"icon_favourite_outlined_white";
		case LMIconFavouriteBlackOutline:
			return @"icon_favourite_outlined_black";
		case LMIconUnfavouriteHUD:
			return @"icon_unfavourite_hud";
		case LMIconUnfavouriteRed:
			return @"icon_unfavourite_red";
		case LMIconUnfavouriteWhite:
			return @"icon_unfavourite_white";
		case LMIconUnfavouriteBlack:
			return @"icon_unfavourite_black";
		case LMIconEdit:
			return @"icon_edit_white";
		case LMIconAdd:
			return @"icon_plus_white";
	}
	return @"icon_bug";
}

+ (UIImage*)imageForIcon:(LMIcon)icon {
	return [self imageForIcon:icon inverted:NO];
}

+ (UIImage*)imageForIcon:(LMIcon)icon inverted:(BOOL)inverted {
	UIImage *iconImage = [UIImage imageNamed:[LMAppIcon filenameForIcon:icon]];
	if(inverted){
		return [self invertImage:iconImage];
	}
	return iconImage;
}

+ (UIImage*)invertImage:(UIImage*)image {
	// get width and height as integers, since we'll be using them as
	// array subscripts, etc, and this'll save a whole lot of casting
	CGSize size = image.size;
	int width = size.width;
	int height = size.height;
	
	// Create a suitable RGB+alpha bitmap context in BGRA colour space
	CGColorSpaceRef colourSpace = CGColorSpaceCreateDeviceRGB();
	unsigned char *memoryPool = (unsigned char *)calloc(width*height*4, 1);
	CGContextRef context = CGBitmapContextCreate(memoryPool, width, height, 8, width * 4, colourSpace, kCGBitmapByteOrder32Big | kCGImageAlphaPremultipliedLast);
	CGColorSpaceRelease(colourSpace);
	
	// draw the current image to the newly created context
	CGContextDrawImage(context, CGRectMake(0, 0, width, height), [image CGImage]);
	
	// run through every pixel, a scan line at a time...
	for(int y = 0; y < height; y++)
	{
		// get a pointer to the start of this scan line
		unsigned char *linePointer = &memoryPool[y * width * 4];
		
		// step through the pixels one by one...
		for(int x = 0; x < width; x++)
		{
			// get RGB values. We're dealing with premultiplied alpha
			// here, so we need to divide by the alpha channel (if it
			// isn't zero, of course) to get uninflected RGB. We
			// multiply by 255 to keep precision while still using
			// integers
			int r, g, b;
			if(linePointer[3])
			{
				r = linePointer[0] * 255 / linePointer[3];
				g = linePointer[1] * 255 / linePointer[3];
				b = linePointer[2] * 255 / linePointer[3];
			}
			else
				r = g = b = 0;
			
			// perform the colour inversion
			r = 255 - r;
			g = 255 - g;
			b = 255 - b;
			
			// multiply by alpha again, divide by 255 to undo the
			// scaling before, store the new values and advance
			// the pointer we're reading pixel data from
			linePointer[0] = r * linePointer[3] / 255;
			linePointer[1] = g * linePointer[3] / 255;
			linePointer[2] = b * linePointer[3] / 255;
			linePointer += 4;
		}
	}
	
	// get a CG image from the context, wrap that into a
	// UIImage
	CGImageRef cgImage = CGBitmapContextCreateImage(context);
	UIImage *returnImage = [UIImage imageWithCGImage:cgImage];
	
	// clean up
	CGImageRelease(cgImage);
	CGContextRelease(context);
	free(memoryPool);
	
	// and return
	return returnImage;
}

@end
