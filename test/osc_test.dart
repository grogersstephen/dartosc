import 'package:osc/osc.dart';
import 'package:test/test.dart';

void main() {
  test('conn', () {
    expect(Conn(remoteHost: "192.168.50.1"), 42);
  });
}
