/*
 * This file is part of the EmblaCore Flutter package example
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
import 'package:embla_core/embla_core.dart';
import 'package:permission_handler/permission_handler.dart';

const String kSoftwareTitle = 'EmblaCore Demo';
const String kDefaultPrompt = 'Smelltu á hnappinn til að byrja';
const String kListeningPrompt = 'Hlustandi...';

void main() {
  WidgetsFlutterBinding.ensureInitialized();

  // We call this static function to prepare for session
  // functionality by preloading any required assets.
  EmblaSession.prepare();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: kSoftwareTitle,
      theme: ThemeData(
        primarySwatch: Colors.red,
      ),
      home: const SessionPage(title: kSoftwareTitle),
    );
  }
}

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.title});

  final String title;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  EmblaSession? session;
  EmblaSessionConfig? config;
  String msg = kDefaultPrompt;
  Icon playIcon = const Icon(Icons.play_arrow);
  Icon stopIcon = const Icon(Icons.stop);
  Icon buttonIcon = const Icon(Icons.play_arrow);

  void _stopSession() {
    session!.cancel();
    setState(() {
      buttonIcon = playIcon;
      msg = kDefaultPrompt;
    });
  }

  Future _askForPermissions() async {
    if (await Permission.microphone.isGranted != true) {
      await Permission.microphone.request();
    }
  }

  void _createConfigIfNeeded() {
    if (config != null) {
      return;
    }

    const String serverURL = "https://staging.api.greynir.is"; // http://local-ip-address:8080

    // Create new session config
    config = EmblaSessionConfig(server: serverURL);
    config!.apiKey = "YOUR_API_KEY_HERE";

    config?.onStartStreaming = () {
      setState(() {
        buttonIcon = stopIcon;
        msg = kListeningPrompt;
      });
    };

    config?.onSpeechTextReceived = (String transcript, bool isFinal) {
      setState(() {
        msg = transcript;
      });
    };

    config?.onQueryAnswerReceived = (dynamic answer) {
      setState(() {
        if (answer is Map && answer.containsKey('answer')) {
          msg = "$answer['q']\n\n${answer['answer']}";
        }
      });
    };

    config?.onError = (String error) {
      setState(() {
        msg = error;
        buttonIcon = playIcon;
      });
    };

    config?.onDone = () {
      setState(() {
        buttonIcon = playIcon;
        if (msg == kListeningPrompt) {
          msg = kDefaultPrompt;
        }
      });
    };

    config?.getLocation = () {
      // Dummy location data. Replace with real location data
      // in your app e.g. using the geolocator package.
      return [64.1466, -21.9426];
    };
  }

  void _startSession() {
    _createConfigIfNeeded();

    // Start the session
    session = EmblaSession(config!);
    session!.start();

    setState(() {
      buttonIcon = stopIcon;
    });
  }

  void _buttonClick() async {
    if (session != null && session!.isActive()) {
      // Session is active, so terminate it
      _stopSession();
      return;
    }
    await _askForPermissions();
    _startSession();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.only(left: 20, right: 20, top: 30),
          child: Column(
            children: <Widget>[
              Text(
                msg,
                style: Theme.of(context).textTheme.headlineSmall,
              )
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonClick,
        child: buttonIcon,
      ),
    );
  }
}
