//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "MoPub.h"
#import "MPInterstitialAdController.h"
#import "MPRewardedVideo.h"

@import SpotX;

@interface MoPubViewController : ViewControllerBase <MPInterstitialAdControllerDelegate, MPRewardedVideoDelegate,
                                                   UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@end

