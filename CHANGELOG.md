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
