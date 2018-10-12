//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "MoPubViewController.h"
#import "InlinePlaybackViewController.h"
#import "ResizablePlaybackViewController.h"
#import "Preferences.h"

@import SpotX;

#define DEFAULT_INTERSTITIAL_ID  @"034709d6e1a4493d8b5da8c7a3e0249c"
#define DEFAULT_REWARDED_ID  @"e3b23c46dd6a41d1a2f049eea9ca2f81"

static NSDictionary* presetUnits(){
  static NSDictionary *units;
  static dispatch_once_t onceToken;
  dispatch_once(&onceToken, ^{
    units = @{
              @"MP4 Ad": @"034709d6e1a4493d8b5da8c7a3e0249c",
              @"VPAID Ad": @"ec9e43b19e8646c19f28f08581153472",
              @"Podded Ad": @"b102fcc5233b48e0b52eaee1fad500c6"
              };
  });
  return units;
}

@interface MoPubViewController ()

@property(nonatomic, strong) SpotXInterstitialAdPlayer* player;

@end

@implementation MoPubViewController {
  __weak IBOutlet UIActivityIndicatorView *_loadingIndicator;
  __weak IBOutlet UIButton *_playInterstitialButton;
  __weak IBOutlet UIButton *_playRewardedButton;
  
  IBOutlet UITextField *_interstitialID;
  IBOutlet UITextField *_rewardedID;
  MPInterstitialAdController *_adController;
  BOOL customAdUnit;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  _interstitialID.text = [Preferences stringForKey:PREF_MOPUB_INTERSTITIAL withDefault:DEFAULT_INTERSTITIAL_ID];
  _rewardedID.text = [Preferences stringForKey:PREF_MOPUB_REWARDED withDefault:DEFAULT_REWARDED_ID];
  
  _interstitialID.delegate = self;
  _rewardedID.delegate = self;
}

- (void)dismissKeyboard {
  [self.view endEditing:YES];
  [_interstitialID resignFirstResponder];
  [_rewardedID resignFirstResponder];
}

- (NSString *)interstitialID {
  NSString *adId = _interstitialID.text;
  if (![adId length]) {
    adId = DEFAULT_INTERSTITIAL_ID;
    _interstitialID.text = adId;
  }
  return adId;
}

- (NSString *)rewardedID {
  NSString *adId = _rewardedID.text;
  if (![adId length]) {
    adId = DEFAULT_REWARDED_ID;
    _rewardedID.text = adId;
  }
  return adId;
}

- (void)updateAdIDs {
  [Preferences setString:[self interstitialID] forKey:PREF_MOPUB_INTERSTITIAL];
  [Preferences setString:[self rewardedID] forKey:PREF_MOPUB_REWARDED];
}

- (IBAction)playInterstitial:(id)sender {
  [self dismissKeyboard];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  // MoPub requires a global API key as it can't be set per-request
  [SpotX setAPIKey:SPOTX_API_KEY];
  
  _adController = [MPInterstitialAdController interstitialAdControllerForAdUnitId:[self interstitialID]];
  if(_adController != nil){
    _adController.delegate = self;
    [_loadingIndicator startAnimating];
    [_adController loadAd];
  } else {
    [self showMessage:@"Failed to create MoPub ad controller"];
  }
}

- (IBAction)playRewarded:(id)sender {
  [self dismissKeyboard];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  // MoPub requires a global API key as it can't be set per-request
  [SpotX setAPIKey:SPOTX_API_KEY];
  
  [[MoPub sharedInstance] initializeRewardedVideoWithGlobalMediationSettings:nil delegate:self];
  [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:[self rewardedID] withMediationSettings:nil];
  [_loadingIndicator startAnimating];
}

- (void)showAdFailure {
  [_loadingIndicator stopAnimating];
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
  [self showMessage:@"Ad playback failed"];
}

#pragma mark - Pop-up ad unit selector

-(void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if ([segue.identifier isEqualToString:@"pickerSegue"]) {
    // Showing the pop-up with picker view
    UIViewController *vc = [segue destinationViewController];
    vc.modalPresentationStyle = UIModalPresentationPopover;
    vc.popoverPresentationController.delegate = self;
    
    // Set ourselves as the picker source
    UIPickerView* picker = vc.view.subviews[0];
    picker.delegate = self;
    picker.dataSource = self;
    // Select the current ad unit (if any)
    NSUInteger adUnitIndex = [presetUnits().allValues indexOfObject:[self interstitialID]];
    if(adUnitIndex != NSNotFound){
      customAdUnit = NO;
      [picker selectRow:adUnitIndex inComponent:0 animated:NO];
    } else {
      customAdUnit = YES;
      [picker selectRow:presetUnits().count inComponent:0 animated:NO];
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
  return presetUnits().count + (customAdUnit ? 1 : 0);
}

- (NSString *)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
  if(row >= presetUnits().count){
    return @"---";
  }
  return presetUnits().allKeys[row];
}

- (void)pickerView:(UIPickerView *)pickerView didSelectRow:(NSInteger)row inComponent:(NSInteger)component {
  // Set Ad Unit text field to the selected ad
  NSString* adUnit = presetUnits().allValues[row];
  [_interstitialID setText:adUnit];
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

#pragma mark - MPInterstitialAdControllerDelegate

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial
{
  NSLog(@"MoPub:interstitialDidLoadAd");
  // Ad loaded; play the ad
  [_loadingIndicator stopAnimating];
  [_adController showFromViewController:self];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
{
  NSLog(@"MoPub:interstitialDidFailToLoadAd");
  [self showAdFailure];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial
{
  NSLog(@"MoPub:interstitialDidDisappear");
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial
{
  NSLog(@"MoPub:interstitialDidExpire");
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial
{
  // Use this event to monitor click-thru
  NSLog(@"MoPub:interstitialDidReceiveTapEvent");
}

#pragma mark - MPRewardedVideoDelegate

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  NSLog(@"MoPub:rewardedVideoAdDidLoad");
  [_loadingIndicator stopAnimating];
  [MPRewardedVideo presentRewardedVideoAdForAdUnitID:adUnitID fromViewController:self withReward:nil];    // add your reward here
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  NSLog(@"MoPub:rewardedVideoAdDidFailToLoad");
  [self showAdFailure];
}

- (void)rewardedVideoAdDidFailToPlayForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  NSLog(@"MoPub:rewardedVideoAdDidFailToPlay");
  [self showAdFailure];
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  NSLog(@"MoPub:rewardedVideoAdDidDisappear");
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  NSLog(@"MoPub:rewardedVideoAdDidExpire");
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

@end
