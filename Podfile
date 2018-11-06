platform :ios, "10.3"
use_frameworks!

def default_pods
    pod 'ChameleonFramework/Swift', :git => 'https://github.com/ViccAlexander/Chameleon.git'
    pod 'Cosmos'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'Eureka'
    pod 'FBSDKCoreKit'
    pod 'FBSDKLoginKit'
    pod 'FBSDKShareKit'
    pod 'FBSDKMessengerShareKit'
    pod 'Firebase/Core'
    pod 'Firebase/Database'
    pod 'Firebase/Auth'
    pod 'FirebaseUI/Storage'
    pod 'FontAwesome.swift'
    pod 'GoogleSignIn'
    pod 'IDMPhotoBrowser'
    pod 'InAppSettingsKit'
    pod 'iCarousel'
    pod 'Kanna', '~> 4.0.0'
    pod 'ManaKit'
    pod 'MBProgressHUD'
    pod 'MMDrawerController'
    pod 'MMDrawerController+Storyboard'
    pod 'NYAlertViewController'
    pod 'OAuthSwift'
    pod 'PromiseKit'
    pod 'SSZipArchive'
    #pod 'SwiftOCR'
end

target 'ManaGuide' do
    default_pods
end

target 'ManaGuideTests' do
    default_pods
end

target 'ManaGuideUITests' do
    default_pods
    pod 'SimulatorStatusMagic', :configurations => ['Debug']
end

