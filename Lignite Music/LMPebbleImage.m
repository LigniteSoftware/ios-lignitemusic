//
//  KBPebbleImage.m
//  pebbleremote
//
//  Created by Katharine Berry on 27/05/2013.
//  Copyright (c) 2013 Katharine Berry. All rights reserved.
//

#import <wand/MagickWand.h>
#import <YYImage/YYImage.h>
#import "LMPebbleImage.h"

@implementation LMPebbleImage

+ (NSString*)ditherImage:(UIImage*)originalImage
               withSize:(CGSize)size
          forTotalParts:(uint8_t)totalParts
        withCurrentPart:(uint8_t)currentPart
        isBlackAndWhite:(BOOL)blackAndWhite
           isRoundWatch:(BOOL)isRound           {
    
    NSArray *paths = NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES);
    
    UIGraphicsBeginImageContextWithOptions(size, NO, 1.0);
    
    if(isRound){
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:size.width/2] addClip];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height-45) cornerRadius:0] addClip];
    }
    
    //Must be header icon
    if(size.width < 50){
        UIBezierPath *path =[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:8];
        blackAndWhite ? [[UIColor blackColor] setFill] : [[UIColor redColor] setFill];
        [[UIBezierPath bezierPathWithRoundedRect:CGRectMake(0, 0, size.width, size.height) cornerRadius:0] fill];
        [path addClip];
    }
    
    [originalImage drawInRect:CGRectMake(0, 0, size.width, size.height)];
    
    UIImage *image = UIGraphicsGetImageFromCurrentImageContext();
    UIGraphicsEndImageContext();
    
    int widthOfImagePart = size.width/totalParts;
    CGRect frame = CGRectMake(widthOfImagePart*currentPart, 0, widthOfImagePart, size.height-(isRound ? 45 : 0));
    NSLog(@"Frame %@", NSStringFromCGRect(frame));
    CGImageRef imageRef = CGImageCreateWithImageInRect([image CGImage], frame);
    image = [UIImage imageWithCGImage:imageRef];
    CGImageRelease(imageRef);
    
    NSString *sourceImagePath =  [[paths objectAtIndex:0] stringByAppendingPathComponent:@"current_album_artwork.png"];
    NSData *imageData = [YYImageEncoder encodeImage:image type:YYImageTypePNG quality:1];
    [imageData writeToFile:sourceImagePath atomically:YES];
    
    NSString *coloursGif = [[NSBundle mainBundle] pathForResource:blackAndWhite ? @"aplite_colours" : @"pebble_colours_64" ofType:@"gif"];
    char *coloursFilePath = strdup([coloursGif UTF8String]);
    
    NSString *outputString = [[paths objectAtIndex:0] stringByAppendingPathComponent:[NSString stringWithFormat:@"output_image_part_%d.png", currentPart]];
    
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
    
    char *bw_argv[] = { "convert", inputPath,
        "-opaque", "none",
        "-dither", "FloydSteinberg",
        "-remap", coloursFilePath,
        "-define", "png:compression-level=9",
        "-define", "png:compression-strategy=0",
        "-define", "png:exclude-chunk=all",
        outputPath,
        NULL };
     
    MagickCoreGenesis(blackAndWhite ? *bw_argv : *argv, MagickFalse);
    MagickWand *magick_wand = NewMagickWand();
    NSData * dataObject = imageData;
    MagickBooleanType status;
    status = MagickReadImageBlob(magick_wand, [dataObject bytes], [dataObject length]);
    if (status == MagickFalse) {
        NSLog(@"Error %@", magick_wand);
        //throw magickwand exception
    }
    
    ImageInfo *imageInfo = AcquireImageInfo();
    ExceptionInfo *exceptionInfo = AcquireExceptionInfo();
    
    int elements = 0;
    while ((blackAndWhite ? bw_argv[elements] : argv[elements]) != NULL)
    {
        elements++;
    }
    
    // ConvertImageCommand(ImageInfo *, int, char **, char **, MagickExceptionInfo *);
    status = ConvertImageCommand(imageInfo, elements, blackAndWhite ? bw_argv : argv, NULL, exceptionInfo);
    
    if (exceptionInfo->severity != UndefinedException)
    {
        status=MagickTrue;
        CatchException(exceptionInfo);
    }
    
    if (status == MagickFalse) {
        fprintf(stderr, "Error in call");
        //ThrowWandException(magick_wand); // Always throws an exception here...
    }
    
    return outputString;
}

@end

