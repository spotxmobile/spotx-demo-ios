//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import <SpotX/SpotX.h>
#import "ViewControllerBase.h"

@interface ViewControllerBase ()

@end

@implementation ViewControllerBase

- (void)viewDidLoad {
    [super viewDidLoad];
  
  // update version label
  _versionLabel.text = [NSString stringWithFormat:@"VERSION %@", [SpotX version]];
  
  // create "done" button on keyboard
  _keyboardDoneButtonView = [[UIToolbar alloc] init];
  [_keyboardDoneButtonView sizeToFit];
  UIBarButtonItem *doneButton = [[UIBarButtonItem alloc] initWithTitle:@"Done " style:UIBarButtonItemStylePlain target:self action:@selector(doneClicked:)];
  UIBarButtonItem *fakeButton = [[UIBarButtonItem alloc] initWithBarButtonSystemItem:UIBarButtonSystemItemFlexibleSpace target:nil action:nil];
  [_keyboardDoneButtonView setItems:[NSArray arrayWithObjects:fakeButton, doneButton, nil]];
}

- (void)doneClicked:(id)sender {
  [self dismissKeyboard];
}

- (void)backgroundTap:(UITapGestureRecognizer *)sender {
  [self dismissKeyboard];
}

- (void)dismissKeyboard {
}

-(void)showMessage:(NSString *)message {
  UIAlertController * alert = [UIAlertController alertControllerWithTitle:nil message:message preferredStyle:UIAlertControllerStyleAlert];
  
  UIAlertAction* defaultAction = [UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler: ^(UIAlertAction * action) {}];
  [alert addAction:defaultAction];
  [self presentViewController:alert animated:YES completion:nil];
}

@end
