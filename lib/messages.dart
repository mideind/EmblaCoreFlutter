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

import './common.dart' show dlog;
import './config.dart' show EmblaSessionConfig;

class GreetingsOutputMessage {
  final String type = "greetings";
  int msg_id = 0;
  Map<String, dynamic> data = {};

  GreetingsOutputMessage();

  GreetingsOutputMessage.fromConfig(EmblaSessionConfig config) {
    if (config.engine != null) {
      data["engine"] = config.engine;
    }

    // Engine options
    Map<String, dynamic> engine_opts = {};
    if (config.language != null) {
      engine_opts["language"] = config.language;
    }
    data["engine_options"] = engine_opts;

    data["private"] = config.private;
    data["test"] = config.test;
    data["query"] = true;

    // Query options
    Map<String, dynamic> query_opts = {};
    if (config.clientID != null) {
      query_opts["client_id"] = config.clientID;
    }
    if (config.clientType != null) {
      query_opts["client_type"] = config.clientType;
    }
    if (config.clientVersion != null) {
      query_opts["client_version"] = config.clientVersion;
    }
    if (config.voiceID != null) {
      query_opts["voice"] = config.voiceID;
    }
    if (config.voiceSpeed != null) {
      query_opts["voice_speed"] = config.voiceSpeed;
    }
    if (config.getLocation != null) {
      List<double> loc = config.getLocation!();
      if (loc.length == 2) {
        query_opts["latitude"] = loc[0];
        query_opts["longitude"] = loc[1];
      } else {
        dlog("WARNING: Config getLocation() function returned invalid location!");
      }
    }
    query_opts["voice"] = true;
    data["query_options"] = query_opts;
  }

  String toJSON() {
    Map<String, dynamic> msg = {"type": type, "msg_id": msg_id, "data": data};
    return json.encode(msg);
  }
}

// {type: greetings, msg_id: 0, code: 200, info: {name: Ratatoskur Server, version: 0.1.2, engine: azure, options: {language: is-IS, sample_rate: 16000, bit_rate: 16, channels: 1}}}

class GreetingsResponseMessage {
  String? name;
  String? version;
  String? author;
  String? copyright;
  String? engine;
  Map<String, dynamic>? engineOptions;

  GreetingsResponseMessage.fromJson(String jsonStr) {
    var d = json.decode(jsonStr);
    var info = d["info"];
    name = info["name"];
    version = info["version"];
    author = info["author"];
    copyright = info["copyright"];
    engine = info["engine"];
    engineOptions = info["options"];
  }
}
