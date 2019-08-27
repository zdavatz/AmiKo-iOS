platform :ios, '13.0'

# Uncomment the next line if you're using Swift or would like to use dynamic frameworks
# use_frameworks!

def common_pods
  pod 'TesseractOCRiOS', '4.0.0'
  #pod 'TesseractOCRiOS', :git => 'git://github.com/parallaxe/Tesseract-OCR-iOS.git', :branch => 'macos-support'
  pod 'WebViewJavascriptBridge', '4.1.4'
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
        if target.name == 'TesseractOCRiOS'
            target.build_configurations.each do |config|
                config.build_settings['ENABLE_BITCODE'] = 'NO'
            end
            header_phase = target.build_phases().select do |phase|
                phase.is_a? Xcodeproj::Project::PBXHeadersBuildPhase
            end.first

            duplicated_header_files = header_phase.files.select do |file|
                file.display_name == 'config_auto.h'
            end

            duplicated_header_files.each do |file|
                header_phase.remove_build_file file
            end
        end
    end
end

