//
//  LMTutorialView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-27.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTutorialView.h"
#import "LMLabel.h"

@interface LMTutorialView()

/**
 The title of this tutorial view.
 */
@property NSString *titleText;

/**
 The description of this tutorial view.
 */
@property NSString *descriptionText;

/**
 The view which goes in the background to blur out the rest of the app.
 */
@property UIVisualEffectView *backgroundBlurView;

/**
 The background for the content view box.
 */
@property UIView *contentViewBackground;

/**
 The actual content view which gets contents such as the title placed inside of it.
 */
@property UIView *contentView;

/**
 The title label.
 */
@property LMLabel *titleLabel;

/**
 The description label.
 */
@property UILabel *descriptionLabel;

/**
 The label for if the user wants us to stop the popups from coming up.
 */
@property LMLabel *stopThesePopupsLabel;

@end

@implementation LMTutorialView

- (instancetype)initForAutoLayoutWithTitle:(NSString*)title description:(NSString*)description {
    self = [super initForAutoLayout];
    
    if(self){
        self.titleText = title;
        self.descriptionText = description;
        self.boxAlignment = LMTutorialViewAlignmentCenter;
        self.arrowAlignment = LMTutorialViewAlignmentCenter;
        self.icon = nil;
    }
    
    return self;
}

- (void)layoutSubviews {
    if(!self.didLayoutConstraints) {
        self.didLayoutConstraints = YES;
        
        
        self.backgroundColor = [UIColor purpleColor];
        
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.backgroundBlurView = [[UIVisualEffectView alloc] initWithEffect:blurEffect];
        self.backgroundBlurView.translatesAutoresizingMaskIntoConstraints = NO;
        [self addSubview:self.backgroundBlurView];
        
        [self.backgroundBlurView autoPinEdgesToSuperviewEdges];
        
     
        self.contentViewBackground = [UIView newAutoLayoutView];
        self.contentViewBackground.backgroundColor = [UIColor whiteColor];
        self.contentViewBackground.layer.shadowOpacity = 0.25f;
        self.contentViewBackground.layer.shadowOffset = CGSizeMake(0, 0);
        self.contentViewBackground.layer.masksToBounds = NO;
        self.contentViewBackground.layer.shadowRadius = 15;
        [self addSubview:self.contentViewBackground];
        
        [self.contentViewBackground autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if(self.boxAlignment == LMTutorialViewAlignmentCenter){
            [self.contentViewBackground autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        }
        [self.contentViewBackground autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self withMultiplier:(6.0/10.0)];
        [self.contentViewBackground autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(8.0/10.0)];
        
        
        self.contentView = [UIView newAutoLayoutView];
        self.contentView.backgroundColor = [UIColor lightGrayColor];
        [self.contentViewBackground addSubview:self.contentView];
        
        [self.contentView autoCenterInSuperview];
        [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentViewBackground withMultiplier:(9.5/10.0)];
        [self.contentView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentViewBackground withMultiplier:(9.5/10.0)];
        
        
        self.titleLabel = [LMLabel newAutoLayoutView];
        self.titleLabel.text = self.titleText;
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:50.0f];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.titleLabel];
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.titleLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0/10.0)];
        
        
        self.descriptionLabel = [UILabel newAutoLayoutView];
        self.descriptionLabel.text = self.descriptionText;
        self.descriptionLabel.textColor = [UIColor blackColor];
        self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
        self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.descriptionLabel];
        
        [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:10];
        
        
        self.stopThesePopupsLabel = [LMLabel newAutoLayoutView];
        self.stopThesePopupsLabel.text = @"stop";
        self.stopThesePopupsLabel.textColor = [UIColor blackColor];
        self.stopThesePopupsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
        self.stopThesePopupsLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.stopThesePopupsLabel];
        
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        [self.stopThesePopupsLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.contentView withMultiplier:(1.0/20.0)];
    }
}

@end
