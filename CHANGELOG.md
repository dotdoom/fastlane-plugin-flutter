## 0.9.0

- If args has `--verbase` then print the flutter command to be executed.

## 0.8.0

- Parse "flutter build" command output even when it doesn't contain a period.

## 0.7.1

- Remove `coverage_all_imports` file before codegeneration, as the latter may
  sometimes be confused.

## 0.7.0

- Obsolete `vendor/flutter` (as it turns out, this never worked very well) and
  `FLUTTER_SDK_ROOT` environment variable.
- Be verbose about why a certain Flutter location was determined as current by
  the plugin.

## 0.6.1

- Detect `vendor/flutter` directory as default Flutter installation if there's a
  Flutter binary inside.

## 0.6.0

- Support `.flutter` subdirectory for project-specific flutter installation
  (usually for Flutter version pinning).

## 0.5.0

- Do not print a warning message when not able to parse "flutter build" output
  and "--config-only" argument is present.
- Install "stable" version of Flutter by default (instead of "beta").

## 0.4.2

- Return Flutter SDK path from `flutter_bootstrap`.

## 0.4.1

- Add `coverage_all_imports: true` support to `flutter_generate()`, which would
  generate a test importing all `.dart` files in `lib/`. This will make coverage
  tools consider percentage of overall project rather than files with non-zero
  coverage only.

## 0.4.0

- Support `--split-per-abi` flag and return a list from `flutter_build()` in
  that case.

## 0.3.19

- Fill in some well-known context variables in `flutter_build()` action.
- Slightly expand on `flutter_generate()` command.

## 0.3.18

- Add an example of how an `.ipa` file can be built for a Flutter app.
- Fix `capture_stdout` parameter of `flutter` action to actually return stdout.
