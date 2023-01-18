# EmblaCore

This is the repository for EmblaCore, a library containing the core session functionality
in Embla, an Icelandic-language voice assistant client implemented in Dart/Flutter.

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

## License

TBD
