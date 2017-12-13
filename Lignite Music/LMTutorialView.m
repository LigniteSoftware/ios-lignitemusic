//
//  LMTutorialView.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-27.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMLayoutManager.h"
#import "LMTriangleView.h"
#import "LMTutorialView.h"
#import "LMColour.h"

#define LMTutorialViewDontShowHintsKey @"LMTutorialViewDontShowHintsKey"

@interface LMTutorialView()<LMLayoutChangeDelegate>

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

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

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
    [UIView animateWithDuration:0.50 animations:^{
        self.backgroundBlurView.effect = nil;
        self.contentViewBackground.alpha = 0;
    } completion:^(BOOL finished) {
        if(finished){
            [self removeFromSuperview];
			
			for(UIView *subview in self.subviews){
				[LMLayoutManager removeAllConstraintsRelatedToView:subview];
			}
			
			[LMLayoutManager removeAllConstraintsRelatedToView:self];
            
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
	return NO;
#warning tutorial is disabled bitch
	
//    NSUserDefaults *userDefaults = [NSUserDefaults standardUserDefaults];
//	    
//    //If the user has disabled tutorials or the specific tutorial has already been done do not run that tutorial
//    if([userDefaults objectForKey:LMTutorialViewDontShowHintsKey] || [userDefaults objectForKey:tutorialKey]){
//        return NO;
//    }
//    
//    //Otherwise, go for it!
//    return YES;
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id<UIViewControllerTransitionCoordinator>)coordinator {
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		for(UIView *subview in self.subviews){
			[subview removeFromSuperview];
			[LMLayoutManager removeAllConstraintsRelatedToView:subview];
		}
		
		self.didLayoutConstraints = NO;
		
		[self setNeedsLayout];
		[self layoutIfNeeded];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		
	}];
}

- (void)layoutSubviews {
    if(!self.didLayoutConstraints) {
        self.didLayoutConstraints = YES;
		
		self.layoutManager = [LMLayoutManager sharedLayoutManager];
		[self.layoutManager addDelegate:self];
        
        
		CGFloat screenSizeScaleFactor = (self.layoutManager.isLandscape ? self.frame.size.height : self.frame.size.width)/414.0;
		
		if(screenSizeScaleFactor > 1.0){
			screenSizeScaleFactor = 1.0;
		}
        
        
        self.backgroundColor = [UIColor clearColor];
        
        
        UIBlurEffect *blurEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleLight];
        self.backgroundBlurView = [UIVisualEffectView newAutoLayoutView];
		self.backgroundBlurView.hidden = ([self.key isEqualToString:LMTutorialKeyMiniPlayer] || [self.key isEqualToString:LMTutorialKeyBottomNavigation]);
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
		
		[self.contentViewBackground autoAlignAxisToSuperviewAxis:[LMLayoutManager isLandscape] ? ALAxisHorizontal : ALAxisVertical];
        if(self.boxAlignment == LMTutorialViewAlignmentCenter){
            [self.contentViewBackground autoAlignAxisToSuperviewAxis:[LMLayoutManager isLandscape] ? ALAxisVertical : ALAxisHorizontal];
        }
        else {
			ALEdge alignment = (self.boxAlignment == LMTutorialViewAlignmentBottom) ? ALEdgeBottom : ALEdgeTop;
			if([LMLayoutManager isLandscape]){
				alignment = (self.boxAlignment == LMTutorialViewAlignmentBottom) ? ALEdgeTrailing : ALEdgeLeading;
			}
			[self.contentViewBackground autoPinEdgeToSuperviewEdge:alignment withInset:self.frame.size.height/([self.key isEqualToString:LMTutorialKeyTopBar] ? ([LMLayoutManager isiPad] ? 12.0 : 6.0) : 8.0)];
        }
		[self.contentViewBackground autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self withMultiplier:(([LMLayoutManager isiPad] ? ([LMLayoutManager isLandscapeiPad] ? 4.0 : 5.0) : 8.0)/10.0)];
        
        
        if(self.arrowAlignment != LMTutorialViewAlignmentCenter){
            self.triangleView = [LMTriangleView newAutoLayoutView];
            self.triangleView.backgroundColor = [UIColor orangeColor];
            [self.contentViewBackground addSubview:self.triangleView];
			
			if(self.layoutManager.isLandscape){
				[self.triangleView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
				
				if(self.arrowAlignment == LMTutorialViewAlignmentBottom){
					self.triangleView.maskDirection = LMTriangleMaskDirectionRight;
					[self.triangleView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.contentViewBackground];
				}
				else{
					self.triangleView.maskDirection = LMTriangleMaskDirectionLeft;
					[self.triangleView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.contentViewBackground];
				}
			}
			else{
				[self.triangleView autoAlignAxisToSuperviewAxis:ALAxisVertical];
				
				if(self.arrowAlignment == LMTutorialViewAlignmentBottom){
					self.triangleView.maskDirection = LMTriangleMaskDirectionDownwards;
					[self.triangleView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.contentViewBackground];
				}
				else{
					self.triangleView.maskDirection = LMTriangleMaskDirectionUpwards;
					[self.triangleView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.contentViewBackground];
				}
			}
            [self.triangleView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth
										   ofView:self.contentViewBackground withMultiplier:self.layoutManager.isLandscape ? (1.0/10.0) : (2.0/10.0)];
			
            [self.triangleView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth
										   ofView:self.contentViewBackground withMultiplier:self.layoutManager.isLandscape ? (1.5/10.0) : (1.0/10.0)];
            
            [self insertSubview:self.contentViewBackground aboveSubview:self.triangleView];
        }
        
        self.contentView = [UIView newAutoLayoutView];
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self.contentViewBackground addSubview:self.contentView];
        
        [self.contentView autoCenterInSuperview];
        [self.contentView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentViewBackground withMultiplier:(10.0/10.0)];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeTop];
        [self.contentView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
        
        
        self.titleLabel = [UILabel newAutoLayoutView];
        self.titleLabel.text = self.titleText;
        self.titleLabel.textColor = [UIColor blackColor];
        self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:30.0f * screenSizeScaleFactor];
        self.titleLabel.textAlignment = NSTextAlignmentLeft;
        [self.contentView addSubview:self.titleLabel];
		
		[self.titleLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:10];
		[self.titleLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:(9.0/10.0)];
        
        
        self.stopThesePopupsLabel = [UILabel newAutoLayoutView];
        self.stopThesePopupsLabel.text = NSLocalizedString(@"StopShowingTheseHints", nil);
        self.stopThesePopupsLabel.textColor = [UIColor blackColor];
        self.stopThesePopupsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f * screenSizeScaleFactor];
        self.stopThesePopupsLabel.textAlignment = NSTextAlignmentCenter;
        self.stopThesePopupsLabel.userInteractionEnabled = YES;
        [self.contentView addSubview:self.stopThesePopupsLabel];
		
		[self.stopThesePopupsLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[self.stopThesePopupsLabel autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.titleLabel];
        [self.stopThesePopupsLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:10];
        
        UITapGestureRecognizer *stopTutorialsGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedStopTutorialsButton)];
        [self.stopThesePopupsLabel addGestureRecognizer:stopTutorialsGestureRecognizer];
        
        
        self.thanksForTheHintButton = [UILabel newAutoLayoutView];
        self.thanksForTheHintButton.text = NSLocalizedString(@"OkThanksForTheHint", nil);
        self.thanksForTheHintButton.textColor = [UIColor whiteColor];
        self.thanksForTheHintButton.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:24.0f * screenSizeScaleFactor];
        self.thanksForTheHintButton.backgroundColor = [LMColour mainColour];
        self.thanksForTheHintButton.textAlignment = NSTextAlignmentCenter;
        self.thanksForTheHintButton.userInteractionEnabled = YES;
		self.thanksForTheHintButton.layer.masksToBounds = NO;
		self.thanksForTheHintButton.layer.cornerRadius = 8;
		self.thanksForTheHintButton.clipsToBounds = YES;
        [self.contentView addSubview:self.thanksForTheHintButton];
		
		[self.thanksForTheHintButton autoAlignAxisToSuperviewAxis:ALAxisVertical];
        [self.thanksForTheHintButton autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.titleLabel];
        [self.thanksForTheHintButton autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.stopThesePopupsLabel withOffset:-10];
		[self.thanksForTheHintButton autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleLabel withMultiplier:[LMLayoutManager isiPad] ? 1.5 : 2.0];
        
        
        UITapGestureRecognizer *closeTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedCloseButton)];
        [self.thanksForTheHintButton addGestureRecognizer:closeTapGestureRecognizer];
        
        if(self.icon){
            self.iconView = [UIImageView newAutoLayoutView];
            self.iconView.image = self.icon;
            self.iconView.contentMode = UIViewContentModeScaleAspectFit;
            [self.contentView addSubview:self.iconView];
            
            [self.iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:(1.0/4.0)];
            [self.iconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.contentView withMultiplier:(1.0/4.0)];
			[self.iconView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
            [self.iconView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
        }
        
        self.descriptionLabel = [UILabel newAutoLayoutView];
        self.descriptionLabel.text = self.descriptionText;
        self.descriptionLabel.textColor = [UIColor blackColor];
        self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f * screenSizeScaleFactor];
        self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
        self.descriptionLabel.numberOfLines = 0;
        [self.contentView addSubview:self.descriptionLabel];
		
//		[self.descriptionLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
        if(self.icon){
            [self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.iconView withOffset:15];
        }
        else{
            [self.descriptionLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleLabel];
        }
		[self.descriptionLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleLabel];
		[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
        [self.descriptionLabel autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.thanksForTheHintButton withOffset:-20];
        
        [UIView animateWithDuration:0.5 animations:^{
            self.contentViewBackground.alpha = 1;
            self.backgroundBlurView.effect = blurEffect;
        }];
    }
}

@end
