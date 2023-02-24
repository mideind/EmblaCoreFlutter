/*
 * This file is part of the EmblaCore Flutter package
 *
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

// JSON messages sent to and received from the Embla server

import 'dart:convert' show json;

import './config.dart' show EmblaSessionConfig;

class GreetingsOutputMessage {
  final String type = "greetings";
  int msg_id = 0;
  Map<String, dynamic> data = {};

  GreetingsOutputMessage(
      {String client_id = "",
      String client_type = "",
      String client_version = "",
      String language = "is-IS",
      String engine = "azure",
      String? query_server = "https://greynir.is"}) {
    data["client_id"] = client_id;
    data["client_type"] = client_type;
    data["client_version"] = client_version;
    data["language"] = language;
    data["engine"] = engine;
    data["query_server"] = query_server;
  }

  GreetingsOutputMessage.fromConfig(EmblaSessionConfig config) {
    // TODO: Implement me
  }

  String toJSON() {
    Map<String, dynamic> msg = {"type": type, "msg_id": msg_id, "data": data};
    return json.encode(msg);
  }
}

class GreetingsResponseMessage {
  String? name;
  String? version;
  String? author;
  String? copyright;
  String? default_engine;
  List<String>? supported_engines;
  Map<String, dynamic>? audio_settings;

  GreetingsResponseMessage.fromJson(Map<String, dynamic> json) {
    name = json["name"];
    version = json["version"];
    author = json["author"];
    copyright = json["copyright"];
    default_engine = json["default_engine"];
    supported_engines = json["supported_engines"];
    audio_settings = json["audio_settings"];
  }
}
