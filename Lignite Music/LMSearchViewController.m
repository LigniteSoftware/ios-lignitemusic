//
//  LMSearchViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/7/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMSearchViewController.h"
#import "LMSearchView.h"

@interface LMSearchViewController ()

@property LMSearchView *searchView;

@end

@implementation LMSearchViewController

- (void)viewDidLoad {
	[super viewDidLoad];
	// Do any additional setup after loading the view.
	
	self.searchView = [LMSearchView newAutoLayoutView];
	[self.view addSubview:self.searchView];
	
	[self.searchView autoPinEdgesToSuperviewEdges];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	// Dispose of any resources that can be recreated.
}

- (void)loadView {
	NSLog(@"Load search view controller's view");
	
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
