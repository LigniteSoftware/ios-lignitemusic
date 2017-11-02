//
//  LMEnhancedPlaylistEditorViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/31/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import <BEMCheckBox/BEMCheckBox.h>
#import "LMEnhancedPlaylistEditorViewController.h"
#import "LMColour.h"
#import "LMAppIcon.h"
#import "LMImagePickerView.h"
#import "LMTableView.h"
#import "LMExtras.h"
#import "LMListEntry.h"
#import "LMMusicPlayer.h"
#import "LMBoxWarningView.h"
#import "LMMusicPickerController.h"

@interface LMEnhancedPlaylistEditorViewController ()<LMLayoutChangeDelegate, LMImagePickerViewDelegate, LMMusicPickerDelegate>

/**
 The music player.
 */
@property LMMusicPlayer *musicPlayer;

/**
 The playlist manager.
 */
@property LMPlaylistManager *playlistManager;

/**
 The layout manager.
 */
@property LMLayoutManager *layoutManager;

/**
 The image picker view.
 */
@property LMImagePickerView *imagePickerView;

/**
 The text field for the title of the playlist.
 */
@property UITextField *titleTextField;

/**
 The song count label.
 */
@property UILabel *songCountLabel;

/**
 The warning box for letting users know of problematic constraints or a lack of thereof.
 */
@property LMBoxWarningView *warningBoxView;

/**
 The checkbox for whether or not the user wants all of the songs shuffled or in order.
 */
@property BEMCheckBox *shuffleAllCheckbox;

/**
 The background view to the "want to hear" section
 */
@property UIView *wantToHearBackgroundView;

/**
 The label for what the user wants to hear.
 */
@property UILabel *wantToHearLabel;

/**
 The add songs button for the want to hear section.
 */
@property UIView *wantToHearAddSongsButtonView;

/**
 The background view to the "don't want to hear" section
 */
@property UIView *dontWantToHearBackgroundView;

/**
 The label for what the user doesn't want to hear.
 */
@property UILabel *dontWantToHearLabel;

/**
 The add songs button for the don't want to hear section.
 */
@property UIView *dontWantToHearAddSongsButtonView;

/**
 The music picker controller for getting conditions for either what the user wants to hear or doesn't want to hear.
 */
@property LMMusicPickerController *conditionsMusicPickerController;

/**
 If the conditions music picker is picking for music the user wants to hear.
 */
@property BOOL isPickingWantToHear;

/**
 The playlist that this enhanced playlist editor is handling.
 */
@property LMPlaylist *playlist;

@end

@implementation LMEnhancedPlaylistEditorViewController

/* Begin image picker code */

- (void)imagePickerView:(LMImagePickerView *)imagePickerView wantsToPresentViewController:(UIViewController *)viewController {
	[self presentViewController:viewController animated:YES completion:nil];
}

- (void)imagePickerView:(LMImagePickerView *)imagePickerView didFinishPickingImage:(UIImage *)image {
	self.playlist.image = image;
}

- (void)imagePickerView:(LMImagePickerView *)imagePickerView deletedImage:(UIImage *)image {
	self.playlist.image = nil;
}

/* End image picker code */


- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator	{
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		[self.songListTableView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
//		[self.songListTableView reloadData];
	}];
}


- (void)cancelPlaylistEditing {
	NSLog(@"Cancel enhanced playlist");
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if([self.delegate respondsToSelector:@selector(enhancedPlaylistEditorViewControllerDidCancel:)]){
		[self.delegate enhancedPlaylistEditorViewControllerDidCancel:self];
	}
}

- (void)savePlaylistEditing {
	NSLog(@"Save enhanced playlist");
	
	self.playlist.title = self.titleTextField.text;
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.playlistManager savePlaylist:self.playlist];

	NSLog(@"Saved.");
	
	if([self.delegate respondsToSelector:@selector(enhancedPlaylistEditorViewController:didSaveWithPlaylist:)]){
		[self.delegate enhancedPlaylistEditorViewController:self didSaveWithPlaylist:self.playlist];
	}
}

- (void)musicPicker:(LMMusicPickerController*)musicPicker didFinishPickingMusicWithTrackCollections:(NSArray<LMMusicTrackCollection*>*)trackCollections {
	
	NSLog(@"Finished with %d collections and %d music types", (int)trackCollections.count, (int)musicPicker.musicTypes.count);
	
	NSMutableDictionary *mutableEnhancedConditionsDictionary = [NSMutableDictionary new];
	if(self.playlist.enhancedConditionsDictionary){
		mutableEnhancedConditionsDictionary = [NSMutableDictionary dictionaryWithDictionary:self.playlist.enhancedConditionsDictionary];
	}
	
	NSMutableArray *persistentIDArray = [NSMutableArray new];
	for(NSInteger i = 0; i < musicPicker.trackCollections.count; i++){
		LMMusicTrackCollection *trackCollection = [musicPicker.trackCollections objectAtIndex:i];
		LMMusicType musicType = (LMMusicType)[[musicPicker.musicTypes objectAtIndex:i] integerValue];
		
		[persistentIDArray addObject:
		 @([LMMusicPlayer persistentIDForMusicTrackCollection:trackCollection withMusicType:musicType])
		 ];
	}
	
	NSDictionary *toHearDictionary = @{
									   LMEnhancedPlaylistPersistentIDsKey: [NSArray arrayWithArray:persistentIDArray],
									   LMEnhancedPlaylistMusicTypesKey: musicPicker.musicTypes
									   };
	
	[mutableEnhancedConditionsDictionary setObject:toHearDictionary forKey:self.isPickingWantToHear ? LMEnhancedPlaylistWantToHearKey : LMEnhancedPlaylistDontWantToHearKey];
	
	self.playlist.enhancedConditionsDictionary = [NSDictionary dictionaryWithDictionary:mutableEnhancedConditionsDictionary];
	
	NSLog(@"Mutable enhanced %@", self.playlist.enhancedConditionsDictionary);
	
	if(trackCollections.count > 0){
		[self.warningBoxView hide];
	}
	
	[self reloadConditionsLabelAndWarningBox];
}

- (void)addConditionsButtonTapped:(UITapGestureRecognizer*)tapGestureRecognizer {
	self.isPickingWantToHear = (tapGestureRecognizer.view == self.wantToHearAddSongsButtonView);

	
	self.conditionsMusicPickerController = [LMMusicPickerController new];
	self.conditionsMusicPickerController.delegate = self;
	self.conditionsMusicPickerController.selectionMode = LMMusicPickerSelectionModeAllCollections;
	
	
	NSMutableArray *musicTrackCollectionsMutableArray = [NSMutableArray new];
	
	NSDictionary *toHearDictionary =  [self.playlist.enhancedConditionsDictionary objectForKey:self.isPickingWantToHear ? LMEnhancedPlaylistWantToHearKey : LMEnhancedPlaylistDontWantToHearKey];
	
	NSArray *persistentIDsArray = [toHearDictionary objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	NSArray *musicTypesArray = [toHearDictionary objectForKey:LMEnhancedPlaylistMusicTypesKey];
	
	for(NSInteger i = 0; i < persistentIDsArray.count; i++){
		MPMediaEntityPersistentID persistentID = [[persistentIDsArray objectAtIndex:i] longLongValue];
		LMMusicType musicType = (LMMusicType)[[musicTypesArray objectAtIndex:i] integerValue];
		
		NSArray<LMMusicTrackCollection*> *trackCollections = [self.musicPlayer collectionsForPersistentID:persistentID forMusicType:musicType];
		
		NSLog(@"%d items, first having %d for %lld", (int)trackCollections.count, (int)trackCollections.firstObject.count, persistentID);
		
		[musicTrackCollectionsMutableArray addObject:trackCollections.firstObject];
	}

	self.conditionsMusicPickerController.trackCollections = [NSArray arrayWithArray:musicTrackCollectionsMutableArray];
	self.conditionsMusicPickerController.musicTypes = musicTypesArray;
	
	for(LMMusicTrackCollection *collection in musicTrackCollectionsMutableArray){
		NSLog(@"Collection with %d items", (int)collection.count);
	}
	

	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.conditionsMusicPickerController];
	[self presentViewController:navigation animated:YES completion:nil];
	
}

- (void)tappedShuffleAllLabel {
	[self.shuffleAllCheckbox setOn:!self.shuffleAllCheckbox.on animated:YES];
}

- (void)reloadConditionsLabelAndWarningBox {
	NSArray *wantToHearPersistentIDsArray = [[self.playlist.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistWantToHearKey] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	NSArray *dontWantToHearPersistentIDsArray = [[self.playlist.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistDontWantToHearKey] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	
	NSInteger numberOfConditions = (wantToHearPersistentIDsArray.count + dontWantToHearPersistentIDsArray.count);
	
	if(numberOfConditions == 0){
		self.songCountLabel.text = NSLocalizedString(@"NoConditionsYet", nil);
	}
	else if(numberOfConditions == 1){
		self.songCountLabel.text = NSLocalizedString(@"OneCondition", nil);
	}
	else{
		self.songCountLabel.text = [NSString stringWithFormat:NSLocalizedString(@"XConditions", nil), numberOfConditions];
	}
	
	if(numberOfConditions == 0){
		self.warningBoxView.titleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsTitle", nil);
		self.warningBoxView.subtitleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoConditionsDescription", nil);
		
		[self.warningBoxView show];
	}
	else if(wantToHearPersistentIDsArray.count == 0 && dontWantToHearPersistentIDsArray.count > 0){
		self.warningBoxView.titleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoWantsTitle", nil);
		self.warningBoxView.subtitleLabel.text = NSLocalizedString(@"EnhancedPlaylistNoWantsDescription", nil);
		
		[self.warningBoxView show];
	}
}

/* Begin initialization code */

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = NSLocalizedString(@"EnhancedPlaylist", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPlaylistEditing)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(savePlaylistEditing)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.playlistManager = [LMPlaylistManager sharedPlaylistManager];
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	if(!self.playlist){
		self.playlist = [LMPlaylist new];
		self.playlist.enhanced = YES;
		self.playlist.enhancedConditionsDictionary = [NSDictionary new];
	}
	
	
	self.warningBoxView = [LMBoxWarningView newAutoLayoutView];
	[self.view addSubview:self.warningBoxView];
	
	[self.warningBoxView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.warningBoxView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	self.warningBoxView.topToSuperviewConstraint = [self.warningBoxView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:84];
	
	
	self.imagePickerView = [LMImagePickerView newAutoLayoutView];
//	self.imagePickerView.image = self.playlist ? self.playlist.image : nil;
	self.imagePickerView.delegate = self;
	[self.view addSubview:self.imagePickerView];
	
	NSArray *imagePickerViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningBoxView withOffset:18];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.5/10.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewPortraitConstraints:imagePickerViewPortraitConstraints];
	
	NSArray *imagePickerViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningBoxView withOffset:18];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.0/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:imagePickerViewLandscapeConstraints];
	
	
	self.titleTextField = [UITextField newAutoLayoutView];
	self.titleTextField.placeholder = NSLocalizedString(@"YourPlaylistTitle", nil);
//	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
	self.titleTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
	self.titleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	[self.view addSubview:self.titleTextField];
	
	NSArray *titleTextFieldPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.titleTextField autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.titleTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imagePickerView];
		[self.titleTextField autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.imagePickerView withOffset:15];
	}];
	[LMLayoutManager addNewPortraitConstraints:titleTextFieldPortraitConstraints];
	
	NSArray *titleTextFieldLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.titleTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imagePickerView];
		[self.titleTextField autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.imagePickerView withOffset:15];
	}];
	
	NSLayoutConstraint *trailingPinnedToCenterVerticalAxisConstraint
	= [NSLayoutConstraint constraintWithItem:self.titleTextField
								   attribute:NSLayoutAttributeTrailing
								   relatedBy:NSLayoutRelationEqual
									  toItem:self.view
								   attribute:NSLayoutAttributeCenterX
								  multiplier:1.0
									constant:0.0];
	
	NSMutableArray *mutableTextViewLandscapeConstraintsArray = [NSMutableArray arrayWithArray:titleTextFieldLandscapeConstraints];
	[mutableTextViewLandscapeConstraintsArray addObject:trailingPinnedToCenterVerticalAxisConstraint];
	titleTextFieldLandscapeConstraints = [NSArray arrayWithArray:mutableTextViewLandscapeConstraintsArray];
	
	[LMLayoutManager addNewLandscapeConstraints:titleTextFieldLandscapeConstraints];
	
	UIView *textFieldLineView = [UIView newAutoLayoutView];
	textFieldLineView.backgroundColor = [UIColor grayColor];
	[self.view addSubview:textFieldLineView];
	
	[textFieldLineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleTextField withOffset:2];
	[textFieldLineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[textFieldLineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
	[textFieldLineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	
	
	self.songCountLabel = [UILabel newAutoLayoutView];
	self.songCountLabel.text = @"nice work";
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
	self.songCountLabel.textColor = [UIColor blackColor];
	[self.view addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textFieldLineView withOffset:6.0f];
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textFieldLineView];
	[self.songCountLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textFieldLineView];
	
	
	
	self.shuffleAllCheckbox = [BEMCheckBox newAutoLayoutView];
	self.shuffleAllCheckbox.boxType = BEMBoxTypeSquare;
	self.shuffleAllCheckbox.tintColor = [LMColour controlBarGrayColour];
	self.shuffleAllCheckbox.onFillColor = [LMColour ligniteRedColour];
	self.shuffleAllCheckbox.onCheckColor = [UIColor whiteColor];
	self.shuffleAllCheckbox.onTintColor = [LMColour ligniteRedColour];
	self.shuffleAllCheckbox.onAnimationType = BEMAnimationTypeFill;
	self.shuffleAllCheckbox.offAnimationType = BEMAnimationTypeFill;
	[self.view addSubview:self.shuffleAllCheckbox];
	
	[self.shuffleAllCheckbox autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[self.shuffleAllCheckbox autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imagePickerView];
	[self.shuffleAllCheckbox autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.titleTextField];
	[self.shuffleAllCheckbox autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.shuffleAllCheckbox];
	
	UILabel *shuffleAllLabel = [UILabel newAutoLayoutView];
	shuffleAllLabel.text = NSLocalizedString(@"ShuffleAll", nil);
	shuffleAllLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:16.0f];
	shuffleAllLabel.textColor = [UIColor blackColor];
	shuffleAllLabel.userInteractionEnabled = YES;
	[self.view addSubview:shuffleAllLabel];
	
	[shuffleAllLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.shuffleAllCheckbox withOffset:10];
	[shuffleAllLabel autoAlignAxis:ALAxisHorizontal toSameAxisOfView:self.shuffleAllCheckbox];
	
	UITapGestureRecognizer *shuffleAllTextTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(tappedShuffleAllLabel)];
	[shuffleAllLabel addGestureRecognizer:shuffleAllTextTapGestureRecognizer];
	
	
	self.wantToHearBackgroundView = [UIView newAutoLayoutView];
	[self.view addSubview:self.wantToHearBackgroundView];
	
	[self.wantToHearBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView withOffset:22];
	[self.wantToHearBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.wantToHearBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	self.wantToHearAddSongsButtonView = [UIView newAutoLayoutView];
	self.wantToHearAddSongsButtonView.backgroundColor = [LMColour darkGrayColour];
	self.wantToHearAddSongsButtonView.layer.masksToBounds = YES;
	self.wantToHearAddSongsButtonView.layer.cornerRadius = 6.0f;
	[self.wantToHearBackgroundView addSubview:self.wantToHearAddSongsButtonView];
	
	UITapGestureRecognizer *wantToHearTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addConditionsButtonTapped:)];
	[self.wantToHearAddSongsButtonView addGestureRecognizer:wantToHearTapGestureRecognizer];
	
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.wantToHearAddSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(2.0/40.0)];
	[self.wantToHearAddSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.wantToHearAddSongsButtonView];
	
	UIImageView *addSongsIconImageView = [UIImageView newAutoLayoutView];
	addSongsIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	addSongsIconImageView.image = [LMAppIcon imageForIcon:LMIconAdd];
	[self.wantToHearAddSongsButtonView addSubview:addSongsIconImageView];
	
	[addSongsIconImageView autoCenterInSuperview];
	[addSongsIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.wantToHearAddSongsButtonView withMultiplier:(5.0/10.0)];
	[addSongsIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:addSongsIconImageView];
	
	
	self.wantToHearLabel = [UILabel newAutoLayoutView];
	self.wantToHearLabel.text = NSLocalizedString(@"WantToHearTitle", nil);
	self.wantToHearLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:22.0f];
	self.wantToHearLabel.textColor = [UIColor blackColor];
	self.wantToHearLabel.textAlignment = NSTextAlignmentLeft;
	[self.wantToHearBackgroundView addSubview:self.wantToHearLabel];

	[self.wantToHearLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.wantToHearLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.wantToHearLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.wantToHearAddSongsButtonView];
	
	
	
	self.dontWantToHearBackgroundView = [UIView newAutoLayoutView];
	[self.view addSubview:self.dontWantToHearBackgroundView];
	
	[self.dontWantToHearBackgroundView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.wantToHearBackgroundView withOffset:22];
	[self.dontWantToHearBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.dontWantToHearBackgroundView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	self.dontWantToHearAddSongsButtonView = [UIView newAutoLayoutView];
	self.dontWantToHearAddSongsButtonView.backgroundColor = [LMColour darkGrayColour];
	self.dontWantToHearAddSongsButtonView.layer.masksToBounds = YES;
	self.dontWantToHearAddSongsButtonView.layer.cornerRadius = 6.0f;
	[self.dontWantToHearBackgroundView addSubview:self.dontWantToHearAddSongsButtonView];
	
	UITapGestureRecognizer *dontWantToHearTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addConditionsButtonTapped:)];
	[self.dontWantToHearAddSongsButtonView addGestureRecognizer:dontWantToHearTapGestureRecognizer];
	
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.dontWantToHearAddSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(2.0/40.0)];
	[self.dontWantToHearAddSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.dontWantToHearAddSongsButtonView];
	
	UIImageView *addSongsDontWantIconImageView = [UIImageView newAutoLayoutView];
	addSongsDontWantIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	addSongsDontWantIconImageView.image = [LMAppIcon imageForIcon:LMIconAdd];
	[self.dontWantToHearAddSongsButtonView addSubview:addSongsDontWantIconImageView];
	
	[addSongsDontWantIconImageView autoCenterInSuperview];
	[addSongsDontWantIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.dontWantToHearAddSongsButtonView withMultiplier:(5.0/10.0)];
	[addSongsDontWantIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:addSongsIconImageView];
	
	
	self.dontWantToHearLabel = [UILabel newAutoLayoutView];
	self.dontWantToHearLabel.text = NSLocalizedString(@"DontWantToHearTitle", nil);
	self.dontWantToHearLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:22.0f];
	self.dontWantToHearLabel.textColor = [UIColor blackColor];
	self.dontWantToHearLabel.textAlignment = NSTextAlignmentLeft;
	[self.dontWantToHearBackgroundView addSubview:self.dontWantToHearLabel];
	
	[self.dontWantToHearLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.dontWantToHearLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.dontWantToHearLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.dontWantToHearAddSongsButtonView];
	
	[self reloadConditionsLabelAndWarningBox];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

/* End initialization code */

@end
