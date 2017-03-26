//
//  LMCoreNavigationController.m
//  Lignite Music
//
//  Created by Edwin Finch on 2017-03-26.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <ApIdleManager/APIdleManager.h>

#import "LMCoreNavigationController.h"

@interface LMCoreNavigationController ()

@end

@implementation LMCoreNavigationController

- (void)viewDidLoad {
    [super viewDidLoad];
    // Do any additional setup after loading the view.
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (UIResponder *)nextResponder {
    [[APIdleManager sharedInstance] didReceiveInput];
    return [super nextResponder];
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
