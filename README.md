# flutter plugin

[![Gem Version](https://badge.fury.io/rb/fastlane-plugin-flutter.svg)](https://badge.fury.io/rb/fastlane-plugin-flutter)
[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-flutter)
[![Build Status](https://github.com/dotdoom/fastlane-plugin-flutter/workflows/end-to-end%20test/badge.svg?branch=master)](https://github.com/dotdoom/fastlane-plugin-flutter/actions?query=workflow%3A"end-to-end+test"+branch%3Amaster)

Automated end-to-end test (download Flutter, create an app, build it) on the
following platforms:

* macOS (iOS)
* macOS (Android)
* Ubuntu Linux (Android)
* Windows (Android)

## Getting Started

This project is a [_fastlane_](https://github.com/fastlane/fastlane) plugin. To get started with `fastlane-plugin-flutter`, add it to your project by running:

```shell
$ fastlane add_plugin flutter
```

## About flutter

Flutter actions plugin for Fastlane.

## Example

Check out the [example `Fastfile`](fastlane/Fastfile) to see how to use this plugin.

## Run tests for this plugin

To run both the tests, and code style validation, run

```shell
$ bundle install
$ bundle exec rake
$ bundle exec fastlane end_to_end_test
```

To automatically fix many of the styling issues, use

```shell
$ bundle install
$ bundle exec rubocop -a
```

## Issues and Feedback

For any other issues and feedback about this plugin, please submit it to this repository.

## Troubleshooting

If you have trouble using plugins, check out the [Plugins Troubleshooting](https://docs.fastlane.tools/plugins/plugins-troubleshooting/) guide.

## Using _fastlane_ Plugins

For more information about how the `fastlane` plugin system works, check out the [Plugins documentation](https://docs.fastlane.tools/plugins/create-plugin/).

## About _fastlane_

_fastlane_ is the easiest way to automate beta deployments and releases for your iOS and Android apps. To learn more, check out [fastlane.tools](https://fastlane.tools).
