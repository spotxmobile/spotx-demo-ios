//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

@import Foundation;
@import SpotX;

// Keys used by the app
#define PREF_VPAID                @"VPAID"            // VPAID enabled?

#define PREF_POD_ENABLE           @"PodEnable"        // Do podding?
#define PREF_POD_COUNT            @"PodCount"         // How many ads in the pod?
#define PREF_POD_AD_DURATION      @"PodAdDuration"    // Maximum duration for each ad in the pod
#define PREF_POD_DURATION         @"PodDuration"      // Maximum duration of the entire pod

#define PREF_GDPR_ENABLE          @"GDPREnable"       // Add GDPR variables to the request?
#define PREF_GDPR_CONSENT         @"GDPRConsent"      // The consent string to use for GDPR

#define PREF_SDK_CHANNEL          @"Channel"          // Channel ID (SDK view)
#define PREF_MOPUB_INTERSTITIAL   @"MoPubI"           // Ad Unit ID (MoPub, Interstitial)
#define PREF_MOPUB_REWARDED       @"MoPubR"           // Ad Unit ID (MoPub, Rewarded)
#define PREF_ADMOB_INTERSTITIAL   @"AdMobI"           // Ad Unit ID (AdMob, Interstitial)
#define PREF_ADMOB_REWARDED       @"AdMobR"           // Ad Unit ID (AdMob, Rewarded)

#define DEFAULT_CHANNEL_ID  @"85394"

#define SPOTX_API_KEY       @"apikey-1234"

// Global ad preferences
@interface Preferences : NSObject

// Get/set keys directly
+(BOOL)boolForKey:(NSString *)key withDefault:(BOOL)def;
+(void)setBool:(BOOL)b forKey:(NSString *)key;
+(NSString *)stringForKey:(NSString *)key withDefault:(NSString *)def;
+(void)setString:(NSString *)string forKey:(NSString *)key;

// Create an ad request with standard settings
+ (SpotXAdRequest *)requestWithSettings;

@end
