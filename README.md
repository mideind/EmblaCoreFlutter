[![Language](https://img.shields.io/badge/language-dart-lightblue)]()
[![Build](https://github.com/mideind/embla_core/actions/workflows/tests.yml/badge.svg)]()

# EmblaCore

EmblaCore is a Dart library containing the core session functionality in
[Embla](https://github.com/mideind/EmblaFlutterApp), a mobile Icelandic-language
voice assistant client implemented in [Flutter](https://flutter.dev/).
Requires Flutter >= 3.0.0.

## How to use

Add this to the dependencies list in your `pubspec.yaml` file:

```yaml
  embla_core: ">=0.1.0"
```

and then run the following command from the project root:

```bash
flutter pub get
```

## Demo App

A simple demo app that demonstrates how to use EmblaCore can viewed at
[`example/lib/main.dart`](example/lib/main.dart).

To run the app on a device of your choice:

```bash
cd example
flutter run -d [device_id]
```

## API

### Create and use session object

```dart
import 'package:embla_core/embla_core.dart';

...

var config = EmblaConfig();
var session = EmblaSession(config=config);

session.start();
```

## License

Greynir is Copyright &copy; 2023 [Miðeind ehf.](https://mideind.is)

This set of programs is free software: you can redistribute it and/or modify it
under the terms of the GNU General Public License as published by the Free
Software Foundation, either version 3 of the License, or (at your option) any later
version.

This set of programs is distributed in the hope that it will be useful, but WITHOUT
ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR
A PARTICULAR PURPOSE. See the GNU General Public License for more details.

The full text of the GNU General Public License v3 is
[included here](https://github.com/mideind/Greynir/blob/master/LICENSE.txt)
and also available here:
[https://www.gnu.org/licenses/gpl-3.0.html](https://www.gnu.org/licenses/gpl-3.0.html).

If you wish to use this set of programs in ways that are not covered under the
GNU GPLv3 license, please contact us at [mideind@mideind.is](mailto:mideind@mideind.is)
to negotiate a custom license. This applies for instance if you want to include or use
this software, in part or in full, in other software that is not licensed under
GNU GPLv3 or other compatible licenses.
