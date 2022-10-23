import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import 'dart:convert';


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
  String? _result = "";
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
    _result = "";
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
        imageMean: 0.5,
        imageStd: 1.0,
        threshold: 0.1,
        numResults: 1,
        asynch: true
    );
    var result = "malaria";
    if (output != null && output.length != 0){
      var temp = output[0];
      result = (temp['index'] == 1) ? "healthy" : "malaria";
    }

    print("predict = "+result);
    setState(() {
      _outputs = output;
      _result = result;
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
              Container(
                margin: const EdgeInsets.all(30.0),
                child: Text('Result:',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
              ),
              Container(
                child: Text(_result.toString(),
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 23)),
              )
            ]),
          ),
        ));
  }
}