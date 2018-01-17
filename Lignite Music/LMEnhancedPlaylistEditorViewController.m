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
#import "LMScrollView.h"
#import "LMEnhancedPlaylistCollectionViewFlowLayout.h"
#import "NSTimer+Blocks.h"
#import "LMCoreNavigationController.h"
#import "LMCoreViewController.h"
#import "LMAnswers.h"

#define LMEnhancedPlaylistEditorRestorationKeyPlaylistDictionary @"LMEnhancedPlaylistEditorRestorationKeyPlaylistDictionary"

@interface LMEnhancedPlaylistEditorViewController ()<LMLayoutChangeDelegate, LMImagePickerViewDelegate, LMMusicPickerDelegate, BEMCheckBoxDelegate, UICollectionViewDelegate, UICollectionViewDataSource, UICollectionViewDelegateFlowLayout, LMListEntryDelegate, UITextFieldDelegate, LMBoxWarningViewDelegate, UIViewControllerRestoration>

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
 The collection view for conditions of want to listen to and don't want to listen to.
 */
@property UICollectionView *conditionsCollectionView;

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
 The top constraint for the image picker so we can readjust based on whether or not to show a warning box warning.
 */
@property NSLayoutConstraint *imagePickerTopConstraint;

/**
 Whether or not this was a new playlist being created. NO if it was just an old one being edited.
 */
@property BOOL newPlaylist;

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

- (void)reloadImagePickerTopConstraint {
	[self.imagePickerTopConstraint autoRemove];
	
	if(self.warningBoxView.showing){
		self.imagePickerTopConstraint = [self.imagePickerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningBoxView withOffset:18];
	}
	else{
		self.imagePickerTopConstraint = [self.imagePickerView autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.warningBoxView];
	}
	
	[self.view layoutIfNeeded];
}

- (void)rootViewWillTransitionToSize:(CGSize)size withTransitionCoordinator:(id <UIViewControllerTransitionCoordinator>)coordinator	{
	
//	BOOL willBeLandscape = size.width > size.height;
	[coordinator animateAlongsideTransition:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.conditionsCollectionView reloadData];
	} completion:^(id<UIViewControllerTransitionCoordinatorContext>  _Nonnull context) {
		[self.conditionsCollectionView reloadData];
		
//		if(WINDOW_FRAME.size.height < 340){ //Tiny landscape
//			[self.warningBoxView hide];
//			
//			[self reloadImagePickerTopConstraint];
//		}
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
	
	if(self.titleTextField.text.length == 0 || !self.titleTextField.text){
		self.playlist.title = NSLocalizedString(@"YourPlaylistTitle", nil);
	}
	
	[self.playlist regenerateEnhancedPlaylist];
	
	[self.playlistManager savePlaylist:self.playlist];
	
	[self dismissViewControllerAnimated:YES completion:nil];

	NSLog(@"Saved.");
	
	if([self.delegate respondsToSelector:@selector(enhancedPlaylistEditorViewController:didSaveWithPlaylist:)]){
		[self.delegate enhancedPlaylistEditorViewController:self didSaveWithPlaylist:self.playlist];
	}
	
	dispatch_async(dispatch_get_global_queue(NSQualityOfServiceBackground, 0), ^{
		if(self.newPlaylist){
			[LMAnswers logCustomEventWithName:@"Enhanced Playlist Created" customAttributes:@{
																							@"Want To Hear Condition Count": @(self.playlist.wantToHearTrackCollections.count),
																							@"Don't Want To Hear Condition Count": @(self.playlist.dontWantToHearTrackCollections.count),
																							@"Has Custom Image": @(self.playlist.image ? YES : NO)
																							}];
		}
	});
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
		
		if(musicType == LMMusicTypeFavourites){
			musicType = LMMusicTypeTitles;
		}
		
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
		[self reloadImagePickerTopConstraint];
	}
	
	[self reloadConditionsLabelAndWarningBox];
	[self.conditionsCollectionView reloadData];
}

- (void)addConditionsButtonTapped:(UITapGestureRecognizer*)tapGestureRecognizer {
	self.isPickingWantToHear = (tapGestureRecognizer.view == self.wantToHearAddSongsButtonView);

	
	self.conditionsMusicPickerController = [LMMusicPickerController new];
	self.conditionsMusicPickerController.delegate = self;
	self.conditionsMusicPickerController.selectionMode = LMMusicPickerSelectionModeAllCollections;
	
	self.conditionsMusicPickerController.trackCollections = self.isPickingWantToHear ? [self.playlist wantToHearTrackCollections] : [self.playlist dontWantToHearTrackCollections];
	self.conditionsMusicPickerController.musicTypes = self.isPickingWantToHear ? [self.playlist wantToHearMusicTypes] : [self.playlist dontWantToHearMusicTypes];
	
//	for(LMMusicTrackCollection *collection in musicTrackCollectionsMutableArray){
//		NSLog(@"Collection with %d items", (int)collection.count);
//	}
	

	UINavigationController *navigation = [[UINavigationController alloc] initWithRootViewController:self.conditionsMusicPickerController];
	[self presentViewController:navigation animated:YES completion:nil];
	
}

- (void)tappedShuffleAllLabel {
	[self.shuffleAllCheckbox setOn:!self.shuffleAllCheckbox.on animated:YES];
	
	self.playlist.enhancedShuffleAll = self.shuffleAllCheckbox.enabled;
}

- (void)didTapCheckBox:(BEMCheckBox*)checkBox {
	self.playlist.enhancedShuffleAll = checkBox.enabled;
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
//	else if(self.titleTextField.text.length == 0 || !self.titleTextField.text){
//		self.warningBoxView.titleLabel.text = NSLocalizedString(@"NoTitleTitle", nil);
//		self.warningBoxView.subtitleLabel.text = NSLocalizedString(@"NoTitleDescription", nil);
//
//		[self.warningBoxView show];
//	}
	else{
		[self.warningBoxView hide];
	}
	[self reloadSaveButton];
	[self reloadImagePickerTopConstraint];
}

/* Begin collection view code */

- (BOOL)indexPathIsWantToHear:(NSIndexPath*)indexPath {
	if(indexPath.section == 0 && indexPath.row == 0){
		return YES;
	}
	return NO;
}

- (BOOL)indexPathIsDontWantToHear:(NSIndexPath*)indexPath {
	if(indexPath.section == 1 && indexPath.row == 0){
		return YES;
	}
	return NO;
}

- (NSInteger)numberOfSectionsInCollectionView:(UICollectionView *)collectionView {
	return 2; //I want to hear, and I don't want to hear
}

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
	return (section == 0 ? [self.playlist wantToHearTrackCollections].count : [self.playlist dontWantToHearTrackCollections].count) + 1;
}

- (UICollectionViewCell*)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {

	UICollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"ConditionsCollectionViewCellIdentifier" forIndexPath:indexPath];
	
	cell.contentView.backgroundColor = [UIColor whiteColor];
	
	for(UIView *subview in cell.contentView.subviews){
		[subview removeFromSuperview];
	}
	
	if([self indexPathIsWantToHear:indexPath]){
		[cell.contentView addSubview:self.wantToHearBackgroundView];
		
		[self.wantToHearBackgroundView autoPinEdgesToSuperviewEdges];
	}
	else if([self indexPathIsDontWantToHear:indexPath]){
		[cell.contentView addSubview:self.dontWantToHearBackgroundView];
		
		[self.dontWantToHearBackgroundView autoPinEdgesToSuperviewEdges];
	}
	else{
		LMListEntry *listEntry = [LMListEntry newAutoLayoutView];
		listEntry.delegate = self;
		listEntry.indexPath = indexPath;
		listEntry.iconInsetMultiplier = (1.0/3.0);
		listEntry.iconPaddingMultiplier = (3.0/4.0);
		listEntry.stretchAcrossWidth = YES;
		listEntry.iPromiseIWillHaveAnIconForYouSoon = YES;
		listEntry.roundedCorners = NO;
		
		[cell.contentView addSubview:listEntry];
		
		[listEntry autoPinEdgesToSuperviewEdges];
		
//		listEntry.keepTextColoursTheSame = YES;
//		[listEntry changeHighlightStatus:YES animated:NO];
		
		cell.contentView.layer.masksToBounds = YES;
		cell.contentView.layer.cornerRadius = 6.0f;
		cell.contentView.backgroundColor = [LMColour controlBarGreyColour];
	}
	
	return cell;
}

//- (CGSize)collectionView:(UICollectionView *)collectionView layout:(UICollectionViewLayout*)collectionViewLayout sizeForItemAtIndexPath:(NSIndexPath *)indexPath {
//
//	CGFloat dimensionToUse = [LMLayoutManager isLandscape] ? WINDOW_FRAME.size.width : WINDOW_FRAME.size.height;
//
//	CGSize size = CGSizeMake(0, 0);
//
//	if([self indexPathIsWantToHear:indexPath] || [self indexPathIsDontWantToHear:indexPath]){
//		size = CGSizeMake(self.conditionsCollectionView.frame.size.width, dimensionToUse/16.0f);
//	}
//	else{
//		size = CGSizeMake(self.conditionsCollectionView.frame.size.width, dimensionToUse/9.0f);
//	}
//
//	if([LMLayoutManager isiPad]){
//		size.width = size.width/2;
//		size.width -= 40;
//	}
//
//	return size;
//}

- (CGFloat)collectionView:(UICollectionView *)collectionView layout:(UICollectionView *)collectionViewLayout minimumLineSpacingForSectionAtIndex:(NSInteger)section {
	return 10;
}

/* End collection view code */

- (NSString*)titlePropertyStringForMusicType:(LMMusicType)musicType {
	switch(musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return MPMediaItemPropertyTitle;
		case LMMusicTypeComposers:
			return MPMediaItemPropertyComposer;
		case LMMusicTypeAlbums:
		case LMMusicTypeCompilations:
			return MPMediaItemPropertyAlbumTitle;
		case LMMusicTypeArtists:
			return MPMediaItemPropertyArtist;
		case LMMusicTypeGenres:
			return MPMediaItemPropertyGenre;
		default:
			NSAssert(true, @"This music type (%d) is not yet supported", musicType);
			return @"";
	}
}

- (void)tappedListEntry:(LMListEntry*)entry {
	NSLog(@"Tapped %@", entry);
}

- (UIColor*)tapColourForListEntry:(LMListEntry*)entry {
	return [LMColour controlBarGreyColour];
}

- (NSString*)titleForListEntry:(LMListEntry*)entry {
	BOOL isWantToHear = (entry.indexPath.section == 0);
	
	LMMusicType musicType = (LMMusicType)[[(isWantToHear ? [self.playlist wantToHearMusicTypes] : [self.playlist dontWantToHearMusicTypes]) objectAtIndex:entry.indexPath.row - 1] integerValue];
	LMMusicTrackCollection *collection = [(isWantToHear ? [self.playlist wantToHearTrackCollections] : [self.playlist dontWantToHearTrackCollections]) objectAtIndex:entry.indexPath.row - 1];
	
	NSLog(@"Value for %@ '%@'/'%@'/'%@'", collection.representativeItem, collection.representativeItem.genre, [collection.representativeItem valueForProperty:[self titlePropertyStringForMusicType:musicType]], collection.representativeItem.artist);
	
	return [collection.representativeItem valueForProperty:[self titlePropertyStringForMusicType:musicType]];
}

- (NSString*)subtitleForListEntry:(LMListEntry*)entry {
	BOOL isWantToHear = (entry.indexPath.section == 0);
	
	LMMusicType musicType = (LMMusicType)[[(isWantToHear ? [self.playlist wantToHearMusicTypes] : [self.playlist dontWantToHearMusicTypes]) objectAtIndex:entry.indexPath.row - 1] integerValue];
	LMMusicTrackCollection *collection = [(isWantToHear ? [self.playlist wantToHearTrackCollections] : [self.playlist dontWantToHearTrackCollections]) objectAtIndex:entry.indexPath.row - 1];
	
	switch(musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return collection.representativeItem.artist;
		case LMMusicTypeComposers:
		case LMMusicTypeArtists: {
			BOOL usingSpecificTrackCollections = (musicType != LMMusicTypePlaylists
												  && musicType != LMMusicTypeCompilations
												  && musicType != LMMusicTypeAlbums);
			
			if(usingSpecificTrackCollections){
				//Fixes for compilations
				NSUInteger albums = [self.musicPlayer collectionsForRepresentativeTrack:collection.representativeItem
																		   forMusicType:musicType].count;
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)albums, NSLocalizedString(albums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
			else{
				return [NSString stringWithFormat:@"%lu %@", (unsigned long)collection.numberOfAlbums, NSLocalizedString(collection.numberOfAlbums == 1 ? @"AlbumInline" : @"AlbumsInline", nil)];
			}
		}
		case LMMusicTypeGenres:
		case LMMusicTypePlaylists:
		{
			return [NSString stringWithFormat:@"%ld %@", (unsigned long)collection.trackCount, NSLocalizedString(collection.trackCount == 1 ? @"Song" : @"Songs", nil)];
		}
		case LMMusicTypeCompilations:
		case LMMusicTypeAlbums: {
			if(collection.variousArtists){
				return NSLocalizedString(@"Various", nil);
			}
			return collection.representativeItem.artist ? collection.representativeItem.artist : NSLocalizedString(@"UnknownArtist", nil);
		}
		default: {
			return nil;
		}
	}
}

- (UIImage*)iconForListEntry:(LMListEntry*)entry {
	BOOL isWantToHear = (entry.indexPath.section == 0);
	
	LMMusicType musicType = (LMMusicType)[[(isWantToHear ? [self.playlist wantToHearMusicTypes] : [self.playlist dontWantToHearMusicTypes]) objectAtIndex:entry.indexPath.row - 1] integerValue];
//	LMMusicTrackCollection *collection = [(isWantToHear ? [self.playlist wantToHearTrackCollections] : [self.playlist dontWantToHearTrackCollections]) objectAtIndex:entry.indexPath.row - 1];
	
	switch(musicType){
		case LMMusicTypeFavourites:
		case LMMusicTypeTitles:
			return [LMAppIcon imageForIcon:LMIconTitles];
		case LMMusicTypeComposers:{
			return [LMAppIcon imageForIcon:LMIconComposers];
		}
		case LMMusicTypeArtists: {
			return [LMAppIcon imageForIcon:LMIconArtists];
		}
		case LMMusicTypeGenres:{
			return [LMAppIcon imageForIcon:LMIconGenres];
		}
		case LMMusicTypePlaylists:
		{
			return [LMAppIcon imageForIcon:LMIconPlaylists];
		}
		case LMMusicTypeCompilations:{
			return [LMAppIcon imageForIcon:LMIconCompilations];
		}
		case LMMusicTypeAlbums: {
			return [LMAppIcon imageForIcon:LMIconAlbums];
		}
	}
	
	return [LMAppIcon imageForIcon:LMIconBug];
}

- (void)deleteEntryWithIndexPath:(NSIndexPath*)indexPath {
	BOOL isWantToHear = (indexPath.section == 0);
	
	NSMutableArray *persistentIDsMutableArray = [[NSMutableArray alloc] initWithArray:isWantToHear ? self.playlist.wantToHearPersistentIDs : self.playlist.dontWantToHearPersistentIDs];
	[persistentIDsMutableArray removeObjectAtIndex:indexPath.row-1];
	
	NSMutableArray *musicTypesMutableArray = [[NSMutableArray alloc]initWithArray:isWantToHear ? self.playlist.wantToHearMusicTypes : self.playlist.dontWantToHearMusicTypes];
	[musicTypesMutableArray removeObjectAtIndex:indexPath.row-1];
	
	NSMutableDictionary *mutableConditionsDictionary = [NSMutableDictionary dictionaryWithDictionary:self.playlist.enhancedConditionsDictionary];
	
	NSString *sectionKey = isWantToHear ? LMEnhancedPlaylistWantToHearKey : LMEnhancedPlaylistDontWantToHearKey;
	
	[mutableConditionsDictionary removeObjectForKey:sectionKey];
	[mutableConditionsDictionary setObject:@{
											 LMEnhancedPlaylistPersistentIDsKey: [NSArray arrayWithArray:persistentIDsMutableArray],
											 LMEnhancedPlaylistMusicTypesKey: [NSArray arrayWithArray:musicTypesMutableArray]
											 } forKey:sectionKey];
	
	self.playlist.enhancedConditionsDictionary = [NSDictionary dictionaryWithDictionary:mutableConditionsDictionary];
	
	[self reloadConditionsLabelAndWarningBox];
	[self.conditionsCollectionView reloadData];
}

- (void)tappedXCross:(UITapGestureRecognizer*)tapGestureRecognizer {
	UIView *view = tapGestureRecognizer.view.superview;
	while(view){
		if([view class] == [LMListEntry class]){
			LMListEntry *listEntry = (LMListEntry*)view;
			[self deleteEntryWithIndexPath:listEntry.indexPath];
			break;
		}
		view = view.superview;
	}
}

- (UIView*)rightViewForListEntry:(LMListEntry*)entry {
	UIView *arrowIconPaddedView = [UIView newAutoLayoutView];
	
	UIImageView *arrowIconView = [UIImageView newAutoLayoutView];
	arrowIconView.contentMode = UIViewContentModeScaleAspectFit;
	arrowIconView.image = [LMAppIcon invertImage:[LMAppIcon imageForIcon:LMIconXCross]];
	
	[arrowIconPaddedView addSubview:arrowIconView];
	
	[arrowIconView autoPinEdgeToSuperviewEdge:ALEdgeLeading withInset:-4];
	[arrowIconView autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[arrowIconView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:arrowIconPaddedView withMultiplier:(5.0/8.0)];
	[arrowIconView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:arrowIconPaddedView];
	
	UITapGestureRecognizer *tapGestureRecognizer = [[UITapGestureRecognizer alloc]initWithTarget:self action:@selector(tappedXCross:)];
	[arrowIconPaddedView addGestureRecognizer:tapGestureRecognizer];
	
	return arrowIconPaddedView;
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
	[textField resignFirstResponder];
	return YES;
}

- (void)touchesBegan:(NSSet*)touches withEvent:(UIEvent*)event {
	[self.titleTextField resignFirstResponder];
}

- (void)reloadSaveButton {
	NSArray *wantToHearPersistentIDsArray = [[self.playlist.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistWantToHearKey] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	NSArray *dontWantToHearPersistentIDsArray = [[self.playlist.enhancedConditionsDictionary objectForKey:LMEnhancedPlaylistDontWantToHearKey] objectForKey:LMEnhancedPlaylistPersistentIDsKey];
	
	NSInteger numberOfConditions = (wantToHearPersistentIDsArray.count + dontWantToHearPersistentIDsArray.count);
	
	if(numberOfConditions == 0){
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
	else if(wantToHearPersistentIDsArray.count == 0 && dontWantToHearPersistentIDsArray.count > 0){
		self.navigationItem.rightBarButtonItem.enabled = NO;
	}
//	else if(self.titleTextField.text.length == 0 || !self.titleTextField.text){
//		self.navigationItem.rightBarButtonItem.enabled = NO;
//	}
	else{
		self.navigationItem.rightBarButtonItem.enabled = YES;
	}
}

- (BOOL)textField:(UITextField *)textField shouldChangeCharactersInRange:(NSRange)range replacementString:(NSString *)string {
	[NSTimer scheduledTimerWithTimeInterval:0.25 block:^{
		[self reloadSaveButton];
		[self reloadConditionsLabelAndWarningBox];
		self.playlist.title = self.titleTextField.text;
	} repeats:NO];
	
	[self reloadSaveButton];
	
	return YES;
}

- (void)boxWarningViewWasForceClosed:(LMBoxWarningView *)boxWarningView {
	[self reloadImagePickerTopConstraint];
}

/* Begin initialization code */

- (void)encodeRestorableStateWithCoder:(NSCoder *)coder {
	[super encodeWithCoder:coder];
	
	NSDictionary *playlistDictionary = self.playlist.dictionaryRepresentation;
	[coder encodeObject:playlistDictionary forKey:LMEnhancedPlaylistEditorRestorationKeyPlaylistDictionary];
}

- (void)decodeRestorableStateWithCoder:(NSCoder *)coder {
	[super decodeRestorableStateWithCoder:coder];
	
	NSLog(@"Got encoded playlist for restoration");
	
	NSDictionary *playlistDictionary = [coder decodeObjectForKey:LMEnhancedPlaylistEditorRestorationKeyPlaylistDictionary];
	if(playlistDictionary){
		self.playlist = [[LMPlaylistManager sharedPlaylistManager] playlistForPlaylistDictionary:playlistDictionary];
		[self reloadContents];
	}
}

+ (nullable UIViewController *) viewControllerWithRestorationIdentifierPath:(NSArray *)identifierComponents coder:(NSCoder *)coder {
	LMCoreNavigationController *coreNavigationController = (LMCoreNavigationController*)[[[[UIApplication sharedApplication] windows] firstObject] rootViewController];
	
	LMEnhancedPlaylistEditorViewController *enhancedPlaylistEditor = [LMEnhancedPlaylistEditorViewController new];
	
	LMCoreViewController *coreViewController = coreNavigationController.viewControllers.firstObject;
	coreViewController.pendingStateRestoredEnhancedPlaylistEditor = enhancedPlaylistEditor;
	
	return enhancedPlaylistEditor;
}

- (void)reloadContents {
	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
	
	self.imagePickerView.image = self.playlist ? self.playlist.image : nil;
	
	[self reloadSaveButton];
	
	[self.conditionsCollectionView reloadData];
	
	[self reloadConditionsLabelAndWarningBox];
}

- (void)viewDidLoad {
    [super viewDidLoad];

	self.title = NSLocalizedString(@"EnhancedPlaylistTitle", nil);
	
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
		self.newPlaylist = YES;
	}
	
	
	self.warningBoxView = [LMBoxWarningView newAutoLayoutView];
	self.warningBoxView.hideOnLayout = !self.newPlaylist;
	self.warningBoxView.delegate = self;
	[self.view addSubview:self.warningBoxView];
	
//	[self.warningBoxView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.navigationController.navigationBar];
	[self.warningBoxView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.warningBoxView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	if(@available(iOS 11, *)){
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.warningBoxView
									 attribute:NSLayoutAttributeTop
									 relatedBy:NSLayoutRelationEqual
										toItem:self.view.safeAreaLayoutGuide
									 attribute:NSLayoutAttributeTop
									multiplier:1.0f
									  constant:20.0f]];
	}
	else{
		[self.view addConstraint:[NSLayoutConstraint constraintWithItem:self.warningBoxView
															  attribute:NSLayoutAttributeTop
															  relatedBy:NSLayoutRelationEqual
																 toItem:self.topLayoutGuide
															  attribute:NSLayoutAttributeBottom
															 multiplier:1.0f
															   constant:20.0f]];
	}
//	[self.warningBoxView autoPinEdgeToSuperviewEdge:ALEdgeTop withInset:self.view.safeAreaLayoutGuide.topAnchor];
	
	
	/*
	 
	 if #available(iOS 11, *) {
	 let guide = view.safeAreaLayoutGuide
	 NSLayoutConstraint.activate([
	 greenView.topAnchor.constraintEqualToSystemSpacingBelow(guide.topAnchor, multiplier: 1.0),
	 guide.bottomAnchor.constraintEqualToSystemSpacingBelow(greenView.bottomAnchor, multiplier: 1.0)
	 ])
	 
	 } else {
	 let standardSpacing: CGFloat = 8.0
	 NSLayoutConstraint.activate([
	 greenView.topAnchor.constraint(equalTo: topLayoutGuide.bottomAnchor, constant: standardSpacing),
	 bottomLayoutGuide.topAnchor.constraint(equalTo: greenView.bottomAnchor, constant: standardSpacing)
	 ])
	 }
	 
	 */
	
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
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.view withMultiplier:(3.0/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewLandscapeConstraints:imagePickerViewLandscapeConstraints];
	
	NSArray *imagePickerViewiPadConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.imagePickerView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
		[self.imagePickerView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionHeight ofView:self.view withMultiplier:(4.0/20.0)];
		[self.imagePickerView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.imagePickerView];
	}];
	[LMLayoutManager addNewiPadConstraints:imagePickerViewiPadConstraints];
	
	self.imagePickerTopConstraint = [self.imagePickerView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.warningBoxView withOffset:18];
	
	
	self.titleTextField = [UITextField newAutoLayoutView];
	self.titleTextField.placeholder = NSLocalizedString(@"YourPlaylistTitle", nil);
	self.titleTextField.text = self.playlist ? self.playlist.title : nil;
	self.titleTextField.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:19.0f];
	self.titleTextField.autocapitalizationType = UITextAutocapitalizationTypeWords;
	self.titleTextField.returnKeyType = UIReturnKeyDone;
	self.titleTextField.delegate = self;
	[self.view addSubview:self.titleTextField];
	
//	NSArray *titleTextFieldPortraitConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
		[self.titleTextField autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
		[self.titleTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imagePickerView];
		[self.titleTextField autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.imagePickerView withOffset:15];
//	}];
//	[LMLayoutManager addNewPortraitConstraints:titleTextFieldPortraitConstraints];
	
//	NSArray *titleTextFieldLandscapeConstraints = [NSLayoutConstraint autoCreateConstraintsWithoutInstalling:^{
//		[self.titleTextField autoPinEdge:ALEdgeTop toEdge:ALEdgeTop ofView:self.imagePickerView];
//		[self.titleTextField autoPinEdge:ALEdgeLeading toEdge:ALEdgeTrailing ofView:self.imagePickerView withOffset:15];
//	}];
//
//	NSLayoutConstraint *trailingPinnedToCenterVerticalAxisConstraint
//	= [NSLayoutConstraint constraintWithItem:self.titleTextField
//								   attribute:NSLayoutAttributeTrailing
//								   relatedBy:NSLayoutRelationEqual
//									  toItem:self.view
//								   attribute:NSLayoutAttributeCenterX
//								  multiplier:1.0
//									constant:0.0];
//
//	NSMutableArray *mutableTextViewLandscapeConstraintsArray = [NSMutableArray arrayWithArray:titleTextFieldLandscapeConstraints];
//	[mutableTextViewLandscapeConstraintsArray addObject:trailingPinnedToCenterVerticalAxisConstraint];
//	titleTextFieldLandscapeConstraints = [NSArray arrayWithArray:mutableTextViewLandscapeConstraintsArray];
//
//	[LMLayoutManager addNewLandscapeConstraints:titleTextFieldLandscapeConstraints];
	
	UIView *textFieldLineView = [UIView newAutoLayoutView];
	textFieldLineView.backgroundColor = [UIColor grayColor];
	[self.view addSubview:textFieldLineView];
	
	[textFieldLineView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.titleTextField withOffset:2];
	[textFieldLineView autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:self.titleTextField];
	[textFieldLineView autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:self.titleTextField];
	[textFieldLineView autoSetDimension:ALDimensionHeight toSize:1.0f];
	
	
	self.songCountLabel = [UILabel newAutoLayoutView];
	self.songCountLabel.text = @"nice work";
	self.songCountLabel.font = [UIFont fontWithName:@"HelveticaNeue-Light" size:[LMLayoutManager isExtraSmall] ? 14.0f : 18.0f];
	self.songCountLabel.textColor = [UIColor blackColor];
	self.songCountLabel.numberOfLines = 0;
	[self.view addSubview:self.songCountLabel];
	
	[self.songCountLabel autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:textFieldLineView withOffset:6.0f];
	[self.songCountLabel autoPinEdge:ALEdgeLeading toEdge:ALEdgeLeading ofView:textFieldLineView];
	[self.songCountLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeTrailing ofView:textFieldLineView];
	
	
	
	self.shuffleAllCheckbox = [BEMCheckBox newAutoLayoutView];
	self.shuffleAllCheckbox.delegate = self;
	self.shuffleAllCheckbox.boxType = BEMBoxTypeSquare;
	self.shuffleAllCheckbox.tintColor = [LMColour controlBarGreyColour];
	self.shuffleAllCheckbox.onFillColor = [LMColour mainColour];
	self.shuffleAllCheckbox.onCheckColor = [UIColor whiteColor];
	self.shuffleAllCheckbox.onTintColor = [LMColour mainColour];
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
	
	
	LMEnhancedPlaylistCollectionViewFlowLayout *flowLayout = [LMEnhancedPlaylistCollectionViewFlowLayout new];
	flowLayout.sectionInset = UIEdgeInsetsMake(10, 10, 0, 10);
	
	self.conditionsCollectionView = [[UICollectionView alloc] initWithFrame:CGRectZero collectionViewLayout:flowLayout];
	self.conditionsCollectionView.translatesAutoresizingMaskIntoConstraints = NO;
	self.conditionsCollectionView.delegate = self;
	self.conditionsCollectionView.dataSource = self;
	self.conditionsCollectionView.allowsSelection = NO;
	[self.conditionsCollectionView registerClass:[UICollectionViewCell class] forCellWithReuseIdentifier:@"ConditionsCollectionViewCellIdentifier"];
	self.conditionsCollectionView.backgroundColor = [UIColor whiteColor];
	[self.view addSubview:self.conditionsCollectionView];
	
	[self.conditionsCollectionView autoPinEdge:ALEdgeTop toEdge:ALEdgeBottom ofView:self.imagePickerView withOffset:22];
	[self.conditionsCollectionView autoPinEdgeToSuperviewMargin:ALEdgeLeading];
	[self.conditionsCollectionView autoPinEdgeToSuperviewMargin:ALEdgeTrailing];
	[self.conditionsCollectionView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	
	
	self.wantToHearBackgroundView = [UIView newAutoLayoutView];
	
	
	self.wantToHearAddSongsButtonView = [UIView newAutoLayoutView];
	self.wantToHearAddSongsButtonView.backgroundColor = [LMColour darkGreyColour];
	self.wantToHearAddSongsButtonView.layer.masksToBounds = YES;
	self.wantToHearAddSongsButtonView.layer.cornerRadius = 6.0f;
	[self.wantToHearBackgroundView addSubview:self.wantToHearAddSongsButtonView];
	
	UITapGestureRecognizer *wantToHearTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addConditionsButtonTapped:)];
	[self.wantToHearAddSongsButtonView addGestureRecognizer:wantToHearTapGestureRecognizer];
	
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.wantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.wantToHearAddSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.wantToHearAddSongsButtonView];
	
	UIImageView *addSongsIconImageView = [UIImageView newAutoLayoutView];
	addSongsIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	addSongsIconImageView.image = [LMAppIcon imageForIcon:LMIconAdd];
	[self.wantToHearAddSongsButtonView addSubview:addSongsIconImageView];
	
	[addSongsIconImageView autoCentreInSuperview];
	[addSongsIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.wantToHearAddSongsButtonView withMultiplier:(5.0/10.0)];
	[addSongsIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:addSongsIconImageView];
	
	
	self.wantToHearLabel = [UILabel newAutoLayoutView];
	self.wantToHearLabel.text = NSLocalizedString(@"WantToHearTitle", nil);
	self.wantToHearLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:[LMLayoutManager isExtraSmall] ? 18.0f : 22.0f];
	self.wantToHearLabel.textColor = [UIColor blackColor];
	self.wantToHearLabel.textAlignment = NSTextAlignmentLeft;
	[self.wantToHearBackgroundView addSubview:self.wantToHearLabel];

	[self.wantToHearLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.wantToHearLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.wantToHearLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.wantToHearAddSongsButtonView];
	
	
	self.dontWantToHearBackgroundView = [UIView newAutoLayoutView];
	
	self.dontWantToHearAddSongsButtonView = [UIView newAutoLayoutView];
	self.dontWantToHearAddSongsButtonView.backgroundColor = [LMColour darkGreyColour];
	self.dontWantToHearAddSongsButtonView.layer.masksToBounds = YES;
	self.dontWantToHearAddSongsButtonView.layer.cornerRadius = 6.0f;
	[self.dontWantToHearBackgroundView addSubview:self.dontWantToHearAddSongsButtonView];
	
	UITapGestureRecognizer *dontWantToHearTapGestureRecognizer = [[UITapGestureRecognizer alloc] initWithTarget:self action:@selector(addConditionsButtonTapped:)];
	[self.dontWantToHearAddSongsButtonView addGestureRecognizer:dontWantToHearTapGestureRecognizer];
	
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTrailing];
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeTop];
	[self.dontWantToHearAddSongsButtonView autoPinEdgeToSuperviewEdge:ALEdgeBottom];
	[self.dontWantToHearAddSongsButtonView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionHeight ofView:self.dontWantToHearAddSongsButtonView];
	
	UIImageView *addSongsDontWantIconImageView = [UIImageView newAutoLayoutView];
	addSongsDontWantIconImageView.contentMode = UIViewContentModeScaleAspectFit;
	addSongsDontWantIconImageView.image = [LMAppIcon imageForIcon:LMIconAdd];
	[self.dontWantToHearAddSongsButtonView addSubview:addSongsDontWantIconImageView];
	
	[addSongsDontWantIconImageView autoCentreInSuperview];
	[addSongsDontWantIconImageView autoMatchDimension:ALDimensionWidth toDimension:ALDimensionWidth ofView:self.dontWantToHearAddSongsButtonView withMultiplier:(5.0/10.0)];
	[addSongsDontWantIconImageView autoMatchDimension:ALDimensionHeight toDimension:ALDimensionWidth ofView:addSongsDontWantIconImageView];
	
	
	self.dontWantToHearLabel = [UILabel newAutoLayoutView];
	self.dontWantToHearLabel.text = NSLocalizedString(@"DontWantToHearTitle", nil);
	self.dontWantToHearLabel.font = [UIFont fontWithName:@"HelveticaNeue" size:[LMLayoutManager isExtraSmall] ? 18.0f : 22.0f];
	self.dontWantToHearLabel.textColor = [UIColor blackColor];
	self.dontWantToHearLabel.textAlignment = NSTextAlignmentLeft;
	[self.dontWantToHearBackgroundView addSubview:self.dontWantToHearLabel];
	
	[self.dontWantToHearLabel autoPinEdgeToSuperviewEdge:ALEdgeLeading];
	[self.dontWantToHearLabel autoAlignAxisToSuperviewAxis:ALAxisHorizontal];
	[self.dontWantToHearLabel autoPinEdge:ALEdgeTrailing toEdge:ALEdgeLeading ofView:self.dontWantToHearAddSongsButtonView];
	
	[self reloadConditionsLabelAndWarningBox];
	
	[NSTimer scheduledTimerWithTimeInterval:0.5 block:^{
//		if(WINDOW_FRAME.size.height < 340){
//			[self.warningBoxView hide];
//			[self reloadImagePickerTopConstraint];
//		}
	} repeats:NO];
}

- (void)loadView {
	self.view = [UIView new];
	self.view.backgroundColor = [UIColor whiteColor];
}

- (void)didReceiveMemoryWarning {
	[super didReceiveMemoryWarning];
}

- (instancetype)init {
	self = [super init];
	if(self){
		self.restorationIdentifier = [[self class] description];
		self.restorationClass = [self class];
	}
	return self;
}

/* End initialization code */

@end
