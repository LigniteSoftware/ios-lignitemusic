//
//  LMContactViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/27/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMContactViewController.h"
#import "LMContactView.h"

@interface LMContactViewController ()

@property LMContactView *contactView;

@end

@implementation LMContactViewController

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
	
	self.contactView = [LMContactView newAutoLayoutView];
	[self.view addSubview:self.contactView];
	
	[self.contactView autoPinEdgesToSuperviewEdges];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (void)loadView {
	self.view = [UIView new];
}

@end
