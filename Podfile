# Uncomment this line to define a global platform for your project
# platform :ios, '6.0'

use_frameworks!

def shared_pods
    pod 'MarqueeLabel'
    pod 'PebbleKit'
    pod 'YYImage'
    pod 'ImageMagick', '6.8.8-9'
    pod 'PureLayout'
    pod 'SDWebImage', '~>3.8'
    pod 'MBProgressHUD', '~> 1.0.0'
    pod 'AFNetworking', '~> 3.0'
    pod 'SecureNSUserDefaults', '~> 1.0.1'
    pod 'Fabric'
    pod 'Crashlytics'
    pod 'BSKeyboardControls', '~> 2.2'
    pod 'ApIdleManager'
    pod 'Unirest'
end

target 'Lignite Music' do
    shared_pods
end

target 'Lignite Music for Spotify' do
    shared_pods
    pod 'couchbase-lite-ios', '~> 1.3.1'
end