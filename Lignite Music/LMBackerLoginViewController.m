//
//  LMBackerLoginViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 12/16/16.
//  Copyright © 2016 Lignite. All rights reserved.
//

#import <sys/utsname.h>
#import <AFNetworking/AFNetworking.h>
#import <PureLayout/PureLayout.h>
#import <MBProgressHUD/MBProgressHUD.h>
#import "LMBackerLoginViewController.h"
#import "LMScrollView.h"
#import "LMPaddedTextField.h"
#import "LMColour.h"
#import "LMAppIcon.h"
#import "LMDebugViewController.h"
#import "LMSettings.h"
#import "LMAlertView.h"
#import "LMPurchaseManager.h"
#import "LMAnswers.h"
#import "NSTimer+Blocks.h"

@interface LMBackerLoginViewController () <UITextFieldDelegate, UITextViewDelegate>

/**
 The root view so we can adjust for the keyboard.
 */
@property UIView *rootView;

/**
 The height constraint for the root view.
 */
@property NSLayoutConstraint *rootViewHeightConstraint;

/**
 The root scroll view of the feedback view.
 */
@property LMScrollView *scrollView;

/**
 The title label.
 */
@property UILabel *titleLabel;

/**
 The description label for telling the user what's gonna go down.
 */
@property UILabel *descriptionLabel;

/**
 The controls for the bottom.
 */
@property UIView *bottomControlsBackgroundView;

/**
 The view for the send button.
 */
@property UIView *sendButtonView;

/**
 The view for the back button.
 */
@property UIView *backButtonView;

/**
 The text field/views for text entries array.
 */
@property NSMutableArray *textEntryArray;

/**
 The view controller which displays when the feedback sending is pending.
 */
@property UIAlertController *pendingViewController;

/**
 The label/button for seeing all reports.
 */
@property UILabel *seeAllReportsLabel;

@end

@implementation LMBackerLoginViewController

- (BOOL)prefersStatusBarHidden {
	return YES;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)scrollToView:(UIView*)view {
	view = [self.textEntryArray objectAtIndex:0];
	[self.scrollView setContentOffset:CGPointMake(0, view.frame.origin.y-40) animated:YES];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
	[self scrollToView:textField];
}

- (void)textViewDidBeginEditing:(UITextView *)textView {
	[self scrollToView:textView];
}

- (void)keyboardWillShow:(NSNotification*)notification {
	NSDictionary *info = notification.userInfo;
	NSValue *value = [info objectForKey:UIKeyboardFrameEndUserInfoKey];
	
	CGRect keyboardFrame = [value CGRectValue];
	
	[self.view layoutIfNeeded];
	self.rootViewHeightConstraint.constant = -keyboardFrame.size.height;
	
	[UIView animateWithDuration:0.25 animations:^{
		[self.view layoutIfNeeded];
	}];
}

- (void)keyboardWillHide:(NSNotification*)notification {
	[self.view layoutIfNeeded];
	self.rootViewHeightConstraint.constant = 0;
	[UIView animateWithDuration:0.25 animations:^{
		[self.view layoutIfNeeded];
	}];
	
	[self.scrollView setContentOffset:CGPointMake(0, 0) animated:YES];
}

//http://stackoverflow.com/questions/3139619/check-that-an-email-address-is-valid-on-ios
- (BOOL)validEmail:(NSString*)checkString {
	BOOL stricterFilter = NO;
	NSString *stricterFilterString = @"^[A-Z0-9a-z\\._%+-]+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2,4}$";
	NSString *laxString = @"^.+@([A-Za-z0-9-]+\\.)+[A-Za-z]{2}[A-Za-z]*$";
	NSString *emailRegex = stricterFilter ? stricterFilterString : laxString;
	NSPredicate *emailTest = [NSPredicate predicateWithFormat:@"SELF MATCHES %@", emailRegex];
	return [emailTest evaluateWithObject:checkString];
}

- (void)dismissKeyboard {
	[self.view endEditing:YES];
}

- (NSString*)jsonStringWithDictionary:(NSDictionary*)dictionary prettyPrint:(BOOL)prettyPrint {
	NSError *error;
	NSData *jsonData = [NSJSONSerialization dataWithJSONObject:dictionary
													   options:(NSJSONWritingOptions)(prettyPrint ? NSJSONWritingPrettyPrinted : 0)
														 error:&error];
	
	if (!jsonData) {
		NSLog(@"jsonStringWithDictionary: error: %@", error.localizedDescription);
		return @"{}";
	} else {
		return [[NSString alloc] initWithData:jsonData encoding:NSUTF8StringEncoding];
	}
}

NSString* backerDeviceName(){
	struct utsname systemInfo;
	uname(&systemInfo);
	
	return [NSString stringWithCString:systemInfo.machine
							  encoding:NSUTF8StringEncoding];
}

- (void)sendFeedback {
	NSString *emailText = [[self.textEntryArray objectAtIndex:0] text];
	NSString *passwordText = [[self.textEntryArray objectAtIndex:1] text];

	NSString *errorText = nil;
	
	NSNumberFormatter *formatter = [NSNumberFormatter new];
	formatter.numberStyle = NSNumberFormatterDecimalStyle;
	NSNumber *passwordNumber = [formatter numberFromString:passwordText];
	
	if(![self validEmail:emailText]){
		errorText = @"EnterAValidEmail";
	}
	if(!passwordNumber){
		errorText = @"EnterAValidPassword";
	}
	
	if(errorText){
		UIAlertController *alert = [UIAlertController
									alertControllerWithTitle:NSLocalizedString(@"OhBoy", nil)
									message:[NSString stringWithFormat:@"\n%@\n", NSLocalizedString(errorText, nil)]
									preferredStyle:UIAlertControllerStyleAlert];
		
		UIAlertAction *yesButton = [UIAlertAction
									actionWithTitle:NSLocalizedString(@"Okay", nil)
									style:UIAlertActionStyleDefault
									handler:nil];
		
		[alert addAction:yesButton];
		
		NSArray *viewArray = [[[[[[[[[[[[alert view] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews] firstObject] subviews]; //lol
		//		UILabel *alertTitle = viewArray[0];
		UILabel *alertMessage = viewArray[1];
		alertMessage.textAlignment = NSTextAlignmentLeft;
		
		[self presentViewController:alert animated:YES completion:nil];
	}
	else{
		[self dismissKeyboard];
		
		//http://stackoverflow.com/a/32518540/5883707
		self.pendingViewController = [UIAlertController alertControllerWithTitle:nil
																		 message:[NSString stringWithFormat:@"%@\n\n\n", NSLocalizedString(@"LoggingYouIn", nil)]
																  preferredStyle:UIAlertControllerStyleAlert];
		UIActivityIndicatorView* indicator = [[UIActivityIndicatorView alloc] initWithActivityIndicatorStyle:UIActivityIndicatorViewStyleWhiteLarge];
		indicator.color = [UIColor blackColor];
		indicator.translatesAutoresizingMaskIntoConstraints = NO;
		[self.pendingViewController.view addSubview:indicator];
		NSDictionary * views = @{ @"pending": self.pendingViewController.view,
								  @"indicator": indicator };
		
		NSArray *constraintsVertical = [NSLayoutConstraint constraintsWithVisualFormat:@"V:[indicator]-(20)-|" options:0 metrics:nil views:views];
		NSArray *constraintsHorizontal = [NSLayoutConstraint constraintsWithVisualFormat:@"H:|[indicator]|" options:0 metrics:nil views:views];
		NSArray *constraints = [constraintsVertical arrayByAddingObjectsFromArray:constraintsHorizontal];
		[self.pendingViewController.view addConstraints:constraints];
		
		[indicator setUserInteractionEnabled:NO];
		[indicator startAnimating];
		
		[self presentViewController:self.pendingViewController animated:YES completion:nil];
		[NSTimer scheduledTimerWithTimeInterval:1.0 block:^{
			NSDictionary *loginDictionary = @{
												@"email": emailText,
												@"password": @([passwordNumber integerValue]),
												@"device": backerDeviceName()
												 };
			
			NSLog(@"%@", loginDictionary);
			
			NSString *URLString = @"https://api.lignite.me:1212/login";
			NSURLRequest *urlRequest = [[AFJSONRequestSerializer serializer] requestWithMethod:@"POST" URLString:URLString parameters:loginDictionary error:nil];
			
			NSURLSessionConfiguration *configuration = [NSURLSessionConfiguration defaultSessionConfiguration];
			AFURLSessionManager *manager = [[AFURLSessionManager alloc] initWithSessionConfiguration:configuration];
			
			AFHTTPResponseSerializer *responseSerializer = manager.responseSerializer;
			
			responseSerializer.acceptableContentTypes = [responseSerializer.acceptableContentTypes setByAddingObject:@"text/plain"];
			
			NSURLSessionDataTask *dataTask = [manager dataTaskWithRequest:urlRequest completionHandler:^(NSURLResponse *response, id responseObject, NSError *error) {
				if (error) {
					NSLog(@"Error logging in: %@", error);
					
					[self dismissViewControllerAnimated:YES completion:^{
						UIAlertController *alert = [UIAlertController
													alertControllerWithTitle:NSLocalizedString(@"CantLoginTitle", nil)
													message:NSLocalizedString(@"CantLoginDescription", nil)
													preferredStyle:UIAlertControllerStyleAlert];
						
						UIAlertAction *yesButton = [UIAlertAction
													actionWithTitle:NSLocalizedString(@"ContactUs", nil)
													style:UIAlertActionStyleDefault
													handler:^(UIAlertAction *action) {
														dispatch_async(dispatch_get_main_queue(), ^{
															NSString *errorString = [NSString stringWithFormat:@"Hey guys,\n\nI'm trying to login and it's not working!\n\nThe error says '%@'.\n\nMy login details:\n%@.\n\nThanks!", error, loginDictionary];
															
															NSString *recipients = [NSString stringWithFormat:@"mailto:contact@lignite.io?subject=%@&body=%@",
																					[@"Can't login to Lignite Music" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
																					[errorString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
															//															recipients = [recipients stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
															NSLog(@"Can open %@ %d", recipients, [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:recipients]]);
															
															[[UIApplication sharedApplication] openURL:[NSURL URLWithString:recipients] options:@{} completionHandler:^(BOOL success) {
																NSLog(@"Done %d", success);
															}];
														});
													}];
						
						UIAlertAction *nopeButton = [UIAlertAction
													 actionWithTitle:NSLocalizedString(@"DoNothing", nil)
													 style:UIAlertActionStyleCancel
													 handler:^(UIAlertAction *action) {
														 
													 }];
						
						[alert addAction:yesButton];
						[alert addAction:nopeButton];
						
						[self presentViewController:alert animated:YES completion:nil];
					}];
					
					[LMAnswers logLoginWithMethod:@"Backer"
										success:@NO
							   customAttributes:@{ @"email":emailText, @"error": error }];
				} else {
					NSLog(@"%@ %@", response, [[responseObject class] description]);
					
					NSDictionary *jsonDictionary = responseObject;
					
					NSLog(@"Response dict %@", jsonDictionary);
					
					NSInteger statusCode = [[jsonDictionary objectForKey:@"status"] integerValue];
					
					if(statusCode == 200){ //Good to go
						[self dismissViewControllerAnimated:YES completion:^{
							MBProgressHUD *hud = [MBProgressHUD showHUDAddedTo:self.view animated:YES];
							
							hud.mode = MBProgressHUDModeCustomView;
							UIImage *image = [[UIImage imageNamed:@"icon_checkmark.png"] imageWithRenderingMode:UIImageRenderingModeAlwaysTemplate];
							hud.customView = [[UIImageView alloc] initWithImage:image];
							hud.square = YES;
							hud.label.text = NSLocalizedString(@"LoggedIn", nil);
							
							[hud hideAnimated:YES afterDelay:2.0f];
							
							[[LMPurchaseManager sharedPurchaseManager] setBackerDetailsWithEmail:emailText
																						password:[passwordNumber integerValue]
																					sessionToken:[[jsonDictionary objectForKey:@"session"] objectForKey:@"token"]];
							
							[NSTimer scheduledTimerWithTimeInterval:2.25 block:^() {
								[self closeView];
							} repeats:NO];
							
							[LMAnswers logLoginWithMethod:@"Backer"
												success:@YES
									   customAttributes:@{ @"email":emailText }];
						}];
					}
					else if(statusCode == 420){ //Account usage hit
						[self dismissViewControllerAnimated:YES completion:^{
							LMAlertView *alertView = [LMAlertView newAutoLayoutView];
							
							alertView.title = NSLocalizedString(@"LoginsAllUsedUpTitle", nil);
							alertView.body = [NSString stringWithFormat:NSLocalizedString(@"LoginsAllUsedUpDescription", nil), (int)[[jsonDictionary objectForKey:@"sessionsLimit"] integerValue]];
							alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
							alertView.alertOptionTitles = @[NSLocalizedString(@"DoNothing", nil), NSLocalizedString(@"ManageAccounts", nil)];
							
							[alertView launchOnView:self.view withCompletionHandler:^(NSUInteger optionSelected) {
								if(optionSelected == 1){
									[[UIApplication sharedApplication] openURL:
										[NSURL URLWithString:[NSString stringWithFormat:@"https://www.lignite.io/logins/%@/%d",
															  [loginDictionary objectForKey:@"email"],
															  [[loginDictionary objectForKey:@"password"] intValue]]]];
								}
							}];
						}];
						
						[LMAnswers logLoginWithMethod:@"Backer"
											success:@NO
								   customAttributes:@{ @"email":emailText, @"error": @"Out of sessions", @"outOfSessions":@YES }];
					}
					else if(statusCode == 401){ //User not found or mutiple accounts
						[self dismissViewControllerAnimated:YES completion:^{
							LMAlertView *alertView = [LMAlertView newAutoLayoutView];
							
							alertView.title = NSLocalizedString(@"AccountNotFoundTitle", nil);
							alertView.body = NSLocalizedString(@"AccountNotFoundDescription", nil);
							alertView.alertOptionColours = @[[LMColour darkLigniteRedColour], [LMColour ligniteRedColour]];
							alertView.alertOptionTitles = @[NSLocalizedString(@"DoNothing", nil), NSLocalizedString(@"INeedHelpLoggingIn", nil)];
							
							[alertView launchOnView:self.view withCompletionHandler:^(NSUInteger optionSelected) {
								if(optionSelected == 1){
									[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.lignitemusic.com/help/"]];
								}
							}];
						}];
						
						[LMAnswers logLoginWithMethod:@"Backer"
											success:@NO
								   customAttributes:@{ @"email":emailText, @"error": @"User not found" }];
					}
					else{
						[self dismissViewControllerAnimated:YES completion:^{
							UIAlertController *alert = [UIAlertController
														alertControllerWithTitle:NSLocalizedString(@"CantLoginTitle", nil)
														message:NSLocalizedString(@"CantLoginDescription", nil)
														preferredStyle:UIAlertControllerStyleAlert];
							
							UIAlertAction *yesButton = [UIAlertAction
														actionWithTitle:NSLocalizedString(@"ContactUs", nil)
														style:UIAlertActionStyleDefault
														handler:^(UIAlertAction *action) {
															dispatch_async(dispatch_get_main_queue(), ^{
																NSString *errorString = [NSString stringWithFormat:@"Hey guys,\n\nI'm trying to login and it's not working!\n\nThe error says '%@'.\n\nMy login details:\n%@\n\nThanks!", [NSString stringWithFormat:@"internalError%d", (int)statusCode], loginDictionary];
																
																NSString *recipients = [NSString stringWithFormat:@"mailto:contact@lignite.io?subject=%@&body=%@",
																						[@"Can't login to Lignite Music" stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]],
																						[errorString stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]]];
																//															recipients = [recipients stringByAddingPercentEncodingWithAllowedCharacters:[NSCharacterSet URLHostAllowedCharacterSet]];
																NSLog(@"Can open %@ %d", recipients, [[UIApplication sharedApplication] canOpenURL:[NSURL URLWithString:recipients]]);
																
																[[UIApplication sharedApplication] openURL:[NSURL URLWithString:recipients] options:@{} completionHandler:^(BOOL success) {
																	NSLog(@"Done %d", success);
																}];
															});
														}];
							
							UIAlertAction *nopeButton = [UIAlertAction
														 actionWithTitle:NSLocalizedString(@"DoNothing", nil)
														 style:UIAlertActionStyleCancel
														 handler:^(UIAlertAction *action) {
															 
														 }];
							
							[alert addAction:yesButton];
							[alert addAction:nopeButton];
							
							[self presentViewController:alert animated:YES completion:nil];
						}];
						
						[LMAnswers logLoginWithMethod:@"Backer"
											success:@NO
								   customAttributes:@{ @"email":emailText, @"error": [NSString stringWithFormat:@"Unknown server error %d", (int)statusCode] }];
					}
				}
			}];
			[dataTask resume];
		} repeats:NO];
	}
}

- (void)closeView {
	NSLog(@"Hey there!!");
	[self dismissViewControllerAnimated:YES completion:nil];
}

- (void)seeAllReportsTapped {
	[[UIApplication sharedApplication] openURL:[NSURL URLWithString:@"http://www.lignitemusic.com/help/"]];
}

- (void)viewDidLoad {
	[super viewDidLoad];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillShow:)
												 name:UIKeyboardWillShowNotification
											   object:nil];
	
	[[NSNotificationCenter defaultCenter] addObserver:self
											 selector:@selector(keyboardWillHide:)
												 name:UIKeyboardWillHideNotification
											   object:nil];
	
	
	self.rootView = [UIView newAutoLayoutView];
	[self.view addSubview:self.rootView];
	
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.rootView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	self.rootViewHeightConstraint = [self.rootView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	
	self.bottomControlsBackgroundView = [UIView newAutoLayoutView];
	self.bottomControlsBackgroundView.backgroundColor = [UIColor whiteColor];
	[self.rootView addSubview:self.bottomControlsBackgroundView];
	
	[self.bottomControlsBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.bottomControlsBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.bottomControlsBackgroundView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.bottomControlsBackgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/8.0)];
	
	self.sendButtonView = [UIView newAutoLayoutView];
	self.sendButtonView.backgroundColor = [LMColour ligniteRedColour];
	[self.bottomControlsBackgroundView addSubview:self.sendButtonView];
	
	[self.sendButtonView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.sendButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.sendButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.sendButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.bottomControlsBackgroundView withMultiplier:(1.0/2.0)].constant = -1;
	
	UITapGestureRecognizer *sendButtonTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(sendFeedback)];
	[self.sendButtonView addGestureRecognizer:sendButtonTap];
	
	UIImageView *sendButtonIcon = [UIImageView newAutoLayoutView];
	sendButtonIcon.contentMode = UIViewContentModeScaleAspectFit;
	sendButtonIcon.image = [LMAppIcon imageForIcon:LMIconWhiteCheckmark];
	[self.sendButtonView addSubview:sendButtonIcon];
	
	[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[sendButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[sendButtonIcon autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[sendButtonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomControlsBackgroundView withMultiplier:(1.0/3.0)];
	
	self.backButtonView = [UIView newAutoLayoutView];
	self.backButtonView.backgroundColor = [LMColour ligniteRedColour];
	[self.bottomControlsBackgroundView addSubview:self.backButtonView];
	
	[self.backButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.backButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.backButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.backButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.bottomControlsBackgroundView withMultiplier:(1.0/2.0)].constant = -1;
	
	UITapGestureRecognizer *backButtonTap = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeView)];
	[self.backButtonView addGestureRecognizer:backButtonTap];
	
	UIImageView *backButtonIcon = [UIImageView newAutoLayoutView];
	backButtonIcon.contentMode = UIViewContentModeScaleAspectFit;
	backButtonIcon.image = [LMAppIcon imageForIcon:LMIconBack];
	[self.backButtonView addSubview:backButtonIcon];
	
	[backButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[backButtonIcon autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[backButtonIcon autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[backButtonIcon autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.bottomControlsBackgroundView withMultiplier:(1.0/3.0)];
	
	
	self.scrollView = [LMScrollView newAutoLayoutView];
	self.scrollView.backgroundColor = [UIColor whiteColor];
	self.scrollView.keyboardDismissMode = UIScrollViewKeyboardDismissModeOnDrag;
	self.scrollView.scrollEnabled = NO;
	[self.rootView addSubview:self.scrollView];
	
	UITapGestureRecognizer *dismissKeyboardOnScrollTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(dismissKeyboard)];
	[self.scrollView addGestureRecognizer:dismissKeyboardOnScrollTapGesture];
	
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.scrollView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.scrollView autoPinEdge:ALEdgeBottom toEdge:ALEdgeTop ofView:self.bottomControlsBackgroundView];
	
	self.titleLabel = [UILabel newAutoLayoutView];
	self.titleLabel.numberOfLines = 0;
	self.titleLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0f];
	self.titleLabel.text = NSLocalizedString(@"BackerLoginTitle", nil);
	self.titleLabel.textAlignment = NSTextAlignmentLeft;
	[self.scrollView addSubview:self.titleLabel];
	
	[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
	[self.titleLabel autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:20];
	
	
	self.descriptionLabel = [UILabel newAutoLayoutView];
	self.descriptionLabel.numberOfLines = 0;
	self.descriptionLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:20.0f];
	self.descriptionLabel.text = NSLocalizedString(@"BackerLoginDescription", nil);
	self.descriptionLabel.textAlignment = NSTextAlignmentLeft;
	[self.scrollView addSubview:self.descriptionLabel];
	
	[self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:20];
	[self.descriptionLabel autoPinEdgeToSuperviewEdge:ALEdgeTrailing withInset:20];
	[self.descriptionLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleLabel withOffset:20];
	
	NSMutableArray *viewsArray = [NSMutableArray new];
	
	NSArray *textKeys = @[
						  @"Email",
						  @"Password"
						  ];
	
	UIKeyboardType keyboardTypes[] = {
		UIKeyboardTypeEmailAddress, UIKeyboardTypeNumberPad
	};
	
	for(int i = 0; i < textKeys.count; i++){
		BOOL isFirst = (i == 0);
		
		UIView *previousViewToAttachTo = isFirst ? self.descriptionLabel : [viewsArray lastObject];
		
		NSString *text = NSLocalizedString([textKeys objectAtIndex:i], nil);
		
		UILabel *textLabel = [UILabel newAutoLayoutView];
		textLabel.text = text;
		textLabel.font = [UIFont fontWithName:@"HelveticaNeue-Bold" size:20.0];
		textLabel.numberOfLines = 0;
		textLabel.textAlignment = NSTextAlignmentLeft;
		[self.scrollView addSubview:textLabel];
		
		[textLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:previousViewToAttachTo];
		[textLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:previousViewToAttachTo];
		[textLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
		[textLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:previousViewToAttachTo withOffset:20];
		
		if([[textKeys objectAtIndex:i] isEqualToString:@"DetailedReport"]){
			UITextView *textView = [UITextView newAutoLayoutView];
			textView.textColor = [UIColor blackColor];
			textView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0];
			textView.textContainerInset = UIEdgeInsetsMake(10, 10, 10, 10);
			textView.keyboardType = UIKeyboardTypeDefault;
			textView.returnKeyType = UIReturnKeyDone;
			textView.backgroundColor = [UIColor colorWithRed:0.91 green:0.90 blue:0.91 alpha:1.0];
			textView.clipsToBounds = YES;
			textView.layer.masksToBounds = YES;
			textView.layer.cornerRadius = 0;
			textView.delegate = self;
			[self.scrollView addSubview:textView];
			
			[textView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:previousViewToAttachTo];
			[textView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:previousViewToAttachTo];
			[textView autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[textView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textLabel withOffset:10];
			[textView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(2.0/8.0)];
			
			[viewsArray addObject:textView];
		}
		else{
			LMPaddedTextField *textField = [LMPaddedTextField newAutoLayoutView];
			textField.textColor = [UIColor blackColor];
			textField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0];
			textField.delegate = self;
			textField.keyboardType = keyboardTypes[i];
			textField.returnKeyType = UIReturnKeyDone;
			textField.backgroundColor = [UIColor colorWithRed:0.91 green:0.90 blue:0.91 alpha:1.0];
			textField.clipsToBounds = YES;
			textField.layer.masksToBounds = YES;
			textField.layer.cornerRadius = 0;
			[self.scrollView addSubview:textField];
			
			[textField autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:previousViewToAttachTo];
			[textField autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:previousViewToAttachTo];
			[textField autoAlignAxisToSuperviewAxis:ALAxisVertical];
			[textField autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textLabel withOffset:10];
			[textField autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/11.0)];
			
			[viewsArray addObject:textField];
			
			if(keyboardTypes[i] == UIKeyboardTypeEmailAddress){
				textField.autocapitalizationType = UITextAutocapitalizationTypeNone;
			}
		}
	}
	
	self.textEntryArray = viewsArray;
	
	
	self.seeAllReportsLabel = [UILabel newAutoLayoutView];
	self.seeAllReportsLabel.text = NSLocalizedString(@"INeedHelpLoggingIn", nil);
	self.seeAllReportsLabel.textAlignment = NSTextAlignmentCenter;
	self.seeAllReportsLabel.numberOfLines = 0;
	self.seeAllReportsLabel.layer.masksToBounds = YES;
	self.seeAllReportsLabel.layer.cornerRadius = 0.0;
	self.seeAllReportsLabel.backgroundColor = [LMColour ligniteRedColour];
	self.seeAllReportsLabel.textColor = [UIColor whiteColor];
	self.seeAllReportsLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:22.0f];
	self.seeAllReportsLabel.userInteractionEnabled = YES;
	[self.scrollView addSubview:self.seeAllReportsLabel];
	
	UIView *lastView = [self.textEntryArray lastObject];
	
	[self.seeAllReportsLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:lastView withOffset:20];
	[self.seeAllReportsLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:lastView];
	[self.seeAllReportsLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:lastView];
	[self.seeAllReportsLabel autoAlignAxisToSuperviewAxis:ALAxisVertical];
	[self.seeAllReportsLabel autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(1.0/11.0)];
	
	UITapGestureRecognizer *tapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(seeAllReportsTapped)];
	[self.seeAllReportsLabel addGestureRecognizer:tapGesture];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
	
}

- (void)loadView {
	self.view = [UIView new];
	
	self.view.backgroundColor = [UIColor whiteColor];
}

@end
