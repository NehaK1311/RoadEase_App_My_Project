import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:geolocator/geolocator.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';
import 'package:users_app/models/driver_data.dart';
import 'package:users_app/models/user_model.dart';

final FirebaseAuth fAuth = FirebaseAuth.instance;
//if we write as _firebaseAuth then this '_' (underscore) make this firebaseAuth private

User? currentFirebaseUser;

UserModel? userModelCurrentInfo;

List dList = []; //online-active drivers Information List

String? chosenDriverId = ""; //the driver which the user have chosen
String cloudMessagingServerToken =
    "key=AAAAUiYkeIs:APA91bGUlJ2ShaEMJEwrnOO0Cyz479DmWKpfCD3U6aZ3EBH8YJAevPU5pq9CDyZMLbP0g3nwMGCYPK75uIRiUH3kPKpib0Ky0a5cl9x7IUCcpztwvnS8caCWZOsmnsJgp3QyKRWGPUXd";

String driverName = "";
String driverPhone = "";
String driverRideRequestId = "";

//for updating the live location of the driver in the map
StreamSubscription<Position>? streamSubscriptionPosition;
StreamSubscription<Position>? streamSubscriptionDriverLivePosition;
Position? driverCurrentPosition;
DriverData onlineDriverData = DriverData();

LatLng driverCurrentPositionLatLng = LatLng(0, 0);
String assignedDriverId = "";

double countRatingStars = 0.0;
String titleStarsRating = "";
