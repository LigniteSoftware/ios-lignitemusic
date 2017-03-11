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

@property NSLayoutConstraint *browsingDetailViewHeightConstraint;

@end

@implementation LMBrowsingDetailViewController

@synthesize requiredHeight = _requiredHeight;

- (float)requiredHeight {
	return _requiredHeight;
}

- (void)setRequiredHeight:(float)requiredHeight {
	_requiredHeight = requiredHeight;
	
	NSLog(@"Setting required height to %f", requiredHeight);
	
	if(self.browsingDetailViewHeightConstraint){
		[self.view layoutIfNeeded];
		
		self.browsingDetailViewHeightConstraint.constant = requiredHeight;
		
		[UIView animateWithDuration:(WINDOW_FRAME.size.height/4 * 3 < requiredHeight) ? 0.10 : 0.75 animations:^{
			[self.view layoutIfNeeded];
		}];
	}
}

- (BOOL)prefersStatusBarHidden {
	return ![LMSettings shouldShowStatusBar];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
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
