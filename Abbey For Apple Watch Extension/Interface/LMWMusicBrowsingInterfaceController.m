//
//  LMWMusicBrowsingInterfaceController.m
//  Abbey For Apple Watch Extension
//
//  Created by Edwin Finch on 11/28/17.
//  Copyright © 2017 Lignite. All rights reserved.
//

#import "LMWMusicBrowsingInterfaceController.h"
#import "LMWCompanionBridge.h"

@interface LMWMusicBrowsingInterfaceController()

/**
 The bridge to the companion.
 */
@property LMWCompanionBridge *companionBridge;

@end

@implementation LMWMusicBrowsingInterfaceController

- (void)awakeWithContext:(id)context {
	NSDictionary *dictionaryContext = (NSDictionary*)context;
	
	[self setTitle:[dictionaryContext objectForKey:@"title"]];
}

- (void)willActivate {
	[self.loadingIcon setImageNamed:@"LoadingIcon/Activity"];
	[self.loadingIcon startAnimatingWithImagesInRange:NSMakeRange(0, 30)
											 duration:1.0
										  repeatCount:0];
}

@end
