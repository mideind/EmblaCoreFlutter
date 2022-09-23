/*
 * This file is part of the Embla Flutter app
 * Copyright (c) 2020-2022 Miðeind ehf. <mideind@mideind.is>
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

// Various utility functions and custom class extensions

// String extensions
extension StringExtension on String {
  // Does string end w. standard punctuation?
  bool isPunctuationTerminated() {
    if (length == 0) {
      return false;
    }
    List<String> punctuation = ['.', '?', '!', '."', '.“', ".'"];
    for (String p in punctuation) {
      if (endsWith(p)) {
        return true;
      }
    }
    return false;
  }

  // Return period-terminated string if not already ending w. punctuation
  String periodTerminated() {
    if (isPunctuationTerminated() == false) {
      return "${this}.";
    }
    return this;
  }

  // Return string with first character capitalized.
  // Why isn't this part of of the standard library?
  String sentenceCapitalized() {
    if (length == 0) {
      return this;
    }
    return "${this[0].toUpperCase()}${substring(1)}";
  }

  // Convert Icelandic characters to their ASCII equivalent.
  String asciify() {
    Map<String, String> icechar2ascii = {
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

    String s = this;

    // Substitute all Icelandic chars for their ASCII equivalents
    icechar2ascii.forEach((k, v) {
      s = s.replaceAll(k, v);
    });
    return s;
  }
}
