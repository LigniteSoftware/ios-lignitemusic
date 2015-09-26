//
//  NPAlbumArtView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NPAlbumArtView.h"
#import "XYPieChart.h"
#import "PieChartView.h"
#import "LMExtras.h"

@interface NPAlbumArtView() <XYPieChartDataSource, XYPieChartDelegate, PieChartViewDataSource, PieChartViewDelegate>

@property UIImageView *albumArt;
@property XYPieChart *animatedMusicProgress;
@property PieChartView *batteryEfficientMusicProgress;

@property NSTimer *currentTimer;

@end

@implementation NPAlbumArtView

#define BATTERY_SAVER NO

- (id)init {
    self = [super init];
    
    self.batteryEfficientMusicProgress = [[PieChartView alloc]init];
    self.batteryEfficientMusicProgress.delegate = self;
    self.batteryEfficientMusicProgress.datasource = self;
    
    self.animatedMusicProgress = [[XYPieChart alloc]init];
    [self.animatedMusicProgress setDataSource:self];
    [self.animatedMusicProgress setDelegate:self];
    [self.animatedMusicProgress setAnimationSpeed:1.0];
    [self.animatedMusicProgress setPieBackgroundColor:[UIColor clearColor]];
    [self.animatedMusicProgress setPieRadius:75];
    [self.animatedMusicProgress setUserInteractionEnabled:YES];
    [self.animatedMusicProgress setLabelShadowColor:[UIColor clearColor]];
    [self addSubview:self.animatedMusicProgress];
    
    self.albumArt = [[UIImageView alloc]init];
    self.albumArt.layer.masksToBounds = YES;
    [self addSubview:self.albumArt];
    
    self.currentTimer = [NSTimer scheduledTimerWithTimeInterval:0.5 target:self selector:@selector(onTimer:) userInfo:nil repeats:YES];
    
    /*
    self.albumArt.backgroundColor = [UIColor yellowColor];
    self.backgroundColor = [UIColor redColor];
     */

    return self;
}

- (void)updateContentWithMediaItem:(MPMediaItem*)nowPlaying {
    self.albumArt.image = [[nowPlaying artwork]imageWithSize:[[nowPlaying artwork] imageCropRect].size];
}

- (void)updateContentWithFrame:(CGRect)newFrame {
    [UIView animateWithDuration:0.3 animations:^{
        self.frame = newFrame;
        
        CGSize newAlbumArtSize = CGSizeMake(self.frame.size.width/1.5, self.frame.size.width/1.5);
        CGPoint newStart = CGPointMake((self.frame.size.width-newAlbumArtSize.width)/2, (self.frame.size.height-newAlbumArtSize.height)/2);
        
        CGRect newAlbumArtFrame = CGRectMake(newStart.x, newStart.y, newAlbumArtSize.width, newAlbumArtSize.height);
        self.albumArt.frame = newAlbumArtFrame;
        self.albumArt.layer.cornerRadius = newAlbumArtSize.width/2;
        
        self.batteryEfficientMusicProgress.frame = CGRectMake(self.frame.size.width/2, self.frame.size.height/2, self.frame.size.width, self.frame.size.width);
        self.animatedMusicProgress.frame = CGRectMake(self.frame.size.width/2, self.frame.size.height/2, self.frame.size.width, self.frame.size.width);
        
        [self.animatedMusicProgress setPieRadius:newAlbumArtSize.width/2 + 10];
    }];
}

- (void)onTimer:(NSTimer *)timer {
    if(timer != nil){
        [self.animatedMusicProgress removeFromSuperview];
        [self.batteryEfficientMusicProgress removeFromSuperview];
        
        if(!BATTERY_SAVER){
            [self addSubview:self.animatedMusicProgress];
            [self.animatedMusicProgress reloadData];
        }
        else{
            [self addSubview:self.batteryEfficientMusicProgress];
            [self.batteryEfficientMusicProgress reloadData];
        }
        [self addSubview:self.albumArt];
    }
}

- (UIColor*)GetRandomUIColor:(int)index {
    UIColor *colour;
    if(index <= self.musicPlayer.currentPlaybackTime){
        colour = LIGNITE_COLOUR;//[UIColor colorWithRed:index*0.009 green:0.16 blue:0.17 alpha:1.0f];
    }
    else{
        colour = [UIColor clearColor];
    }
    return colour;
}

/*
 * Beautiful pie chart
 */
#pragma mark - XYPieChart Data Source

- (NSUInteger)numberOfSlicesInPieChart:(XYPieChart *)pieChart{
    return [[self.musicPlayer nowPlayingItem] playbackDuration];
}

- (CGFloat)pieChart:(XYPieChart *)pieChart valueForSliceAtIndex:(NSUInteger)index{
    return 1;
}

- (UIColor*)pieChart:(XYPieChart *)pieChart colorForSliceAtIndex:(NSUInteger)index{
    return [self GetRandomUIColor:(int)index];
}


/*
 * Battery efficient pie chart
 */
#pragma mark - PieChartViewDelegate

-(CGFloat)centerCircleRadius{
    return 1;
}

#pragma mark - PieChartViewDataSource

- (int)numberOfSlicesInPieChartView:(PieChartView *)pieChartView{
    return [[self.musicPlayer nowPlayingItem] playbackDuration];
}

- (UIColor *)pieChartView:(PieChartView*)pieChartView colorForSliceAtIndex:(NSUInteger)index{
    return [self GetRandomUIColor:(int)index];
}

- (double)pieChartView:(PieChartView*)pieChartView valueForSliceAtIndex:(NSUInteger)index{
    return 1;
}

- (void)pieChart:(XYPieChart *)pieChart didSelectSliceAtIndex:(NSUInteger)index{
    [self.musicPlayer setCurrentPlaybackTime:index];
}


@end
