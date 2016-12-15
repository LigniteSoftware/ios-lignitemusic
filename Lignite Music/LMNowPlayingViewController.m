//
//  LMContactViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMNowPlayingViewController.h"

@interface LMNowPlayingViewController ()

@end

@implementation LMNowPlayingViewController

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	[self.view addSubview:self.nowPlayingView];
	
	[self.nowPlayingView autoPinEdgesToSuperviewEdges];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
}

- (instancetype)init {
	self = [super init];
	if(self) {
		self.nowPlayingView = [LMNowPlayingView newAutoLayoutView];
		NSLog(@"Spoooook!");
	}
	return self;
}

@end
