import 'dart:convert';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;

import 'package:geolocator/geolocator.dart';

class Imagen extends StatefulWidget {
  @override
  State<StatefulWidget> createState() {
    return _ImagenState();
  }
}

class _ImagenState extends State<Imagen> {
  String imagePath =
      "https://www.dqarquitectura.com/informacion/wp-content/uploads/2019/04/logo-fotografia-022-1.jpg";
  String uploadedImage = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("CARGAR MULTIMEDIA"),
      ),
      body: Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                onPressed: () {
                  originMedia();
                },
                child: Icon(
                  Icons.add_a_photo,
                  color: Colors.white,
                  size: 100,
                ),
              ),
              Container(
                margin:
                    EdgeInsets.only(top: 20, left: 20, right: 20, bottom: 20),
                width: MediaQuery.of(context).size.width * 0.6,
                height: MediaQuery.of(context).size.height * 0.5,
                decoration: BoxDecoration(
                    shape: BoxShape.rectangle,
                    image: DecorationImage(
                        fit: BoxFit.cover, image: NetworkImage(imagePath))),
              ),
              TextFormField(
                decoration: InputDecoration(labelText: 'Agregar descripción'),
              )
            ],
          )),
    );
  }

  Future<void> originMedia() {
    return showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            content: SingleChildScrollView(
                child: Column(
              children: [
                GestureDetector(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Tomar una foto",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.camera_alt, color: Colors.white)
                      ],
                    ),
                  ),
                  onTap: () {
                    getImage(ImageSource.camera);
                  },
                ),
                GestureDetector(
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.blue),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Seleccionar una foto",
                            style: TextStyle(fontSize: 16),
                          ),
                        ),
                        Icon(Icons.image, color: Colors.white)
                      ],
                    ),
                  ),
                  onTap: () {
                    getImage(ImageSource.gallery);
                  },
                ),
                GestureDetector(
                  onTap: () {
                    Navigator.of(context).pop();
                  },
                  child: Container(
                    padding: EdgeInsets.all(20),
                    decoration: BoxDecoration(color: Colors.red),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            "Cancelar",
                            style: TextStyle(fontSize: 16, color: Colors.white),
                            textAlign: TextAlign.center,
                          ),
                        )
                      ],
                    ),
                  ),
                ),
              ],
            )),
          );
        });
  }

  void getImage(ImageSource source) async {
    File image;

    var picture = await ImagePicker.platform.pickImage(source: source);

    if (picture != null) {
      image = File(picture.path);
      Navigator.of(context).pop();
      ImageResponse go = await upLoadImag(image);

      this.uploadedImage = go.fileUploaded;

      if (uploadedImage != '') {
        setState(() {
          this.imagePath =
              //Heroku no está funcionando bien, en ese caso, cambiar la url por http://10.0.2.2:8888/obtenerimagen/
              "https://media-app-mobile.herokuapp.com/obtenerimagen/" +
                  uploadedImage;
          this.uploadedImage = '';
          Navigator.of(context).pop();
        });
      }
    }
  }

  Future<ImageResponse> upLoadImag(File image) async {
    var request = http.MultipartRequest(
        //Heroku no está funcionando bien, en ese caso, cambiar la url por http://10.0.2.2:8888/subirimagen/
        "POST",
        Uri.parse("https://media-app-mobile.herokuapp.com/subirimagen"));

    var picture = await http.MultipartFile.fromPath("imagen", image.path);

    request.files.add(picture);

    Position position = await getGeografy();

    request.fields["longitud"] = position.longitude.toString();
    request.fields["latitud"] = position.latitude.toString();
    request.fields["altitud"] = position.altitude.toString();

    var response = await request.send();

    var responseData = await response.stream.toBytes();

    String rawResponse = utf8.decode(responseData);

    var jsonResponse = jsonDecode(rawResponse);

    print(rawResponse);

    ImageResponse go = ImageResponse(jsonResponse);

    return go;
  }

  Future<Position> getGeografy() async {
    bool enableService = await Geolocator.isLocationServiceEnabled();
    //GPS esta encendido

    if (enableService) {
      LocationPermission permits = await Geolocator.checkPermission();

      if (permits == LocationPermission.denied ||
          permits == LocationPermission.deniedForever) {
        permits = await Geolocator.requestPermission();
      }

      if (permits == LocationPermission.whileInUse ||
          permits == LocationPermission.always) {
        Position position = await Geolocator.getCurrentPosition(
            desiredAccuracy: LocationAccuracy.bestForNavigation);
        return position;
      }
    }

    return Position(
        longitude: 0,
        latitude: 0,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        heading: 0,
        speed: 0,
        speedAccuracy: 0);
  }
}

class ImageResponse {
  String fileUploaded = '';

  ImageResponse(Map jsonResponse) {
    this.fileUploaded = jsonResponse["fileUploaded"];
  }
}
