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

@interface LMPlaylistEditorViewController()<LMTableViewSubviewDataSource, LMListEntryDelegate, DDTableViewDelegate, LMImagePickerViewDelegate, LMMusicPickerDelegate, LMLayoutChangeDelegate>

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

@end

@implementation LMPlaylistEditorViewController

/* Begin adding songs code */

- (void)musicPicker:(LMMusicPickerController *)musicPicker didFinishPickingMusicWithTrackCollection:(LMMusicTrackCollection *)trackCollection {
	
	NSLog(@"Finished!");
	
	self.playlist.trackCollection = trackCollection;
	
	self.songListTableView.totalAmountOfObjects = self.playlist.trackCollection.count;
	[self.songListTableView reloadSubviewData];
	[self.songListTableView reloadData];
	
	self.songCountLabel.text = self.playlist.trackCollection.count == 0
	? NSLocalizedString(@"NoSongsYet", nil)
	: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
}

- (void)musicPickerDidCancelPickingMusic:(LMMusicPickerController *)musicPicker {
	NSLog(@"Cancelled");
}

- (void)addSongsButtonTapped {
	NSLog(@"Add songs...");
	
	LMMusicPickerController *musicPicker = [LMMusicPickerController new];
	musicPicker.delegate = self;
	musicPicker.trackCollection = self.playlist.trackCollection;
	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:musicPicker];
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
	return title ? title : NSLocalizedString(@"UnknownTitle", nil);
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

- (id)subviewAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	LMListEntry *entry = [self.bigListEntryArray objectAtIndex:index % self.bigListEntryArray.count];
	entry.collectionIndex = index;
	
	//	if((self.currentlyHighlighted == entry.collectionIndex) ){
	//		entry.backgroundColor = [UIColor cyanColor];
	//	}
	
	[entry reloadContents];
	return entry;
}

- (float)heightAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
	if([LMLayoutManager isiPad]){
		return ([LMLayoutManager isLandscapeiPad] ? WINDOW_FRAME.size.height : WINDOW_FRAME.size.width)/10.0f;
	}
	return ([LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height)/9.0f;
}

- (float)spacingAtIndex:(NSUInteger)index forTableView:(LMTableView*)tableView {
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
				
				return YES;
			}];
			saveButton.titleLabel.font = font;
			saveButton.titleLabel.hidden = YES;
			saveButton.imageView.contentMode = UIViewContentModeScaleAspectFit;
			saveButton.imageEdgeInsets = UIEdgeInsetsMake(25, 0, 25, 0);
			
			listEntry.rightButtons = @[ saveButton ];
			listEntry.rightButtonExpansionColour = [UIColor colorWithRed:0.92 green:0.00 blue:0.00 alpha:1.0];
			
			[self.bigListEntryArray addObject:listEntry];
		}
	}
}

- (void)tableView:(UITableView*)tableView moveRowAtIndexPath:(NSIndexPath *)sourceIndexPath toIndexPath:(NSIndexPath *)destinationIndexPath {
	NSLog(@"Move %@ to %@ from %p", sourceIndexPath, destinationIndexPath, tableView);
	
	if((([[NSDate new] timeIntervalSince1970] - self.lastTimeOfSwap)*1000) < 10){
		NSLog(@"double up, rejecting");
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
	[self dismissViewControllerAnimated:YES completion:nil];
	
	if([self.delegate respondsToSelector:@selector(playlistEditorViewControllerDidCancel:)]){
		[self.delegate playlistEditorViewControllerDidCancel:self];
	}
}

- (void)savePlaylistEditing {
	NSLog(@"Save playlist");
	
	self.playlist.title = self.titleTextField.text;
	
	[self dismissViewControllerAnimated:YES completion:nil];
	
	[self.playlistManager savePlaylist:self.playlist];
	
	if([self.delegate respondsToSelector:@selector(playlistEditorViewController:didSaveWithPlaylist:)]){
		[self.delegate playlistEditorViewController:self didSaveWithPlaylist:self.playlist];
	}
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator	{
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.songListTableView reloadData];
	}];
}

- (void)viewDidLoad {
    [super viewDidLoad];
	
	self.title = NSLocalizedString(self.playlist ? @"EditingPlaylist" : @"NewPlaylist", nil);
	
	self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Cancel", nil) style:UIBarButtonItemStylePlain target:self action:@selector(cancelPlaylistEditing)];
	self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc]initWithTitle:NSLocalizedString(@"Save", nil) style:UIBarButtonItemStyleDone target:self action:@selector(savePlaylistEditing)];
	
	
	if(!self.playlist){
		self.playlist = [LMPlaylist new];
	}
	
	
	self.musicPlayer = [LMMusicPlayer sharedMusicPlayer];
	self.playlistManager = [LMPlaylistManager sharedPlaylistManager];
	self.layoutManager = [LMLayoutManager sharedLayoutManager];
	[self.layoutManager addDelegate:self];
	
	
	self.imagePickerView = [LMImagePickerView newAutoLayoutView];
	self.imagePickerView.image = self.playlist ? self.playlist.image : nil;
	self.imagePickerView.delegate = self;
	[self.view addSubview:self.imagePickerView];
	
	NSArray *imagePickerViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:88];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.5/10.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewPortraitConstraints:imagePickerViewPortraitConstraints];
	
	NSArray *imagePickerViewLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:68];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.0/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:imagePickerViewLandscapeConstraints];
		
	
	self.titleTextField = [UITextField newAutoLayoutView];
	self.titleTextField.placeholder = NSLocalizedString(@"YourPlaylistTitle", nil);
	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
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
	self.songCountLabel.text = self.playlist.trackCollection.count == 0
		? NSLocalizedString(@"NoSongsYet", nil)
	: [NSString stringWithFormat:NSLocalizedString(self.playlist.trackCollection.count == 1 ? @"XSongsSingle" : @"XSongs", nil), self.playlist.trackCollection.count];
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
	self.songCountLabel.textColor = [UIColor blackColor];
	[self.view addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textFieldLineView withOffset:6.0f];
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textFieldLineView];
	[self.songCountLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textFieldLineView];
	
	
	self.addSongsButtonView = [UIView newAutoLayoutView];
	self.addSongsButtonView.backgroundColor = [LMColour ligniteRedColour];
	self.addSongsButtonView.layer.cornerRadius = 8.0f;
	self.addSongsButtonView.layer.masksToBounds = YES;
	[self.view addSubview:self.addSongsButtonView];
	
	NSArray *addSongsButtonViewPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeBottom toEdge:ALEdgeBottom ofView:self.imagePickerView];
		[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(1.2/3.0)];
	}];
	[LMLayoutManager addNewPortraitConstraints:addSongsButtonViewPortraitConstraints];
	
	NSArray *addSongsButtonViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.addSongsButtonView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
		[self.addSongsButtonView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.songCountLabel withOffset:14];
		[self.addSongsButtonView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.imagePickerView withMultiplier:(0.8/3.0)];
		[self.addSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(1.0/3.0)];
	}];
	[LMLayoutManager addNewiPadConstraints:addSongsButtonViewiPadConstraints];
	
	UITapGestureRecognizer *addSongsButtonTapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(addSongsButtonTapped)];
	[self.addSongsButtonView addGestureRecognizer:addSongsButtonTapGestureRecognizer];
	
	UIView *backgroundView = [UIView newAutoLayoutView];
	[self.addSongsButtonView addSubview:backgroundView];
	
	[backgroundView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.addSongsButtonView withMultiplier:(1.0/4.0)];
	[backgroundView autoCenterInSuperview];
	
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
	labelView.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:18.0f];
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
	self.songListTableView.alwaysBounceVertical = NO;
	self.songListTableView.longPressReorderDelegate = self;
	self.songListTableView.longPressReorderEnabled = YES;
	[self.view addSubview:self.songListTableView];
	
	[self.songListTableView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView withOffset:15];
	[self.songListTableView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.songListTableView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.songListTableView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.songListTableView reloadSubviewData];
	
	
	self.noSongsInSongTableViewLabel = [UILabel newAutoLayoutView];
	self.noSongsInSongTableViewLabel.font = self.titleTextField.font;
	self.noSongsInSongTableViewLabel.text = NSLocalizedString(@"NoSongsInPlaylistBuilder", nil);
	self.noSongsInSongTableViewLabel.textColor = [UIColor blackColor];
	self.noSongsInSongTableViewLabel.hidden = self.songListTableView.totalAmountOfObjects > 0;
	self.noSongsInSongTableViewLabel.textAlignment = NSTextAlignmentLeft;
	self.noSongsInSongTableViewLabel.numberOfLines = 0;
	[self.view addSubview:self.noSongsInSongTableViewLabel];
	
	[self.noSongsInSongTableViewLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.noSongsInSongTableViewLabel autoPinEdgeToSuperviewEdge:ALEdgeBottom];
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

/* End other code */

@end
