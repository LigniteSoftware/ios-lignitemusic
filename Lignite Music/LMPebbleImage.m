//
//  KBPebbleImage.m
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <wand/MagickWand.h>
#import "LMPebbleImage.h"

@implementation LMPebbleImage

+ (UIImage*)imageWithImage:(UIImage*)image scaledToSize:(CGSize)newSize {
    UIGraphicsBeginImageContextWithOptions(newSize, NO, 1.0);

    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, newSize.width, newSize.height) cornerRadius:newSize.width/2] addClip];
    [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, newSize.width, newSize.height-45) cornerRadius:0] addClip];
    
    [image drawInRect:CGRectMake(0, 0, newSize.width, newSize.height)];
    
    UIImage *newImage = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    CGImageRef imageRef = CGImageCreateWithImageInRect([newImage CGImage], CGRectMake(0, 0, newSize.width, newSize.height-45));
    newImage = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    return newImage;
}

+ (UIImage*)ditherImageForPebble:(UIImage*)originalImage withColourPalette:(BOOL)colourPalette withSize:(CGSize)size withBlackAndWhite:(BOOL)blackAndWhite {
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    //NSLog(@"Old size %lu size %f, %f, scale %f", [UIImagePNGRepresentation(originalImage) length], originalImage.size.width, originalImage.size.height, originalImage.scale);
    
    UIImage *image = [LMPebbleImage imageWithImage:originalImage scaledToSize:size];
    //NSLog(@"New size %lu size %f, %f, scale %f", [UIImagePNGRepresentation(image) length], image.size.width, image.size.height, image.scale);
    
    NSString *sourceImagePath =  [[paths objectAtIndex:0] stringByAppendingPathComponent:@"current_album_artwork.png"];
    [UIImagePNGRepresentation(image) writeToFile:sourceImagePath atomically:YES];
    
    NSString *coloursGif = [[NSBundle mainBundle] pathForResource:@"pebble_colours_64" ofType:@"gif"];
    char *coloursFilePath = strdup([coloursGif UTF8String]);
    
    NSString *outputString = [[paths objectAtIndex:0] stringByAppendingPathComponent:@"outputimage.png"];
    
    //NSLog(@"Got paths %@ and %@", sourceImagePath, outputString);
    
    // Get image from bundle.
    char *inputPath = strdup([sourceImagePath UTF8String]);
    char *outputPath = strdup([outputString UTF8String]);

    char *argv[] = { "convert", inputPath,
        "-opaque", "none",
        "-dither", "FloydSteinberg",
         "-remap", coloursFilePath,
        "-define", "png:compression-level=9",
        "-define", "png:compression-strategy=0",
        "-define", "png:exclude-chunk=all",
        outputPath,
        NULL };
    
    /*
    char *argv[] = {
        "convert", inputPath,
        "-opaque", "none",
        "-type", "Grayscale",
        "-colorspace", "Gray",
        "-black-threshold", "50%",
        "-white-threshold", "50%",
        "-ordered-dither", "2x1",
        "-colors", "2",
        "-depth", "1",
        "-define", "png:compression-level=9",
        "-define", "png:compression-strategy=0",
        "-define", "png:exclude-chunk=all",
        outputPath,
        NULL
    };
     */
    
    /*
     * Black and white support
     *
    char *argv[] = {
        "convert", inputPath,
        "-opaque", "none",
        "-type", "Grayscale",
        "-colorspace", "Gray",
        "-colors", "2",
        "-depth", "1",
        "-define", "png:compression-level=9",
        "-define", "png:compression-strategy=0",
        "-define", "png:exclude-chunk=all",
        outputPath,
        NULL
    };
     */
    
    MagickCoreGenesis(*argv, MagickFalse);
    MagickWand *magick_wand = NewMagickWand();
    NSData * dataObject = UIImagePNGRepresentation([UIImage imageWithContentsOfFile:sourceImagePath]);
    MagickBooleanType status;
    status = MagickReadImageBlob(magick_wand, [dataObject bytes], [dataObject length]);
    if (status == MagickFalse) {
        NSLog(@"Error %@", magick_wand);
        //throw magickwand exception
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
}

@end

