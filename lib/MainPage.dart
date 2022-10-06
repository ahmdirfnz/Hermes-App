import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:avatar_view/avatar_view.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bluetooth_raspberry/models/communication.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:headset_connection_event/headset_event.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

import './SelectBondedDevicePage.dart';
import './ChatPage.dart';
// import 'package:instagram_share/instagram_share.dart';
import 'package:social_share/social_share.dart';
import 'package:path_provider/path_provider.dart';
//import './ChatPage2.dart';


class MainPage extends StatefulWidget {

  @override
  _MainPage createState() => new _MainPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _MainPage extends State<MainPage> {
  BluetoothState _bluetoothState = BluetoothState.UNKNOWN;

  static final clientID = 0;
  BluetoothConnection connection;

  List<_Message> messages = List<_Message>();
  String _messageBuffer = '';

  final TextEditingController textEditingController =
  new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  String bluetoothName = '';

  // BluetoothDevice namebluetooth = SelectBondedDevicePage(checkAvailability: false,)

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  _Message message;

  String _address = "...";
  String _name = "...";

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  final FlutterTts tts = FlutterTts();
  final TextEditingController _textEditingController = TextEditingController(text: 'Bottle');

  double _currentLEDValue = 10;
  double _currentSoundValue = 0.5;
  // BluetoothState _bluetoothState = BluetoothState.UNKNOWN;
  // TextEditingController _textEditingController = TextEditingController();
  //
  // late StreamSubscription<double> _subscription;

  double currentVolume = 0.5;

  final _headsetPlugin = HeadsetEvent();
  HeadsetState _headsetState;

  // String _address = "...";
  // String _name = "...";

  // Timer? _discoverableTimeoutTimer;
  // int _discoverableTimeoutSecondsLeft = 0;

  // BackgroundCollectingTask? _collectingTask;

  final bool _autoAcceptPairingRequests = false;

  Future speak(String text) async {
    await tts.setLanguage('en-gb');
    await tts.setPitch(2);
    // await tts.setSpeechRate(0.4);
    await tts.speak(text);
    // print(await tts.getLanguages);
  }

  @override
  void initState() {
    super.initState();
    initialization();

    // BluetoothConnection.toAddress(widget.server.address).then((_connection) {
    //   print('Connected to the device');
    //   connection = _connection;
    //   setState(() {
    //     isConnecting = false;
    //     isDisconnecting = false;
    //   });
    //
    //   connection.input.listen(_onDataReceived).onDone(() {
    //     // Example: Detect which side closed the connection
    //     // There should be `isDisconnecting` flag to show are we are (locally)
    //     // in middle of disconnecting process, should be set before calling
    //     // `dispose`, `finish` or `close`, which all causes to disconnect.
    //     // If we except the disconnection, `onDone` should be fired as result.
    //     // If we didn't except this (no flag set), it means closing by remote.
    //     if (isDisconnecting) {
    //       print('Disconnecting locally!');
    //     } else {
    //       print('Disconnected remotely!');
    //     }
    //     if (this.mounted) {
    //       setState(() {});
    //     }
    //   });
    // }).catchError((error) {
    //   print('Cannot connect, exception occured');
    //   print(error);
    // });

    PerfectVolumeControl.hideUI = false; //set if system UI is hided or not on volume up/down
    Future.delayed(Duration.zero,() async {
      currentVolume = await PerfectVolumeControl.getVolume();
      setState(() {
        //refresh UI
      });
    });

    PerfectVolumeControl.stream.listen((volume) {
      setState(() {
        currentVolume = volume;
      });
    });

    _headsetPlugin.getCurrentState.then((_val) {
      setState(() {
        _headsetState = _val;
      });
    });

    _headsetPlugin.setListener((_val) {
      setState(() {
        _headsetState = _val;
      });
    });

    // Get current state
    FlutterBluetoothSerial.instance.state.then((state) {
      setState(() {
        _bluetoothState = state;
      });
    });

    Future.doWhile(() async {
      // Wait if adapter not enabled
      if (await FlutterBluetoothSerial.instance.isEnabled) {
        return false;
      }
      await Future.delayed(Duration(milliseconds: 0xDD));
      return true;
    }).then((_) {
      // Update the address field
      FlutterBluetoothSerial.instance.address.then((address) {
        setState(() {
          _address = address;
        });
      });
    });

    FlutterBluetoothSerial.instance.name.then((name) {
      setState(() {
        _name = name;
      });
    });

    // Listen for futher state changes
    FlutterBluetoothSerial.instance
        .onStateChanged()
        .listen((BluetoothState state) {
      setState(() {
        _bluetoothState = state;
      });
    });
  }

  void initialization() async {
    // This is where you can initialize the resources needed by your app while
    // the splash screen is displayed.  Remove the following example because
    // delaying the user experience is a bad design practice!
    // ignore_for_file: avoid_print
    // print('ready in 3...');
    // await Future.delayed(const Duration(seconds: 1));
    // print('ready in 2...');
    // await Future.delayed(const Duration(seconds: 1));
    // print('ready in 1...');
    // await Future.delayed(const Duration(seconds: 1));
    // print('go!');
    FlutterNativeSplash.remove();
  }

  // This code is just a example if you need to change page and you need to communicate to the raspberry again
  void init() async {
    Communication com = Communication();
    await com.connectBl(_address);
    com.sendMessage("Hello");
    setState(() {});
  }

  @override
  void dispose() {

    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    FlutterBluetoothSerial.instance.setPairingRequestHandler(null);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    BluetoothDevice nameBluetooth;
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
        title:  Text('HERMES', style: GoogleFonts.fredokaOne(textStyle: const TextStyle(fontWeight: FontWeight.bold)),),
        centerTitle: true,
        actions: [
          IconButton(
              onPressed: () async {
                // Directory tempDir = await getTemporaryDirectory();
                // String tempPath = tempDir.path;
                // File file = File(tempDir.path+'/newlogo3.png');
                // final byteData = await rootBundle.load('assets/images/newlogo3.png');
                // await file.writeAsBytes(byteData.buffer.asUint8List(byteData.offsetInBytes, byteData.lengthInBytes));
                // await SocialShare.shareInstagramStory(file.path);
                // Navigator.of(context).pop();
                SocialShare.shareTwitter(
                  "Hermes App",
                  hashtags: ["SHELLSELAMATSAMPAI", "Hermes", "UTeM", "FTKEE"],
                  url: "https://play.google.com/store/apps/details?id=com.hermes.hermes_app",
                  trailingText: "\nHermes App",
                  ).then((data) {
                  print(data);
                });
              },
              icon: const Icon(Icons.share,))
        ],
        // iconTheme: IconThemeData(color: Colors.black),
      ),
      drawer:  Drawer(
        child: ListView(
          // Important: Remove any padding from the ListView.
          padding: EdgeInsets.zero,
          children: [
            const UserAccountsDrawerHeader(
              decoration: BoxDecoration(
                color: Colors.deepPurpleAccent
              ),
              accountName: Text('Ahmad Irfan'),
              accountEmail: Text('irfanz6985@gmail.com'),
              currentAccountPicture: AvatarView(
                radius: 60,
                borderColor: Colors.blueGrey,
                isOnlyText: false,
                text: Text('C', style: TextStyle(color: Colors.white, fontSize: 50),),
                avatarType: AvatarType.CIRCLE,
                backgroundColor: Colors.deepPurpleAccent,
                imagePath: 'assets/images/account.png',
                placeHolder: Icon(Icons.person, size: 50,),
                errorWidget: Icon(Icons.error, size: 50,),
              ),
            ),
            ListTile(
              leading: const Icon(
                Icons.account_circle,
              ),
              title: const Text('Profile'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.notifications,
              ),
              title: const Text('Notifications'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.settings,
              ),
              title: const Text('Settings'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: ListView(
        children: [
          SizedBox(
            height: 20.0,
          ),
          SwitchListTile(
              title: const Text('Turn on bluetooth'),
              activeColor: Colors.deepPurpleAccent,
              value: _bluetoothState.isEnabled,
              onChanged: (bool value) {
                // Do the request and update with the true value then
                future() async {
                  // async lambda seems to not working
                  if (value) {
                    await FlutterBluetoothSerial.instance.requestEnable();
                  } else {
                    await FlutterBluetoothSerial.instance.requestDisable();
                  }
                }

                future().then((_) {
                  setState(() {});
                });
              }),
          ListTile(
            title: const Text('Bluetooth setting'),
            subtitle: Text(_bluetoothState.toString()),
            trailing: ElevatedButton(
              style: ElevatedButton.styleFrom(
                primary: Colors.deepPurpleAccent
              ),
                child: const Text('Settings'),
                onPressed: () {
                  FlutterBluetoothSerial.instance.openSettings();
                }
            ),
          ),
          Divider(),
          SizedBox(
            height: 20.0,
          ),
          Center(
            child: Container(
              decoration: BoxDecoration(
                boxShadow: [
                  BoxShadow(
                    color: _headsetState == HeadsetState.CONNECT ? Colors.blueAccent : Colors.transparent,
                    blurRadius: _headsetState == HeadsetState.CONNECT ? 13.0 : 0.0,
                  )
                ]
              ),
              child: Card(
                color: Colors.white,
                elevation: 10,
                shape: const RoundedRectangleBorder(
                  side: BorderSide(
                    color: Colors.blue,
                    width: 2.4,
                  ),
                  borderRadius: BorderRadius.all(Radius.circular(15)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: SizedBox(
                    width: 340,
                    height: 215,
                    child: Column(
                      children: [
                        SizedBox(
                          height: 3.8,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Hermes Devices',
                              style: GoogleFonts.fredokaOne(textStyle: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children:  [
                            Image.asset(_headsetState == HeadsetState.CONNECT ? 'assets/images/headsetBlue.png' : 'assets/images/headsetGrey.png', height: 100, width: 70,),
                            IconButton(onPressed: () async {

                              final BluetoothDevice selectedDevice =
                              await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) {
                                    return SelectBondedDevicePage(checkAvailability: false);
                                  },
                                ),
                              );

                              // bluetoothName = selectedDevice.name;

                              // print(selectedDevice.name);

                              if (selectedDevice != null) {
                                print('Connect -> selected ' + selectedDevice.address);
                                _startChat(context, selectedDevice);
                              } else {
                                print('Connect -> no device selected');
                              }

                            },
                                icon: Image.asset('assets/images/wifiPhoneGrey.png'),
                              iconSize: 65,
                            ),
                          ],
                        ),
                        const SizedBox(
                          height: 5,
                        ),
                        Divider(
                          indent: 16,
                          endIndent: 16,
                          thickness: 0.9,
                          color: _headsetState == HeadsetState.CONNECT ? Colors.black : Colors.grey,
                        ),
                        const SizedBox(
                          height: 10,
                        ),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          children:  [
                            const SizedBox(
                              width: 16,
                            ),
                            _headsetState == HeadsetState.CONNECT ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:  const [
                                Text('Headset Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.blueAccent),
                                ),
                                Text(
                                  'Connected',
                                  style: TextStyle(fontSize: 15, color: Colors.blueAccent, fontWeight: FontWeight.bold),
                                ),
                              ],
                            ) : Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children:  const [
                                Text('Headset Device', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey),
                                ),
                                Text(
                                  'Not Connected',
                                  style: TextStyle(fontSize: 15, color: Colors.grey),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
          // Container(
          //   margin: const EdgeInsets.only(top:40),
          //   padding: const EdgeInsets.all(20),
          //   child: Column(
          //     children: [
          //
          //       Card(
          //         elevation: 1,
          //         shape: const RoundedRectangleBorder(
          //           side: BorderSide(
          //             color: Colors.black,
          //           ),
          //           borderRadius: BorderRadius.all(Radius.circular(12)),
          //         ),
          //         child: Padding(
          //           padding: const EdgeInsets.all(8.0),
          //           child: SizedBox(
          //             width: 340,
          //             height: 210,
          //             child: Column(
          //               children: [
          //                 Row(
          //                   mainAxisAlignment: MainAxisAlignment.center,
          //                   children: const [
          //                     Text(
          //                       'Hermes Devices',
          //                       style: TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
          //                     ),
          //                   ],
          //                 ),
          //                 const SizedBox(
          //                   height: 50,
          //                 ),
          //                 Text(
          //                         'Message Here')
          //               ],
          //             ),
          //           ),
          //         ),
          //       ),
          //
          //       Text("Current Volume: ${(_currentSoundValue * 100).toInt()}"),
          //
          //       const Divider(),
          //
          //       Slider(
          //         value: _currentSoundValue,
          //         label: '${(_currentSoundValue * 100).toInt()}',
          //         onChanged: (newvol){
          //           _currentSoundValue = newvol;
          //           PerfectVolumeControl.setVolume(newvol);
          //           //set new volume
          //           setState(() {
          //             // _currentSoundValue = newvol;
          //           });
          //         },
          //         min: 0, //
          //         max:  1,
          //         divisions: 10,
          //       ),
          //
          //       const Divider(
          //         height: 50.0,
          //         color: Colors.white,
          //       ),
          //
          //       const Text("LED"),
          //       const Divider(),
          //       Slider(
          //         min: 0.0,
          //         max: 100.0,
          //         value: _currentLEDValue,
          //         divisions: 5,
          //         label: '${_currentLEDValue.round()}',
          //         onChanged: (value) {
          //           setState(() {
          //             _currentLEDValue = value;
          //           });
          //         },
          //       ),
          //       // TextFormField(
          //       //   textAlign: TextAlign.center,
          //       //   controller: _textEditingController,
          //       // ),
          //       // ElevatedButton(
          //       //     onPressed: () {
          //       //       speak(_textEditingController.text);
          //       //     },
          //       //     child: const Text('Speak')),
          //     ],
          //   ),
          // ),
        ],
      ),
    );
  }

  void _onDataReceived(Uint8List data) {
    // Allocate buffer for parsed data
    int backspacesCounter = 0;
    data.forEach((byte) {
      if (byte == 8 || byte == 127) {
        backspacesCounter++;
      }
    });
    Uint8List buffer = Uint8List(data.length - backspacesCounter);
    int bufferIndex = buffer.length;

    // Apply backspace control character
    backspacesCounter = 0;
    for (int i = data.length - 1; i >= 0; i--) {
      if (data[i] == 8 || data[i] == 127) {
        backspacesCounter++;
      } else {
        if (backspacesCounter > 0) {
          backspacesCounter--;
        } else {
          buffer[--bufferIndex] = data[i];
        }
      }
    }

    // Create message if there is new line character
    String dataString = String.fromCharCodes(buffer);
    int index = buffer.indexOf(13);
    if (~index != 0) {
      setState(() {
        messages.add(
          _Message(
            1,
            backspacesCounter > 0
                ? _messageBuffer.substring(
                0, _messageBuffer.length - backspacesCounter)
                : _messageBuffer + dataString.substring(0, index),
          ),
        );
        _messageBuffer = dataString.substring(index);
      });
    } else {
      _messageBuffer = (backspacesCounter > 0
          ? _messageBuffer.substring(
          0, _messageBuffer.length - backspacesCounter)
          : _messageBuffer + dataString);
    }
  }

  void _sendMessage(String text) async {
    text = text.trim();
    textEditingController.clear();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text + "\r\n"));
        await connection.output.allSent;

        setState(() {
          messages.add(_Message(clientID, text));
        });

        Future.delayed(Duration(milliseconds: 333)).then((_) {
          listScrollController.animateTo(
              listScrollController.position.maxScrollExtent,
              duration: Duration(milliseconds: 333),
              curve: Curves.easeOut);
        });
      } catch (e) {
        // Ignore error, but notify state
        setState(() {});
      }
    }
  }

  void _startChat(BuildContext context, BluetoothDevice server) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) {
          return ChatPage(server: server);
        },
      ),
    );
  }
}
