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
  int messageID = 0;
  Map<String, dynamic> data = {};

  GreetingsOutputMessage();

  GreetingsOutputMessage.fromConfig(EmblaSessionConfig config) {
    if (config.engine != null) {
      data["engine"] = config.engine;
    }

    // Engine options
    Map<String, dynamic> engineOpts = {};
    if (config.language != null) {
      engineOpts["language"] = config.language;
    }
    data["engine_options"] = engineOpts;

    data["private"] = config.private;
    data["test"] = config.test;
    data["query"] = true;

    // Query options
    Map<String, dynamic> queryOpts = {};
    if (config.clientID != null) {
      queryOpts["client_id"] = config.clientID;
    }
    if (config.clientType != null) {
      queryOpts["client_type"] = config.clientType;
    }
    if (config.clientVersion != null) {
      queryOpts["client_version"] = config.clientVersion;
    }
    if (config.voiceID != null) {
      queryOpts["voice"] = config.voiceID;
    }
    if (config.voiceSpeed != null) {
      queryOpts["voice_speed"] = config.voiceSpeed;
    }
    if (config.getLocation != null) {
      List<double> loc = config.getLocation!();
      if (loc.length == 2) {
        queryOpts["latitude"] = loc[0];
        queryOpts["longitude"] = loc[1];
      } else {
        dlog("WARNING: Config getLocation() function returned invalid location!");
      }
    }
    queryOpts["voice"] = true;
    data["query_options"] = queryOpts;
  }

  String toJSON() {
    Map<String, dynamic> msg = {"type": type, "msg_id": messageID, "data": data};
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
