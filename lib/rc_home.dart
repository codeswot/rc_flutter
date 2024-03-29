import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:rc/audio_handler.dart';
import 'package:rc/firebase_storage_handler.dart';
import 'package:record/record.dart';

class RcHome extends StatefulWidget {
  const RcHome({super.key});

  @override
  State<RcHome> createState() => _RcHomeState();
}

class _RcHomeState extends State<RcHome> {
  final AudioHandler _audioHandler = AudioHandler();
  final FirebaseStorageHandler _storageHandler = FirebaseStorageHandler();
  File? _recordedFile;
  File? _pickedAudioFile;

  late Timer _timer;
  int _elapsedSeconds = 0;
  // bool _isRecording = false;

  @override
  void initState() {
    super.initState();
    _audioHandler
        .streamAudioRecordingStatus()
        .listen((RecordState recordState) {
      if (recordState == RecordState.pause) {
        _pauseTimer();
      }
    });
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (Timer timer) {
      if (mounted) {
        setState(() {
          _elapsedSeconds++;
        });
      }
    });
    // _isRecording = true;
  }

  void _pauseTimer() {
    _timer.cancel();

    setState(() {});
  }

  void _resetTimer() {
    _timer.cancel();
    _elapsedSeconds = 0;

    setState(() {});
  }

  String _formatDuration(Duration duration) {
    String twoDigits(int n) => n.toString().padLeft(2, '0');
    String twoDigitMinutes = twoDigits(duration.inMinutes.remainder(60));
    String twoDigitSeconds = twoDigits(duration.inSeconds.remainder(60));
    return "${twoDigits(duration.inHours)}:$twoDigitMinutes:$twoDigitSeconds";
  }

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

              return Column(
                children: [
                  if (recordState == RecordState.stop) ...[
                    Row(
                      children: [
                        IconButton.filled(
                          onPressed: () async {
                            _startTimer();
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
                                      await _storageHandler.uploadFile(
                                    _recordedFile!,
                                    durationSecond: _elapsedSeconds,
                                    durationText: _formatDuration(
                                        Duration(seconds: _elapsedSeconds)),
                                  );

                                  if (kDebugMode) {
                                    print('Download URL $downloadUrl');
                                  }
                                  _recordedFile = null;
                                  setState(() {});
                                  _resetTimer();
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
                            _pauseTimer();

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
                  ],
                  Text(
                    _formatDuration(Duration(seconds: _elapsedSeconds)),
                    style: const TextStyle(fontSize: 18),
                  ),
                ],
              );
            },
          ),
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
    _timer.cancel();
    _audioHandler.disposeAudioRecording();
    super.dispose();
  }
}
