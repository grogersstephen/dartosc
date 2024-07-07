import 'dart:io';

class Endpoint {
  final InternetAddress _address;
  final int _port;

  Endpoint(InternetAddress address, int port)
      : _address = address,
        _port = isValidPortNumber(port)
            ? port
            : throw Exception("invalid port number");

  get address => _address;
  get port => _port;

  @override
  String toString() {
    return "$address:$port";
  }
}

bool isValidPortNumber(int val) {
  if (val >= 0 && val <= 65535) {
    return true;
  }
  return false;
}

bool isValidIPAddress(String val) {
  final parts = val.split(".");

  // check if ip address has 4 parts
  if (parts.length != 4) return false;

  // check if each part is an integer within valid range (0-255)
  for (final part in parts) {
    final num = int.tryParse(part);
    if (num == null || num < 0 || num > 255) {
      return false;
    }
  }

  return true;
}
