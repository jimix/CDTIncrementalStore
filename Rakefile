desc "Run the CDTIncrementalStore Tests for iOS"
task :testios do
    # build using xcpretty as otherwise it's very verbose when running tests
  $ios_success = system("xcodebuild -workspace CDTIncrementalStore.xcworkspace -scheme 'CDTIS_iOSTests' -destination 'platform=iOS Simulator,OS=latest,name=iPhone 4S' build | xcpretty; exit ${PIPESTATUS[0]}")
  unless $ios_success
    puts "** Build failed"
    exit(-1)
  end
  $ios_success = system("xcodebuild -workspace CDTIncrementalStore.xcworkspace -scheme 'CDTIS_iOSTests' -destination 'platform=iOS Simulator,OS=latest,name=iPhone 4S' test")
  puts "\033[0;31m! iOS unit tests failed with status code #{$?}" unless $ios_success
  if $ios_success
    puts "** All tests executed successfully"
  else
    exit(-1)
  end
end

desc "Run the CDTIncrementalStore Tests for OS X"
task :testosx do
    # build using xcpretty as otherwise it's very verbose when running tests
  $osx_success = system("xcodebuild -workspace CDTIncrementalStore.xcworkspace -scheme 'CDTIS_OSXTests' -destination 'platform=OS X' build | xcpretty; exit ${PIPESTATUS[0]}")
  unless $osx_success
    puts "** Build failed"
    exit(-1)
  end
  $osx_success = system("xcodebuild -workspace CDTIncrementalStore.xcworkspace -scheme 'CDTIS_OSXTests' -destination 'platform=OS X' test")
  puts "\033[0;31m! OS X unit tests failed with status code #{$?}" unless $osx_success
  if $osx_success
    puts "** All tests executed successfully"
  else
    exit(-1)
  end
end

desc "Run tests for all platforms"
task :test do
  sh "rake testios"
  sh "rake testosx"
end

desc "Task for travis"
task :travis do
  sh "rake testios"
  sh "rake testosx"
  sh "pod lib lint --allow-warnings"
end
