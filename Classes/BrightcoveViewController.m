//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import "BrightcoveViewController.h"
#import "BrightcovePlayerController.h"
#import "Preferences.h"
#import "SettingsViewController.h"

#define SEGMENT_MP4           0
#define SEGMENT_VPAID         1

#define PLAYER_SEGUE          @"playerSegue"
#define SETTINGS_SEGUE        @"settingsSegue"

@interface BrightcoveViewController ()

@end

@implementation BrightcoveViewController {
  __weak IBOutlet UISegmentedControl *_vpaidControl;
  
  __weak IBOutlet UITextField *_channelIDField;
}

- (void)viewDidLoad {
  [super viewDidLoad];
  
  // create "done" button on keyboard
  UIToolbar *keyboardDoneButtonView = [[UIToolbar alloc] init];
  [keyboardDoneButtonView sizeToFit];
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done " style:UIBarButtonItemStylePlain target:self action:@selector(doneClicked:)];
  UIBarButtonItem *fakeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [keyboardDoneButtonView setItems:[NSArray arrayWithObjects:fakeButton, doneButton, nil]];
  _channelIDField.inputAccessoryView = keyboardDoneButtonView;
  _channelIDField.delegate = self;
}

- (void)viewWillAppear:(BOOL)animated {
  // Update preference display
  _channelIDField.text = [Preferences stringForKey:PREF_SDK_CHANNEL withDefault:DEFAULT_CHANNEL_ID];
  _vpaidControl.selectedSegmentIndex = [Preferences boolForKey:PREF_VPAID withDefault:NO] ? SEGMENT_VPAID : SEGMENT_MP4;
}

- (void)didReceiveMemoryWarning {
  [super didReceiveMemoryWarning];
  // Dispose of any resources that can be recreated.
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

#pragma mark - Navigation

// In a storyboard-based application, you will often want to do a little preparation before navigation
- (void)prepareForSegue:(UIStoryboardSegue *)segue sender:(id)sender {
  if([segue.identifier isEqual:PLAYER_SEGUE]){
    // Opening the player. Update channel ID first.
    [self updateChannelID];
  } else if([segue.identifier isEqual:SETTINGS_SEGUE]){
    // When displaying the settings screen, ask it to display a blue toolbar to match the screen
    [(SettingsViewController*)segue.destinationViewController setPreferredTint:[UIColor colorWithRed:0. green:0x7A/255. blue:1. alpha:1.]];
  }
}

@end

