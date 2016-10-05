//
//  NPAlbumArtView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NPAlbumArtView.h"
#import "LMExtras.h"
#import "LMProgressCircleView.h"

@interface NPAlbumArtView()

@property MPMediaItem *currentMediaItem;
@property UIImageView *albumArt;

@property NSTimer *currentTimer;

@property LMProgressCircleView *progressCircle;

@end

@implementation NPAlbumArtView

//#define BATTERY_SAVER

- (void)setupWithAlbumImage:(UIImage*)albumImage {
    self.backgroundColor = [UIColor clearColor];
	
	self.progressCircle = [[LMProgressCircleView alloc]init];
	self.progressCircle.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressCircle.thickness = 8;
	[self addSubview:self.progressCircle];
	[self.progressCircle reload];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressCircle
													 attribute:NSLayoutAttributeCenterX
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterX
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressCircle
													 attribute:NSLayoutAttributeCenterY
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeCenterY
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressCircle
													 attribute:NSLayoutAttributeWidth
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:1.0
													  constant:0]];
	
	[self addConstraint:[NSLayoutConstraint constraintWithItem:self.progressCircle
													 attribute:NSLayoutAttributeHeight
													 relatedBy:NSLayoutRelationEqual
														toItem:self
													 attribute:NSLayoutAttributeWidth
													multiplier:1.0
													  constant:0]];
	
    self.albumArt = [[UIImageView alloc]init];
    self.albumArt.translatesAutoresizingMaskIntoConstraints = NO;
    //self.albumArt.backgroundColor = [UIColor redColor];
    [self addSubview:self.albumArt];
	
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArt
                                                     attribute:NSLayoutAttributeCenterX
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterX
                                                    multiplier:1.0
                                                      constant:0]];
	
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArt
                                                     attribute:NSLayoutAttributeCenterY
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeCenterY
                                                    multiplier:1.0
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArt
                                                     attribute:NSLayoutAttributeWidth
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:0.95
                                                      constant:0]];
    
    [self addConstraint:[NSLayoutConstraint constraintWithItem:self.albumArt
                                                     attribute:NSLayoutAttributeHeight
                                                     relatedBy:NSLayoutRelationEqual
                                                        toItem:self
                                                     attribute:NSLayoutAttributeWidth
                                                    multiplier:0.95
                                                      constant:0]];
}

- (void)updateContentWithMusicPlayer:(MPMusicPlayerController*)musicPlayer {
//    NSLog(@"Reloading %@", NSStringFromCGRect(self.albumArt.frame));
    if(musicPlayer.nowPlayingItem != self.currentMediaItem && self.albumArt.frame.size.width != 0){
        self.albumArt.image = [[musicPlayer.nowPlayingItem artwork]imageWithSize:self.albumArt.frame.size];
        
        self.albumArt.layer.cornerRadius = self.albumArt.frame.size.width/2;
        self.albumArt.clipsToBounds = YES;
        NSLog(@"%f", self.albumArt.layer.cornerRadius);
        self.currentMediaItem = musicPlayer.nowPlayingItem;
    }
}

- (UIColor*)GetRandomUIColor:(int)index {
    UIColor *colour;
    if(index <= self.musicPlayer.currentPlaybackTime){
        colour = LIGNITE_RED;//[UIColor colorWithRed:index*0.009 green:0.16 blue:0.17 alpha:1.0f];
    }
    else{
        colour = [UIColor clearColor];
    }
    return colour;
}

//- (void)drawRect:(CGRect)rect {
//    int smallerFactor = MIN(rect.size.width, rect.size.height);
//    int progressBarThickness = 5;
//    
//    CGContextRef context = UIGraphicsGetCurrentContext();
//    CGFloat theHalf = rect.size.width/2;
//    CGFloat lineWidth = smallerFactor/2;
//    CGFloat radius = smallerFactor/4;
//    CGFloat centerX = theHalf;
//    CGFloat centerY = rect.size.height/2;
//    
//    float startAngle = - M_PI_2;
//    float endAngle = 0.0f;
//    
//    endAngle = startAngle + M_PI*2;
//    CGContextAddArc(context, centerX, centerY, radius, startAngle, endAngle, false);
//    
//    CGContextSetStrokeColorWithColor(context, [UIColor blackColor].CGColor);
//    CGContextSetLineWidth(context, lineWidth);
//    CGContextStrokePath(context);
//    
//    [[UIColor clearColor] setFill];
//
//    CGContextSetBlendMode(context, kCGBlendModeClear);
//    CGContextSetRGBFillColor(context, 1.0, 1.0, 1.0, 0.0);
//    CGRect circleRect = CGRectMake(centerX-(radius*2)+progressBarThickness, centerY-(radius*2)+progressBarThickness, radius*4-(progressBarThickness*2), radius*4-(progressBarThickness*2));
//    CGContextFillEllipseInRect(context, circleRect);
//}

@end
