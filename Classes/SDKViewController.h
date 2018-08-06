//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@import SpotX;

@interface SDKViewController : UIViewController <SpotXAdPlayerDelegate, UITextFieldDelegate>

@property(strong) IBOutlet UILabel* versionLabel;

@end

