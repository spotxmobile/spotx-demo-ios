//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@import SpotX;

@interface InlinePlaybackViewController : UIViewController <SpotXAdPlayerDelegate>

+ (instancetype)newInstance;

- (void)playAd;

- (IBAction)dismiss:(id)sender;

@end
