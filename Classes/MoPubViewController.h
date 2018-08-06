//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "MoPub.h"
#import "MPInterstitialAdController.h"
#import "MPRewardedVideo.h"

@import SpotX;

@interface MoPubViewController : UIViewController <MPInterstitialAdControllerDelegate, MPRewardedVideoDelegate,
                                                   UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@property(strong) IBOutlet UILabel* versionLabel;

@end

