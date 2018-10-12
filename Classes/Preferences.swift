//
//  Copyright © 2018 SpotX. All rights reserved.
//

import Foundation
import SpotX

// Global ad preferences
class Preferences {
  // Keys used by the app
  enum Key: String {
    case VPAID                = "VPAID"           // VPAID enabled?
    
    case POD_ENABLE           = "PodEnable"       // Do podding?
    case POD_COUNT            = "PodCount"        // How many ads in the pod?
    case POD_AD_DURATION      = "PodAdDuration"   // Maximum duration for each ad in the pod
    case POD_DURATION         = "PodDuration"     // Maximum duration of the entire pod
    
    case GDPR_ENABLE          = "GDPREnable"      // Add GDPR variables to the request?
    case GDPR_CONSENT         = "GDPRConsent"     // The consent string to use for GDPR
    
    case CHANNEL              = "Channel"         // Channel ID
    case MOPUB_INTERSTITIAL   = "MoPubI"          // Ad Unit ID (MoPub, Interstitial)
    case MOPUB_REWARDED       = "MoPubR"          // Ad Unit ID (MoPub, Rewarded)
    case ADMOB_INTERSTITIAL   = "AdMobI"          // Ad Unit ID (AdMob, Interstitial)
    case ADMOB_REWARDED       = "AdMobR"          // Ad Unit ID (AdMob, Rewarded)
  }
  
  // Default value when we can't find the User Default
  public static let DEFAULT_CHANNEL_ID  = "85394"
  
  // Demo API key
  public static let SPOTX_API_KEY       = "apikey-1234"
  
  // Getters/settings for preference values
  public static func string(forKey: Key) -> String? {
    return UserDefaults.standard.string(forKey: forKey.rawValue)
  }
  
  public static func bool(forKey: Key) -> Bool? {
    return UserDefaults.standard.bool(forKey: forKey.rawValue)
  }
  
  public static func set(_ value: Bool, forKey: Key) {
    UserDefaults.standard.set(value, forKey: forKey.rawValue)
  }
  
  public static func set(_ value: String, forKey: Key) {
    UserDefaults.standard.set(value, forKey: forKey.rawValue)
  }
  
  // Used to build SpotXAdRequests, since preferences are application-wide
  public static func getAdRequest() -> SpotXAdRequest {
    
    // Create a request with your API key
    let request = SpotXAdRequest(apiKey: "apikey-1234")!
    
    let channelId = string(forKey: .CHANNEL) ?? DEFAULT_CHANNEL_ID
    request.setChannel(channelId)
    
    // This is how to request a VPAID ad
    if bool(forKey: .VPAID) == true {
      request.setParam("VPAID", value: "js")
    }
    
    // This is how to use podding
    if bool(forKey: .POD_ENABLE) == true {
      let podSize = string(forKey: .POD_COUNT) ?? "3"
      let podAdDuration = string(forKey: .POD_AD_DURATION) ?? "60"
      let podDuration = string(forKey: .POD_DURATION) ?? "180"
      
      request.setCustom("pod[size]", value: podSize)
      request.setCustom("pod[max_ad_dur]", value: podAdDuration)
      request.setCustom("pod[max_pod_dur]", value: podDuration)
    }
    
    // This is how to enable GDPR with a consent string
    if bool(forKey: .GDPR_ENABLE) == true {
      let userConsentString = string(forKey: .GDPR_CONSENT) ?? ""
      UserDefaults.standard.set("1", forKey: "IABConsent_SubjectToGDPR")
      UserDefaults.standard.set(userConsentString, forKey: "IABConsent_ConsentString")
      UserDefaults.standard.synchronize()
    } else {
      UserDefaults.standard.removeObject(forKey: "IABConsent_SubjectToGDPR")
      UserDefaults.standard.removeObject(forKey: "IABConsent_ConsentString")
      UserDefaults.standard.synchronize()
    }
    
    // This is what KVPs look like where `multiple=false`
    // request.setCustom("custom[production_year]", value: "1999")
    
    // This is what KVPs look like where `multiple=true`
    // request.setCustom("custom[production_year]", value: "1999")
    // request.setCustom("custom[trucks]", values: ["Ford", "Toyota", "Chevrolet"])
    
    // This is what Custom Macros look like
    // request.setCustom("token[cm-key]", value: "cm-value")
    // request.setCustom("token[cms-key]", values: ["cms-value1", "cms-value2", "cms-value3"])
    
    return request
  }
}
