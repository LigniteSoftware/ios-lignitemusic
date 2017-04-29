//
//  LMBrowsingDetailViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 11/25/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMBrowsingDetailViewController.h"
#import "LMSettings.h"
#import "LMExtras.h"

@interface LMBrowsingDetailViewController ()

@end

@implementation LMBrowsingDetailViewController

- (BOOL)prefersStatusBarHidden {
	return [self.browsingDetailView.rootViewController prefersStatusBarHidden];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)handlePopGesture:(UIGestureRecognizer *)gesture{
	if(self.navigationController.topViewController == self){
		if(gesture.state == UIGestureRecognizerStateEnded){
			self.browsingDetailView.rootViewController.itemPopped = self.browsingDetailView.rootViewController.navigationBar.topItem;
			[self.browsingDetailView.rootViewController.navigationBar popNavigationItemAnimated:YES];
		}
	}
}

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
		
	[self.view addSubview:self.browsingDetailView];
	
	[self.browsingDetailView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.browsingDetailView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.browsingDetailView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.browsingDetailView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:64];
	
	[self.browsingDetailView setup];
	
	[self.navigationController.interactivePopGestureRecognizer addTarget:self action:@selector(handlePopGesture:)];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

/*
#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
    // Get the new view controller using [segue destinationViewController].
    // Pass the selected object to the new view controller.
}
*/

@end
