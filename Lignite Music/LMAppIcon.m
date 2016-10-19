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
		case LMIconBug:
			return @"icon_bug.png";
		case LMIconNoAlbumArt:
			return @"icon_no_cover_art.png";
	}
}

+ (UIImage*)imageForIcon:(LMIcon)icon {
	return [UIImage imageNamed:[LMAppIcon filenameForIcon:icon]];
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
