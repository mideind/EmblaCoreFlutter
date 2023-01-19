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

// Network communication with query server

import 'dart:convert' show json;
import 'dart:io' show Platform;

import 'package:platform_device_id/platform_device_id.dart';
import 'package:http/http.dart' show Response;
import 'package:http/http.dart' as http;
import 'package:package_info_plus/package_info_plus.dart' show PackageInfo;

import './common.dart';

const kRequestTimeout = Duration(seconds: 10); // Seconds

Future<Map<String, String>> _clientInfo() async {
  PackageInfo packageInfo = await PackageInfo.fromPlatform();
  String? deviceID = await PlatformDeviceId.getDeviceId;
  return {
    'platform': Platform.operatingSystem.toLowerCase(),
    'platform_version': Platform.operatingSystemVersion,
    'device_id': deviceID ?? '',
    'app_name': packageInfo.appName,
    'app_version': packageInfo.version,
    'app_build': packageInfo.buildNumber,
  };
}

// Future<String> _clientType() async {
//   PackageInfo packageInfo = await PackageInfo.fromPlatform();
//   return "${packageInfo.appName}_${Platform.operatingSystem}_flutter";
// }

// Future<String?> _clientID() async {
//   return await PlatformDeviceId.getDeviceId;
// }

// Future<String> _clientVersion() async {
//   PackageInfo packageInfo = await PackageInfo.fromPlatform();
//   return packageInfo.version;
// }

// Send a request to query server
Future<Response?> _makePostRequest(String path, Map<String, dynamic> qargs,
    [Function? handler]) async {
  String apiURL = kDefaultQueryServer + path;

  dlog("Sending query POST request to $apiURL: ${qargs.toString()}");
  Response? response;
  try {
    response = await http.post(Uri.parse(apiURL), body: qargs).timeout(kRequestTimeout);
  } catch (e) {
    dlog("Exception $e while sending query POST request to $apiURL");
    response = null;
  }

  // Handle null response
  if (response == null) {
    if (handler != null) {
      handler(null);
    }
    return null;
  }

  // We have a valid response object
  dlog("Response status: ${response.statusCode}");
  dlog("Response body: ${response.body}");
  if (handler != null) {
    // Parse JSON body and feed ensuing data structure to handler function
    dynamic arg = response.statusCode == 200 ? json.decode(response.body) : null;
    arg = (arg is Map) == false ? null : arg; // Should be a dict, otherwise something's gone wrong
    handler(arg);
  }

  return response;
}

// Wrapper class around communication with query server
class QueryService {
  // Send request to query server API
  static Future<void> sendQuery(List<String> queries, Function? handler,
      {bool test = false,
      bool private = false,
      double voiceSpeed = 1.0,
      String voiceID = kDefaultSpeechSynthesisVoice,
      double? latitude,
      double? longitude}) async {
    //
    // Create query args
    Map<String, String?> qargs = {
      'q': queries.join('|'),
      'voice': '1',
      'voice_id': voiceID,
      'voice_speed': voiceSpeed.toString()
    };

    // Never send client information in privacy mode
    if (private) {
      qargs['private'] = '1';
    } else {
      Map<String, String> clientInfo = await _clientInfo();
      // TODO: Client type should include platform and app name
      qargs['client_type'] = clientInfo['platform'];
      qargs['client_id'] = clientInfo['device_id'];
      qargs['client_version'] = clientInfo['app_version'];
    }

    if (test == true) {
      qargs['test'] = '1';
    }

    qargs['voice_speed'] = voiceSpeed.toString();

    bool shareLocation = (private == true || latitude == null || longitude == null);
    if (shareLocation) {
      qargs['latitude'] = latitude.toString();
      qargs['longitude'] = longitude.toString();
    }

    await _makePostRequest(kQueryAPIPath, qargs, handler);
  }

  // Send request to speech synthesis API
  static Future<void> requestSpeechSynthesis(String text,
      [String voiceID = kDefaultSpeechSynthesisVoice, Function? handler]) async {
    Map<String, String> qargs = {
      'text': text,
      'voice_id': voiceID,
      'format': 'text', // No SSML for now...
      'api_key': '', // TODO: Add API key
    };

    await _makePostRequest(kSpeechSynthesisAPIPath, qargs, handler);
  }
}
