//
//  KBPebbleImage.m
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <wand/MagickWand.h>
#import "KBPebbleImage.h"

static inline uint8_t pixelShade(uint8_t* i) {
    return (i[0] * 0.21) + (i[1] * 0.72) + (i[2] * 0.07);
}

static inline size_t offset(size_t width, size_t x, size_t y) {
    return (x * width) + (y); // RGBA
}

#define DIFFUSE_ERROR(b,a) if((a) < width && (b) < height) grey[(b)*width+(a)] = MAX(0, MIN(255, grey[(b)*width+(a)] + (int16_t)(0.125 * (float)err)))

@implementation KBPebbleImage

+ (void)floydSteinbergWithData:(uint8_t*)data forLength:(int)length width:(uint16_t)w height:(uint16_t)h {
    int numcomponents = length / (w * h);
    NSLog(@"Number of components %d", numcomponents);
    
    for(int i = 0; i < length; i += 100){
        NSLog(@"Data %d: %d", i, data[i]);
    }
    
    for(int y = 0; y < h; y++){
        for(int x = 0; x < w; x++){
            uint8_t ci = numcomponents*(y*w+x);               // current buffer index
            for(uint8_t comp = 0; comp < numcomponents; comp++){
                uint8_t cc = data[ci+comp];         // current color
                //NSLog(@"got %d", data[ci+comp]);
                uint8_t rc = [KBPebbleImage nearestColourToPalette:cc];    // real (rounded) color
                data[ci+comp] = rc;                  // saving real color
                uint8_t err = cc-rc;              // error amount
                if(x+1 < w){
                    data[ci+comp+1] += (err*7)>>4;  // if right neighbour exists
                }
                if(y+1 == h){ // hey its carter
                    //NSLog(@"last line %d %d", x, y);
                    if(x > 0){
                        data[ci+comp+numcomponents*w-1] += (err*3) >> 4;  // bottom left neighbour
                    }
                    data[ci+comp+numcomponents*w] += (err*5) >> 4;  // bottom neighbour
                    if(x+1 < w){
                        data[ci+comp+numcomponents*w+1] += (err*1) >> 4;  // bottom right neighbour
                    }
                }
            }
        }
    }
}

+ (uint8_t)nearestColourToPalette:(uint8_t)component{
    uint8_t number = floor((component + 42) / 85) * 85;
    //NSLog(@"%d", number);
    return number;
}

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    //UIGraphicsBeginImageContext(newSize);
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 0.0);
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    return newImage;
}

+ (UIImage*)ditherImageForPebble:(UIImage*)image withColourPalette:(BOOL)colourPalette {
    NSString *string = [[NSBundle mainBundle] pathForResource:@"robot" ofType:@"png"];
    NSString *coloursGif = [[NSBundle mainBundle] pathForResource:@"pebble_colours_64" ofType:@"gif"];
    char *coloursFilePath = strdup([coloursGif UTF8String]);
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    NSString *outputString = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"outputimage.png"];
    
    NSLog(@"Got paths %@ and %@", string, outputString);
    
    // Get image from bundle.
    char *inputPath = strdup([string UTF8String]);
    char *outputPath = strdup([outputString UTF8String]);

    char *argv[] = {"convert", inputPath,
        //"-adaptive-resize", "'144x168>'",
        "-fill", "'#FFFFFF00'",
        "-opaque", "none",
        "-dither", "FloydSteinberg",
        "-remap", coloursFilePath,
        "-define", "png:compression-level=9",
        "-define", "png:compression-strategy=0",
        "-define", "png:exclude-chunk=all",
        outputPath,
        NULL};
    
    MagickCoreGenesis(*argv, MagickFalse);
    MagickWand *magick_wand = NewMagickWand();
    NSData * dataObject = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:string]);
    MagickBooleanType status;
    status = MagickReadImageBlob(magick_wand, [dataObject bytes], [dataObject length]);
    if (status == MagickFalse) {
        NSLog(@"Error %@", magick_wand);
        
    }
    
    ImageInfo *imageInfo = AcquireImageInfo();
    ExceptionInfo *exceptionInfo = AcquireExceptionInfo();
    
    int elements = 0;
    while (argv[elements] != NULL)
    {
        elements++;
    }
    
    // ConvertImageCommand(ImageInfo *, int, char **, char **, MagickExceptionInfo *);
    status = ConvertImageCommand(imageInfo, elements, argv, NULL, exceptionInfo);
    
    if (exceptionInfo->severity != UndefinedException)
    {
        status=MagickTrue;
        CatchException(exceptionInfo);
    }
    
    if (status == MagickFalse) {
        fprintf(stderr, "Error in call");
        //ThrowWandException(magick_wand); // Always throws an exception here...
    }
    
    UIImage *convertedImage = [UIImage imageWithContentsOfFile:outputString];
    
    return convertedImage;
    
    //return nil;
}


+ (NSData*)ditheredBitmapFromImage:(NSData *)freshData withHeight:(NSUInteger)height width:(NSUInteger)originalWidth {
    NSUInteger width = ceil((double) originalWidth / 32)*32;
    
    NSData *imageData = [[NSData alloc]initWithData:freshData];

    if(!imageData){
        NSLog(@"No image! Rejecting");
        return nil;
    }
    
    uint8_t *rawBytes = (uint8_t*)[imageData bytes];
    uint8_t *modifiedBytes = malloc([imageData length]);
    memcpy(modifiedBytes, rawBytes, [imageData length]);
    [self floydSteinbergWithData:modifiedBytes forLength:(int)[imageData length] width:width height:height];
    
    /*
    uint8_t *bitmap = (uint8_t *)[imageData bytes];
    
    uint8_t *bytes = bitmap;
    NSUInteger len = [imageData length];
    NSMutableString *result = [NSMutableString stringWithCapacity:len * 3];
    [result appendString:@"["];
    for (NSUInteger i = 0; i < len; i++) {
        if (i) {
            [result appendString:@","];
        }
        [result appendFormat:@"%d", bytes[i]];
    }
    [result appendString:@"]"];
    NSLog(@"%@", result);
    NSLog(@"Hey");
    
    // A greyscale version
    uint8_t *grey = malloc(width * height);
    // And the output
    uint8_t *output = malloc(width * height / 8);
    memset(output, 0, (width * height) / 8);
    memset(grey, 0, width * height);
    
    // Build up the greyscale image
    for(int i = 0; i < imageData.length; ++i) {
        grey[i] = pixelShade(&bitmap[i*4]);
        NSLog(@"%d", grey[i]);
    }
    
    // Dither it to black and white
    for(int y = 0; y < width; ++y) {
        for(int x = 0; x < height; ++x) {
            int i = (int)offset(width, x, y); // RGBA
            uint8_t shade = grey[i];
            uint8_t actual_shade = shade > 130 ? 255 : 0;
            int16_t err = shade - actual_shade;
            //NSLog(@"err = %d; diff = %d", err, (uint8_t)(0.125 * err));
            grey[i] = actual_shade;
            
            // Dithering
            DIFFUSE_ERROR(x+1, y);
            DIFFUSE_ERROR(x+2, y);
            DIFFUSE_ERROR(x-1, y+1);
            DIFFUSE_ERROR(x, y+1);
            DIFFUSE_ERROR(x+1, y+1);
            DIFFUSE_ERROR(x, y+2);
        }
    }
    
    // Put it into the output
    for(size_t i = 0; i < width*height; ++i) {
        output[i/8] |= (grey[i]&1) << ((i%8));
    }
    
    //[self floydSteinbergWithData:rawData forLength:(uint16_t)(width*height) width:width height:height];
 
    NSData *output_data = [NSData dataWithBytes:grey length:imageData.length];
    NSLog(@"got %@ and %lu", NSStringFromCGSize(resizedImage.size), (unsigned long)output_data.length);
     
    return output_data;
     */
    
    return [NSData dataWithBytes:modifiedBytes length:[imageData length]];
}

/*
+ (NSData*)ditheredBitmapFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)originalWidth {
    if(!image) return nil;
    
    NSUInteger width = ceil((double) originalWidth / 32)*32;
    
    CGImageRef cg = image.CGImage;
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:cg withHeight:height width:width];
    if(!context) return nil;
    
    CGRect rect = CGRectMake(0, 0, originalWidth, height);
    
    // Draw image into the context to get the raw image data
    CGContextDrawImage(context, rect, cg);
    
    // Get a pointer to the data
    uint8_t *bitmap = (uint8_t*)CGBitmapContextGetData(context);
    // A greyscale version
    uint8_t *grey = malloc(width * height);
    // And the output
    uint8_t *output = malloc(width * height / 8);
    memset(output, 0, width * height / 8);
    memset(grey, 0, width * height);
    
    // Build up the greyscale image
    for(int i = 0; i < width * height; ++i) {
        grey[i] = pixelShade(&bitmap[i*4]);
    }
    CFRelease(context);
    // Dither it to black and white
    for(int y = 0; y < width; ++y) {
        for(int x = 0; x < height; ++x) {
            int i = (int)offset(width, x, y); // RGBA
            uint8_t shade = grey[i];
            uint8_t actual_shade = shade > 130 ? 255 : 0;
            int16_t err = shade - actual_shade;
            //NSLog(@"err = %d; diff = %d", err, (uint8_t)(0.125 * err));
            grey[i] = actual_shade;
            
            // Dithering
            DIFFUSE_ERROR(x+1, y);
            DIFFUSE_ERROR(x+2, y);
            DIFFUSE_ERROR(x-1, y+1);
            DIFFUSE_ERROR(x, y+1);
            DIFFUSE_ERROR(x+1, y+1);
            DIFFUSE_ERROR(x, y+2);
        }
    }
    // Put it into the output
    for(size_t i = 0; i < width*height; ++i) {
        output[i/8] |= (grey[i]&1) << ((i%8));
    }
    free(grey);
    NSData *output_data = [NSData dataWithBytes:output length:(width*height/8)];
    free(output);
    return output_data;
}
 */

/*

+ (NSData*)ditheredBitmapFromImage:(UIImage *)image withHeight:(NSUInteger)height width:(NSUInteger)originalWidth {
    if(!image) return nil;
    
    NSUInteger width = ceil((double) originalWidth / 32)*32;
    
    CGImageRef cg = image.CGImage;
    CGContextRef context = [self newBitmapRGBA8ContextFromImage:cg withHeight:height width:width];
    if(!context){
        NSLog(@"Didn't get a CGContextRef!");
        return nil;
    }
	
	CGRect rect = CGRectMake(0, 0, originalWidth, height);
	
	// Draw image into the context to get the raw image data
	CGContextDrawImage(context, rect, cg);
	
	// Get a pointer to the data
	uint8_t *bitmap = (uint8_t*)CGBitmapContextGetData(context);
    
    CFRelease(context);
    
    NSLog(@"data before %d", bitmap[54]);
    [self floydSteinbergWithData:bitmap forLength:(uint16_t)(width*height) width:width height:height];
    NSLog(@"data after %d", bitmap[54]);
    
    NSData *output_data = [NSData dataWithBytes:bitmap length:width*height];
    
    free(bitmap);
    NSLog(@"Produced output data with length %lu data %@", (width*height/8), output_data);
    return output_data;
}
 */

+ (CGContextRef) newBitmapRGBA8ContextFromImage:(CGImageRef)image withHeight:(NSUInteger)height width:(NSUInteger)width {
	CGContextRef context = NULL;
	CGColorSpaceRef colorSpace;
	uint32_t *bitmapData;
	
	colorSpace = CGColorSpaceCreateDeviceRGB();
	
	if(!colorSpace) return nil;
	
	// Allocate memory for image data
	bitmapData = (uint32_t *)malloc(width * 4 * height);
	
	if(!bitmapData) {
		CGColorSpaceRelease(colorSpace);
		return nil;
	}
	
	//Create bitmap context
	context = CGBitmapContextCreate(bitmapData,
                                    width,
                                    height,
                                    8,
                                    width * 4,
                                    colorSpace,
                                    kCGImageAlphaPremultipliedLast);	// RGBA
	if(!context) {
		free(bitmapData);
	}
	
	CGColorSpaceRelease(colorSpace);
	
	return context;
}

@end
