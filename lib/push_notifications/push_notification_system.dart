// import 'dart:js';

import 'package:assets_audio_player/assets_audio_player.dart';
import 'package:drivers_app/global/global.dart';
import 'package:drivers_app/models/user_ride_request_information.dart';
import 'package:drivers_app/push_notifications/notification_dialog_box.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

/*Access the device registration token
On initial startup of your app, the FCM SDK generates a registration token for the client app instance. If you want to target single devices or create device groups, you'll need to access this token by extending FirebaseMessagingService and overriding onNewToken.

This section describes how to retrieve the token and how to monitor changes to the token. Because the token could be rotated after initial startup, you are strongly recommended to retrieve the latest updated registration token.

**If different drivers use the same by creating the diffrent accounts on the app the all those drivers will get the same registration token**

The registration token may change when:

1. The app is restored on a new device
2. The user uninstalls/reinstall the app
3. The user clears app data. */

/*Topics#
Topics are a mechanism which allow a device to subscribe and unsubscribe from named PubSub channels, all managed via FCM. Rather than sending a message to a specific device by FCM token, you can instead send a message to a topic and any devices subscribed to that topic will receive the message.

Topics allow you to simplify FCM server integration as you do not need to keep a store of device tokens. There are, however, some things to keep in mind about topics:

Messages sent to topics should not contain sensitive or private information. Do not create a topic for a specific user to subscribe to.
Topic messaging supports unlimited subscriptions for each topic.
One app instance can be subscribed to no more than 2000 topics.
The frequency of new subscriptions is rate-limited per project. If you send too many subscription requests in a short period of time, FCM servers will respond with a 429 RESOURCE_EXHAUSTED ("quota exceeded") response. Retry with an exponential backoff.
A server integration can send a single message to multiple topics at once. This, however, is limited to 5 topics.
To learn more about how to send messages to devices subscribed to topics, view the Send messages to topics documentation.

Subscribing to topics#
To subscribe a device, call the subscribeToTopic method with the topic name:

// subscribe to topic on each app start-up
await FirebaseMessaging.instance.subscribeToTopic('weather');
Unsubscribing from topics#
To unsubscribe from a topic, call the unsubscribeFromTopic method with the topic name:

await FirebaseMessaging.instance.unsubscribeFromTopic('weather'); */

/*Authorize HTTP requests
A message request consists of two parts: the HTTP header and the HTTP body. The HTTP header must contain the following headers:

Authorization: key=YOUR_SERVER_KEY
Make sure this is the server key, whose value is available in the Cloud Messaging tab of the Firebase console Settings pane. Android, Apple platform, and browser keys are rejected by FCM.
Content-Type: application/json for JSON; application/x-www-form-urlencoded;charset=UTF-8 for plain text.
If Content-Type is omitted, the format is assumed to be plain text. */

class PushNotificationSystem {
  FirebaseMessaging messaging = FirebaseMessaging.instance;

  Future initializeCloudMassaging(BuildContext context) async {
    //1. Terminated :- when the app is completely closed and we directly open the app from the push notification
    //.instance means that the app is not open and we are opening tha app from the pushed message
    //thus remoteMessage contains the information s=about the use rwho has sent the request
    FirebaseMessaging.instance
        .getInitialMessage()
        .then((RemoteMessage? remoteMessage) {
      if (remoteMessage != null) {
        print("This is Ride Request Id");
        print(remoteMessage.data["rideRequestId"]);
        //display the ride request/ user information who has requested the help
        readUserRideRequestInformation(
            remoteMessage!.data["rideRequestId"], context);
      }
    });

    //2. Foreground :- When the application is open, in view & in use and we recieve the notification
    //.onMessage means that the app already open
    FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
      //display the ride request/ user information who has requested the help
      readUserRideRequestInformation(
          remoteMessage!.data["rideRequestId"], context);
    });

    //3. Background :- When the application is open, however in the background (minimised) and we directly open the app from the push notification
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
      //display the ride request/ user information who has requested the help
      readUserRideRequestInformation(
          remoteMessage!.data["rideRequestId"], context);
    });
  }

  //context means from where we are calling the method. In this case context is coming directly from the home_tab. So that this method will know that it is called directly from the home_tab
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
        //for the notification sound when message comes
        audioPlayer.open(Audio("music/music_notification.mp3"));
        audioPlayer.play();

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
          builder: (BuildContext context) => NotificationDialogBox(
            userRideRequestDetails: userRideRequestDetails,
          ),
        );
      } else {
        Fluttertoast.showToast(msg: "This Ride Request Id do not exist");
      }
    });
  }

  Future generateAndGetToken() async {
    //using this we get the token, newly generated token
    String? registrationToken = await messaging.getToken();
    print("FCM registration token");
    print(registrationToken);

    //using this we saved this token for that specific driver
    FirebaseDatabase.instance
        .ref()
        .child("drivers")
        .child(currentFirebaseUser!.uid)
        .child("token")
        .set(registrationToken);

    messaging.subscribeToTopic("allDrivers");
    messaging.subscribeToTopic("allUsers");
  }
}

// class PushNotificationSystem {
//   FirebaseMessaging messaging = FirebaseMessaging.instance;

//   Future initializeCloudMessaging() async {
//     //1.Terminated
//     //When the app is completely closed and opened directly from the push notification
//     FirebaseMessaging.instance
//         .getInitialMessage()
//         .then((RemoteMessage? remoteMessage) {
//       //remoteMessage brings the service request from which we can get user info and his location
//       if (remoteMessage != null) {
//         print("This is remote message : ");
//         print(remoteMessage?.data["rideRequestId"]);
//         //display the request of user and user information who request for service(repair the car)
//       }
//     });

//     //2.Forground
//     //When the app is opend & it receives a push notification
//     //onMessage means the app is open and we can see notications it will perform that functionality
//     FirebaseMessaging.onMessage.listen((RemoteMessage? remoteMessage) {
//       print("This is remote message : ");
//       print(remoteMessage?.data["rideRequestId"]);
//       //display the request and user information
//     });

//     //3.Background
//     //When the app is in the background and opened directly from the push notifications.
//     //onMessageOpenedApp performs the functionality which is When the app is in the background and opened directly from the push notifications.

//     FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage? remoteMessage) {
//       //display the request and user information
//     });
//   }

//   //When the user sent a request to mechanic to come for repairing a car.Then we will communicate and recognize that specific mechanic
//   //This can be done with the help of Token that is registered  token each mechanic has it's own token which will stored in realtime database
//   //with the help of these token we can communicate(user - mechanic)

//   //Method which is responsible for generating tokens
//   Future generateAndGetToken() async {
//     String? registerationToken = await messaging
//         .getToken(); //generate and get the token and assign to the registrationToken varible.
//     //once we get the token then have to stored in the database for that each mechanic who is currently online.
//     //When any mechanic restored the app or reinstalled the app or uninstalled the app or clear up the phone data,then mechanic again open up the app and log in then it will generate new token(updated token).

//     // print("FCM registration token : ");
//     // print(registerationToken);

//     FirebaseDatabase.instance
//         .ref()
//         .child("drivers")
//         .child(currentFirebaseUser!.uid)
//         .child("token")
//         .set(registerationToken);

//     //for send and receive notications
//     messaging.subscribeToTopic("allDrivers");
//     messaging.subscribeToTopic("allUsers");
//   }
// }
