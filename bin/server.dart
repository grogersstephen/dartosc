import 'dart:io';

import 'package:typed_data/typed_buffers.dart';
import 'package:udp/udp.dart';
import 'dart:typed_data';

void main() async {
  var receiver = await UDP.bind(Endpoint.any(port: Port(65002)));
  // final stream = receiver.asStream(timeout: Duration(seconds: 20));
  final stream = receiver.asStream();

  try {
    await for (final event in stream) {
      // var data = event;

      final Uint8List data = event?.data ?? Uint8List(0);
      final InternetAddress address = event?.address ?? InternetAddress("");
      final int port = event?.port ?? 0;

      print('data: ${String.fromCharCodes(data)}');
      print('address:port $address:$port');

      Uint8Buffer resp = Uint8Buffer(0)
        ..addAll("/".codeUnits)
        ..add(0)
        ..add(0)
        ..add(0);

      print('resp: $resp');

      receiver.socket!.send(resp, address, port);
    }
  } catch (e) {
    print('error: $e');
  } finally {
    receiver.close();
  }
}
