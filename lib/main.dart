import 'dart:io';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rc/audio_handler.dart';
import 'package:rc/firebase_options.dart';
import 'package:rc/firebase_storage_handler.dart';
import 'package:record/record.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.deepPurple,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: const RcApp(),
    );
  }
}

class RcApp extends StatefulWidget {
  const RcApp({super.key});

  @override
  State<RcApp> createState() => _RcAppState();
}

class _RcAppState extends State<RcApp> {
  final AudioHandler _audioHandler = AudioHandler();
  final FirebaseStorageHandler _storageHandler = FirebaseStorageHandler();
  File? _recordedFile;
  File? _pickedAudioFile;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('RC handler'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: StreamBuilder<RecordState>(
              stream: _audioHandler.streamAudioRecordingStatus(),
              builder: (context, snapshot) {
                final recordState = snapshot.data ?? RecordState.stop;
                if (kDebugMode) {
                  print("SNAPS $recordState");
                }

                // if (snapshot.connectionState == ConnectionState.waiting) {
                //   return const Center(child: CircularProgressIndicator());
                // }
                return Column(
                  children: [
                    if (recordState == RecordState.stop) ...[
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: () async {
                              _audioHandler.startAudioRecording();
                            },
                            icon: const Icon(Icons.record_voice_over),
                          ),
                          IconButton.filledTonal(
                            onPressed: _recordedFile != null
                                ? () async {
                                    if (kDebugMode) {
                                      print(
                                          'recoded data is ${_recordedFile?.path}');
                                    }

                                    final String downloadUrl =
                                        await _storageHandler
                                            .uploadFile(_recordedFile!);
                                    if (kDebugMode) {
                                      print('Download URL $downloadUrl');
                                    }
                                  }
                                : null,
                            icon: const Icon(Icons.send),
                          ),
                        ],
                      ),
                    ],
                    if (recordState == RecordState.record ||
                        recordState == RecordState.pause) ...[
                      Row(
                        children: [
                          IconButton.filled(
                            onPressed: () async {
                              final recordPath =
                                  await _audioHandler.stopAudioRecording();
                              if (recordPath != null) {
                                File recordFile = File(recordPath);
                                _recordedFile = recordFile;
                                setState(() {});
                              }
                            },
                            icon: const Icon(Icons.stop),
                          ),
                          IconButton.filledTonal(
                            onPressed: () async {
                              await _audioHandler.pauseResumeAudioRecording();
                            },
                            icon: Icon(
                              recordState == RecordState.pause
                                  ? Icons.start
                                  : Icons.pause,
                            ),
                          ),
                        ],
                      ),
                    ]
                  ],
                );
              }),
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _pickedAudioFile != null
            ? () {
                // upload file
              }
            : () async {
                final filePath = await _audioHandler.pickAudioFile();
                if (filePath != null) {
                  _pickedAudioFile = File(filePath);
                  setState(() {});
                  if (kDebugMode) {
                    print(filePath);
                  }
                  // upload file

                  final String downloadUrl =
                      await _storageHandler.uploadFile(_pickedAudioFile!);
                  if (kDebugMode) {
                    print('Download URL $downloadUrl');
                  }
                }
              },
        child: Icon(_pickedAudioFile != null ? Icons.send : Icons.file_open),
      ),
    );
  }

  @override
  void dispose() {
    _audioHandler.disposeAudioRecording();
    super.dispose();
  }
}
