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

/// Communication with REST API

import 'dart:convert' show json;

import 'package:http/http.dart' show Response;
import 'package:http/http.dart' as http;

import './common.dart';

/// Send JSON POST request to API server.
Future<Response?> _makeRequest(String apiURL, String apiKey, Map<String, dynamic> qargs,
    [void Function(Map? result)? handler]) async {
  dlog("Sending query POST request to $apiURL: ${qargs.toString()}");
  Response? response;
  try {
    final Map<String, String> headers = {
      "X-API-Key": apiKey,
      "Content-Type": "application/json",
      "Accept": "application/json"
    };
    response = await http
        .post(Uri.parse(apiURL), body: json.encode(qargs), headers: headers)
        .timeout(kRequestTimeout, onTimeout: () {
      handler!(null);
      return Response("Request timed out", 408);
    });
  } catch (e) {
    dlog("Error while making POST request: $e");
    response = null;
  }

  // Handle null response
  if (response == null) {
    handler!(null);
    return null;
  }

  // We have a valid response object
  dlog("Response status: ${response.statusCode}");
//   dlog("Response body: ${response.body}");
  if (handler != null) {
    // Parse JSON body and feed ensuing data structure to handler function
    dynamic arg = (response.statusCode == 200) ? json.decode(response.body) : null;
    // JSON response should be a dict, otherwise something's gone horribly wrong
    arg = (arg is Map) == false ? null : arg;
    handler(arg);
  }

  return response;
}

/// Static class wrapper for functions communicating with the Embla REST API.
class EmblaRESTAPI {
  /// Send request to clear query history for a given device ID.
  /// Boolean [allData] param determines whether all device-specific
  /// data or only query history should be deleted server-side.
  static Future<void> clearUserData(String deviceID, String apiKey,
      {bool allData = false,
      String serverURL = kDefaultServer,
      void Function(Map? result)? completionHandler}) async {
    final Map<String, String> qargs = {
      'action': allData ? 'clear_all' : 'clear',
      'client_id': deviceID,
    };

    final String apiURL = "$serverURL$kClearHistoryEndpoint";
    await _makeRequest(apiURL, apiKey, qargs, completionHandler);
  }
}
