import 'dart:async';

// import 'dart:js_util';
// import 'dart:html';
// import 'package:location/location.dart';
import 'package:animated_text_kit/animated_text_kit.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/services.dart';
import 'package:flutter_geofire/flutter_geofire.dart';
import 'package:flutter_polyline_points/flutter_polyline_points.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:geolocator/geolocator.dart' as geolocator;

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:users_app/assistants/assistant_methods.dart';
import 'package:users_app/assistants/geofire_assistant.dart';
import 'package:users_app/authentication/login_screen.dart';
import 'package:users_app/global/global.dart';
import 'package:users_app/infoHandler/app_info.dart';
import 'package:users_app/main.dart';
import 'package:users_app/mainScreens/new_trip_screen.dart';
import 'package:users_app/mainScreens/rate_driver_screen.dart';
import 'package:users_app/mainScreens/search_places_screen.dart';
import 'package:users_app/mainScreens/select_nearest_active_drivers_screen.dart';
import 'package:users_app/models/active_nearby_available_drivers.dart';
import 'package:users_app/models/user_ride_request_information.dart';
import 'package:users_app/widgets/my_drawer.dart';
import 'package:users_app/widgets/progress_dialog.dart';

/*How the Geocoding API works
The Geocoding API does both geocoding and reverse geocoding:

Geocoding: Converts addresses such as "1600 Amphitheatre Parkway, Mountain View, CA" into latitude and longitude coordinates or Place IDs. You can use these coordinates to place markers on a map, or to center or reposition the map within the view frame.

Reverse geocoding: Converts latitude/longitude coordinates or a Place ID into a human-readable address. You can use addresses for a variety of scenarios, including deliveries or pickups. */

//Geofire :-
/*Geo Queries
GeoFire allows you to query all keys within a geographic area using GeoQuery objects. As the locations for keys change, the query is updated in realtime and fires events letting you know if any relevant keys have moved. GeoQuery parameters can be updated later to change the size and center of the queried area. */

class MainScreen extends StatefulWidget {
  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final Completer<GoogleMapController> _controllerGoogleMap = Completer();

  GoogleMapController? newGoogleMapController;

  // CameraPosition _kGooglePlex = CameraPosition(
  //   target: LatLng(37.42796133580664, -122.085749655962),
  //   zoom: 14.4746,
  // );

  GlobalKey<ScaffoldState> sKey = GlobalKey<ScaffoldState>();
  double searchLocationContainerHeight = 220.0;
  double waitingResponseFromDriverContainerHeight = 0;
  double assignedDriverInfoContainerHeight = 0;

  Position? userCurrentPosition;
  var geoLocator = Geolocator();

  LocationPermission? _locationPermission;
  double bottomPaddingOfMap = 0;

  List<LatLng> pLineCoOrdinatesList = [];
  Set<Polyline> polylineSet = {};

  String userName = "Your Name";
  String userEmail = "Your Email";

  Set<Marker> markersSet = {};
  Set<Circle> circlesSet = {};

  bool openNavigationDrawer = true;

  bool activeNearbyDriverKeysLoaded = false;
  BitmapDescriptor? activeNearbyIcon;

  List<ActiveNearbyAvailableDrivers> onlineNearByAvailableDriversList = [];

  DatabaseReference? referenceRideRequest;
  String driverRideStatus = "Mechanic is Coming";

  StreamSubscription<DatabaseEvent>?
      tripRideRequestInfoStreamSudscription; //for getting the live updates of the driver

  blackThemeGoogleMap() {
    newGoogleMapController!.setMapStyle('''
                    [
                      {
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#242f3e"
                          }
                        ]
                      },
                      {
                        "featureType": "administrative.locality",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#263c3f"
                          }
                        ]
                      },
                      {
                        "featureType": "poi.park",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#6b9a76"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#38414e"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#212a37"
                          }
                        ]
                      },
                      {
                        "featureType": "road",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#9ca5b3"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#746855"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "geometry.stroke",
                        "stylers": [
                          {
                            "color": "#1f2835"
                          }
                        ]
                      },
                      {
                        "featureType": "road.highway",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#f3d19c"
                          }
                        ]
                      },
                      {
                        "featureType": "transit",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#2f3948"
                          }
                        ]
                      },
                      {
                        "featureType": "transit.station",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#d59563"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "geometry",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.fill",
                        "stylers": [
                          {
                            "color": "#515c6d"
                          }
                        ]
                      },
                      {
                        "featureType": "water",
                        "elementType": "labels.text.stroke",
                        "stylers": [
                          {
                            "color": "#17263c"
                          }
                        ]
                      }
                    ]
                ''');
  }

  checkIfLocationPermissionAllowed() async {
    _locationPermission = await Geolocator
        .requestPermission(); //it will request the locationPermission that hey allow the permission

    //if user denied the permission to turn on the location of the phone. Then we again request the user to turn on the location
    if (_locationPermission == LocationPermission.denied) {
      _locationPermission = await Geolocator
          .requestPermission(); //it will request the locationPermission that hey allow the permission
    }
  }

  locateUserPosition() async {
    //the below code will give us the position of the current user at the real time
    Position cPosition = await Geolocator.getCurrentPosition(
        // desiredAccuracy: geolocator.LocationAccuracy.high);
        desiredAccuracy: LocationAccuracy
            .high); //we used high here bcz we want the exact accurate location of the user
    // userCurrentPosition = cPosition;
    if (cPosition != null) {
      print("User position: ${cPosition.latitude}, ${cPosition.longitude}");
      // Update the user's position
      setState(() {
        userCurrentPosition = cPosition;
      });
    } else {
      print("Failed to get user's position.");
    }

    LatLng latLngPosition =
        LatLng(userCurrentPosition!.latitude, userCurrentPosition!.longitude);
    CameraPosition cameraPosition =
        CameraPosition(target: latLngPosition, zoom: 14);

    newGoogleMapController!
        .animateCamera(CameraUpdate.newCameraPosition(cameraPosition));

    //we have implemented the reverse geocoding here i.e. we have converted the address in the terms of the coordinates to the human readable address.

    String humanReadableAddress =
        await AssistantMethods.searchAddressForGeographicCoOrdinates(
            userCurrentPosition!,
            context); //we passed the position i.e. the coordinates to the method. This method is defined in the assistant_methods.dart file
    print("this is your Address = " + humanReadableAddress);

    userName = userModelCurrentInfo!.name!;
    userEmail = userModelCurrentInfo!.email!;

    initializeGeofireListener();
  }

  @override
  void initState() {
    super.initState();
    checkIfLocationPermissionAllowed();
    // AssistantMethods.readCurrentOnlineUserInfo();
  }

  saveRideRequestInformation() {
    //save the ride request information. i.e. which user have placed the request

    referenceRideRequest =
        FirebaseDatabase.instance.ref().child("All Ride Request").push();
    //this .push() generates unique ID
    var originLocation =
        Provider.of<AppInfo>(context, listen: false).userPickUpLocation;

    //this is a map in the form the key-value pair and not the google map
    Map originLocationMap = {
      "latitude": originLocation!.locationLatitude.toString(),
      "longitude": originLocation!.locationLongitude.toString(),
    };

    Map userInformationMap = {
      "origin": originLocationMap,
      "time": DateTime.now().toString(),
      "userName": userModelCurrentInfo!.name,
      "userPhone": userModelCurrentInfo!.phone,
      "originAddress": originLocation.locationName,
      "driverId": "waiting",
    };

    referenceRideRequest!.set(
        userInformationMap); //it will save the information in te database "All Ride Request"

    tripRideRequestInfoStreamSudscription =
        referenceRideRequest!.onValue.listen((eventSnap) async {
      if (eventSnap.snapshot.value == null) {
        return;
      }

      driverRideRequestId = eventSnap.snapshot.value.toString();

      if ((eventSnap.snapshot.value as Map)["driverPhone"] != null) {
        setState(() {
          driverPhone =
              (eventSnap.snapshot.value as Map)["driverPhone"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["driverName"] != null) {
        setState(() {
          driverName =
              (eventSnap.snapshot.value as Map)["driverName"].toString();
        });
      }

      if ((eventSnap.snapshot.value as Map)["driverLocation"] != null) {
        double driverCurrentPositionLat = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["latitude"]
                .toString());
        double driverCurrentPositionLng = double.parse(
            (eventSnap.snapshot.value as Map)["driverLocation"]["longitude"]
                .toString());

        driverCurrentPositionLatLng =
            LatLng(driverCurrentPositionLat, driverCurrentPositionLng);
      }

      //user can rate the driver now
      if ((eventSnap.snapshot.value as Map)["driverId"] != null) {
        assignedDriverId =
            (eventSnap.snapshot.value as Map)["driverId"].toString();
      }
    });

    onlineNearByAvailableDriversList =
        GeofireAssistant.activeNearbyAvailableDriversList;
    searchNearestOnlineDrivers();
  }

  searchNearestOnlineDrivers() async {
    //no driver is available/online nearby
    if (onlineNearByAvailableDriversList.length == 0) {
      //we have to delete the ride request
      referenceRideRequest!.remove();
      setState(() {
        polylineSet.clear();
        markersSet.clear();
        circlesSet.clear();
        pLineCoOrdinatesList.clear();
      });
      Fluttertoast.showToast(msg: "");
      Fluttertoast.showToast(
          msg:
              "No Online Nearest Mechanic Available, Search Again after sometime, Restarting App Now...");
      Future.delayed(const Duration(milliseconds: 4000), () {
        SystemNavigator.pop();
      }); //after 4 seconds we will restart the app
      return;
    }

    //nearby active driver driver is available, therefore we will retrieve the info that active driver from the database
    await retrieveOnlineDriversInformation(onlineNearByAvailableDriversList);

    //when the user goes to the SelectNearestActiveDriversScreen then it chooses some mechanic and this page returns that selected mechanic

    //we have to wait for the response from the SelectNearestActiveDriversScreen as this screen returns the chosenDriverId
    var response = await Navigator.push(
        context,
        MaterialPageRoute(
            builder: (c) => SelectNearestActiveDriversScreen(
                referenceRideRequest: referenceRideRequest)));

    //we are writing once() means this query to the database will execute only once
    if (response == "driverChoosed") {
      FirebaseDatabase.instance
          .ref()
          .child("drivers")
          .child(chosenDriverId!)
          .once()
          .then((snap) {
        //means if the chosenDriverId exists inside the parent node i.e. drivers database
        if (snap.snapshot.value != null) {
          //send notification to that specific driver
          sendNotificationToDriverNow(chosenDriverId!);

          //Display waiting for responce from a driver ui
          showWaitingResponseFromDriverUI();

          //Response from the mechanic

          //here we are going to the value of newRideStatus in the drivers database when it changes
          FirebaseDatabase.instance
              .ref()
              .child("drivers")
              .child(chosenDriverId!)
              .child("newRideStatus")
              .onValue
              .listen((eventSnapshot) {
            //1. driver cancel the ride request help
            //newRideStatus becomes 'idle'
            if (eventSnapshot.snapshot.value == "idle") {
              Fluttertoast.showToast(
                  msg:
                      "The Mechanic has cancelled your request. Please choose another Mechanic");
              Future.delayed(const Duration(milliseconds: 3000), () {
                Fluttertoast.showToast(msg: "Please Restart App Now");
                SystemNavigator.pop();
              });
            }

            //2. driver accept the ride request help
            //newRideStatus becomes 'accepted'
            if (eventSnapshot.snapshot.value == "accepted") {
              //design and display ui for displaying assigned driver's information
              showUIForAssignedDriverInfo();
              // readUserRideRequestInformation(driverRideRequestId, context);
              // LatLng userLiveLocation = LatLng(userCurrentPosition!.latitude,
              //     userCurrentPosition!.longitude);
              // LatLng driversLiveLatLng = LatLng(
              //     driverLiveLocation.latitude, driverLiveLocation.longitude);

              // drawPolyLineFromOriginToDestination(
              //     userLiveLocation, driversLiveLatLng);
            }
          });
        } else {
          Fluttertoast.showToast(msg: "This driver do not exist. Try again");
        }
      });
    }
  }

  showUIForAssignedDriverInfo() {
    setState(() {
      searchLocationContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 0;
      assignedDriverInfoContainerHeight = 220;
    });
  }

  showWaitingResponseFromDriverUI() {
    setState(() {
      searchLocationContainerHeight = 0;
      waitingResponseFromDriverContainerHeight = 220;
    });
  }

  sendNotificationToDriverNow(String chosenDriverId) {
    //assign/set rideRequestId to newRideStatus in Drivers parent node for that specific choosen driver
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("newRideStatus")
        .set(referenceRideRequest!.key);

    //automate the push notification

    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(chosenDriverId)
        .child("token")
        .once()
        .then((snap) {
      if (snap.snapshot.value != null) {
        String deviceRegistrationToken = snap.snapshot.value.toString();

        //send notification now. Context of this page is the mainScreen
        AssistantMethods.sendNotificationToDriverNow(deviceRegistrationToken,
            referenceRideRequest!.key.toString(), context);

        Fluttertoast.showToast(msg: "Notification Sent Successfully");
      } else {
        Fluttertoast.showToast(msg: "Please select another Mechanic.");
        return;
      }
    });
  }

  retrieveOnlineDriversInformation(List onlineNearestDriversList) async {
    DatabaseReference ref = FirebaseDatabase.instance
        .ref()
        .child("drivers"); //"drivers" is the parent collection/database

    //using the for loop we are adding all the nearby online drivers to the dList
    for (int i = 0; i < onlineNearByAvailableDriversList.length; i++) {
      await ref
          .child(onlineNearestDriversList[i].driverId.toString())
          .once()
          .then((dataSnapshot) {
        var driverKeyInfo = dataSnapshot.snapshot
            .value; //using this we add the all info present in the drivers database about the active driver to the dlist
        dList.add(driverKeyInfo);
        // print("drivers key information" + dList.toString());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    createActiveNearbyDriverIconMarker();

    return Scaffold(
      key: sKey,
      drawer: userModelCurrentInfo != null
          ? MyDrawer(
              name: userName,
              email: userEmail,
            )
          : const CircularProgressIndicator(), // Replace with an appropriate loading indicator

      body: Stack(
        children: [
          GoogleMap(
            padding: EdgeInsets.only(bottom: bottomPaddingOfMap),
            mapType: MapType.normal,
            myLocationEnabled: true,
            initialCameraPosition: userCurrentPosition != null
                ? CameraPosition(
                    target: LatLng(userCurrentPosition!.latitude,
                        userCurrentPosition!.longitude),
                    zoom: 14, // Adjust the zoom level as needed
                  )
                : CameraPosition(
                    target: LatLng(37.42796133580664,
                        -122.085749655962), // Default fallback position
                    zoom: 14, // Adjust the zoom level as needed
                  ),
            // initialCameraPosition: _kGooglePlex, //i.e. from where our map will start
            polylines: polylineSet,
            markers: markersSet,
            circles: circlesSet,

            onMapCreated: (GoogleMapController controller) {
              _controllerGoogleMap.complete(controller);
              newGoogleMapController = controller;

              //for black theme google map
              blackThemeGoogleMap();

              setState(() {
                bottomPaddingOfMap = 265;
              });
              locateUserPosition();
            },
          ),

          //custom hamburger button for drawer
          Positioned(
            top: 30,
            left: 14,
            child: GestureDetector(
              //GestureDetector is basically our clicky event
              onTap: () {
                sKey.currentState!.openDrawer();
              },
              child: const CircleAvatar(
                backgroundColor: Colors.grey,
                child: Icon(
                  Icons.menu,
                  color: Colors.black54,
                ),
              ),
            ),
          ),

          //ui for searching location
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: AnimatedSize(
              curve: Curves.easeIn,
              duration: const Duration(microseconds: 120),
              child: Container(
                height: searchLocationContainerHeight,
                decoration: const BoxDecoration(
                  color: Colors.black54,
                  borderRadius: BorderRadius.only(
                    topRight: Radius.circular(20),
                    topLeft: Radius.circular(20),
                  ),
                ),
                child: Padding(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                  child: Column(
                    children: [
                      //from location
                      Row(
                        children: [
                          const Icon(
                            Icons.add_location_alt_outlined,
                            color: Colors.grey,
                          ),
                          const SizedBox(
                            width: 12.0,
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "From",
                                style: TextStyle(
                                  color: Colors.grey,
                                  fontSize: 12,
                                ),
                              ),
                              Text(
                                Provider.of<AppInfo>(context)
                                            .userPickUpLocation !=
                                        null
                                    ? (Provider.of<AppInfo>(context)
                                                .userPickUpLocation!
                                                .locationName!)
                                            .substring(0, 25) +
                                        "..."
                                    : "Not getting address",
                                style: const TextStyle(
                                  color: Colors.grey,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),

                      // const SizedBox(
                      //   height: 10,
                      // ),

                      // const Divider(
                      //   height: 1,
                      //   thickness: 1,
                      //   color: Colors.grey,
                      // ),

                      const SizedBox(
                        height: 35,
                      ),

                      // //to destination
                      // //I haven't implemented the code the here if needed see the section
                      // GestureDetector(
                      //   onTap: () {
                      //     //go to search places screen
                      //     Navigator.push(
                      //         context,
                      //         MaterialPageRoute(
                      //             builder: (c) => SearchPlacesScreen()));
                      //   },
                      //   child: Row(
                      //     children: [
                      //       const Icon(
                      //         Icons.add_location_alt_outlined,
                      //         color: Colors.grey,
                      //       ),
                      //       const SizedBox(
                      //         width: 12.0,
                      //       ),
                      //       Column(
                      //         crossAxisAlignment: CrossAxisAlignment.start,
                      //         children: [
                      //           const Text(
                      //             "To",
                      //             style: TextStyle(
                      //               color: Colors.grey,
                      //               fontSize: 12,
                      //             ),
                      //           ),
                      //           Text(
                      //             "where to go",
                      //             style: const TextStyle(
                      //               color: Colors.grey,
                      //               fontSize: 14,
                      //             ),
                      //           ),
                      //         ],
                      //       ),
                      //     ],
                      //   ),
                      // ),

                      // const SizedBox(
                      //   height: 10,
                      // ),

                      const Divider(
                        height: 1,
                        thickness: 1,
                        color: Colors.grey,
                      ),

                      const SizedBox(
                        height: 16,
                      ),

                      ElevatedButton(
                        child: const Text(
                          "Request a Help",
                        ),
                        onPressed: () {
                          saveRideRequestInformation();
                        },
                        style: ElevatedButton.styleFrom(
                            primary: Colors.green,
                            textStyle: const TextStyle(
                              fontSize: 16.0,
                              fontWeight: FontWeight.bold,
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for waiting response from driver
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: waitingResponseFromDriverContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Center(
                  child: AnimatedTextKit(
                    animatedTexts: [
                      FadeAnimatedText(
                        'Waiting for Response\nfrom Mechanic',
                        duration: const Duration(seconds: 6),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 30.0,
                            color: Colors.white,
                            fontWeight: FontWeight.bold),
                      ),
                      ScaleAnimatedText(
                        'Please Wait...',
                        duration: const Duration(seconds: 10),
                        textAlign: TextAlign.center,
                        textStyle: const TextStyle(
                            fontSize: 32.0,
                            color: Colors.white,
                            fontFamily: 'Canterbury'),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          //ui for displaying assigned driver information
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: assignedDriverInfoContainerHeight,
              decoration: const BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.only(
                  topRight: Radius.circular(20),
                  topLeft: Radius.circular(20),
                ),
              ),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 25,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    //status of the mechanic
                    Center(
                      child: Text(
                        driverRideStatus,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.white54,
                        ),
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    //driver name
                    Text(
                      driverName,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white54,
                      ),
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    //call driver button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () async {
                          final Uri url = Uri(
                            scheme: 'tel',
                            path: driverPhone,
                          );

                          if (await canLaunchUrl(url)) {
                            await launchUrl(url);
                          } else {
                            Fluttertoast.showToast(
                                msg: "Invalid Phone No. Can't make a call");
                          }
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.green,
                        ),
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.black54,
                          size: 22,
                        ),
                        label: const Text(
                          "Call Mechanic",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),

                    const Divider(
                      height: 2,
                      thickness: 2,
                      color: Colors.white54,
                    ),

                    const SizedBox(
                      height: 5,
                    ),

                    //rate mechanic button
                    Center(
                      child: ElevatedButton.icon(
                        onPressed: () {
                          Navigator.push(
                              context,
                              MaterialPageRoute(
                                  builder: (c) => RateDriverScreen(
                                        assignedDriverId: assignedDriverId,
                                      )));
                        },
                        style: ElevatedButton.styleFrom(
                          primary: Colors.orangeAccent,
                        ),
                        icon: const Icon(
                          Icons.phone_android,
                          color: Colors.black54,
                          size: 22,
                        ),
                        label: const Text(
                          "Rate Mechanic",
                          style: TextStyle(
                            color: Colors.black54,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  initializeGeofireListener() {
    //i have copied this code from the pub.dev flutter _geofire dependency readme section

    Geofire.initialize("activeDrivers");

    //this 5 represents the distance in kilometers. That means from the user current position within the 5 kilometers if there is a active/online mechanic/driver then those active/online drivers will be displayed on the map.
    Geofire.queryAtLocation(
            userCurrentPosition!.latitude, userCurrentPosition!.longitude, 5)!
        .listen((map) {
      print(map);
      if (map != null) {
        var callBack = map['callBack'];

        //latitude will be retrieved from map['latitude']
        //longitude will be retrieved from map['longitude']

        switch (callBack) {
          //onKeyEntered simply means that whenever any driver becomes active/online then we get active/online driver information and we add that to the list.

          //the current location of the active/online driver is updated in the realtime database of the firebase. That information we will retrieve from the database by using map['latitude'], map['longitude']

          case Geofire.onKeyEntered:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeofireAssistant.activeNearbyAvailableDriversList
                .add(activeNearbyAvailableDriver);
            if (activeNearbyDriverKeysLoaded == true) {
              displayActiveDriversOnUserMap();
            }
            break;

          //whenever any driver goes offline or becomes non-active
          case Geofire.onKeyExited:
            GeofireAssistant.deleteOfflineDriverFromList(map['key']);
            displayActiveDriversOnUserMap();
            break;

          //it will be called whenever the driver moves. Therefore we have to update the driver's location here
          case Geofire.onKeyMoved:
            ActiveNearbyAvailableDrivers activeNearbyAvailableDriver =
                ActiveNearbyAvailableDrivers();
            activeNearbyAvailableDriver.locationLatitude = map['latitude'];
            activeNearbyAvailableDriver.locationLongitude = map['longitude'];
            activeNearbyAvailableDriver.driverId = map['key'];
            GeofireAssistant.updateActiveNearbyAvailableDriverLocation(
                activeNearbyAvailableDriver);
            displayActiveDriversOnUserMap();
            break;

          //using this we will display all the active drivers within particular range to the user on the map of the user's screen.
          case Geofire.onGeoQueryReady:
            activeNearbyDriverKeysLoaded = true;
            displayActiveDriversOnUserMap();
            break;
        }
      }

      setState(() {});
    });
  }

  displayActiveDriversOnUserMap() {
    setState(() {
      markersSet.clear();
      circlesSet.clear();

      Set<Marker> driversMarkerSet = Set<Marker>();

      //we will add markers one by one to all the active nearby drivers
      for (ActiveNearbyAvailableDrivers eachDriver
          in GeofireAssistant.activeNearbyAvailableDriversList) {
        LatLng eachDriverActivePosition =
            LatLng(eachDriver.locationLatitude!, eachDriver.locationLongitude!);

        Marker marker = Marker(
          markerId: MarkerId(eachDriver.driverId!),
          position: eachDriverActivePosition,
          icon: activeNearbyIcon!,
          rotation: 360,
        );

        driversMarkerSet.add(marker);
      }

      setState(() {
        markersSet = driversMarkerSet;
      });
    });
  }

  createActiveNearbyDriverIconMarker() {
    if (activeNearbyIcon == null) {
      ImageConfiguration imageConfiguration =
          createLocalImageConfiguration(context, size: const Size(2, 2));
      BitmapDescriptor.fromAssetImage(imageConfiguration, "images/mech.png")
          .then((value) {
        activeNearbyIcon = value;
      });
    }
  }

  readUserRideRequestInformation(
      String userRideRequestId, BuildContext context) {
    //create reference to the database

    //from the 'All Ride Requests' database we will take only the particular userRideRequestId to which the request has been made
    FirebaseDatabase.instance
        .ref()
        .child("All Ride Request")
        .child(userRideRequestId)
        .once()
        .then((snapData) {
      if (snapData.snapshot.value != null) {
        double originLat = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["latitude"]);

        double originLng = double.parse(
            (snapData.snapshot.value! as Map)["origin"]["longitude"]);

        String originAddress =
            (snapData.snapshot.value! as Map)["originAddress"];

        String userName = (snapData.snapshot.value! as Map)["userName"];

        String userPhone = (snapData.snapshot.value! as Map)["userPhone"];

        String? rideRequestId = snapData.snapshot
            .key; //here we took the value of the rideRequestId from the database.

        //we cant use these variables outside the if{} block therefore to access these variables outside the if condition we have create the class and we will define attributes in that class and then we can access to these varibles anywhere in the program through that class

        //therefore we are assigning all this info to our model class instances
        UserRideRequestInformation userRideRequestDetails =
            UserRideRequestInformation();
        userRideRequestDetails.originLatLng = LatLng(originLat, originLng);
        userRideRequestDetails.originAddress = originAddress;

        userRideRequestDetails.userName = userName;
        userRideRequestDetails.userPhone = userPhone;

        userRideRequestDetails.rideRequestId = rideRequestId;

        print("User ride request information : ");
        print(userRideRequestDetails.userName);
        print(userRideRequestDetails.userPhone);
        print(userRideRequestDetails.originAddress);

        showDialog(
          context: context,
          builder: (BuildContext context) => NewTripScreen(
            userRideRequestDetails: userRideRequestDetails,
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "This Ride Request Id do not exist");
      }
    });
  }
}
