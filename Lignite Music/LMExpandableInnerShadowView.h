//
//  LMExpandableInnerShadowView.h
//  Lignite Music
//
//  Created by Edwin Finch on 5/7/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMView.h"
#import "LMCollectionViewFlowLayout.h"

@interface LMExpandableInnerShadowView : LMView

/**
 The flow layout used for calculations of moving the triangle.
 */
@property LMCollectionViewFlowLayout *flowLayout;

@end
