//
//  NPVTextInfoView.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/24/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import <MediaPlayer/MediaPlayer.h>
#import "NPTextInfoView.h"
#import "LMExtras.h"

@interface NPTextInfoView()

@property BOOL isMiniPlayer;
@property UILabel *songTitle, *songArtist, *songAlbum, *songDuration;

@end

@implementation NPTextInfoView

- (void)updateContentWithMediaItem:(MPMediaItem*)newItem {
    CGRect songTitleFrame, songAlbumFrame, songArtistFrame;
    
    self.songTitle.text = [newItem title];
    self.songArtist.text = [newItem artist];
    self.songAlbum.text = [newItem albumTitle];
    
    NSLog(@"%@", newItem);
    
    NSLog(@"Current frame %@", NSStringFromCGRect(self.frame));
    
    return;
    
    CGSize titleTextSize = [self.songTitle.text sizeWithAttributes:@{NSFontAttributeName: self.songTitle.font}];
    CGSize artistTextSize = [self.songArtist.text sizeWithAttributes:@{NSFontAttributeName: self.songArtist.font}];
    CGSize albumTextSize = [self.songAlbum.text sizeWithAttributes:@{NSFontAttributeName: self.songAlbum.font}];
    
    float albumArtY = 0;
    float textStartX = 0;
    
    float titleX = textStartX;
    float titleY = albumArtY;
    int titleOverflow = 0;
    if(titleTextSize.width+titleX > self.frame.size.width){
        titleOverflow = (titleTextSize.width+titleX)/(self.frame.size.width-titleX);
    }
    
    int titleHeight = titleTextSize.height*(titleOverflow+1)+10;
    CGRect newTitleRect = CGRectMake(titleX, titleY-(titleOverflow > 0 ? titleHeight/3 : 0), self.frame.size.width, titleHeight);
    self.songTitle.frame = newTitleRect;
    
    float artistX = self.songTitle.frame.origin.x;
    float artistY = titleY+newTitleRect.size.height;
    int artistOverflow = 0;
    if(artistTextSize.width+artistX > self.frame.size.width){
        artistOverflow = (artistTextSize.width+artistX)-self.frame.size.width;
    }
    
    CGRect newArtistRect = CGRectMake(artistX, artistY, self.frame.size.width, artistTextSize.height*(artistOverflow > 0 ? 2 : 1));
    self.songArtist.frame = newArtistRect;
    
    float albumX = self.songTitle.frame.origin.x;
    float albumY = artistY+newArtistRect.size.height;
    int albumOverflow = 0;
    if(albumTextSize.width+albumX > self.frame.size.width){
        albumOverflow = (artistTextSize.width+albumX)-self.frame.size.width;
    }
    CGRect newAlbumRect = CGRectMake(albumX, albumY, self.frame.size.width, albumTextSize.height*(artistOverflow > 0 ? 2 : 1));
    self.songAlbum.frame = newAlbumRect;
}

- (void)updateContentWithFrame:(CGRect)newFrame isPortrait:(BOOL)isPortrait {
    [UIView animateWithDuration:0.3 animations:^{
        //self.frame = newFrame;
        
        self.songTitle.textAlignment = isPortrait ? NSTextAlignmentCenter : NSTextAlignmentLeft;
        self.songArtist.textAlignment = isPortrait ? NSTextAlignmentCenter : NSTextAlignmentLeft;
        self.songAlbum.textAlignment = isPortrait ? NSTextAlignmentCenter : NSTextAlignmentLeft;
    }];
}

- (id)initWithFrame:(CGRect)frame withMiniPlayerStatus:(BOOL)isMiniPlayer {
    self = [super initWithFrame:frame];
    self.isMiniPlayer = isMiniPlayer;
    
    int fourthWidth = self.frame.size.height/3;
    
    UIFont *titleFont = [UIFont fontWithName:@"HelveticaNeue-Light" size:fourthWidth + 2];
    UIColor *textColour = self.isMiniPlayer ? [UIColor blackColor] : [UIColor whiteColor];
    
    CGRect songFrame = CGRectMake(0, 10, self.frame.size.width, fourthWidth + 6);

    self.songTitle = [[UILabel alloc]initWithFrame:songFrame];
    self.songTitle.text = @"Title";
    self.songTitle.font = titleFont;
    self.songTitle.textColor = textColour;
    self.songTitle.contentMode = UIViewContentModeTopLeft;
    self.songTitle.numberOfLines = 0;
    [self addSubview:self.songTitle];
    
    CGRect songArtistFrame = CGRectMake(0, songFrame.origin.y + songFrame.size.height + 2, songFrame.size.width, fourthWidth/2 + 4);
    self.songArtist = [[UILabel alloc]initWithFrame:songArtistFrame];
    self.songArtist.text = @"Artist";
    self.songArtist.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:songArtistFrame.size.height - 2];
    self.songArtist.textColor = textColour;
    self.songArtist.numberOfLines = 0;
    [self addSubview:self.songArtist];
    
    CGRect songAlbumFrame = CGRectMake(0, songArtistFrame.origin.y + songArtistFrame.size.height, songFrame.size.width, songArtistFrame.size.height);
    self.songAlbum = [[UILabel alloc]initWithFrame:songAlbumFrame];
    self.songAlbum.text = @"Album";
    self.songAlbum.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:songAlbumFrame.size.height - 6];
    self.songAlbum.textColor = textColour;
    [self addSubview:self.songAlbum];
    
    CGRect songDurationFrame = CGRectMake(0, songAlbumFrame.origin.y, songAlbumFrame.size.width, songAlbumFrame.size.height);
    self.songDuration = [[UILabel alloc]initWithFrame:songDurationFrame];
    self.songDuration.text = @"01:19 of 02:53";
    self.songDuration.font = self.songAlbum.font;
    self.songDuration.textColor = textColour;
    self.songDuration.numberOfLines = 0;
    self.songDuration.textAlignment = NSTextAlignmentRight;
    [self addSubview:self.songDuration];
    
    /*
    self.songTitle.backgroundColor = [UIColor colorWithRed:0.5 green:0 blue:0 alpha:1];
    self.songArtist.backgroundColor = [UIColor colorWithRed:0.7 green:0 blue:0 alpha:1];
    self.songAlbum.backgroundColor = [UIColor colorWithRed:1.0 green:0 blue:0 alpha:1];
    self.backgroundColor = [UIColor blueColor];
    */
    
    return self;
}

/*
// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
}
*/

@end
