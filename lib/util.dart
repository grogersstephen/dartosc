// data validation

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
