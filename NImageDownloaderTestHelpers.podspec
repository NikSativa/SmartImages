Pod::Spec.new do |spec|
  spec.name         = "NImageDownloaderTestHelpers"
  spec.version      = "1.0.2"
  spec.summary      = "Async image downloader based on NRequest framework"

  spec.source       = { :git => "git@github.com:NikSativa/NImageDownloader.git" }
  spec.homepage     = "https://github.com/NikSativa/NImageDownloader"

  spec.license          = 'MIT'
  spec.author           = { "Nikita Konopelko" => "nik.sativa@gmail.com" }
  spec.social_media_url = "https://www.facebook.com/Nik.Sativa"

  spec.ios.deployment_target = '11.0'
  spec.swift_version = '5.5'

  spec.resources = ['TestHelpers/**/*.{xcassets,json,imageset,png,strings,stringsdict}']
  spec.source_files = 'TestHelpers/**/*.{storyboard,xib,swift}'

  spec.dependency 'NImageDownloader'
  spec.dependency 'NSpry'

  spec.dependency 'NRequest'
  spec.dependency 'NRequestTestHelpers'

  spec.frameworks = 'Foundation', 'UIKit'

#  spec.scheme = {
#    :code_coverage => true
#  }

  spec.test_spec 'Tests' do |tests|
    #      tests.requires_app_host = true

    tests.dependency 'Quick'
    tests.dependency 'Nimble'
    tests.dependency 'NSpry_Nimble'

    tests.dependency 'NQueue'
    tests.dependency 'NQueueTestHelpers'

    tests.dependency 'NCallback'
    tests.dependency 'NCallbackTestHelpers'

    tests.resources = ['Tests/**/*.{xcassets,json,imageset,png,strings,stringsdict,txt}']
    tests.source_files = 'Tests/**/*.swift'

    tests.frameworks = 'XCTest', 'Foundation', 'UIKit'
  end
end
