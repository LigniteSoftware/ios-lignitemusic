//
//  LMPurchaseViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/19/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPurchaseViewController.h"

@interface LMPurchaseViewController ()

/**
 The background (tiled) image view.
 */
@property UIImageView *backgroundImageView;

@end

@implementation LMPurchaseViewController

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.backgroundImageView = [UIImageView newAutoLayoutView];
	self.backgroundImageView.contentMode = UIViewContentModeScaleAspectFit;
	self.backgroundImageView.image = [UIImage imageNamed:@"lignite_background_portrait.png"];
	[self.view addSubview:self.backgroundImageView];
	
	[self.backgroundImageView autoPinEdgesToSuperviewEdges];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
