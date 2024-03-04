import 'package:flutter/material.dart';
import 'package:location/location.dart' as location;
import 'package:geocoding/geocoding.dart' as geocoding;
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:math';
import 'package:vibration/vibration.dart'; // Import du package Vibration
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase/Views/crediantial.dart';
import 'package:mailer/mailer.dart';
import 'package:mailer/smtp_server.dart';
import 'package:sensors/sensors.dart';

class MyHomePage extends StatefulWidget {
  const MyHomePage({Key? key}) : super(key: key);

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  final end = TextEditingController();
  bool isVisible = false;
  List<LatLng> routpoints = [LatLng(52.05884, -1.345583)];
  late GoogleMapController _controller;
  location.Location _locationController = location.Location();
  LatLng? destination;
  LatLng? _currentP;
  bool _isFalling = false;

  @override
  void initState() {
    super.initState();
    accelerometerEvents.listen((AccelerometerEvent event) {
      // Détection de la chute (par exemple, une accélération rapide vers le bas)
      if (event.z < -5) {
        setState(() {
          _isFalling = true;
        });
        // Réaction à une chute détectée, par exemple afficher une alerte
        sendEmail(context);
      } else {
        setState(() {
          _isFalling = false;
        });
      }
    });
    getLocationUpdates();
    _getCurrentLocation();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Google Map',
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
        ),
        centerTitle: true,
        backgroundColor: Colors.grey[300],
      ),
      backgroundColor: Colors.grey[300],
      body: Stack(
        children: [
          Align(
          alignment: Alignment.bottomRight,
          child: locationButton(),
        ),
          GoogleMap(
            initialCameraPosition: CameraPosition(
              target: _currentP ?? LatLng(0, 0),
              zoom: 15,
            ),
            onMapCreated: (GoogleMapController controller) {
              _controller = controller;
            },
            markers: {
              if (_currentP != null)
                Marker(
                  markerId: MarkerId('currentLocation'),
                  position: _currentP!,
                  icon: BitmapDescriptor.defaultMarker,
                ),
              if (destination != null)
                Marker(
                  markerId: MarkerId('destination'),
                  position: destination!,
                  icon: BitmapDescriptor.defaultMarkerWithHue(
                    BitmapDescriptor.hueBlue,
                  ),
                ),
            },
            polylines: Set<Polyline>.from([
              Polyline(
                polylineId: PolylineId("route"),
                points: routpoints,
                color: Colors.blue,
                width: 9,
              ),
            ]),
          ),
          Positioned(
            
            top: 15.0,
            left: 15.0,
            right: 15.0,
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white,
              ),
              
              child: Row(
                children: [
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      child: TextField(
                        controller: end,
                        onChanged: (value) {
                          _calculateDistance();
                        },
                        decoration: InputDecoration(
                          hintText: 'Destination',
                          border: InputBorder.none,
                        ),
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () async {
                      if (end.text.isNotEmpty) {
                        List<geocoding.Location> end_l =
                            await geocoding.locationFromAddress(end.text);

                        var v3 = end_l[0].latitude;
                        var v4 = end_l[0].longitude;

                        var url = Uri.parse(
                            'http://router.project-osrm.org/route/v1/driving/${_currentP!.longitude},${_currentP!.latitude};$v4,$v3?steps=true&annotations=true&geometries=geojson&overview=full');
                        var response = await http.get(url);
                        print(response.body);
                        setState(() {
                          routpoints = [];
                          var ruter = jsonDecode(response.body)['routes'][0]
                              ['geometry']['coordinates'];
                          for (int i = 0; i < ruter.length; i++) {
                            var reep = ruter[i].toString();
                            reep = reep.replaceAll("[", "");
                            reep = reep.replaceAll("]", "");
                            var lat1 = reep.split(',');
                            var long1 = reep.split(",");
                            routpoints.add(LatLng(
                                double.parse(lat1[1]), double.parse(long1[0])));
                          }
                          destination = LatLng(v3, v4);
                          isVisible = !isVisible;
                          print(routpoints);
                          _calculateDistance();
                        });
                      } else {
                        showDialog(
                          context: context,
                          builder: (context) => AlertDialog(
                            title: Text('Erreur'),
                            content: Text('Veuillez entrer une destination.'),
                            actions: [
                              TextButton(
                                onPressed: () {
                                  Navigator.of(context).pop();
                                },
                                child: Text('OK'),
                              ),
                            ],
                          ),
                        );
                      }
                    },
                    icon: Icon(Icons.search),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            bottom: 15.0,
            left: 15.0,
            right: 15.0,
            child: Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                children: [
                  Visibility(
                    visible: isVisible,
                    child: Container(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(20),
                        color: Colors.white,
                      ),
                      padding: EdgeInsets.all(10),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'Distance: ${_calculateDistance().toStringAsFixed(2)} km',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),
                    ),
                  ),
                  SizedBox(height: 10),
                  sosButton(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _cameraToPosition(LatLng pos) async {
    final GoogleMapController controller = await _controller;
    CameraPosition _newCameraPosition = CameraPosition(
      target: pos,
      zoom: 15,
    );
    await controller.animateCamera(
      CameraUpdate.newCameraPosition(_newCameraPosition),
    );
  }

  Future<void> getLocationUpdates() async {
    bool _serviceEnabled;
    location.PermissionStatus _permissionGranted;

    _serviceEnabled = await _locationController.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await _locationController.requestService();
    }
    if (!_serviceEnabled) {
      throw Exception('Location service not enabled');
    }

    _permissionGranted = await _locationController.hasPermission();
    if (_permissionGranted == location.PermissionStatus.denied) {
      _permissionGranted = await _locationController.requestPermission();
      if (_permissionGranted != location.PermissionStatus.granted) {
        throw Exception('Location permission not granted');
      }
    }

    _locationController.onLocationChanged
        .listen((location.LocationData currentLocation) {
      if (currentLocation.latitude != null &&
          currentLocation.longitude != null) {
        setState(() {
          _currentP =
              LatLng(currentLocation.latitude!, currentLocation.longitude!);
          _cameraToPosition(_currentP!);
          if (destination != null) {
            double distance = _calculateDistance();
            // Vibration lorsque la distance restante est inférieure à 100 mètres (vous pouvez ajuster cette valeur selon vos besoins)
            if (distance < 0.1) {
              Vibration.vibrate(duration: 1000);
            }
          }
        });
      }
    });
  }

  void _getCurrentLocation() async {
    location.LocationData currentLocation =
        await _locationController.getLocation();

    setState(() {
      isVisible = true;
      _currentP = LatLng(currentLocation.latitude!, currentLocation.longitude!);
    });
  }

  double _calculateDistance() {
    if (_currentP == null || destination == null) return 0.0;
    final double earthRadius = 6371.0;
    double lat1 = _currentP!.latitude;
    double lon1 = _currentP!.longitude;
    double lat2 = destination!.latitude;
    double lon2 = destination!.longitude;
    double dLat = _toRadians(lat2 - lat1);
    double dLon = _toRadians(lon2 - lon1);
    double a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRadians(lat1)) *
            cos(_toRadians(lat2)) *
            sin(dLon / 2) *
            sin(dLon / 2);
    double c = 2 * asin(sqrt(a));
    double distance = earthRadius * c;
    return distance;
  }

  double _toRadians(double degree) {
    return degree * pi / 180;
  }

  void callEmergencyNumber() async {
    final Uri emergencyNumber = Uri(
      scheme: 'tel',
      path: '+21652631030',
    );

    if (await canLaunch(emergencyNumber.toString())) {
      await launch(emergencyNumber.toString());
    } else {
      throw 'Could not launch $emergencyNumber';
    }
  }

  Widget sosButton() {
    return GestureDetector(
      onTap: callEmergencyNumber,
      child: Container(
        width: 60,
        height: 60,
        padding: EdgeInsets.all(8.0),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.red,
        ),
        child: Icon(
          Icons.sos,
          color: Colors.white,
          size: 30,
        ),
      ),
    );
  }
  

  sendEmail(BuildContext context //For showing snackbar
      ) async {
    String username = EMAIL; //Your Email
    String password =
        PASS; // 16 Digits App Password Generated From Google Account

    final smtpServer = gmail(username, password);
    String googleMapsLink =
        generateGoogleMapsLink(_currentP!.latitude, _currentP!.longitude);
    // Create our message.
    final message = Message()
      ..from = Address(username, 'Rahma ktari')
      ..recipients.add('khalilkossentini69@gmail.com')
      ..subject = 'Attention!!!'
      ..text = 'j\'ai besoin d\'aide:\n$googleMapsLink';
    try {
      final sendReport = await send(message, smtpServer);
      print('Message sent: ' + sendReport.toString());
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Mail Sent Successfully")));
    } on MailerException catch (e) {
      print('Message not sent.');
      print(e.message);
      for (var p in e.problems) {
        print('Problem: ${p.code}: ${p.msg}');
      }
    }
  }
Widget locationButton() {
  return GestureDetector(
    onTap: () {
      sendEmail(context);
    },
    child: Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Expanded(
          child: Container(
            width: 30,
            height: 30,
            padding: EdgeInsets.all(7.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
            child: Icon(
              Icons.location_on,
              color: Colors.blue,
              size: 60,
            ),
          ),
        ),
        SizedBox(width: 8),
        Expanded(
          child: Container(
            width: 30,
            height: 30,
            padding: EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blueAccent,
            ),
            child: Icon(
              Icons.send,
              color: Colors.white,
              size: 30,
            ),
          ),
        ),
      ],
    ),
  );
}


  String generateGoogleMapsLink(double latitude, double longitude) {
    return "https://www.google.com/maps/search/?api=1&query=$latitude,$longitude";
  }
  
}

