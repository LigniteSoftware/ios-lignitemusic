//
//  LMMusicPickerController.h
//  Lignite Music
//
//  Created by Edwin Finch on 10/23/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "LMMusicPlayer.h"

@class LMMusicPickerController;

@protocol LMMusicPickerDelegate <NSObject>
@optional

/**
 The music picker finished picking music (the user tapped "Done") and the track collections provided are the latest and greatest available.

 @param musicPicker The music picker which has finished selection.
 @param trackCollections The track collections which is the final product of the picker.
 */
- (void)musicPicker:(LMMusicPickerController*)musicPicker didFinishPickingMusicWithTrackCollections:(NSArray<LMMusicTrackCollection*>*)trackCollections;

/**
 The user cancelled picking music and the trackCollection that may exist should be ignored.

 @param musicPicker The music picker which the user cancelled for.
 */
- (void)musicPickerDidCancelPickingMusic:(LMMusicPickerController*)musicPicker;

@end

@interface LMMusicPickerController : UIViewController

/**
 The selection mode of the music picker controller, which determines how the music picker should handle the selections of tracks or collections.

 - LMMusicPickerSelectionModeOnlyTracks: The music picker should allow selection of only tracks. This is for uses such as the playlist builder, where the presentor requires a single collection of tracks.
 - LMMusicPickerSelectionModeAllCollections: The music picker should allow selection of collections. All results will be returned as instances of LMTrackCollection, even for individual tracks. This selection mode is for uses such as the dynamic playlist builder which require more broad selections or selections of whose data is mined for information.
 */
typedef NS_ENUM(NSInteger, LMMusicPickerSelectionMode) {
	LMMusicPickerSelectionModeOnlyTracks = 0,
	LMMusicPickerSelectionModeAllCollections
};

/**
 Sets a track as selected. If NO, the track will be removed from the trackCollection.

 @param track The track to change selection for.
 @param selected Whether or not the track is selected.
 */
//- (void)setTrack:(LMMusicTrack*)track asSelected:(BOOL)selected;

- (void)setCollection:(LMMusicTrackCollection*)collection asSelected:(BOOL)selected forMusicType:(LMMusicType)musicType;

/**
 Cancel the music picker.
 */
- (void)cancelSongSelection;

/**
 Finish picking music, and provide the trackCollection to the delegate.
 */
- (void)saveSongSelection;

/**
 The selection mode of the music picker. Default is LMMusicPickerSelectionModeOnlyTracks.
 */
@property LMMusicPickerSelectionMode selectionMode;

/**
 The delegate for music picking notifications.
 */
@property id<LMMusicPickerDelegate> delegate;

/**
 The track collections based off of the trackCollectionsData array of dictionaries.
 */
@property NSArray<LMMusicTrackCollection*> *trackCollections;

/**
 The music types associated with the above track collections based off of the trackCollectionsData array of dictionaries.
 */
@property NSArray<NSNumber*> *musicTypes;


@end
