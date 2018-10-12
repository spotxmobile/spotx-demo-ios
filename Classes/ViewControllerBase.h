//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface ViewControllerBase : UIViewController

@property(strong) IBOutlet UILabel* versionLabel;

@property(readonly) UIToolbar* keyboardDoneButtonView;

- (IBAction)backgroundTap:(UITapGestureRecognizer *)sender;

// Displays an alert message to the user
- (void)showMessage:(NSString*)message;

// Provided by subclasses
- (void)dismissKeyboard;

@end
