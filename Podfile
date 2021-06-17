platform :ios, '11.0'

post_install do |installer|
    installer.pods_project.build_configurations.each do |config|
        config.build_settings.delete('CODE_SIGNING_ALLOWED')
        config.build_settings.delete('CODE_SIGNING_REQUIRED')
    end
end

target 'camera-poc' do

  use_frameworks!
  inhibit_all_warnings!
  pod "AWSS3"
end
