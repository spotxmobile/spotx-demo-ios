//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "AdMobViewController.h"
#import "InlinePlaybackViewController.h"
#import "ResizablePlaybackViewController.h"
#import "Preferences.h"

@import SpotX;
@import GoogleMobileAds;

#define SPOTX_ADMOB_APPID @"ca-app-pub-3831702055122907~6634335857"

#define SPOTX_INTERSTITIAL_ID  @"ca-app-pub-3831702055122907/7657534644"
#define SPOTX_REWARDED_ID  @"ca-app-pub-3831702055122907/3610069309"

static NSDictionary* interPresetUnits(){
  static NSDictionary *units;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    units = @{
              @"Google Ad Unit": @"ca-app-pub-3940256099942544/4411468910",
              @"SpotX Regular Ad Unit": SPOTX_INTERSTITIAL_ID,
              @"SpotX VPAID Ad Unit": @"ca-app-pub-3831702055122907/6100501279",
              @"SpotX Podding Ad Unit": @"ca-app-pub-3831702055122907/2943854894"
              };
  });
  return units;
}

static NSDictionary* rewardPresetUnits(){
  static NSDictionary *units;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    units = @{
              @"Google Ad Unit": @"ca-app-pub-3940256099942544/1712485313",
              @"SpotX Regular Ad Unit": SPOTX_REWARDED_ID,
              @"SpotX VPAID Ad Unit": @"ca-app-pub-3831702055122907/2161256264",
              @"SpotX Podding Ad Unit": @"ca-app-pub-3831702055122907/2313299501"
              };
  });
  return units;
}

@implementation AdMobViewController {
  __weak IBOutlet UIActivityIndicatorView *_loadingIndicator;
  __weak IBOutlet UIButton *_playInterstitialButton;
  __weak IBOutlet UIButton *_playRewardedButton;
  
  IBOutlet UITextField *_interstitialID;
  IBOutlet UITextField *_rewardedID;
  GADInterstitial *_interstitial;
  
  // For the UIPicker
  __weak NSDictionary *_presetUnits;
  __weak UITextField *_pickerField;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _interstitialID.text = [Preferences stringForKey:PREF_ADMOB_INTERSTITIAL withDefault:SPOTX_INTERSTITIAL_ID];
  _rewardedID.text = [Preferences stringForKey:PREF_ADMOB_REWARDED withDefault:SPOTX_REWARDED_ID];
  
  _interstitialID.delegate = self;
  _rewardedID.delegate = self;
  
  [GADMobileAds configureWithApplicationID:SPOTX_ADMOB_APPID];
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
  [_interstitialID resignFirstResponder];
  [_rewardedID resignFirstResponder];
}

- (NSString *)interstitialID {
  NSString *adId = _interstitialID.text;
  if (![adId length]) {
    adId = SPOTX_INTERSTITIAL_ID;
    _interstitialID.text = adId;
  }
  return adId;
}

- (NSString *)rewardedID {
  NSString *adId = _rewardedID.text;
  if (![adId length]) {
    adId = SPOTX_REWARDED_ID;
    _rewardedID.text = adId;
  }
  return adId;
}

- (void)updateAdIDs {
  [Preferences setString:[self interstitialID] forKey:PREF_ADMOB_INTERSTITIAL];
  [Preferences setString:[self rewardedID] forKey:PREF_ADMOB_REWARDED];
}

- (IBAction)playInterstitial:(id)sender {
  [self dismissKeyboard];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  GADRequest *request = [GADRequest request];
  
  request.testDevices = @[ kGADSimulatorID ];
  GADCustomEventExtras *extras = [[GADCustomEventExtras alloc] init];
  
  [extras setExtras:@{@"SampleExtra": @(YES)} forLabel:@"ObjC Interstitial"];
  [request registerAdNetworkExtras:extras];
  
  _interstitial = [[GADInterstitial alloc]
                       initWithAdUnitID:[self interstitialID]];
  if (_interstitial != nil) {
    _interstitial.delegate = self;
    [_loadingIndicator startAnimating];
    [_interstitial loadRequest:request];
  } else {
    [self showMessage:@"Failed to create AdMob interstitial"];
  }
}

- (IBAction)playRewarded:(id)sender {
  [self dismissKeyboard];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  GADRequest *request = [GADRequest request];
  GADCustomEventExtras *extras = [[GADCustomEventExtras alloc] init];
  [extras setExtras:@{@"SampleExtra": @(YES)} forLabel:@"ObjC Rewarded"];
  [request registerAdNetworkExtras:extras];
  
  [GADRewardBasedVideoAd sharedInstance].delegate = self;
  [[GADRewardBasedVideoAd sharedInstance] loadRequest:request
                                         withAdUnitID:[self rewardedID]];
  
  [_loadingIndicator startAnimating];
}

- (void)showAdFailure {
  [_loadingIndicator stopAnimating];
  _interstitial = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
  [self showMessage:@"Ad playback failed"];
}

#pragma mark - Pop-up ad unit selector

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  BOOL isInterSegue = [segue.identifier isEqualToString:@"interPickerSegue"];
  BOOL isRewardSegue = [segue.identifier isEqualToString:@"rewardPickerSegue"];
  
  if (isInterSegue || isRewardSegue) {
    NSUInteger adUnitIndex = NSNotFound;
    if (isInterSegue) {
      _presetUnits = interPresetUnits();
      adUnitIndex = [_presetUnits.allValues indexOfObject:[self interstitialID]];
      _pickerField = _interstitialID;
    } else if (isRewardSegue) {
      _presetUnits = rewardPresetUnits();
      adUnitIndex = [_presetUnits.allValues indexOfObject:[self rewardedID]];
      _pickerField = _rewardedID;
    }
    
    // Showing the pop-up with picker view
    UIViewController *vc = [segue destinationViewController];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.popoverPresentationController.delegate = self;
    
    // Set ourselves as the picker source
    UIPickerView* picker = vc.view.subviews[0];
    picker.delegate = self;
    picker.dataSource = self;
    // Select the current ad unit (if any)
    if(adUnitIndex != NSNotFound){
      [picker selectRow:adUnitIndex inComponent:0 animated:NO];
    }
  }
}

-(UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller {
  return UIModalPresentationNone;
}

- (UIModalPresentationStyle)adaptivePresentationStyleForPresentationController:(UIPresentationController *)controller traitCollection:(UITraitCollection *)traitCollection {
  return UIModalPresentationNone;
}

- (NSInteger)numberOfComponentsInPickerView:(UIPickerView *)pickerView {
  return 1;
}

- (NSInteger)pickerView:(UIPickerView *)pickerView numberOfRowsInComponent:(NSInteger)component {
  return _presetUnits.count;
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  return _presetUnits.allKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  // Set Ad Unit text field to the selected ad
  NSString* adUnit = _presetUnits.allValues[row];
  [_pickerField setText:adUnit];
  [self updateAdIDs];
}

#pragma mark - UITextFieldDelegate

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self updateAdIDs];
}

- (BOOL)textFieldShouldReturn:(UITextField *)textField {
  [textField resignFirstResponder];
  return YES;
}

#pragma mark - GADInterstitialDelegate
- (void)interstitialDidReceiveAd:(GADInterstitial *)ad {
  NSLog(@"AdMob:interstitialDidReceiveAd");
  // Ad loaded; play the ad
  [_loadingIndicator stopAnimating];
  if (_interstitial.isReady) {
    [_interstitial presentFromRootViewController:self];
  } else {
    NSLog(@"AdMob:interstitialDidReceiveAd - Ad Not Ready");
  }
}

- (void)interstitial:(GADInterstitial *)ad didFailToReceiveAdWithError:(GADRequestError *)error {
  NSLog(@"AdMob:didFailToReceiveAdWithError");
  [self showAdFailure];
}

- (void)interstitialDidFailToPresentScreen:(GADInterstitial *)ad {
  NSLog(@"AdMob:interstitialDidFailToPresentScreen");
  [self showAdFailure];
}

- (void)interstitialDidDismissScreen:(GADInterstitial *)ad {
  NSLog(@"AdMob:interstitialDidDismissScreen");
  _interstitial = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)interstitialWillLeaveApplication:(GADInterstitial *)ad {
  // Use this event to monitor click-thru
  NSLog(@"AdMob:interstitialWillLeaveApplication");
}

#pragma mark - GADRewardBasedVideoAdDelegate

- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
   didRewardUserWithReward:(GADAdReward *)reward {
  NSLog(@"AdMob:rewardBasedVideoAd:didRewardUserWithReward");
}

- (void)rewardBasedVideoAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd
    didFailToLoadWithError:(NSError *)error {
  NSLog(@"AdMob:rewardBasedVideoAd:didFailToLoadWithError");
  [self showAdFailure];
}

- (void)rewardBasedVideoAdDidReceiveAd:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
  NSLog(@"AdMob:rewardBasedVideoAdDidReceiveAd");
  [_loadingIndicator stopAnimating];
  if ([[GADRewardBasedVideoAd sharedInstance] isReady]) {
    [[GADRewardBasedVideoAd sharedInstance] presentFromRootViewController:self];
  } else {
    NSLog(@"AdMob:rewardBasedVideoAdDidReceiveAd - Ad Not Ready");
  }
}

- (void)rewardBasedVideoAdDidClose:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
  NSLog(@"AdMob:rewardBasedVideoAdDidClose");
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)rewardBasedVideoAdWillLeaveApplication:(GADRewardBasedVideoAd *)rewardBasedVideoAd {
  // Use this event to monitor click-thru
  NSLog(@"AdMob:rewardBasedVideoAdWillLeaveApplication");
}

@end

