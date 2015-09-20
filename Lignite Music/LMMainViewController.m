//
//  LMMainViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 9/20/15.
//  Copyright © 2015 Lignite. All rights reserved.
//

#import "LMMainViewController.h"
#import "LMNowPlayingView.h"

@interface LMMainViewController ()

@end

@implementation LMMainViewController

- (void)viewDidLoad {
    [super viewDidLoad];
    
    UILabel *testLabel = [[UILabel alloc]initWithFrame:CGRectMake(0, 0, self.view.frame.size.width, 30)];
    testLabel.text = @"Memememememememememe";
    [self.view addSubview:testLabel];
    
    LMNowPlayingView *view = [[LMNowPlayingView alloc]initWithFrame:self.view.frame];
    [view viewDidLoad];
    view.userInteractionEnabled = YES;
    [self.view addSubview:view];
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
