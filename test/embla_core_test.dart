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
import 'package:embla_core/src/util.dart';

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

  // test("Verify that singletons are singletons", () {
  //   expect(AudioPlayer() == AudioPlayer(), true);
  //   expect(AudioRecorder() == AudioRecorder(), true);
  // });

  // Test string extension methods
  test('Strings should have first character capitalized', () {
    const List<String> ts = [
      "mikið er þetta gaman",
      "HVAÐ ER EIGINLEGA Í GANGI?",
      "The rain in Spain stays mainly in the plain",
      "iT's by no means possible",
      "það er nú þannig að ég er ekki alveg viss um þetta",
    ];
    for (String s in ts) {
      expect(s[0].toUpperCase() == s.capFirst()[0], true);
    }
  });

  test('Strings should be asciified', () {
    const Map<String, String> m = {
      "mikið er þetta gaman": "mikid er thetta gaman",
      "HVAÐ ER EIGINLEGA Í GANGI?": "HVAD ER EIGINLEGA I GANGI?",
      "Örnólfur Gyrðir Böðvarsson": "Ornolfur Gyrdir Bodvarsson",
      "SVEINBJÖRN Þórðarson": "SVEINBJORN THordarson",
    };
    m.forEach((k, v) {
      expect(k.asciify() == v, true);
    });
  });
}
