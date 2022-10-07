Pod::Spec.new do |spec|
  spec.name         = "NImageDownloader"
  spec.version      = "1.0.4"
  spec.summary      = "Async image downloader based on NRequest framework"

  spec.source       = { :git => "git@github.com:NikSativa/NImageDownloader.git" }
  spec.homepage     = "https://github.com/NikSativa/NImageDownloader"

  spec.license          = 'MIT'
  spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
  spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.5'

  spec.resources = ['Source/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
  spec.source_files = 'Source/**/*.{storyboard,xib,swift,h,m}'

  spec.dependency 'NRequest'
  spec.dependency 'NQueue'
  spec.dependency 'NCallback'

  spec.frameworks = 'Foundation', 'UIKit'
end
