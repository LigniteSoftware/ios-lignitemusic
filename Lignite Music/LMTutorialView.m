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

#define LMTutorialViewDontShowHintsKey @"LMTutorialViewDontShowHintsKey"

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
 The view for the icon which goes beside the description label, if one is provided. 
 */
@property UIImageView *iconView;

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

/**
 The user's defaults.
 */
@property NSUserDefaults *userDefaults;

/**
 The key that this tutorial is associated with.
 */
@property NSString *key;

@end

@implementation LMTutorialView

- (instancetype)initForAutoLayoutWithTitle:(NSString*)title description:(NSString*)description key:(NSString*)key {
    self = [super initForAutoLayout];
    
    if(self){
        self.userDefaults = [NSUserDefaults standardUserDefaults];
        
        self.titleText = title;
        self.descriptionText = description;
        self.key = key;
        
        self.boxAlignment = LMTutorialViewAlignmentCenter;
        self.arrowAlignment = LMTutorialViewAlignmentCenter;
        self.icon = nil;
    }
    
    return self;
}

/**
 Closes the tutorial view in an animated fashion and automatically removes it from its superview.
 */
- (void)close {
    if(!self.leadingLayoutConstraint){
        NSLog(@"\n\nWindows error! No leading constraint for tutorial %@", self.key);
        return;
    }
    
    [UIView animateWithDuration:0.50 animations:^{
        self.backgroundBlurView.effect = nil;
        self.contentViewBackground.alpha = 0;
    } completion:^(BOOL finished) {
        if(finished){
            [self removeFromSuperview];
            
            if(self.delegate){
                if([self.delegate respondsToSelector:@selector(tutorialFinishedWithKey:)]){
                    [self.delegate tutorialFinishedWithKey:self.key];
                }
            }
        }
    }];
}

- (void)tappedCloseButton {
    [self.userDefaults setBool:YES forKey:self.key];
    [self.userDefaults synchronize];
    
    [self close];
}

- (void)tappedStopTutorialsButton {
    [self.userDefaults setBool:YES forKey:LMTutorialViewDontShowHintsKey];
    [self.userDefaults synchronize];
    
    [self close];
}

+ (BOOL)tutorialShouldRunForKey:(NSString*)tutorialKey {
    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
    
    //If the user has disabled tutorials or the specific tutorial has already been done do not run that tutorial
    if([userDefaults objectForKey:LMTutorialViewDontShowHintsKey] || [userDefaults objectForKey:tutorialKey]){
        return NO;
    }
    
    //Otherwise, go for it!
    return YES;
}

- (void)layoutSubviews {
    if(!self.didLayoutConstraints) {
        self.didLayoutConstraints = YES;
        
        
        CGFloat screenSizeScaleFactor = self.frame.size.width/414.0;
        
        
        self.backgroundColor = [UIColor clearColor];
        
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
        [self addSubview:self.backgroundBlurView];
        
        [self.backgroundBlurView autoPinEdgesToSuperviewEdges];
        
     
        self.contentViewBackground = [UIView newAutoLayoutView];
        self.contentViewBackground.backgroundColor = [UIColor whiteColor];
        self.contentViewBackground.layer.shadowOpacity = 0.25f;
        self.contentViewBackground.layer.shadowOffset = CGSizeMake(0, 0);
        self.contentViewBackground.layer.masksToBounds = NO;
        self.contentViewBackground.layer.shadowRadius = 15;
        self.contentViewBackground.alpha = 0;
        [self addSubview:self.contentViewBackground];
        
        [self.contentViewBackground autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if(self.boxAlignment == LMTutorialViewAlignmentCenter){
            [self.contentViewBackground autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
        }
        else {
            [self.contentViewBackground autoPinEdgeToSuperviewEdge:(self.boxAlignment == LMTutorialViewAlignmentBottom) ? ALEdgeBottom : ALEdgeTop withInset:self.frame.size.height/8.0];
        }
        [self.contentViewBackground autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(8.0/10.0)];
        
        
        if(self.arrowAlignment != LMTutorialViewAlignmentCenter){
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
        }
        
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
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f * screenSizeScaleFactor];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.titleLabel];
        
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        
        
        self.stopThesePopupsLabel = [UILabel newAutoLayoutView];
        self.stopThesePopupsLabel.text = NSLocalizedString(@"StopShowingTheseHints", nil);
        self.stopThesePopupsLabel.textColor = [UIColor blackColor];
        self.stopThesePopupsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f * screenSizeScaleFactor];
        self.stopThesePopupsLabel.textAlignment = NSTextAlignmentCenter;
        self.stopThesePopupsLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:self.stopThesePopupsLabel];
        
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];
        
        UITapGestureRecognizer *stopTutorialsGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedStopTutorialsButton)];
        [self.stopThesePopupsLabel addGestureRecognizer:stopTutorialsGestureRecognizer];
        
        
        self.thanksForTheHintButton = [UILabel newAutoLayoutView];
        self.thanksForTheHintButton.text = NSLocalizedString(@"OkThanksForTheHint", nil);
        self.thanksForTheHintButton.textColor = [UIColor whiteColor];
        self.thanksForTheHintButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f * screenSizeScaleFactor];
        self.thanksForTheHintButton.backgroundColor = [LMColour ligniteRedColour];
        self.thanksForTheHintButton.textAlignment = NSTextAlignmentCenter;
        self.thanksForTheHintButton.userInteractionEnabled = YES;
        [self.contentView addSubview:self.thanksForTheHintButton];
        
        [self.thanksForTheHintButton autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        [self.thanksForTheHintButton autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.thanksForTheHintButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.stopThesePopupsLabel withOffset:-10];
        [self.thanksForTheHintButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleLabel withMultiplier:2.0];
        
        
        UITapGestureRecognizer *closeTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedCloseButton)];
        [self.thanksForTheHintButton addGestureRecognizer:closeTapGestureRecognizer];
        
        if(self.icon){
            self.iconView = [UIImageView newAutoLayoutView];
            self.iconView.image = self.icon;
            self.iconView.contentMode = UIViewContentModeScaleAspectFit;
            [self.contentView addSubview:self.iconView];
            
            [self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:(1.0/4.0)];
            [self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:(1.0/4.0)];
            [self.iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
            [self.iconView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
        }
        
        self.descriptionLabel = [UILabel newAutoLayoutView];
        self.descriptionLabel.text = self.descriptionText;
        self.descriptionLabel.textColor = [UIColor blackColor];
        self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f * screenSizeScaleFactor];
        self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
        self.descriptionLabel.numberOfLines = 0;
        [self.contentView addSubview:self.descriptionLabel];
        
        if(self.icon){
            [self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.iconView withOffset:15];
        }
        else{
            [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
        }
        [self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
        [self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
        [self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.thanksForTheHintButton withOffset:-20];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.contentViewBackground.alpha = 1;
            self.backgroundBlurView.effect = blurEffect;
        }];
    }
}

@end
