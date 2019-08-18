# flutter plugin

[![CircleCI](https://circleci.com/gh/dotdoom/fastlane-plugin-flutter.svg?style=svg)](https://circleci.com/gh/dotdoom/fastlane-plugin-flutter)
[![fastlane Plugin Badge](https://rawcdn.githack.com/fastlane/fastlane/master/fastlane/assets/plugin-badge.svg)](https://rubygems.org/gems/fastlane-plugin-flutter)

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
