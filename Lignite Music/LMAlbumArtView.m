//
//  NPAlbumArtView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <MediaPlayer/MediaPlayer.h>
#import "LMAlbumArtView.h"
#import "LMExtras.h"
#import "LMProgressCircleView.h"

@interface LMAlbumArtView()

@property MPMediaItem *currentMediaItem;
@property LMMusicTrack *currentTrack;

@property NSTimer *currentTimer;

@property LMProgressCircleView *progressCircle;

@property BOOL adjustedHeight;

@end

@implementation LMAlbumArtView

//#define BATTERY_SAVER

- (void)layoutSubviews {
	NSLog(@"%@ Got %@!", self, NSStringFromCGRect(self.frame));
	
	if(!self.adjustedHeight && self.frame.size.height > 0){
		ALDimension dimensionToMatch = (self.frame.size.width > self.frame.size.height) ? ALDimensionHeight : ALDimensionWidth;
		
		[self.progressCircle autoMatchDimension:ALDimensionHeight toDimension:dimensionToMatch ofView:self];
		[self.progressCircle autoMatchDimension:ALDimensionWidth toDimension:dimensionToMatch ofView:self];
		
		[self.albumArtImageView autoMatchDimension:ALDimensionHeight toDimension:dimensionToMatch ofView:self withMultiplier:0.95];
		[self.albumArtImageView autoMatchDimension:ALDimensionWidth toDimension:dimensionToMatch ofView:self withMultiplier:0.95];
		
		[self.superview setNeedsLayout];
		[self.superview layoutIfNeeded];
		
		self.adjustedHeight = YES;
	}
	
	[super layoutSubviews];
}

- (void)setupWithAlbumImage:(UIImage*)albumImage {
	NSLog(@"Setting up %@", self);
	
    self.backgroundColor = [UIColor clearColor];
	
	self.progressCircle = [[LMProgressCircleView alloc]init];
	self.progressCircle.translatesAutoresizingMaskIntoConstraints = NO;
	self.progressCircle.thickness = 8;
	[self addSubview:self.progressCircle];
	[self.progressCircle reload];
	
	[self.progressCircle autoCenterInSuperview];
	
    self.albumArtImageView = [[UIImageView alloc]initWithImage:albumImage];
    self.albumArtImageView.translatesAutoresizingMaskIntoConstraints = NO;
    self.albumArtImageView.backgroundColor = [UIColor orangeColor];
	self.albumArtImageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.albumArtImageView];
	
	[self.albumArtImageView autoCenterInSuperview];
}

- (void)updateContentWithMusicPlayer:(MPMusicPlayerController*)musicPlayer {
//    NSLog(@"Reloading %@", NSStringFromCGRect(self.albumArtImageView.frame));
    if(musicPlayer.nowPlayingItem != self.currentMediaItem && self.albumArtImageView.frame.size.width != 0){
        self.albumArtImageView.image = [[musicPlayer.nowPlayingItem artwork]imageWithSize:self.albumArtImageView.frame.size];
        self.albumArtImageView.layer.cornerRadius = MIN(self.albumArtImageView.frame.size.width, self.albumArtImageView.frame.size.height)/2;
        self.albumArtImageView.clipsToBounds = YES;
		
		[self.albumArtImageView setNeedsDisplay];
        NSLog(@"%f", self.albumArtImageView.layer.cornerRadius);
        self.currentMediaItem = musicPlayer.nowPlayingItem;
    }
}

- (void)updateContentWithMusicTrack:(LMMusicTrack*)track {
	if(!track.sourceTrack){
		NSLog(@"Source track don't exist");
		return;
	}
	MPMediaItem *nowPlayingItem = track.sourceTrack;
	
	NSLog(@"%@ compared to %@", NSStringFromCGRect(self.albumArtImageView.frame), NSStringFromCGSize(nowPlayingItem.artwork.bounds.size));
	if(track != self.currentTrack && self.albumArtImageView.frame.size.width != 0){
		self.albumArtImageView.image = nil;
		self.albumArtImageView.image = [track albumArt];
		
		self.albumArtImageView.backgroundColor = [UIColor greenColor];
		self.albumArtImageView.layer.cornerRadius = MIN(self.albumArtImageView.frame.size.width, self.albumArtImageView.frame.size.height)/2;
		self.albumArtImageView.clipsToBounds = YES;
		
		[self.albumArtImageView reloadInputViews];
		
		NSLog(@"%f %d", self.albumArtImageView.layer.cornerRadius, self.albumArtImageView ? YES : NO);
		
		self.currentMediaItem = nowPlayingItem;
		self.currentTrack = track;
	}
}

- (UIColor*)GetRandomUIColor:(int)index {
    UIColor *colour;
	NSLog(@"Spooked");
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
