//
//  AdMobViewController.h
//  SpotX-Demo-ObjC
//

#import <UIKit/UIKit.h>
#import "ViewControllerBase.h"
#import "MoPub.h"
#import "MPInterstitialAdController.h"
#import "MPRewardedVideo.h"

@import SpotX;
@import GoogleMobileAds;

@interface AdMobViewController : ViewControllerBase <GADInterstitialDelegate, GADRewardBasedVideoAdDelegate, UITextFieldDelegate, UIPopoverPresentationControllerDelegate, UIPickerViewDataSource, UIPickerViewDelegate>

@end
