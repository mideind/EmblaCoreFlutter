/*
 * This file is part of the EmblaCore Flutter package
 *
 * Copyright (c) 2024 Miðeind ehf. <mideind@mideind.is>
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

/// Utility functions and custom class extensions

extension StringExtension on String {
  /// Convert Icelandic characters to their ASCII equivalent
  /// and remove all other non-ASCII characters.
  String asciify() {
    const Map<String, String> icechar2ascii = {
      "ð": "d",
      "Ð": "D",
      "á": "a",
      "Á": "A",
      "ú": "u",
      "Ú": "U",
      "í": "i",
      "Í": "I",
      "é": "e",
      "É": "E",
      "þ": "th",
      "Þ": "TH",
      "ó": "o",
      "Ó": "O",
      "ý": "y",
      "Ý": "Y",
      "ö": "o",
      "Ö": "O",
      "æ": "ae",
      "Æ": "AE",
    };

    // Replace Icelandic characters
    String s = this;
    icechar2ascii.forEach((k, v) {
      s = s.replaceAll(k, v);
    });

    // Remove all other non-ASCII characters
    var f = '';
    for (var c in s.runes) {
      if (c < 128) {
        f = f + String.fromCharCode(c);
      }
    }
    return f;
  }

  /// Capitalize the first character of a string
  String capFirst() {
    final String s = this;
    if (s.isEmpty) {
      return s;
    }
    if (s.length == 1) {
      return s.toUpperCase();
    }
    return "${s[0].toUpperCase()}${s.substring(1)}";
  }
}
