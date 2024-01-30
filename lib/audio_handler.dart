import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';

class AudioHandler {
  final record = AudioRecorder();

  Future<void> startAudioRecording() async {
    final appDocDir = await getApplicationDocumentsDirectory();
    final dateLabel = DateTime.now().millisecondsSinceEpoch.toString();
    final path = '${appDocDir.path}/record_$dateLabel.aac';

    if (await record.hasPermission()) {
      record.start(const RecordConfig(), path: path);
    }
  }

  Stream<RecordState> streamAudioRecordingStatus() {
    return record.onStateChanged();
  }

  pauseResumeAudioRecording() async {
    final isRecording = await record.isRecording();
    if (isRecording) {
      record.pause();
    } else {
      record.resume();
    }
  }

  Future<String?> stopAudioRecording() async {
    final isRecording = await record.isRecording();
    if (isRecording) {
      final recordPath = await record.stop();

      return recordPath;
    }
    return null;
  }

  Future<String?> pickAudioFile() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      // type: FileType.audio,
      allowMultiple: false,
    );

    return result?.files.single.path;
  }

  disposeAudioRecording() async {
    await record.dispose();
  }
}
