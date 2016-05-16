//
//  LMMiniPlayerView.m
//  Lignite Music
//
//  Created by Edwin Finch on 5/4/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import "LMMiniPlayerView.h"

@implementation LMMiniPlayerView

- (id)initWithFrame:(CGRect)frame {
    self = [super initWithFrame:frame];
    if(self){
        self.backgroundColor = [UIColor clearColor];
        
        for(int i = 0; i < 4; i++){
            uint16_t totalRadius = (MINI_PLAYER_CONTROL_BUTTON_RADIUS+MINI_PLAYER_CONTROL_BUTTON_PADDING);
            int fourthWidth = (self.frame.size.width-(totalRadius*2))/4;
            bool rightQuarterHalf = i % 2;
            bool rightHalf = i > 1;
            uint8_t padding = 12;
            
            CGRect buttonRect = CGRectMake(padding + (rightQuarterHalf*fourthWidth) + (rightHalf*(self.frame.size.width/2 + totalRadius)), 50, fourthWidth-(padding*2), fourthWidth);
            NSLog(@"%@, %d", NSStringFromCGRect(buttonRect), rightHalf);
            /*
            LMButton *button = [[LMButton alloc]initWithTitle:[NSString stringWithFormat:@"Button %d", i] withImage:[UIImage imageNamed:@"shuffle_black.png"] withFrame:buttonRect];
             
            [self addSubview:button];
             */
        }
        CGRect playerRect = CGRectMake(0, self.frame.size.height/2, self.frame.size.width, self.frame.size.height/2);
        NSLog(@"%@", NSStringFromCGRect(playerRect));
        
        self.musicPlayerView = [[LMNowPlayingView alloc]initWithFrame:playerRect withViewMode:NowPlayingViewModeMiniPortrait];
        self.musicPlayerView.userInteractionEnabled = YES;
        [self addSubview:self.musicPlayerView];
         
    }
    else{
        
    }
    return self;
}

// Only override drawRect: if you perform custom drawing.
// An empty implementation adversely affects performance during animation.
- (void)drawRect:(CGRect)rect {
    // Drawing code
    CGContextRef cont = UIGraphicsGetCurrentContext();
    
    uint8_t fixedRadius = MINI_PLAYER_CONTROL_BUTTON_RADIUS+MINI_PLAYER_CONTROL_BUTTON_PADDING;
    
    CGContextSetRGBFillColor(cont, 1.0, 1.0, 1.0, 1.0);
    CGRect backgroundRect = CGRectMake(0, fixedRadius, self.frame.size.width, self.frame.size.height-MINI_PLAYER_CONTROL_BUTTON_RADIUS);
    CGContextFillRect(cont, backgroundRect);
    
    CGContextSetRGBFillColor(cont, 1.0, 1.0, 1.0, 1.0);
    CGRect circleBackgroundRect = CGRectMake(self.frame.size.width/2 - fixedRadius, 0, fixedRadius*2, fixedRadius*2);
    CGContextFillEllipseInRect(cont, circleBackgroundRect);
    
    CGContextSetRGBFillColor(cont, 1.0, 0, 0, 1.0);
    CGRect circleRect = CGRectMake(self.frame.size.width/2 - MINI_PLAYER_CONTROL_BUTTON_RADIUS, fixedRadius-MINI_PLAYER_CONTROL_BUTTON_RADIUS, MINI_PLAYER_CONTROL_BUTTON_RADIUS*2, MINI_PLAYER_CONTROL_BUTTON_RADIUS*2);
    CGContextFillEllipseInRect(cont, circleRect);
}


@end
