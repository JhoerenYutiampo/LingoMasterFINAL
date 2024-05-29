import 'dart:io';
import 'package:flutter/material.dart';
import 'package:gallery_picker/gallery_picker.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:permission_handler/permission_handler.dart';

class Letters extends StatefulWidget {
  @override
  State<Letters> createState() => _LettersState();
}

class _LettersState extends State<Letters> {
  File? selectedMedia;

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    Map<Permission, PermissionStatus> statuses = await [
      Permission.storage,
      Permission.photos,
      Permission.mediaLibrary,
    ].request();

    bool allGranted = statuses.values.every((status) => status.isGranted);

    if (!allGranted) {
      print("Not all permissions are granted");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        centerTitle: true,
        title: const Text("Text Recognition"),
      ),
      body: _buildUI(),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          try {
            print("Attempting to pick media...");
            List<MediaFile>? media = await GalleryPicker.pickMedia(
              context: context,
              singleMedia: true,
            );
            print("Media selected: $media");
            if (media != null && media.isNotEmpty) {
              var data = await media.first.getFile();
              print("Media file data: $data");
              if (data != null) {
                setState(() {
                  selectedMedia = data;
                  print("Media file selected: ${selectedMedia!.path}");
                });
              } else {
                print("Failed to get file from media picker");
              }
            } else {
              print("No media selected");
            }
          } catch (e) {
            print("Error picking media: $e");
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildUI() {
    return Column(
      mainAxisSize: MainAxisSize.max,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _imageView(),
        _extractTextView(),
      ],
    );
  }

  Widget _imageView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("Pick an Image for text recognition"),
      );
    }
    return Center(
      child: Image.file(
        selectedMedia!,
        width: 200,
      ),
    );
  }

  Widget _extractTextView() {
    if (selectedMedia == null) {
      return const Center(
        child: Text("No Result"),
      );
    }
    return FutureBuilder<String?>(
      future: _extractText(selectedMedia!),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const CircularProgressIndicator();
        } else if (snapshot.hasError) {
          return Text(
            "Error: ${snapshot.error}",
            style: const TextStyle(fontSize: 25),
          );
        } else {
          return Text(
            snapshot.data ?? "",
            style: const TextStyle(fontSize: 25),
          );
        }
      },
    );
  }

  Future<String?> _extractText(File file) async {
    try {
      final textRecognizer = TextRecognizer(
        script: TextRecognitionScript.japanese,
      );
      final InputImage inputImage = InputImage.fromFile(file);
      final RecognizedText recognizedText =
          await textRecognizer.processImage(inputImage);
      String text = recognizedText.text;
      textRecognizer.close();
      return text;
    } catch (e) {
      print("Error extracting text: $e");
      return "Error extracting text";
    }
  }
}
