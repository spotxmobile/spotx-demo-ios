//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "MoPubViewController.h"
#import "InlinePlaybackViewController.h"
#import "ResizablePlaybackViewController.h"

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
  _interstitialID.text = DEFAULT_INTERSTITIAL_ID;
  _rewardedID.text = DEFAULT_REWARDED_ID;
  
  _versionLabel.text = [NSString stringWithFormat:@"VERSION %@", [SpotX version]];
  
  // create "done" button on keyboard
  UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
  [keyboardDoneButtonView sizeToFit];
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done " style:UIBarButtonItemStylePlain target:self action:@selector(doneClicked:)];
  UIBarButtonItem *fakeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:fakeButton, doneButton, nil]];
  _interstitialID.inputAccessoryView = keyboardDoneButtonView;
  _rewardedID.inputAccessoryView = keyboardDoneButtonView;
}

-(IBAction)doneClicked:(id)sender
{
  [self.view endEditing:YES];
  [_interstitialID resignFirstResponder];
  [_rewardedID resignFirstResponder];
}

- (NSString *)interstitialID {
  NSString *channel = _interstitialID.text;
  if (![channel length]) {
    channel = DEFAULT_INTERSTITIAL_ID;
  }
  return channel;
}
- (NSString *)rewardedID {
  NSString *channel = _rewardedID.text;
  if (![channel length]) {
    channel = DEFAULT_REWARDED_ID;
  }
  return channel;
}

- (IBAction)playInterstitial:(id)sender {
  [self doneClicked:nil];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  // MoPub requires API key to be set via [SpotX setApiKey:]
  [SpotX setAPIKey:@"apikey-1234"];
  _adController = [MPInterstitialAdController interstitialAdControllerForAdUnitId:[self interstitialID]];
  if(_adController != nil){
    _adController.delegate = self;
    [_loadingIndicator startAnimating];
    [_adController loadAd];
  } else {
    [self showMessage:@"MoPub Failed To Create Ad Controller"];
  }
}

- (IBAction)playRewarded:(id)sender {
  [self doneClicked:nil];
  _playInterstitialButton.enabled = _playRewardedButton.enabled = NO;
  
  // MoPub requires API key to be set via [SpotX setApiKey:]
  [SpotX setAPIKey:@"apikey-1234"];
  [[MoPub sharedInstance] initializeRewardedVideoWithGlobalMediationSettings:nil delegate:self];
  [MPRewardedVideo loadRewardedVideoAdWithAdUnitID:[self rewardedID] withMediationSettings:nil];
  [_loadingIndicator startAnimating];
}

-(void)showMessage:(NSString *)message {
  UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * action) {}];
  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

- (void)showFail {
  [_loadingIndicator stopAnimating];
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
  [self showMessage:@"Ad Failed To Load"];
}

#pragma mark - Pop-up channel selector

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
    NSUInteger adUnitIndex = [presetUnits().allValues indexOfObject:_interstitialID.text];
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
}

#pragma mark - MPInterstitialAdControllerDelegate

- (void)interstitialDidLoadAd:(MPInterstitialAdController *)interstitial
{
  [_loadingIndicator stopAnimating];
  [_adController showFromViewController:self];
}

- (void)interstitialDidFailToLoadAd:(MPInterstitialAdController *)interstitial
{
  [self showFail];
}

- (void)interstitialDidDisappear:(MPInterstitialAdController *)interstitial
{
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)interstitialDidExpire:(MPInterstitialAdController *)interstitial
{
  _adController = nil;
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)interstitialDidReceiveTapEvent:(MPInterstitialAdController *)interstitial
{
  // nothing
}

#pragma mark - MPRewardedVideoDelegate

- (void)rewardedVideoAdDidLoadForAdUnitID:(NSString *)adUnitID {
  [_loadingIndicator stopAnimating];
  [MPRewardedVideo presentRewardedVideoAdForAdUnitID:adUnitID fromViewController:self withReward:nil];  // don't care about the reward
}

- (void)rewardedVideoAdDidFailToLoadForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  [self showFail];
}

- (void)rewardedVideoAdDidFailToPlayForAdUnitID:(NSString *)adUnitID error:(NSError *)error {
  [self showFail];
}

- (void)rewardedVideoAdDidDisappearForAdUnitID:(NSString *)adUnitID {
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

- (void)rewardedVideoAdDidExpireForAdUnitID:(NSString *)adUnitID {
  _playInterstitialButton.enabled = _playRewardedButton.enabled = YES;
}

@end
