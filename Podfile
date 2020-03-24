platform :ios, '13.0'

# Uncomment the next line if you're using Swift or would like to use dynamic frameworks
# use_frameworks!

def common_pods
  #pod 'TesseractOCRiOS', '4.0.0'
  #pod 'TesseractOCRiOS', :git => 'git://github.com/parallaxe/Tesseract-OCR-iOS.git', :branch => 'macos-support'
  #pod 'SWRevealViewController'
end

target 'AmiKoDesitin' do
  common_pods
end

target 'CoMedDesitin' do
  common_pods
end

post_install do |installer|
    installer.pods_project.targets.each do |target|
        puts "=== Target: #{target.name}"
    end
end

