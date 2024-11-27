import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

void main() {
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Pothole Detection',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: HomeScreen(),
    );
  }
}

class HomeScreen extends StatefulWidget {
  @override
  _HomeScreenState createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  File? _image; // To store the captured image
  String _imageUrl = ''; // To store the URL of the processed image
  String _response = ''; // To show status message
  final ImagePicker _picker = ImagePicker(); // ImagePicker instance

  // Method to open the camera
  Future<void> _openCamera() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.camera);
    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path); // Store the captured image
        _imageUrl = ''; // Clear previous result, in case there's an existing image URL
      });
    }
  }

  // Method to send the image to the backend for pothole detection
  Future<void> _sendImageToBackend() async {
    if (_image == null) return;

    String backendUrl = 'http://192.168.1.19:5000/detect_potholes'; // Replace with your backend URL

    // Prepare the image file to be sent
    var uri = Uri.parse(backendUrl);
    var request = http.MultipartRequest('POST', uri);

    // Attach the image to the request
    var file = await http.MultipartFile.fromPath('image', _image!.path,
        contentType: MediaType('image', 'jpeg')); // Adjust contentType if needed
    request.files.add(file);

    // Send the request to the backend
    var response = await request.send();

    // Handle the response
    if (response.statusCode == 200) {
      var result = await http.Response.fromStream(response);
      var jsonResponse = json.decode(result.body);
      String imageUrl = jsonResponse['image_url']; // Get the image URL

      setState(() {
        _response = 'Potholes detected';
        _imageUrl = imageUrl; // Save the image URL for display
      });
    } else {
      setState(() {
        _response = 'Error in detecting potholes.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Pothole Detection'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // If _imageUrl is not empty, display the processed image.
            // Otherwise, display the captured image.
            _imageUrl.isNotEmpty
                ? Image.network(_imageUrl) // Display the processed image from the backend
                : (_image == null
                ? Text('No image captured.')
                : Image.file( // Display the captured image
              _image!,
              width: 200,
              height: 200,
            )),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _openCamera,
              child: Text('Open Camera'),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendImageToBackend,
              child: Text('Send Image for Detection'),
            ),
            SizedBox(height: 20),
            _response.isNotEmpty ? Text(_response) : SizedBox.shrink(),
          ],
        ),
      ),
    );
  }
}
