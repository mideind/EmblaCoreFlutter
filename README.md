[![License: GPL v3](https://img.shields.io/badge/License-GPLv3-blue.svg)](https://www.gnu.org/licenses/gpl-3.0)
[![Language](https://img.shields.io/badge/language-dart-lightblue)]()
![Release](https://shields.io/github/v/release/mideind/EmblaCoreFlutter?display_name=tag)
![pub.dev](https://img.shields.io/pub/v/embla_core)
[![Build](https://github.com/mideind/EmblaCoreFlutter/actions/workflows/tests.yml/badge.svg)]()

<img src="img/emblacore_icon.png" align="right" width="200" height="200" style="margin-left:20px;">

# EmblaCore

EmblaCore is a [Flutter](https://flutter.dev/) library containing the core session
functionality in [Embla](https://github.com/mideind/EmblaFlutterApp), a cross-platform
mobile Icelandic-language voice assistant client. EmblaCore requires Flutter >= 2.17.

## Installation

Add this to the dependencies list in your `pubspec.yaml` file:

```yaml
  embla_core: ">=1.0.0"
```

and then run the following command from the project root:

```bash
flutter pub get
```

## Documentation

Extensive `dartdoc` documentation is [available here](https://embla.is/embla_core).

## Demo App

A simple demo app that demonstrates how to use EmblaCore can viewed at
[`example/lib/main.dart`](https://github.com/mideind/EmblaCoreFlutter/blob/master/example/lib/main.dart).

To run the demo app, you must acquire an API key from [Mideind](https://mideind.is) and add
it in the file `example/lib/main.dart`. Then run the following command from the repo root:

```bash
cd example
flutter run -d [your_device_id]
```

## Basic API usage

```dart
import 'package:embla_core/embla_core.dart';

...

var config = EmblaConfig();

/* Set properties of config object... */

var session = EmblaSession(config=config);

session.start();

...

session.cancel();
```

## License

EmblaCore is Copyright &copy; 2023 [Miðeind ehf.](https://mideind.is)

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
