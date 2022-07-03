import 'package:flutter/material.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:web_qr_system/model/qrgenmodel.dart';
import '../model/usermodel.dart';

class QRGenerate extends StatefulWidget {
  const QRGenerate({Key? key}) : super(key: key);

  @override
  State<QRGenerate> createState() => _QRGenerateState();
}

class _QRGenerateState extends State<QRGenerate> {

  final _formKey = GlobalKey<FormState>();
  String qrData = "";
  String timeStamp = "";
  final eventNameEditingController = new TextEditingController();
  final eventAddressEditingController = new TextEditingController();
  User? user = FirebaseAuth.instance.currentUser;
  UserModel loggedInUser = UserModel();

  @override
  void initState(){
    super.initState();
    FirebaseFirestore.instance
        .collection("users")
        .doc(user!.uid)
        .get()
        .then((value) {
      this.loggedInUser = UserModel.fromMap(value.data());
      setState(() {});
    });
  }

  @override
  Widget build(BuildContext context) {

    final eventName = TextFormField(
      autofocus: false,
      controller: eventNameEditingController,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,

      onSaved: (value) {
        eventNameEditingController.text = value!;
      },
      textInputAction: TextInputAction.next,
      validator: (value) {
        if (value!.isEmpty) {
          return ("Please enter an event name!");
        }
      },
      decoration: InputDecoration(
          prefixIcon: Icon(Icons.event),
          contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
          hintText: "Event Name",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(10),
          ),
      ),
    );

    final eventAddress = TextFormField(
      autofocus: false,
      controller: eventAddressEditingController,
      keyboardType: TextInputType.text,
      textCapitalization: TextCapitalization.words,

      onSaved: (value) {
        eventAddressEditingController.text = value!;
      },
      textInputAction: TextInputAction.done,
      validator: (value) {
        if (value!.isEmpty) {
          return ("Please enter the location of your event!");
        }
      },
      decoration: InputDecoration(
        prefixIcon: Icon(Icons.location_pin),
        contentPadding: EdgeInsets.fromLTRB(20, 15, 20, 15),
        hintText: "Event Location Name",
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    );

    final generateQRButton = Material(
      elevation: 5,
      borderRadius: BorderRadius.circular(30),
      color: Colors.redAccent,
      child: MaterialButton(
        padding: EdgeInsets.fromLTRB(20, 15, 20, 15),
        minWidth: MediaQuery.of(context).size.width,
        onPressed: () {
          generateQR(eventNameEditingController.text, eventAddressEditingController.text);
        },
        child: Text("Generate QR Code",
          textAlign: TextAlign.center,
          style: TextStyle(
              fontSize: 20, color: Colors.white, fontWeight: FontWeight.bold),
        ),
      ),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text('QR Code Generator'),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            width: MediaQuery.of(context).size.width,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Form(
              key: _formKey,
              child: Padding(
                padding: EdgeInsets.symmetric(
                    horizontal: MediaQuery.of(context).size.width/10,
                    vertical: MediaQuery.of(context).size.height/10),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(height: 40),
                    QrImage(
                        version: QrVersions.auto,
                        data: qrData,
                        size: 200,
                        backgroundColor: Colors.white,
                    ),
                    SizedBox(height: 80),
                    Container(width: 800, child: eventName),
                    SizedBox(height: 20),
                    Container(width: 800, child: eventAddress),
                    SizedBox(height: 40),
                    Container(width: 800, child: generateQRButton),
                    SizedBox(height: 40),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  void generateQR(String eventName, String eventAddress) {
    if (_formKey.currentState!.validate()) {
      setState(() {
        qrData = loggedInUser.uid.toString()
            + ":" + eventNameEditingController.text
            + ":" + eventAddressEditingController.text;
        String liveTimeStamp = DateFormat("dd MMMM yyyy  |  hh:mm a")
            .format(DateTime.now());
        timeStamp = liveTimeStamp;
        postDetailsToFirestore();
      });
    }
  }

  postDetailsToFirestore() async {
    //calling firestore
    //calling user model
    //sending the values

    FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
    EventCreateModel eventCreateModel = EventCreateModel();

    //writing all the values
    eventCreateModel.eventName = eventNameEditingController.text;
    eventCreateModel.eventAddress = eventAddressEditingController.text;
    eventCreateModel.timeStamp = timeStamp;
    eventCreateModel.qrData = qrData;

    final eventsRef = firebaseFirestore
        .collection("users")
        .doc(user!.uid)
        .collection("events")
        .doc(eventNameEditingController.text);

    eventsRef.get()
        .then((docSnapshot) async => {
          if (docSnapshot.exists) {
            Fluttertoast.showToast(
                msg: "Error! You have already created this event!", timeInSecForIosWeb: 5)
          }
          else {
            await eventsRef
                .set(eventCreateModel.toMap()),
            Fluttertoast.showToast(
                msg: "QR successfully generated!", timeInSecForIosWeb: 5)
          }
        });
  }
}
