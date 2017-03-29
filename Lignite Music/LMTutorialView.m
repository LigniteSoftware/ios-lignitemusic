//
//  LMTutorialView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-27.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMTriangleView.h"
#import "LMTutorialView.h"
#import "LMColour.h"

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
@property UILabel *titleLabel;

/**
 The description label.
 */
@property UILabel *descriptionLabel;

/**
 The label for if the user wants us to stop the popups from coming up.
 */
@property UILabel *stopThesePopupsLabel;

/**
 The button which lets the user dismiss the popup.
 */
@property UILabel *thanksForTheHintButton;

/**
 The triamgle view for the pointer which will guide the user where to handle on the screen.
 */
@property LMTriangleView *triangleView;

@end

@implementation LMTutorialView

- (instancetype)initForAutoLayoutWithTitle:(NSString*)title description:(NSString*)description {
    self = [super initForAutoLayout];
    
    if(self){
        self.titleText = title;
        self.descriptionText = description;
        self.boxAlignment = LMTutorialViewAlignmentCenter;
        self.arrowAlignment = LMTutorialViewAlignmentTop;
        self.icon = nil;
    }
    
    return self;
}

- (void)layoutSubviews {
    if(!self.didLayoutConstraints) {
        self.didLayoutConstraints = YES;
        
        
        self.backgroundColor = [UIColor clearColor];
        
        
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
        else {
            [self.contentViewBackground autoPinEdgeToSuperviewEdge:(self.boxAlignment == LMTutorialViewAlignmentBottom) ? ALEdgeBottom : ALEdgeTop];
        }
        [self.contentViewBackground autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(8.0/10.0)];
        
        
        self.triangleView = [LMTriangleView newAutoLayoutView];
        self.triangleView.backgroundColor = [UIColor orangeColor];
        [self.contentViewBackground addSubview:self.triangleView];
        
        [self.triangleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if(self.arrowAlignment == LMTutorialViewAlignmentBottom){
            [self.triangleView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.contentViewBackground];
        }
        else{
            self.triangleView.pointingUpwards = YES;
            [self.triangleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.contentViewBackground];
        }
        [self.triangleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentViewBackground withMultiplier:(2.0/10.0)];
        [self.triangleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentViewBackground withMultiplier:(1.0/10.0)];
        
        
        [self insertSubview:self.contentViewBackground aboveSubview:self.triangleView];
        
        
        self.contentView = [UIView newAutoLayoutView];
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentViewBackground addSubview:self.contentView];
        
        [self.contentView autoCenterInSuperview];
        [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentViewBackground withMultiplier:(9.5/10.0)];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        
        
        self.titleLabel = [UILabel newAutoLayoutView];
        self.titleLabel.text = self.titleText;
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.titleLabel];
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        
        
        self.stopThesePopupsLabel = [UILabel newAutoLayoutView];
        self.stopThesePopupsLabel.text = @"stop";
        self.stopThesePopupsLabel.textColor = [UIColor blackColor];
        self.stopThesePopupsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
        self.stopThesePopupsLabel.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.stopThesePopupsLabel];
        
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];
        
        
        self.thanksForTheHintButton = [UILabel newAutoLayoutView];
        self.thanksForTheHintButton.text = @"close this bitch";
        self.thanksForTheHintButton.textColor = [UIColor whiteColor];
        self.thanksForTheHintButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f];
        self.thanksForTheHintButton.backgroundColor = [LMColour ligniteRedColour];
        self.thanksForTheHintButton.textAlignment = NSTextAlignmentCenter;
        [self.contentView addSubview:self.thanksForTheHintButton];
        
        [self.thanksForTheHintButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.thanksForTheHintButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.thanksForTheHintButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.stopThesePopupsLabel withOffset:-10];
        [self.thanksForTheHintButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleLabel withMultiplier:2.0];
        
        
        
        
        
        self.descriptionLabel = [UILabel newAutoLayoutView];
        self.descriptionLabel.text = self.descriptionText;
        self.descriptionLabel.textColor = [UIColor blackColor];
        self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
        self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
        self.descriptionLabel.numberOfLines = 0;
        [self.contentView addSubview:self.descriptionLabel];
        
        [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
        [self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.thanksForTheHintButton withOffset:-20];
//        [self.descriptionLabel autoPinEdgesToSuperviewEdges];
    }
}

@end
