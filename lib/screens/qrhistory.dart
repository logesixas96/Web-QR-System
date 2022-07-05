import 'dart:convert';
import 'package:universal_html/html.dart' as html;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:web_qr_system/screens/attendancelist.dart';

class QRHistory extends StatefulWidget {
  const QRHistory({Key? key}) : super(key: key);

  @override
  State<QRHistory> createState() => _QRHistoryState();
}

class _QRHistoryState extends State<QRHistory> {
  FirebaseFirestore firebaseFirestore = FirebaseFirestore.instance;
  User? user = FirebaseAuth.instance.currentUser;
  final newTextController = TextEditingController();
  GlobalKey globalKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 1,
        title: const Text("My Events"),
        centerTitle: true,
      ),
      body: Center(
        child: SingleChildScrollView(
          child: Container(
            height: MediaQuery.of(context).size.height,
            width: MediaQuery.of(context).size.width,
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage("assets/bg.png"),
                fit: BoxFit.fill,
              ),
            ),
            child: Padding(
              padding: EdgeInsets.symmetric(
                  horizontal: MediaQuery.of(context).size.width / 10,
                  vertical: MediaQuery.of(context).size.height / 10),
              child: StreamBuilder<QuerySnapshot>(
                  stream: firebaseFirestore
                      .collection("users")
                      .doc(user!.uid)
                      .collection("events")
                      .snapshots(),
                  builder: (context, AsyncSnapshot snapshot) {
                    if (!snapshot.hasData) {
                      return const Center(
                        child: CircularProgressIndicator(),
                      );
                    }
                    return ListView.builder(
                        physics: const BouncingScrollPhysics(),
                        itemCount: snapshot.data.docs.length,
                        itemBuilder: (context, index) {
                          DocumentSnapshot event = snapshot.data.docs[index];
                          return Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: MediaQuery.of(context).size.width / 25,
                              vertical: 10,
                            ),
                            child: Container(
                              decoration: BoxDecoration(
                                  boxShadow: [
                                    BoxShadow(
                                        color: Colors.red.shade900.withOpacity(.5),
                                        blurRadius: 10.0,
                                        spreadRadius: 0.0,
                                        offset: const Offset(5.0, 5.0,)
                                    ),
                                  ]
                              ),
                              child: Card(
                                child: Column(
                                  children: <Widget>[
                                    ListTile(
                                        leading: Icon(Icons.event,
                                            size: 40,
                                            color: index.isEven
                                                ? Colors.red.shade900
                                                : Colors.red.shade300),
                                        title: Text(event['eventName'] + ", " + event['eventAddress']),
                                        subtitle: Text("QR Created @  ${event['timeStamp']}"), //added interpolation
                                        trailing: Icon(
                                            Icons.double_arrow_outlined,
                                            color: index.isEven
                                                ? Colors.red.shade900
                                                : Colors.red.shade300),
                                        onTap: () {
                                          newTextController.text =
                                              event['eventName'];
                                          Navigator.push(
                                              context,
                                              MaterialPageRoute(
                                                  builder: (context) =>
                                                      AttendanceList(
                                                          newTextController.text
                                                      )
                                              )
                                          );
                                        }
                                    ),
                                    //getLength(),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.end,
                                      children: [
                                        TextButton.icon(
                                            onPressed: () {
                                              showDialog(
                                                context: context,
                                                builder: (context) => Center(
                                                  child: SingleChildScrollView(
                                                    child: AlertDialog(
                                                      content: SizedBox(
                                                        width: 300,
                                                        child: Column(
                                                          mainAxisAlignment: MainAxisAlignment.center,
                                                          children: <Widget>[
                                                            Align(
                                                              alignment: Alignment.topRight,
                                                              child: IconButton(
                                                                  onPressed: () {
                                                                    Navigator.pop(context);
                                                                  },
                                                                  icon: const Icon(
                                                                      Icons.close,
                                                                      color: Colors.grey)),
                                                            ),
                                                            RepaintBoundary(
                                                              key: globalKey,
                                                              child: QrImage(
                                                                version: QrVersions.auto,
                                                                data: event['qrData'],
                                                                size: 200,
                                                                backgroundColor:
                                                                    Colors.white,
                                                              ),
                                                            ),
                                                            TextButton.icon(
                                                                onPressed: () {
                                                                  downloadQR();
                                                                },
                                                                icon: const Icon(Icons.download),
                                                                label: const Text("Download QR"),
                                                            )
                                                          ],
                                                        ),
                                                      ),
                                                    ),
                                                  ),
                                                ),
                                              );
                                            },
                                            icon: const Icon(Icons.qr_code_2,
                                                color: Colors.grey),
                                            label: const Text("Show QR Code",
                                                style: TextStyle(
                                                    color: Colors.grey))),
                                        TextButton.icon(onPressed: () {
                                          showDialog(context: context, builder: (context) => Center(
                                            child: SingleChildScrollView(
                                              child: AlertDialog(
                                                title: const Text("Confirm Delete?"),
                                                content: Text("You are deleting ${event['eventName']} and  all of the information related to the event!"), //added proper interpolation
                                                actions: <Widget>[
                                                  TextButton(
                                                      onPressed: () {
                                                        Navigator.of(context).pop();
                                                      },
                                                      child: const Text("Cancel")
                                                  ),
                                                  TextButton(
                                                      onPressed: () async {
                                                        var collection = firebaseFirestore
                                                            .collection("users")
                                                            .doc(user!.uid)
                                                            .collection("events")
                                                            .doc(event['eventName'])
                                                            .collection("attendance");
                                                                    var snapshots =
                                                                        await collection.get();
                                                                    for (var doc
                                                                        in snapshots.docs) {
                                                                      await doc.reference.delete();
                                                                    }
                                                                    firebaseFirestore
                                                                        .collection("users")
                                                                        .doc(user!.uid)
                                                                        .collection("events")
                                                                        .doc(event['eventName'])
                                                                        .delete();
                                                                    Fluttertoast.showToast(
                                                                        msg:
                                                                            "Event successfully deleted!",
                                                                        timeInSecForIosWeb: 5);
                                                                    if (!mounted) return;
                                                                    Navigator.of(context).pop();
                                                                  },
                                                                  child: const Text("Confirm"))
                                                            ],
                                                          ),
                                                        ),
                                                      ));
                                            },
                                            icon: const Icon(Icons.delete),
                                            label: const Text("Delete Event")),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        });
                  }),
            ),
          ),
        ),
      ),
    );
  }
  Future<void> myAsyncMethod(BuildContext context, VoidCallback onSuccess) async {
    await Future.delayed(const Duration(seconds: 2));
    onSuccess.call();
  }

  void downloadQR() async {
    RenderRepaintBoundary? boundary =
        globalKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    ui.Image? image = await boundary?.toImage(pixelRatio: 3.0);
    ByteData? byteData =
        await image?.toByteData(format: ui.ImageByteFormat.png);
    Uint8List? pngBytes = byteData?.buffer.asUint8List();

    final base64data = base64Encode(pngBytes!);
    final html.AnchorElement a = html.AnchorElement(href: 'data:image/png;base64,$base64data');
    a.download = 'QR.png';
    a.click();
    a.remove();
  }
}
