//
//  LMMusicCollectionsView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/15/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMMusicPlayer.h"

@interface LMMusicCollectionsView : LMView

/**
 The actual collection view for displaying collections in a compact method.
 */
@property UICollectionView *collectionView;

/**
 The track collections for the music collections view to display.
 */
@property NSArray<LMMusicTrackCollection*> *trackCollections;

@end
