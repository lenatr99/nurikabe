//
//  AdManager.swift
//  Nurikabe
//
//  Created by Assistant on 1/2/26.
//

import UIKit
import SpriteKit
import GoogleMobileAds

/// Manages rewarded video ads for the hint system
/// Singleton pattern for easy access across the app
class AdManager: NSObject {
    
    // MARK: - Singleton
    static let shared = AdManager()
    
    // MARK: - Properties
    
    /// Ad Unit ID for rewarded video ads
    /// 
    /// ⚠️ PRODUCTION SETUP:
    /// 1. Create an AdMob account at https://admob.google.com
    /// 2. Register your app and create a Rewarded Ad Unit
    /// 3. Replace the test ID below with your production Ad Unit ID
    /// 4. Update your Info.plist with your App ID (GADApplicationIdentifier)
    ///
    /// Test ID (for development): ca-app-pub-3940256099942544/1712485313
    /// Production ID format: ca-app-pub-XXXXXXXXXXXXXXXX/XXXXXXXXXX
    // Use test ads in DEBUG, production ads in Release
    #if DEBUG
    private let rewardedAdUnitID = "ca-app-pub-3940256099942544/1712485313" // Google test ID
    #else
    private let rewardedAdUnitID = "ca-app-pub-2418403466454518/5975289869" // Your production ID
    #endif
    
    private var rewardedAd: RewardedAd?
    private var rewardCompletion: ((Bool) -> Void)?
    private var isLoading = false
    
    // MARK: - Initialization
    
    private override init() {
        super.init()
    }
    
    /// Initialize the AdMob SDK - call this from AppDelegate
    static func configure() {
        MobileAds.shared.start { status in
            NSLog("📺 AdMob SDK initialized with status: \(status.adapterStatusesByClassName)")
            // Preload first ad
            AdManager.shared.loadRewardedAd()
        }
    }
    
    // MARK: - Ad Loading
    
    /// Preload a rewarded ad for better UX
    func loadRewardedAd() {
        guard !isLoading && rewardedAd == nil else { return }
        
        isLoading = true
        NSLog("📺 Loading rewarded ad...")
        
        let request = Request()
        
        RewardedAd.load(with: rewardedAdUnitID, request: request) { [weak self] ad, error in
            self?.isLoading = false
            
            if let error = error {
                NSLog("❌ Failed to load rewarded ad: \(error.localizedDescription)")
                return
            }
            
            self?.rewardedAd = ad
            self?.rewardedAd?.fullScreenContentDelegate = self
            NSLog("✅ Rewarded ad loaded successfully")
        }
    }
    
    // MARK: - Ad Presentation
    
    /// Check if an ad is ready to show
    var isAdReady: Bool {
        return rewardedAd != nil
    }
    
    /// Show rewarded ad and call completion with success/failure
    /// - Parameters:
    ///   - viewController: The view controller to present from
    ///   - completion: Called with true if user earned reward, false otherwise
    func showRewardedAd(from viewController: UIViewController, completion: @escaping (Bool) -> Void) {
        guard let rewardedAd = rewardedAd else {
            NSLog("⚠️ No rewarded ad available")
            completion(false)
            // Try to load one for next time
            loadRewardedAd()
            return
        }
        
        self.rewardCompletion = completion
        
        rewardedAd.present(from: viewController) { [weak self] in
            // User earned the reward
            let reward = rewardedAd.adReward
            NSLog("🎁 User earned reward: \(reward.amount) \(reward.type)")
            self?.rewardCompletion?(true)
            self?.rewardCompletion = nil
        }
    }
    
    /// Show rewarded ad with a simple callback for SpriteKit scenes
    /// - Parameters:
    ///   - scene: The SKScene requesting the ad
    ///   - completion: Called with true if user earned reward
    func showRewardedAd(from scene: SKScene, completion: @escaping (Bool) -> Void) {
        guard let viewController = scene.view?.window?.rootViewController else {
            NSLog("❌ Could not find root view controller")
            completion(false)
            return
        }
        
        showRewardedAd(from: viewController, completion: completion)
    }
}

// MARK: - FullScreenContentDelegate

extension AdManager: FullScreenContentDelegate {
    
    func adDidDismissFullScreenContent(_ ad: FullScreenPresentingAd) {
        NSLog("📺 Ad dismissed")
        // Clear the ad reference
        rewardedAd = nil
        // Preload next ad
        loadRewardedAd()
        
        // If completion wasn't called (user skipped), call with false
        if let completion = rewardCompletion {
            completion(false)
            rewardCompletion = nil
        }
    }
    
    func ad(_ ad: FullScreenPresentingAd, didFailToPresentFullScreenContentWithError error: Error) {
        NSLog("❌ Failed to present ad: \(error.localizedDescription)")
        rewardedAd = nil
        rewardCompletion?(false)
        rewardCompletion = nil
        loadRewardedAd()
    }
    
    func adWillPresentFullScreenContent(_ ad: FullScreenPresentingAd) {
        NSLog("📺 Ad will present")
    }
}

// MARK: - SKScene Extension

extension SKScene {
    /// Convenience method to show rewarded ad from any scene
    func showRewardedAd(completion: @escaping (Bool) -> Void) {
        AdManager.shared.showRewardedAd(from: self, completion: completion)
    }
}
