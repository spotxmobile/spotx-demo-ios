//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "SDKViewController.h"
#import "InlinePlaybackViewController.h"
#import "ResizablePlaybackViewController.h"
#import "Preferences.h"

@import SpotX;
@import CoreLocation;

// Segmented control values

#define SEGMENT_INTERSTITIAL  0
#define SEGMENT_INLINE        1
#define SEGMENT_RESIZABLE     2

#define SEGMENT_MP4           0
#define SEGMENT_VPAID         1

@interface SDKViewController ()

@property(nonatomic, strong) SpotXInterstitialAdPlayer* player;

@end

@implementation SDKViewController {
  __weak IBOutlet UIActivityIndicatorView *_loadingIndicator;
  __weak IBOutlet UIButton *_playAdButton;
  __weak IBOutlet UISegmentedControl *_placementTypeControl;
  __weak IBOutlet UISegmentedControl *_vpaidControl;
  
  __weak IBOutlet UITextField *_channelIDField;
  
  InlinePlaybackViewController * _inlineVC;
  ResizablePlaybackViewController * _resizableVC;
  
  CLLocationManager* _locManager;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  _versionLabel.text = [NSString stringWithFormat:@"VERSION %@", [SpotX version]];
  
  // create "done" button on keyboard
  UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
  [keyboardDoneButtonView sizeToFit];
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done " style:UIBarButtonItemStylePlain target:self action:@selector(doneClicked:)];
  UIBarButtonItem *fakeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:fakeButton, doneButton, nil]];
  _channelIDField.inputAccessoryView = keyboardDoneButtonView;
  _channelIDField.delegate = self;
  
  // Request location permissions if they haven't been granted yet.
  // In your own app, you can do this at any time to enable geo-targeting. If you don't request permission, or if the user denies it,
  // the SDK will not pass location info.
  if(!_locManager){
    _locManager = [[CLLocationManager alloc] init];
    [_locManager requestWhenInUseAuthorization];
  }
}

- (void)viewWillAppear:(BOOL)animated {
  [super viewWillAppear:animated];
  
  // Update preference display
  _channelIDField.text = [Preferences stringForKey:PREF_SDK_CHANNEL withDefault:DEFAULT_CHANNEL_ID];
  _vpaidControl.selectedSegmentIndex = [Preferences boolForKey:PREF_VPAID withDefault:NO] ? SEGMENT_VPAID : SEGMENT_MP4;
  
  if (_inlineVC) {
    // must be appearing after the inline viewcontroller has already been displayed
    _inlineVC = nil;
    _playAdButton.enabled = YES;
    _player = nil;
  }
  
  if (_resizableVC) {
    // must be appearing after the resizable viewcontroller has already been displayed
    _resizableVC = nil;
    _playAdButton.enabled = YES;
    _player = nil;
  }
}

- (IBAction)setVPAID:(UISegmentedControl *)sender {
  BOOL enable = sender.selectedSegmentIndex == SEGMENT_VPAID;
  [Preferences setBool:enable forKey:PREF_VPAID];
}

-(IBAction)doneClicked:(id)sender
{
  [self.view endEditing:YES];
  [_channelIDField resignFirstResponder];
}

-(IBAction)backgroundTap:(UITapGestureRecognizer *)sender {
  [self.view endEditing:YES];
  [_channelIDField resignFirstResponder];
}

- (void)updateChannelID {
  NSString* channelID = _channelIDField.text;
  if (![channelID length]) {
    channelID = DEFAULT_CHANNEL_ID;
    [_channelIDField setText:channelID];
  }
  [Preferences setString:channelID forKey:PREF_SDK_CHANNEL];
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
  [self updateChannelID];
}

- (IBAction)play:(id)sender {
  [_channelIDField resignFirstResponder];
  _playAdButton.enabled = NO;

  switch (_placementTypeControl.selectedSegmentIndex) {
    case SEGMENT_INTERSTITIAL:
      [self playInterstitial];
      break;
    case SEGMENT_INLINE:
      [self playInline];
      break;
    case SEGMENT_RESIZABLE:
      [self playResizable];
      break;
  }
}

-(void)showMessage:(NSString *)message {
  UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];

  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * action) {}];
  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

-(void) playInterstitial {
  [_loadingIndicator startAnimating];

  _player = [[SpotXInterstitialAdPlayer alloc] init];
  _player.delegate = self;
  [_player load];
}

-(void)playInline {
  _inlineVC = [InlinePlaybackViewController newInstance];
  [self presentViewController:_inlineVC animated:YES completion:^{
    [_inlineVC playAd];
  }];
}

-(void)playResizable {
  _resizableVC = [ResizablePlaybackViewController newInstance];
  [self presentViewController:_resizableVC animated:YES completion:^{
    [_resizableVC playAd];
  }];
}

#pragma mark - SpotXAdPlayerDelegate methods
- (SpotXAdRequest *_Nullable)requestForPlayer:(SpotXAdPlayer *_Nonnull)player {
  return [Preferences requestWithSettings];
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player didLoadAds:(SpotXAdGroup *_Nullable)group error:(NSError *_Nullable)error {
  [_loadingIndicator stopAnimating];
  
  if (group.ads.count > 0) {
    [player start];
  }
  else {
    [self showMessage:@"No Ads Available"];
    _playAdButton.enabled = YES;
  }
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupStart:(SpotXAdGroup *_Nonnull)group {

}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adGroupComplete:(SpotXAdGroup *_Nonnull)group {
  _playAdButton.enabled  = YES;
  _player = nil;
}


- (void)spotx:(SpotXAdPlayer *_Nonnull)player adTimeUpdate:(SpotXAd *_Nonnull)ad timeElapsed:(double)seconds {
  NSLog(@"SDK:Interstitial:adTimeUpdate: %f", seconds);
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adClicked:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Interstitial:adClicked");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adComplete:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Interstitial:adComplete");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adSkipped:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Interstitial:adSkipped");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adUserClose:(SpotXAd *_Nonnull)ad {
  NSLog(@"SDK:Interstitial:adUserClose");
}

- (void)spotx:(SpotXAdPlayer *_Nonnull)player adError:(SpotXAd *_Nullable)ad error:(NSError *_Nullable)error {
  _playAdButton.enabled = YES;
  _player = nil;

  NSLog(@"SDK:Interstitial:adError: %@", error.localizedFailureReason);
  [[self presentingViewController] dismissViewControllerAnimated:YES completion: ^() {
    [self showMessage:error.localizedDescription];
  }];
}

@end
