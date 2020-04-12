Pod::Spec.new do |s|
  s.name             = 'Propagate'
  s.version          = '0.0.1'
  s.summary          = 'A lightweight framework for handling streams of data in Swift.'

  s.description      = <<-DESC
  Propagate is a simple, lightweight framework for handling streams of data in Swift.
  Tags: Rx, RxSwift, Reactive, Streams, Data Streams, Swift
  DESC
  # I recommend writing a git hook that scrapes this from your README.md file.

  s.homepage         = 'https://github.com/jakehawken/Propagate'
  s.license          = { :type => 'MIT', :file => 'LICENSE' }  #modify as desired
  s.author           = { 'Jake Hawken' => 'https://github.com/jakehawken'}
  s.source           = { :git => 'https://github.com/jakehawken/Propagate.git', :tag => s.version.to_s }

  s.platform              = :ios, "12.4.1"
  s.ios.deployment_target = '12.4.1'

  s.source_files = 'Propagate/**/*' # The relative path within repo for files to actually include in the pod. I highly recommend that this is not the root of the repo.
  # s.dependency '{SOME OTHER POD}' # Create an additional line like this one for every dependency your pod has.
end
