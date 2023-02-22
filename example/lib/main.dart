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

void main() {
  WidgetsFlutterBinding.ensureInitialized();

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
        primarySwatch: Colors.red,
      ),
      home: const SessionPage(title: 'Embla Session Demo'),
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
  String msg = '';
  Icon buttonIcon = const Icon(Icons.play_arrow);

  void _buttonClick() {
    if (session != null && session!.isActive()) {
      // Session is active, so terminate it
      session!.stop();
      buttonIcon = const Icon(Icons.play_arrow);
      return;
    }

    // Create new config
    var config = EmblaSessionConfig();

    config.onStartListening = () {
      setState(() {
        buttonIcon = const Icon(Icons.stop);
        msg = 'Hlustandi...';
      });
    };

    config.onSpeechTextReceived = (List<String> transcripts, bool isFinal) {
      setState(() {
        msg = transcripts[0];
      });
    };

    config.onQueryAnswerReceived = (dynamic answer) {
      setState(() {
        if (answer is Map && answer.containsKey('answer')) {
          msg = answer['answer'];
        }
      });
    };

    config.onError = (String error) {
      setState(() {
        msg = error;
        buttonIcon = const Icon(Icons.play_arrow);
      });
    };

    config.onDone = () {
      setState(() {
        buttonIcon = const Icon(Icons.play_arrow);
        msg = '';
      });
    };

    session = EmblaSession(config);
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
              style: Theme.of(context).textTheme.headlineMedium,
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
