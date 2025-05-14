import 'dart:io';
import 'dart:typed_data';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:patroltracking/MMEFeatures/audiorecorder.dart';
import 'package:patroltracking/MMEFeatures/videorecorder.dart';
import 'package:patroltracking/constants.dart';
import 'package:patroltracking/navigationbar.dart';
import 'package:patroltracking/patrol/patroldashboard.dart';
import 'package:patroltracking/services/api_service.dart';
import 'package:signature/signature.dart';
import 'package:flutter_sound/flutter_sound.dart';
import 'package:permission_handler/permission_handler.dart';
//import 'package:ffmpeg_kit_flutter_full_gpl/ffmpeg_kit.dart';

class PatrolMultimediaScreen extends StatefulWidget {
  final String checklistId;
  final Map<String, dynamic> user;
  final String token;
  final String mode; // 'bymenu' or 'notbymenu'
  const PatrolMultimediaScreen({
    super.key,
    required this.checklistId,
    required this.user,
    required this.token,
    required this.mode,
  });

  @override
  State<PatrolMultimediaScreen> createState() => _PatrolMultimediaScreenState();
}

class _PatrolMultimediaScreenState extends State<PatrolMultimediaScreen> {
  final ImagePicker _picker = ImagePicker();
  final SignatureController _signatureController = SignatureController();
  final TextEditingController _remarksController = TextEditingController();
  final FlutterSoundRecorder _audioRecorder = FlutterSoundRecorder();
  final FlutterSoundPlayer _audioPlayer = FlutterSoundPlayer();

  File? _mediaFile;
  String? _mediaType;
  File? _signatureFile;
  bool _isPlaying = false;
  bool _isSavingSignature = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initAudio();
  }

  Future<void> _initAudio() async {
    await _audioRecorder.openRecorder();
    await _audioPlayer.openPlayer();
    await Permission.microphone.request();
  }

  Future<void> _capturePhoto() async {
    final picked = await _picker.pickImage(source: ImageSource.camera);
    if (picked != null) {
      setState(() {
        _mediaFile = File(picked.path);
        _mediaType = 'image';
      });
    }
  }

  // Future<void> _captureVideo() async {
  //   final picked = await _picker.pickVideo(source: ImageSource.camera);
  //   if (picked != null) {
  //     setState(() {
  //       _mediaFile = File(picked.path);
  //       _mediaType = 'video';
  //     });
  //   }
  // }

  // Future<void> _startRecording() async {
  //   final dir = await getApplicationDocumentsDirectory();
  //   final path = '${dir.path}/audio.aac';
  //   await _audioRecorder.startRecorder(toFile: path);
  //   setState(() => _isRecording = true);
  // }

  // Future<void> _stopRecording() async {
  //   final aacPath = await _audioRecorder.stopRecorder();
  //   setState(() => _isRecording = false);

  //   if (aacPath != null) {
  //     final mp3Path = aacPath.replaceAll(".aac", ".mp3");

  //     // // Convert using FFmpeg
  //     // await FFmpegKit.execute('-i "$aacPath" "$mp3Path"');

  //     final mp3File = File(mp3Path);
  //     if (await mp3File.exists()) {
  //       setState(() {
  //         _mediaFile = mp3File;
  //         _mediaType = 'audio';
  //       });
  //     } else {
  //       ScaffoldMessenger.of(context).showSnackBar(
  //         SnackBar(content: Text("Failed to convert audio to MP3")),
  //       );
  //     }
  //   }
  // }

  Future<void> _togglePlayAudio() async {
    if (_mediaFile == null) return;
    if (!_isPlaying) {
      await _audioPlayer.startPlayer(
        fromURI: _mediaFile!.path,
        whenFinished: () => setState(() => _isPlaying = false),
      );
      setState(() => _isPlaying = true);
    } else {
      await _audioPlayer.stopPlayer();
      setState(() => _isPlaying = false);
    }
  }

  void _clearMedia() {
    setState(() {
      _mediaFile = null;
      _mediaType = null;
      _isPlaying = false;
    });
  }

  // Future<void> _saveSignature() async {
  //   final Uint8List? bytes = await _signatureController.toPngBytes();
  //   if (bytes == null || bytes.isEmpty) return;

  //   final dir = await getApplicationDocumentsDirectory();
  //   final file = File('${dir.path}/signature.png');
  //   await file.writeAsBytes(bytes);
  //   setState(() {
  //     _signatureFile = file;
  //     _isSavingSignature = false;
  //   });
  // }
  Future<void> _saveSignature() async {
    final Uint8List? bytes = await _signatureController.toPngBytes();
    if (bytes == null || bytes.isEmpty) return;

    final dir = await getApplicationDocumentsDirectory();
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final file = File('${dir.path}/signature_$timestamp.png');
    await file.writeAsBytes(bytes);

    setState(() {
      _signatureFile = file;
      _isSavingSignature = false;
    });
  }

  void _clearSignature() {
    _signatureController.clear();
    setState(() {
      _signatureFile = null;
    });
  }

  Future<void> _uploadData() async {
    if (_mediaFile == null || _mediaType == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please add a photo, video, or audio")),
      );
      return;
    }

    setState(() => _isUploading = true);

    try {
      final response = await ApiService.uploadMultimedia(
        token: widget.token,
        checklistId: widget.checklistId,
        mediaFile: _mediaFile!,
        mediaType: _mediaType!,
        description: _remarksController.text.trim(),
        patrolId: widget.user['id'],
        createdBy: widget.user['id'],
      );

      // Save signature if provided
      if (_signatureFile == null && _signatureController.isNotEmpty) {
        final Uint8List? bytes = await _signatureController.toPngBytes();
        if (bytes != null && bytes.isNotEmpty) {
          final dir = await getApplicationDocumentsDirectory();
          final file = File('${dir.path}/${widget.checklistId}Signature.jpg');
          await file.writeAsBytes(bytes);
          _signatureFile = file;
        }
      }

      // Upload signature if available
      if (_signatureFile != null) {
        final signatureResponse = await ApiService.uploadSignature(
          signatureFile: _signatureFile!,
          patrolId: widget.user['id'],
          checklistId: widget.checklistId,
          token: widget.token,
        );
        debugPrint("✅ Signature uploaded: ${signatureResponse['message']}");
      }

      if (response.statusCode == 200) {
        final result = json.decode(response.body);

        if (widget.mode == 'notbymenu') {
          // Just pop back to previous checklist screen
          Navigator.pop(context);
        } else {
          // Navigate to PatrolDashboardScreen
          showDialog(
            context: context,
            builder: (_) => AlertDialog(
              title: const Text('Success'),
              content: Text(
                  result['message'] ?? "Multimedia uploaded successfully."),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(context); // close dialog
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(
                        builder: (_) => PatrolDashboardScreen(
                          userdata: widget.user,
                          token: widget.token,
                        ),
                      ),
                    );
                  },
                  child: const Text('OK'),
                ),
              ],
            ),
          );
        }

        setState(() {
          _mediaFile = null;
          _mediaType = null;
          _signatureFile = null;
          _remarksController.clear();
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Upload failed: ${response.statusCode}")),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Upload error: $e")),
      );
    } finally {
      setState(() => _isUploading = false);
    }
  }

  Widget _buildMediaPreview() {
    if (_mediaFile == null || _mediaType == null) return SizedBox();
    return Column(
      children: [
        if (_mediaType == 'image')
          ClipRRect(
            borderRadius: BorderRadius.all(Radius.circular(12)),
            child: Image.file(_mediaFile!, height: 200),
          ),
        if (_mediaType == 'video')
          Row(children: [
            Icon(Icons.videocam, color: AppConstants.fontColorSecondary),
            SizedBox(width: 8),
            Text("Video selected", style: AppConstants.normalGreyFontStyle)
          ]),
        if (_mediaType == 'audio')
          Row(
            children: [
              Icon(Icons.audiotrack, color: AppConstants.primaryColor),
              TextButton.icon(
                icon: Icon(_isPlaying ? Icons.stop : Icons.play_arrow,
                    color: AppConstants.fontColorSecondary),
                label: Text(_isPlaying ? "Stop" : "Play",
                    style: AppConstants.normalGreyFontStyle),
                onPressed: _togglePlayAudio,
              )
            ],
          ),
        Align(
          alignment: Alignment.centerRight,
          child: TextButton.icon(
            icon: Icon(Icons.clear, color: AppConstants.fontColorSecondary),
            label: Text("Clear", style: AppConstants.normalGreyFontStyle),
            onPressed: _clearMedia,
          ),
        )
      ],
    );
  }

  Widget _buildSignatureSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Digital Signature", style: AppConstants.headingStyle),
        SizedBox(height: 12),
        if (_signatureFile != null)
          Column(
            children: [
              Image.file(_signatureFile!, height: 100),
              TextButton.icon(
                icon: Icon(Icons.clear, color: AppConstants.fontColorSecondary),
                label: Text("Clear Signature",
                    style: AppConstants.normalGreyFontStyle),
                onPressed: _clearSignature,
              )
            ],
          )
        else if (_isSavingSignature)
          Column(
            children: [
              Container(
                height: 150,
                decoration: BoxDecoration(
                  border: Border.all(color: AppConstants.primaryColor),
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                child: Signature(
                    controller: _signatureController,
                    backgroundColor: AppConstants.backgroundColor),
              ),
              Row(
                children: [
                  TextButton.icon(
                    icon: Icon(Icons.check, color: AppConstants.primaryColor),
                    label:
                        Text("Save", style: AppConstants.normalPurpleFontStyle),
                    onPressed: _saveSignature,
                  ),
                  TextButton.icon(
                    icon: Icon(Icons.cancel, color: AppConstants.primaryColor),
                    label: Text("Cancel",
                        style: AppConstants.normalPurpleFontStyle),
                    onPressed: _clearSignature,
                  )
                ],
              ),
            ],
          )
        else
          TextButton.icon(
            icon: Icon(Icons.gesture, color: AppConstants.primaryColor),
            label:
                Text("Add Signature", style: AppConstants.boldPurpleFontStyle),
            onPressed: () => setState(() => _isSavingSignature = true),
          )
      ],
    );
  }

  @override
  void dispose() {
    _audioRecorder.closeRecorder();
    _audioPlayer.closePlayer();
    _signatureController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        //   leading: (widget.mode == 'edit')
        // ? IconButton(
        //     icon: const Icon(Icons.arrow_back),
        //     onPressed: () {
        //       Navigator.pop(context);
        //     },
        //   )
        // : null,
        title: Text(
          "Multimedia ${widget.checklistId}",
          style: AppConstants.headingStyle,
        ),
        leading: (widget.mode == 'notbymenu')
            ? IconButton(
                icon: Icon(Icons.arrow_back, color: AppConstants.primaryColor),
                onPressed: () async {
                  // Then navigate back
                  Navigator.pop(context);
                },
              )
            : Builder(
                builder: (context) => IconButton(
                  icon:
                      const Icon(Icons.menu, color: AppConstants.primaryColor),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              ),
      ),
      drawer: CustomDrawer(userdata: widget.user, token: widget.token),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: _capturePhoto,
                      icon: Icon(Icons.camera_alt,
                          color: AppConstants.primaryColor),
                      label: Text("Photo",
                          style: AppConstants.boldPurpleFontStyle),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final videoFile = await Navigator.push<File>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TimedVideoRecordingScreen(
                              maxDuration: const Duration(seconds: 10),
                            ),
                          ),
                        );

                        if (videoFile != null) {
                          setState(() {
                            _mediaFile = videoFile;
                            _mediaType = 'video';
                          });
                        }
                      },
                      icon: Icon(Icons.videocam,
                          color: AppConstants.primaryColor),
                      label: Text("Video",
                          style: AppConstants.boldPurpleFontStyle),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        final recordedFile = await Navigator.push<File>(
                          context,
                          MaterialPageRoute(
                            builder: (_) => AudioRecordingScreen(
                              onAudioSaved: (File file) {
                                // No need to do anything here since we'll get the file
                                // as the result of Navigator.push
                              },
                            ),
                          ),
                        );

                        if (recordedFile != null) {
                          setState(() {
                            _mediaFile = recordedFile;
                            _mediaType = 'audio';
                          });
                        }
                      },
                      icon: Icon(Icons.mic, color: AppConstants.primaryColor),
                      label: Text("Audio",
                          style: AppConstants.boldPurpleFontStyle),
                      style: ElevatedButton.styleFrom(
                        padding: EdgeInsets.symmetric(vertical: 5.0),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 12),
            _buildMediaPreview(),
            Divider(height: 32),
            _buildSignatureSection(),
            Divider(height: 32),
            TextField(
              controller: _remarksController,
              decoration: InputDecoration(
                labelText: "Remarks",
                labelStyle: AppConstants.normalPurpleFontStyle,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.all(Radius.circular(12)),
                ),
                floatingLabelBehavior: FloatingLabelBehavior
                    .always, // Keeps label inside the border
              ),
              maxLines: 5,
            ),
            SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _isUploading
                  ? null
                  : () {
                      if (_signatureFile == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                "Please add your signature before submitting."),
                            backgroundColor: Colors.red,
                          ),
                        );
                      } else {
                        _uploadData();
                      }
                    },
              icon: Icon(Icons.send, color: AppConstants.primaryColor),
              label:
                  Text("Send MME", style: AppConstants.selectedButtonFontStyle),
              style: ElevatedButton.styleFrom(minimumSize: Size.fromHeight(50)),
            ),
          ],
        ),
      ),
    );
  }
}
