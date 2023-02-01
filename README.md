[![Language](https://img.shields.io/badge/language-dart-lightblue)]()
[![Build](https://github.com/mideind/embla_core/actions/workflows/tests.yml/badge.svg)]()

# EmblaCore

EmblaCore is a Dart library containing the core session functionality in Embla,
a mobile Icelandic-language voice assistant client implemented in Dart/Flutter.

## Installation

```bash
flutter pub get
```

## Demo

See [`example/lib`](example/lib).

## API

### Create and use session object

```dart
import 'package:embla_core/embla_core.dart';

...

var config = EmblaConfig();
var session = EmblaSession(config=config);

session.start();
```

## Development

TBD

## Acknowledgements

TBD

## License

Copyright (c) 2023 Miðeind ehf.

TBD
