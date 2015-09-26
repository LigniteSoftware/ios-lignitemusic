//
//  LMButton.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/25/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMButton.h"

@interface LMButton()

@property UILabel *titleLabel;
@property UIImageView *imageView;

@end

@implementation LMButton

/*
 Initializes the view with the title and image as well as root frame.
 */
- (id)initWithTitle:(NSString*)title withImage:(UIImage*)image withFrame:(CGRect)frame {
    self = [super init];
    self.frame = frame;
    
    self.titleLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, self.frame.size.height/3 * 2, self.frame.size.width, self.frame.size.width/3)];
    self.titleLabel.text = title;
    self.titleLabel.textAlignment = NSTextAlignmentCenter;
    self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Thin" size:14.0f];
    [self addSubview:self.titleLabel];
    
    self.imageView = [[UIImageView alloc]initWithFrame:CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/3 * 2)];
    self.imageView.image = image;
    self.imageView.contentMode = UIViewContentModeScaleAspectFit;
    [self addSubview:self.imageView];
    
    self.layer.masksToBounds = NO;
    self.layer.cornerRadius = 7.0;
    self.layer.borderWidth = 0.0;
    
    UITapGestureRecognizer *clickedRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(buttonClicked)];
    [self addGestureRecognizer:clickedRecognizer];
    
    return self;
}

/*
 Set title
 */
- (void)setTitle:(NSString*)newTitle {
    self.titleLabel.text = newTitle;
}

/*
 Reacts when button is clicked
 */
- (void)buttonClicked {
    if(self.delegate){
        [self.delegate clickedButton:self];
    }
    [UIView animateWithDuration:0.05 animations:^{
        //Fade to black
        self.backgroundColor = [UIColor colorWithRed:0.4 green:0.4 blue:0.4 alpha:1];
    } completion:^(BOOL finished) {
        //Fade in
        [UIView animateWithDuration:0.05 animations:^{
            self.backgroundColor = [UIColor colorWithRed:1 green:1 blue:1 alpha:1];
        }];
    }];
}

/*
 Update all views with the new root frame
 */
- (void)updateWithFrame:(CGRect)newFrame {
    self.frame = newFrame;
    [UIView animateWithDuration:0.3 animations:^{
        self.titleLabel.frame = CGRectMake(0, self.frame.size.height/3 * 2, self.frame.size.width, self.frame.size.width/3);
        self.imageView.frame = CGRectMake(0, 0, self.frame.size.width, self.frame.size.height/3 * 2);
    }];
}


@end
