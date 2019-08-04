fastlane documentation
================
# Installation

Make sure you have the latest version of the Xcode command line tools installed:

```
xcode-select --install
```

Install _fastlane_ using
```
[sudo] gem install fastlane -NV
```
or alternatively using `brew cask install fastlane`

# Available Actions
### bootstrap
```
fastlane bootstrap
```
Useful on CI, this lane installs Flutter and accepts some of the Android

SDK licenses. Note that it does not install Android SDK itself, which is

installed by Gradle automatically during the first build.

Nevertheless, ANDROID_SDK_ROOT or ANDROID_HOME environment variable must

point to a destination directory (which might be empty).
### build
```
fastlane build
```
Generate files, format, lint and build project.
### end_to_end_test
```
fastlane end_to_end_test
```
This is an internal test for Fastlane Flutter plugin. You shouldn't

need to do anything like that in your Fastfile.

It uses 'bootstrap' lane from above to install Flutter, then creates a

temporary (but real) Flutter project, and builds it via 'build' lane.

----

This README.md is auto-generated and will be re-generated every time [fastlane](https://fastlane.tools) is run.
More information about fastlane can be found on [fastlane.tools](https://fastlane.tools).
The documentation of fastlane can be found on [docs.fastlane.tools](https://docs.fastlane.tools).
