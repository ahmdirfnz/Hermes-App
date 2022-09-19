import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_bluetooth_serial/flutter_bluetooth_serial.dart';
import 'package:flutter_tts/flutter_tts.dart';
import 'package:perfect_volume_control/perfect_volume_control.dart';

class ChatPage extends StatefulWidget {
  final BluetoothDevice server;

  const ChatPage({this.server});

  @override
  _ChatPage createState() => new _ChatPage();
}

class _Message {
  int whom;
  String text;

  _Message(this.whom, this.text);
}

class _LED {
  int whom;
  String text;

  _LED(this.whom, this.text);
}

class _ChatPage extends State<ChatPage> {

  double _currentLEDValue = 10;
  int _currentLEDValueInt = 10;
  int listLength = 0;
  bool isSpeakEnable = true;

  double _currentSoundValue = 0.5;

  static final clientID = 0;
  BluetoothConnection connection;

  final FlutterTts tts = FlutterTts();

  List<_Message> messages = List<_Message>();
  // _Message message;
  String _messageBuffer = '';

  List<_LED> brightnessled = List<_LED>();
  String _ledBuffer = '';

  String alert = '';

  final TextEditingController textEditingController =
      new TextEditingController();
  final ScrollController listScrollController = new ScrollController();

  bool isConnecting = true;
  bool get isConnected => connection != null && connection.isConnected;

  bool isDisconnecting = false;

  Future speak(String text, bool isSpeak) async {
    if (isSpeak) {
      await tts.setLanguage('en-gb');
      await tts.setPitch(2);
      // await tts.setSpeechRate(0.4);
      await tts.speak(text);
      // print(await tts.getLanguages);
    }
  }

  Future stop() async {
    await tts.stop();
  }

  @override
  void initState() {
    super.initState();

    BluetoothConnection.toAddress(widget.server.address).then((_connection) {
      print('Connected to the device');
      connection = _connection;
      setState(() {
        isConnecting = false;
        isDisconnecting = false;

      });

      connection.input.listen(_onDataReceived).onDone(() {
        // Example: Detect which side closed the connection
        // There should be `isDisconnecting` flag to show are we are (locally)
        // in middle of disconnecting process, should be set before calling
        // `dispose`, `finish` or `close`, which all causes to disconnect.
        // If we except the disconnection, `onDone` should be fired as result.
        // If we didn't except this (no flag set), it means closing by remote.
        if (isDisconnecting) {
          print('Disconnecting locally!');
        } else {
          print('Disconnected remotely!');
        }
        if (this.mounted) {
          setState(() {

          });
        }
      });
    }).catchError((error) {
      print('Cannot connect, exception occured');
      print(error);
    });
  }

  @override
  void dispose() {
    // Avoid memory leak (`setState` after dispose) and disconnect
    if (isConnected) {
      isDisconnecting = true;
      connection.dispose();
      connection = null;
    }

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final List<Row> list = messages.map((_message) {
      // print(messages.length);
      isSpeakEnable = true;
      alert = _message.text.trim();
      speak(alert, isSpeakEnable);

      return Row(
        children: <Widget>[
          Container(
            child: Text(
                (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_message.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                    _message.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _message.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    final List<Row> listLED = brightnessled.map((_led) {
      // alert = _led.text.trim();
      // speak(alert);
      return Row(
        children: <Widget>[
          Container(
            child: Text(
                    (text) {
                  return text == '/shrug' ? '¯\\_(ツ)_/¯' : text;
                }(_led.text.trim()),
                style: TextStyle(color: Colors.white)),
            padding: EdgeInsets.all(12.0),
            margin: EdgeInsets.only(bottom: 8.0, left: 8.0, right: 8.0),
            width: 222.0,
            decoration: BoxDecoration(
                color:
                _led.whom == clientID ? Colors.blueAccent : Colors.grey,
                borderRadius: BorderRadius.circular(7.0)),
          ),
        ],
        mainAxisAlignment: _led.whom == clientID
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
      );
    }).toList();

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.deepPurple,
          title: (isConnecting
              ? Text('Connecting chat to ' + widget.server.name + '...')
              : isConnected
                  ? Text('Live connecting with ' + widget.server.name)
                  : Text('Chat log with ' + widget.server.name))),
      body: SafeArea(
        child: Column(
          children: <Widget>[
            Flexible(
              child: ListView(
                  padding: const EdgeInsets.all(12.0),
                  controller: listScrollController,
                  children: <Widget>[
                    SizedBox(
                      height: 80.0,
                    ),
                    Card(
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                        side: BorderSide(
                          color: Colors.black
                        ),
                        borderRadius: const BorderRadius.all(Radius.circular(5)),
                      ),
                      child: SizedBox(
                        width: 300,
                        height: 100,
                        child: Center(
                            child: Text(
                              alert,
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: Colors.orangeAccent),
                            ),
                        ),
                      ),
                    ),


                    // speak(alert),
                    // TextButton(onPressed: () {
                    //   speak(alert);
                    // }, child: Text('Speak')),
                    SizedBox(
                      height: 50.0,
                    ),
                    const Text("LED BRIGHTNESS", style: TextStyle(fontSize: 20), textAlign: TextAlign.center,),
                    const Divider(),
                    Slider(
                      min: 0.0,
                      max: 100.0,
                      value: _currentLEDValue,
                      divisions: 10,
                      label: '${_currentLEDValue.round()}',
                      onChanged: (value) {
                        setState(() {
                          isSpeakEnable = false;
                          _currentLEDValue = value;
                          _currentLEDValueInt = _currentLEDValue.toInt();
                          _sendMessage(_currentLEDValueInt.toString());
                        });
                      },
                    ),
                    SizedBox(
                      height: 50.0,
                    ),
                    Text("Current Volume: ${(_currentSoundValue * 100).toInt()}", textAlign: TextAlign.center, style: TextStyle(fontSize: 20),),

                    const Divider(),

                    Slider(
                      value: _currentSoundValue,
                      label: '${(_currentSoundValue * 100).toInt()}',
                      onChanged: (newvol){
                        _currentSoundValue = newvol;
                        isSpeakEnable = false;
                        PerfectVolumeControl.setVolume(newvol);
                        //set new volume
                        setState(() {
                          // _currentSoundValue = newvol;
                        });
                      },
                      min: 0, //
                      max:  1,
                      divisions: 10,
                    ),
                  ]
              ),
            ),
            Row(
              children: <Widget>[
                Flexible(
                  child: Container(
                    margin: const EdgeInsets.only(left: 16.0),
                    child: TextField(
                      style: const TextStyle(fontSize: 15.0),
                      controller: textEditingController,
                      decoration: InputDecoration.collapsed(
                        hintText: isConnecting
                            ? 'Wait until connected...'
                            : isConnected
                                ? 'Type your message...'
                                : 'Chat got disconnected',
                        hintStyle: const TextStyle(color: Colors.grey),
                      ),
                      enabled: isConnected,
                    ),
                  ),
                ),
                Container(
                  margin: const EdgeInsets.all(8.0),
                  child: IconButton(
                      icon: const Icon(Icons.send),
                      onPressed: isConnected
                          ? () => _sendMessage(textEditingController.text)
                          : null),
                ),
              ],
            )
          ],
        ),
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
        // speak(alert);
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
    // textEditingController.clear();
    // stop();

    if (text.length > 0) {
      try {
        connection.output.add(utf8.encode(text));
        await connection.output.allSent;

        setState(() {
          brightnessled.add(_LED(clientID, text));
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
}
