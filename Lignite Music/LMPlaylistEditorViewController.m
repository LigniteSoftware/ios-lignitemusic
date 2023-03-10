//
//  LMPlaylistEditorViewController.m
//  Lignite Music
//
//  Created by Edwin Finch on 10/22/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <PureLayout/PureLayout.h>
#import "LMPlaylistEditorViewController.h"
#import "LMColour.h"
#import "LMAppIcon.h"
#import "LMImagePickerView.h"
#import "LMTableView.h"
#import "LMExtras.h"
#import "LMListEntry.h"
#import "LMMusicPlayer.h"
#import "LMMusicPickerController.h"
#import "LMMusicPickerNavigationController.h"
#import "NSTimer+Blocks.h"
#import "LMCoreNavigationController.h"
#import "LMCoreViewController.h"
#import "LMAnswers.h"

#define LMPlaylistEditorRestorationKeyPlaylistDictionary @"LMPlaylistEditorRestorationKeyPlaylistDictionary"

@interface LMPlaylistEditorViewController()<LMTableViewSubviewDataSource, LMListEntryDelegate, DDTableViewDelegate, LMImagePickerViewDelegate, LMMusicPickerDelegate, LMLayoutChangeDelegate, UITextFieldDelegate, UIViewControllerRestoration>

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
 The add songs button which will be tapped by the user to add new songs.
 */
@property UIView *addSongsButtonView;

/**
 The song list table view.
 */
@property LMTableView *songListTableView;

/**
 The items array for the now playing queue.
 */
@property NSMutableArray *bigListEntryArray;

/**
 The last time items in the song list were swapped.
 */
@property NSTimeInterval lastTimeOfSwap;

/**
 The label for when there are no songs in the table view.
 */
@property UILabel *noSongsInSongTableViewLabel;

/**
 The song count label.
 */
@property UILabel *songCountLabel;

/**
 Whether or not this was a new playlist being created. NO if it was just an old one being edited.
 */
@property BOOL newPlaylist;

@end

@implementation LMPlaylistEditorViewController

/* Begin adding songs code */

- (void)musicPicker:(LMMusicPickerController *)musicPicker didFinishPickingMusicWithTrackCollections:(NSArray<LMMusicTrackCollection *> *)trackCollections {
	
	NSLog(@"Finished!");
	
	self.playlist.trackCollection = [LMMusicPlayer trackCollectionForArrayOfTrackCollections:trackCollections];
	
	self.songListTableView.totalAmountOfObjects = self.playlist.trackCollection.count;
	[self.songListTableView reloadSubviewData];
	[self.songListTableView reloadData];
	
	self.songCountLabel.text = self.playlist.trackCollection.count == 0
	? NSLocalizedString(@"NoSongsYet", nil)
	: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
	
	[self reloadSaveButton];
}

- (void)musicPickerDidCancelPickingMusic:(LMMusicPickerController *)musicPicker {
	NSLog(@"Cancelled");
}

- (void)addSongsButtonTapped {
	NSLog(@"Add songs...");
	
	LMMusicPickerController *musicPicker = [LMMusicPickerController new];
	musicPicker.delegate = self;
	musicPicker.trackCollections = [LMMusicPlayer arrayOfTrackCollectionsForMusicTrackCollection:self.playlist.trackCollection];
	
	LMMusicPickerNavigationController *navigation = [[LMMusicPickerNavigationController alloc] initWithRootViewController:musicPicker];
	
	[self presentViewController:navigation animated:YES completion:nil];
}

/* End adding songs code */

/* Begin songs list table view code */

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %p", entry);
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [UIColor blackColor];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	NSString *title = [self.playlist.trackCollection.items objectAtIndex:entry.collectionIndex].title;
	NSString *fixedTitle = title ? title : NSLocalizedString(@"UnknownTitle", nil);
	
	entry.isAccessibilityElement = YES;
	entry.accessibilityLabel = [NSString stringWithFormat:@"%@, %@", fixedTitle, [self subtitleForListEntry:entry]];
	entry.accessibilityHint = NSLocalizedString(@"VoiceOverHint_EditPlaylistEntryOption", nil);
	
	return fixedTitle;
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	NSString *artist = [self.playlist.trackCollection.items objectAtIndex:entry.collectionIndex].artist;
	NSString *albumTitle =  [self.playlist.trackCollection.items objectAtIndex:entry.collectionIndex].albumTitle;
	
	if(artist && albumTitle){
		return [NSString stringWithFormat:@"%@ - %@", artist, albumTitle];
	}
	else if((artist && !albumTitle) || (!artist && albumTitle)){
		if(artist){
			return artist;
		}
		else{
			return albumTitle;
		}
	}
	else{ //No artist and no album title
		return NSLocalizedString(@"UnknownArtist", nil);
	}
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	UIImage *icon = [self.playlist.trackCollection.items objectAtIndex:entry.collectionIndex].albumArt;
	return icon;
}

- (NSArray<MGSwipeButton*>*)swipeButtonsForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	UIColor *color = [UIColor colorWithRed:47/255.0 green:47/255.0 blue:49/255.0 alpha:1.0];
	UIFont *font = [UIFont fontWithName:@"HelveticaNeue-Light" size:14.0f];
	MGSwipeButton *saveButton = [MGSwipeButton buttonWithTitle:@"" icon:[LMAppIcon imageForIcon:LMIconRemoveFromQueue] backgroundColor:color padding:0 callback:^BOOL(MGSwipeTableCell *sender) {
		LMMusicTrack *trackToRemove = [self.playlist.trackCollection.items objectAtIndex:listEntry.collectionIndex];
		
		NSLog(@"Remove %@", trackToRemove.title);
		
		NSMutableArray *mutableTrackList = [NSMutableArray arrayWithArray:self.playlist.trackCollection.items];
		
		[mutableTrackList removeObjectAtIndex:listEntry.collectionIndex];
		
		self.playlist.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:mutableTrackList];
		
		self.songListTableView.totalAmountOfObjects = self.playlist.trackCollection.count;
		//				[self.songListTableView reloadSubviewData];
		[self.songListTableView reloadData];
		
		self.noSongsInSongTableViewLabel.hidden = self.songListTableView.totalAmountOfObjects > 0;
		
		self.songCountLabel.text = self.playlist.trackCollection.count == 0
		? NSLocalizedString(@"NoSongsYet", nil)
		: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
		
		[self reloadSaveButton];
		
		return YES;
	}];
	saveButton.titleLabel.font = font;
	saveButton.titleLabel.hidden = YES;
	saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
	saveButton.imageEdgeInsets = UIEdgeInsetsMake(LMLayoutManager.isExtraSmall ? 18 : 25, 0, LMLayoutManager.isExtraSmall ? 18 : 25, 0);

	return @[ saveButton ];
}

- (UIColor*)swipeButtonColourForListEntry:(LMListEntry*)listEntry rightSide:(BOOL)rightSide {
	return [UIColor colorWithRed:0.92 green:0.00 blue:0.00 alpha:1.0];
}

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	LMListEntry *entry = [self.bigListEntryArray objectAtIndex:index % self.bigListEntryArray.count];
	entry.collectionIndex = index;
	
	
	//	if((self.currentlyHighlighted == entry.collectionIndex) ){
	//		entry.backgroundColor = [UIColor cyanColor];
	//	}
	
	[entry reloadContents];
	return entry;
}

- (CGFloat)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	return LMLayoutManager.standardListEntryHeight;
}

- (CGFloat)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	return 10;
}

- (void)amountOfObjectsRequiredChangedTo:(NSUInteger)amountOfObjects forTableView:(LMTableView*)tableView {
	self.noSongsInSongTableViewLabel.hidden = self.songListTableView.totalAmountOfObjects > 0;
	
	if(!self.bigListEntryArray){
		self.bigListEntryArray = [NSMutableArray new];
	}
	
	if(self.bigListEntryArray.count < amountOfObjects){
		for(NSUInteger i = self.bigListEntryArray.count; i < amountOfObjects; i++){
			LMListEntry *listEntry = [[LMListEntry alloc]initWithDelegate:self];
			listEntry.collectionIndex = i;
			listEntry.alignIconToLeft = YES;
			listEntry.stretchAcrossWidth = YES;
			listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
			
			[self.bigListEntryArray addObject:listEntry];
		}
	}
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
//	NSLog(@"Move %@ to %@ from %p", sourceIndexPath, destinationIndexPath, tableView);
	
	if((([[NSDate new] timeIntervalSince1970] - self.lastTimeOfSwap)*1000) < 10){
//		NSLog(@"double up, rejecting");
		return;
	}

	LMMusicTrack *currentMusicTrack = [self.playlist.trackCollection.items objectAtIndex:sourceIndexPath.section];

	NSMutableArray *mutableTrackList = [NSMutableArray arrayWithArray:self.playlist.trackCollection.items];
	
	[mutableTrackList removeObjectAtIndex:sourceIndexPath.section];
	[mutableTrackList insertObject:currentMusicTrack atIndex:destinationIndexPath.section];
	
	self.playlist.trackCollection = [[LMMusicTrackCollection alloc]initWithItems:mutableTrackList];
	

//	for(LMListEntry *listEntry in self.bigListEntryArray){
//		[listEntry reloadContents];
//	}
	
//	[currentListEntry reloadContents];

	self.lastTimeOfSwap = [[NSDate new] timeIntervalSince1970];
}

- (UITableViewCell*)tableView:(UITableView *)tableView draggingCell:(UITableViewCell *)cell atIndexPath:(NSIndexPath *)indexPath {
	if(![LMLayoutManager isLandscapeiPad]){
		cell.backgroundColor = [UIColor whiteColor];
	}
	return cell;
}

- (void)tableView:(UITableView *)tableView showDraggingView:(UIView *)draggingView atIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Show dragging view at %@", indexPath);
}

- (void)tableView:(UITableView *)tableView hideDraggingView:(UIView *)draggingView atIndexPath:(NSIndexPath *)indexPath {
	NSLog(@"Hide dragging view at %@", indexPath);
}

- (void)tableView:(UITableView *)tableView draggingGestureChanged:(UILongPressGestureRecognizer *)gesture {
	
}

/* End songs list table view code */

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

/* Begin other code */

- (void)cancelPlaylistEditing {
	NSLog(@"Cancel playlist");
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if([self.delegate respondsToSelector:@selector(playlistEditorViewControllerDidCancel:)]){
		[self.delegate playlistEditorViewControllerDidCancel:self];
	}
}

- (void)savePlaylistEditing {
	NSLog(@"Save playlist");
	
	self.playlist.title = ([self.titleTextField.text isEqualToString:@""] || !self.titleTextField.text) ? NSLocalizedString(@"YourPlaylistTitle", nil) : self.titleTextField.text;
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.playlistManager savePlaylist:self.playlist];
	
	[self.playlistManager reloadCachedPlaylists];
	
	if([self.delegate respondsToSelector:@selector(playlistEditorViewController:didSaveWithPlaylist:)]){
		[self.delegate playlistEditorViewController:self didSaveWithPlaylist:self.playlist];
	}
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceBackground, 0), ^{
		if(self.newPlaylist){
			[LMAnswers logCustomEventWithName:@"Normal Playlist Created" customAttributes:@{
																					@"Track Count": @(self.playlist.trackCollection.count),
																					@"Has Custom Image": @(self.playlist.image ? YES : NO)
																					}];
		}
	});
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator	{
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
	}];
}

- (void)reloadSaveButton {
	self.navigationItem.rightBarButtonItem.enabled = !(self.playlist.trackCollection.count == 0);
//	&& (self.titleTextField.text.length > 0);
}

- (void)closeKeyboard {
	[self.titleTextField resignFirstResponder];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[self closeKeyboard];
	return YES;
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		self.playlist.title = self.titleTextField.text;
		[self reloadSaveButton];
	} repeats:NO];
	
	[self reloadSaveButton];
	
	return YES;
}

- (void)reloadContents {
	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
	
	self.imagePickerView.image = self.playlist ? self.playlist.image : nil;
	
	[self reloadSaveButton];
	
	self.songListTableView.totalAmountOfObjects = self.playlist.trackCollection.count;
	[self.songListTableView reloadSubviewData];
	[self.songListTableView reloadData];
	
	self.songCountLabel.text = self.playlist.trackCollection.count == 0
	? NSLocalizedString(@"NoSongsYet", nil)
	: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
//	NSLog(@"%@", self.navigationController.navigationController);
	
	self.title = NSLocalizedString(self.playlist ? @"EditingPlaylist" : @"NewPlaylist", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPlaylistEditing)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(savePlaylistEditing)];
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.playlistManager = [LMPlaylistManager sharedPlaylistManager];
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	if(!self.playlist){
		self.newPlaylist = YES;
		self.playlist = [LMPlaylist new];
	}
	else{
		BOOL userPortedToLignitePlaylist = self.playlist.userPortedToLignitePlaylist;
		self.playlist = [self.playlistManager playlistForPersistentID:self.playlist.persistentID cached:NO];
		self.playlist.userPortedToLignitePlaylist = userPortedToLignitePlaylist;
	}
	
	
	self.imagePickerView = [LMImagePickerView newAutoLayoutView];
	self.imagePickerView.image = self.playlist ? self.playlist.image : nil;
	self.imagePickerView.delegate = self;
	[self.view addSubview:self.imagePickerView];
	
	NSArray *imagePickerViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.5/10.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewPortraitConstraints:imagePickerViewPortraitConstraints];
	
	NSArray *imagePickerViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.5/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:imagePickerViewLandscapeConstraints];
	
	NSArray *imagePickerViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(4.0/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewiPadConstraints:imagePickerViewiPadConstraints];
	
	if(@available(iOS 11, *)){
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imagePickerView
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.view.safeAreaLayoutGuide
															  attribute:NSLayoutAttributeTop
															 multiplier:1.0f
															   constant:20.0f]];
	}
	else{
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.imagePickerView
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.topLayoutGuide
															  attribute:NSLayoutAttributeBottom
															 multiplier:1.0f
															   constant:20.0f]];
	}
		
	
	self.titleTextField = [UITextField newAutoLayoutView];
	self.titleTextField.placeholder = NSLocalizedString(@"YourPlaylistTitle", nil);
	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
	self.titleTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
	self.titleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	self.titleTextField.returnKeyType = UIReturnKeyDone;
	self.titleTextField.delegate = self;
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
		[self.titleTextField autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	}];
//
//	NSLayoutConstraint *trailingPinnedToCenterVerticalAxisConstraint
//     = [NSLayoutConstraint constraintWithItem:self.titleTextField
//									attribute:NSLayoutAttributeTrailing
//									relatedBy:NSLayoutRelationEqual
//									   toItem:self.view
//									attribute:NSLayoutAttributeCenterX
//								   multiplier:1.0
//									 constant:0.0];
//
//	NSMutableArray *mutableTextViewLandscapeConstraintsArray = [NSMutableArray arrayWithArray:titleTextFieldLandscapeConstraints];
//	[mutableTextViewLandscapeConstraintsArray addObject:trailingPinnedToCenterVerticalAxisConstraint];
//	titleTextFieldLandscapeConstraints = [NSArray arrayWithArray:mutableTextViewLandscapeConstraintsArray];
//
	[LMLayoutManager addNewLandscapeConstraints:titleTextFieldLandscapeConstraints];
	
	UIView *textFieldLineView = [UIView newAutoLayoutView];
	textFieldLineView.backgroundColor = [UIColor grayColor];
	[self.view addSubview:textFieldLineView];
	
	[textFieldLineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleTextField withOffset:2];
	[textFieldLineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[textFieldLineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
	[textFieldLineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	
	
	self.songCountLabel = [UILabel newAutoLayoutView];
	self.songCountLabel.text = self.playlist.trackCollection.count == 0
		? NSLocalizedString(@"NoSongsYet", nil)
	: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 14.0f : 18.0f];
	self.songCountLabel.textColor = [UIColor blackColor];
	self.songCountLabel.numberOfLines = 0;
	[self.view addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textFieldLineView withOffset:6.0f];
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textFieldLineView];
	[self.songCountLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textFieldLineView];
	
	
	self.addSongsButtonView = [UIView newAutoLayoutView];
	self.addSongsButtonView.backgroundColor = [LMColour mainColour];
	self.addSongsButtonView.layer.cornerRadius = 8.0f;
	self.addSongsButtonView.layer.masksToBounds = YES;
	self.addSongsButtonView.isAccessibilityElement = YES;
	self.addSongsButtonView.accessibilityLabel = NSLocalizedString(@"VoiceOverLabel_AddSongs", nil);
	self.addSongsButtonView.accessibilityHint = NSLocalizedString(@"VoiceOverHint_AddSongs", nil);
	[self.view addSubview:self.addSongsButtonView];
	
	NSArray *addSongsButtonViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imagePickerView];
		[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(1.2/3.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:addSongsButtonViewPortraitConstraints];
	
	NSArray *addSongsButtonViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imagePickerView];
		[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(1.2/3.0)];
	}];
	[LMLayoutManager addNewLandscapeConstraints:addSongsButtonViewLandscapeConstraints];
	
	NSArray *addSongsButtonViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.songCountLabel withOffset:22];
		[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(1.2/3.0)];
		[self.addSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/3.0)];
	}];
	[LMLayoutManager addNewiPadConstraints:addSongsButtonViewiPadConstraints];
	
	UITapGestureRecognizer *addSongsButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addSongsButtonTapped)];
	[self.addSongsButtonView addGestureRecognizer:addSongsButtonTapGestureRecognizer];
	
	UIView *backgroundView = [UIView newAutoLayoutView];
	[self.addSongsButtonView addSubview:backgroundView];
	
	[backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.addSongsButtonView withMultiplier:(1.0/4.0)];
	[backgroundView autoCentreInSuperview];
	
	UIImageView *iconView = [UIImageView newAutoLayoutView];
	iconView.image = [LMAppIcon imageForIcon:LMIconAdd];
	iconView.contentMode = UIViewContentModeScaleAspectFit;
	[backgroundView addSubview:iconView];
	
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[iconView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[iconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:backgroundView];
	
	UILabel *labelView = [UILabel newAutoLayoutView];
	labelView.text = NSLocalizedString(@"AddSongs", nil);
	labelView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 14.0f : 18.0f];
	labelView.textColor = [UIColor whiteColor];
	[backgroundView addSubview:labelView];
	
	[labelView autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:iconView withOffset:12.0f];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:-10];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[labelView autoPinEdgeToSuperviewEdge:ALEdgeBottom withInset:-10];
	
	
	self.songListTableView = [LMTableView newAutoLayoutView];
	self.songListTableView.totalAmountOfObjects = self.playlist ? self.playlist.trackCollection.count : 20;
	self.songListTableView.subviewDataSource = self;
	self.songListTableView.shouldUseDividers = YES;
	self.songListTableView.fullDividers = YES;
	self.songListTableView.title = @"SongListTableView";
	self.songListTableView.bottomSpacing = 0;
	self.songListTableView.notHighlightedBackgroundColour = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.0];
	self.songListTableView.backgroundColor = [UIColor colorWithRed:1.0 green:1.0 blue:1.0 alpha:0.5]; //I wonder what this will do
	self.songListTableView.clipsToBounds = YES;
//	self.songListTableView.alwaysBounceVertical = YES;
	self.songListTableView.longPressReorderDelegate = self;
	self.songListTableView.longPressReorderEnabled = YES;
	[self.view addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView withOffset:15];
	[self.songListTableView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.songListTableView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.songListTableView reloadSubviewData];
	
	
	self.noSongsInSongTableViewLabel = [UILabel newAutoLayoutView];
	self.noSongsInSongTableViewLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 16.0f : 18.0f];
	self.noSongsInSongTableViewLabel.text = NSLocalizedString(@"NoSongsInPlaylistBuilder", nil);
	self.noSongsInSongTableViewLabel.textColor = [UIColor blackColor];
	self.noSongsInSongTableViewLabel.hidden = self.songListTableView.totalAmountOfObjects > 0;
	self.noSongsInSongTableViewLabel.textAlignment = NSTextAlignmentLeft;
	self.noSongsInSongTableViewLabel.numberOfLines = 0;
	self.noSongsInSongTableViewLabel.userInteractionEnabled = YES;
	[self.view addSubview:self.noSongsInSongTableViewLabel];
	
	[self.noSongsInSongTableViewLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView withOffset:15];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	
	UITapGestureRecognizer *closeKeyboardTapGesture = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(closeKeyboard)];
	[self.noSongsInSongTableViewLabel addGestureRecognizer:closeKeyboardTapGesture];
	
	[self reloadSaveButton];
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[self.titleTextField resignFirstResponder];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeRestorableStateWithCoder:coder];
	
	[coder encodeObject:self.playlist.dictionaryRepresentation forKey:LMPlaylistEditorRestorationKeyPlaylistDictionary];
	
	
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	NSLog(@"Got encoded playlist for restoration");
	
	NSDictionary *playlistDictionary = [coder decodeObjectForKey:LMPlaylistEditorRestorationKeyPlaylistDictionary];
	if(playlistDictionary){
		self.playlist = [[LMPlaylistManager sharedPlaylistManager] playlistForPlaylistDictionary:playlistDictionary];
		[self reloadContents];
	}
}

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	LMCoreNavigationController *coreNavigationController = (LMCoreNavigationController*)[[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
	
	LMPlaylistEditorViewController *playlistEditor = [LMPlaylistEditorViewController new];
	
	LMCoreViewController *coreViewController = coreNavigationController.viewControllers.firstObject;
	coreViewController.pendingStateRestoredPlaylistEditor = playlistEditor;
	
	return playlistEditor;
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.restorationIdentifier = [[self class] description];
		self.restorationClass = [self class];
	}
	return self;
}

/* End other code */

@end
