import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';

import 'package:tflite/tflite.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    Get.lazyPut(()=>ImageController());
    return const MaterialApp(
      // Hide the debug banner
      debugShowCheckedModeBanner: false,
      title: 'Image upload',
      home: HomePage(),
    );
  }
}

class ImageController {
}

class HomePage extends StatefulWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  File? _image;
  List? _outputs;
  PickedFile? _pickedFile;
  bool _isButtonDisabled = true;

  @override
  void initState() {
    super.initState();
    loadModel().then((value) {setState((){});});
    _isButtonDisabled = true;
  }

  final _picker = ImagePicker();
  // Implementing the image picker
  Future<void> _pickImage() async {
    print("Function pickImage is called!");
    _pickedFile=
    await _picker.getImage(source: ImageSource.gallery);
    if (_pickedFile != null) {
      setState(() {
        _image = File(_pickedFile!.path);
        _isButtonDisabled = false;
      });
    }
  }

  // Start the image prediction.
  classifyImage(File image) async {
    print("Start predict");
    var output = await Tflite.runModelOnImage(
      path: image.path,
      imageMean: 80.0,   // defaults to 117.0
      threshold: 0.2,   // defaults to 0.1
      asynch: true
    );
    print("predict = "+output.toString());
    setState(() {
      _outputs = output;
    });
  }

  loadModel() async {
    await Tflite.loadModel(
      model: "assets/converted_model.tflite",
      labels: "assets/label.txt",
    );
  }

  @override
  void dispose() {
    Tflite.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: const Text('Image upload'),
        ),
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(35),
            child: Column(children: [
              Center(
                child: GestureDetector(
                  child: const Text('Select An Image'),
                  //onPressed: _openImagePicker,
                  //onTap:()=> Get.find<ImageController>().pickImage(),
                  onTap: ()=>_pickImage(),
                ),
              ),
              const SizedBox(height: 35),
              Container(
                alignment: Alignment.center,
                width: double.infinity,
                height: 200,
                color: Colors.grey[300],
                child: _pickedFile != null
                    ? Image.file(
                  File(_pickedFile!
                      .path), width: 200, height: 200, fit: BoxFit.cover,
                )
                    : const Text('Please select an image'),
              ),
              Center(
                child: ElevatedButton(
                  onPressed: _isButtonDisabled ? null : ()=> classifyImage(
                    File(_pickedFile!.path)
                  ),
                  child: Text('Predict'),
                )
              ),
            ]),
          ),
        ));
  }
}