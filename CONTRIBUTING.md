## Tests

### Re-generating demo project

Create a new Flutter project:

```shell
$ flutter create demo
$ cd demo
```

Edit pubspec.yaml:

```diff
 dev_dependencies:
   flutter_test:
     sdk: flutter

+  intl_translation: any
+  build_runner: any
```

Install dependencies:

```shell
$ flutter packages get
```

Create file `lib/intl/intl.dart`:

```dart
import 'dart:async';

import 'messages_all.dart';
import 'package:intl/intl.dart';

class DemoIntl {
  String get helloWorld => Intl.message(
        'Hello, World!',
        name: 'helloWorld',
        desc: 'Text displayed in the center of the login screen',
      );
}
```
