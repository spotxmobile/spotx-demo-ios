//
//  Copyright © 2018 SpotX, Inc. All rights reserved.
//

#import <UIKit/UIKit.h>

@interface SettingsViewController : UIViewController <UITableViewDataSource, UITableViewDelegate>

// Sets the preferred color for the toolbar (defaults to green)
- (void)setPreferredTint:(UIColor *)color;

@end
