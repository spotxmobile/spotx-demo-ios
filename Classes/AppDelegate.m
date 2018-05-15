//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "AppDelegate.h"
@import SpotX;

@implementation AppDelegate

- (BOOL)application:(UIApplication *)application didFinishLaunchingWithOptions:(NSDictionary *)launchOptions {

  self.window = [[UIWindow alloc] initWithFrame:[UIScreen mainScreen].bounds];
  self.window.rootViewController = [[UIStoryboard storyboardWithName:@"MainViewController" bundle:nil] instantiateInitialViewController];
  [self.window makeKeyAndVisible];
  [SpotX debugMode:YES];
  return YES;
}

@end
