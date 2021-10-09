#
# Be sure to run `pod lib lint TyToSearch.podspec' to ensure this is a
# valid spec before submitting.
#
# Any lines starting with a # are optional, but their use is encouraged
# To learn more about a Podspec see https://guides.cocoapods.org/syntax/podspec.html
#

Pod::Spec.new do |s|
  s.name             = 'TyToSearch'
  s.version          = '0.0.3'
  s.summary          = 'Typo-Tolerant Search'
  s.description      = 'Search Engine class that is returning hits and "Did you mean" suggestions. To use this typo-tolerant search, provide it an array of the keywords you want to search. It can be initialized from JSON Data or the path of that JSON file with specified keyPath of the array of keywords in it.'
  s.homepage         = 'https://github.com/nikola-markovic/TyToSearch'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }
  s.author           = { 'Nikola Marković' => 'nikolamarkovic1991@yahoo.com' }
  s.source           = { :git => 'https://github.com/nikola-markovic/TyToSearch.git', :tag => s.version.to_s }
  s.swift_version = '4.0'
  s.ios.deployment_target = '9.0'

  s.source_files = 'TyToSearch/TyToSearch.swift'
end
