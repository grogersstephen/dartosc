import 'dart:io';

import 'package:typed_data/typed_buffers.dart';
import 'package:udp/udp.dart';
import 'dart:typed_data';

void main() async {
  var receiver = await UDP.bind(Endpoint.any(port: Port(65002)));
  // final stream = receiver.asStream(timeout: Duration(seconds: 20));
  final stream = receiver.socket?.asBroadcastStream(onListen: (subscription) {
    print("subscription: $subscription");
  }, onCancel: (subscription) {
    print("cancel: $subscription");
  });

  try {
    if (stream != null) {
      await for (final event in stream) {
        // var data = event;
        if (event == RawSocketEvent.read) {
          final data = receiver.socket?.receive() ??
              Datagram(Uint8List.fromList("empty".codeUnits),
                  InternetAddress(""), 8080);
          print('data: ${String.fromCharCodes(data.data)}');
          print('address:port ${data.address}:${data.port}');
          Uint8Buffer resp = Uint8Buffer(0)
            ..addAll("/".codeUnits)
            ..add(0)
            ..add(0)
            ..add(0);

          print('resp: $resp');

          receiver.socket!.send(resp, data.address, data.port);
        }
      }
    }
  } catch (e) {
    print('error: $e');
  }

  // final ByteBuffer b = ByteBuffer();
  // var str = String.fromCharCodes(data);
  // receiver.send(data, remoteEndpoint)
}
