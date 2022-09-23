/*
 * This file is part of the Embla Core Flutter package
 * Copyright (c) 2022 Miðeind ehf. <mideind@mideind.is>
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

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:embla_core/embla_core.dart';

import './keys.dart' show googleServiceAccount;

void main() {
  // Prepare for session by preloading assets
  EmblaSession.prep();

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Embla Session Demo',
      theme: ThemeData(
        // This is the theme of your application.
        //
        // Try running your application with "flutter run". You'll see the
        // application has a blue toolbar. Then, without quitting the app, try
        // changing the primarySwatch below to Colors.green and then invoke
        // "hot reload" (press "r" in the console where you ran "flutter run",
        // or simply save your changes to "hot reload" in a Flutter IDE).
        // Notice that the counter didn't reset back to zero; the application
        // is not restarted.
        primarySwatch: Colors.red,
      ),
      home: const SessionPage(title: 'Embla Session Demo'),
    );
  }
}

class SessionPage extends StatefulWidget {
  const SessionPage({super.key, required this.title});

  // This widget is the home page of your application. It is stateful, meaning
  // that it has a State object (defined below) that contains fields that affect
  // how it looks.

  // This class is the configuration for the state. It holds the values (in this
  // case the title) provided by the parent (in this case the App widget) and
  // used by the build method of the State. Fields in a Widget subclass are
  // always marked "final".

  final String title;

  @override
  State<SessionPage> createState() => _SessionPageState();
}

class _SessionPageState extends State<SessionPage> {
  EmblaSession? session;
  String msg = '';
  Icon buttonIcon = const Icon(Icons.play_arrow);

  void _buttonClick() {
    if (session != null && session!.isActive()) {
      // Session is active, so terminate it
      session!.cancel();
      buttonIcon = const Icon(Icons.play_arrow);
      return;
    }

    // Create new config
    var config = EmblaConfig(apiKey: readGoogleServiceAccount());

    config!.onStartListening = () {
      setState(() {
        buttonIcon = const Icon(Icons.stop);
        msg = 'Hlustandi...';
      });
    };

    config!.onSpeechTextReceived = (List<String> transcripts, bool isFinal) {
      setState(() {
        msg = transcripts[0];
      });
    };

    config!.onQueryAnswerReceived = (dynamic answer) {
      setState(() {
        if (answer is Map && answer.containsKey('answer')) {
          msg = answer['answer'];
        }
      });
    };

    config!.onError = (String error) {
      setState(() {
        msg = error;
        buttonIcon = const Icon(Icons.play_arrow);
      });
    };

    config!.onDone = () {
      setState(() {
        buttonIcon = const Icon(Icons.play_arrow);
        msg = '';
      });
    };

    session = EmblaSession(config: config);
    session!.start();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(
              msg,
              style: Theme.of(context).textTheme.headline4,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _buttonClick,
        child: buttonIcon,
      ),
    );
  }
}

String _cachedGoogleServiceAccount = '';

// Read and cache Google API service account config JSON
String readGoogleServiceAccount() {
  if (_cachedGoogleServiceAccount == '') {
    _cachedGoogleServiceAccount = utf8.decode(base64.decode(googleServiceAccount));
  }
  return _cachedGoogleServiceAccount;
}
