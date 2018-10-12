//
//  Copyright © 2017 SpotX, Inc. All rights reserved.
//

#import "Preferences.h"

@implementation Preferences

static NSUserDefaults *_userDefaults;

+(void)init
{
  if(_userDefaults == nil){
    _userDefaults = [NSUserDefaults standardUserDefaults];
  }
}

// BOOL

+(BOOL)boolForKey:(NSString *)key withDefault:(BOOL)def
{
  [self init];
  if([_userDefaults objectForKey:key] != nil){
    return [_userDefaults boolForKey:key];
  }
  return def;
}

+(void)setBool:(BOOL)b forKey:(NSString *)key
{
  [self init];
  [_userDefaults setBool:b forKey:key];
  [_userDefaults synchronize];
}

// NSSTRING

+(NSString *)stringForKey:(NSString *)key withDefault:(NSString *)def
{
  [self init];
  if([_userDefaults objectForKey:key] != nil){
    return [_userDefaults stringForKey:key];
  }
  return def;
}

+(void)setString:(NSString *)string forKey:(NSString *)key
{
  [self init];
  [_userDefaults setObject:string forKey:key];
  [_userDefaults synchronize];
}

+ (SpotXAdRequest *)requestWithSettings {
  // Create a request with your API key
  SpotXAdRequest * request = [[SpotXAdRequest alloc] initWithApiKey:@"apikey-1234"];
  
  NSString* channelID = [Preferences stringForKey:PREF_SDK_CHANNEL withDefault:DEFAULT_CHANNEL_ID];
  [request setChannel: channelID];
  
  // This is how to request a VPAID ad
  if([Preferences boolForKey:PREF_VPAID withDefault:NO])
    [request setParam:@"VPAID" value:@"js"];
  
  // This is how to use podding
  if ([Preferences boolForKey:PREF_POD_ENABLE withDefault:NO]) {
    NSString *podSize = [Preferences stringForKey:PREF_POD_COUNT withDefault:@"3"];
    NSString *podAdDuration = [Preferences stringForKey:PREF_POD_AD_DURATION withDefault:@"60"];
    NSString *podDuration = [Preferences stringForKey:PREF_POD_DURATION withDefault:@"180"];
    
    [request setCustom:@"pod[size]" value:podSize];
    [request setCustom:@"pod[max_ad_dur]" value:podDuration];
    [request setCustom:@"pod[max_pod_dur]" value:podAdDuration];
  }
  
  // This is how to enable GDPR with a consent string
  if ([Preferences boolForKey:PREF_GDPR_ENABLE withDefault:NO]) {
    NSString *userConsentString = [Preferences stringForKey:PREF_GDPR_CONSENT withDefault:@"GDPR Consent String"];

    [_userDefaults setObject:@"1" forKey:@"IABConsent_SubjectToGDPR"];
    [_userDefaults setObject:userConsentString forKey:@"IABConsent_ConsentString"];
    [_userDefaults synchronize];
  } else {
    [_userDefaults removeObjectForKey:@"IABConsent_SubjectToGDPR"];
    [_userDefaults removeObjectForKey:@"IABConsent_ConsentString"];
    [_userDefaults synchronize];
  }
  
  // This is what KVPs look like where `multiple=false`
  // [request setCustom:@"custom[production_year]" value:@"1999"];
  
  // This is what KVPs look like where `multiple=true`
  // [request setCustom:@"custom[production_year]" values:@[@"1999"]];
  // [request setCustom:@"custom[trucks]" values:@[@"Ford", @"Toyota", @"Chevrolet"]];
  
  // This is what Custom Macros look like
  // [request setCustom:@"token[cm-key]" value:@"cm-value"];
  // [request setCustom:@"token[cms-key]" values:@[@"cms-value1", @"cms-value2", @"cms-value3"]];
  
  return request;
}

@end
