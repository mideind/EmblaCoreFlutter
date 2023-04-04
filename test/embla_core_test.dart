/*
 * This file is part of the EmblaCore Flutter package
 * Copyright (c) 2023 Miðeind ehf. <mideind@mideind.is>
 * Original author: Sveinbjorn Thordarson
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, version 3.
 *
 * This program is distributed in the hope that it will be useful, but
 * WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:embla_core/embla_core.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  test("Instantiated session in idle state", () {
    // Create and verify config object
    var cfg = EmblaSessionConfig();
    expect(cfg, isNotNull);
    expect((cfg.socketURL != ''), true);
    expect(cfg.apiKey == null, true);
    expect(cfg.queryServer != '', true);

    // Create and verify session object
    var session = EmblaSession(cfg);
    expect(session.state == EmblaSessionState.idle, true);
    expect(session.isActive() == false, true);
  });

  test("Verify that singletons are singletons", () {
    expect(AudioPlayer() == AudioPlayer(), true);
    expect(AudioRecorder() == AudioRecorder(), true);
  });
}
