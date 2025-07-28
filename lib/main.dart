import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:usb_serial/usb_serial.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'USB File Sender',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
      ),
      home: const MyHomePage(title: 'USB File Uploader'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});
  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  String _status = "Idle";

  Future<void> downloadAndSendToUsb(String url) async {
    setState(() => _status = "Downloading file...");
    try {
      final response = await http.get(Uri.parse(url));
      if (response.statusCode != 200) {
        setState(() => _status = "Failed to download file");
        return;
      }
      final Uint8List fileBytes = response.bodyBytes;

      setState(() => _status = "Searching for USB device...");
      List<UsbDevice> devices = await UsbSerial.listDevices();
      if (devices.isEmpty) {
        setState(() => _status = "No USB device found");
        return;
      }

      setState(() => _status = "Connecting to USB device...");
      UsbPort? port = await devices[0].create();
      if (port == null) {
        setState(() => _status = "Failed to create USB port");
        return;
      }

      bool openResult = await port.open();
      if (!openResult) {
        setState(() => _status = "Failed to open USB port");
        return;
      }

      await port.setDTR(true);
      await port.setRTS(true);
      await port.setPortParameters(
        9600,
        UsbPort.DATABITS_8,
        UsbPort.STOPBITS_1,
        UsbPort.PARITY_NONE,
      );

      setState(() => _status = "Sending data...");
      await port.write(fileBytes);
      setState(() => _status = "Data sent to USB device");

      await port.close();
    } catch (e) {
      setState(() => _status = "Error: $e");
    }
  }


  @override
  Widget build(BuildContext context) {
    const fileUrl = "https://stagingiosmls.blob.core.windows.net/packages/9cf617e2-d5b0-4d87-bc72-b6de527e4eda/e5d78222-d647-4609-9482-af2f43ec4795/Dallas-20250616160004.zip"; // replace with real URL

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.title),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text(_status, textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => downloadAndSendToUsb(fileUrl),
              child: const Text("Download & Upload to USB"),
            ),
          ],
        ),
      ),
    );
  }
}
