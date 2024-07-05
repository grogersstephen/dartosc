import 'package:osc/osc.dart';
import 'package:osc/message.dart';

void main() async {
  final conn = Conn.init(
      remoteHost: "45.56.112.149", remotePort: 10023, localPort: 10023);

  // double level = await getLevel(conn: conn, ch: "01");

  // print("\n\nGot level: $level");

  // await getLevels(conn);
  conn.messageStream().listen((msg) {
    print('received: $msg');
  });

  send(conn: conn, ch: "01");
  send(conn: conn, ch: "02");
  send(conn: conn, ch: "03");
  send(conn: conn, ch: "04");
  await Future.delayed(Duration(seconds: 20));
  conn.close();
}

send({required Conn conn, required String ch}) async {
  await Future.delayed(Duration(seconds: 2));
  final msg = Message("/ch/$ch/mix/fader");
  try {
    print('sending msg: $msg');
    await conn.send(msg);
  } catch (e) {
    print("could not send msg '$msg': $e");
  }
}

getLevels(Conn conn) async {
  for (int i = 1; i < 10; i++) {
    // await getLevel(conn: conn, ch: "0$i");
  }
}

/*
Future<double> getLevel({required Conn conn, required String ch}) async {
  final msg = Message("/ch/$ch/mix/fader");
  try {
    await conn.send(msg);
    print("sent message: $msg");
  } catch (e) {
    print("could not send msg '$msg': $e");
  }

  Message reply = await conn.receive(Duration(seconds: 1));
  print("Received message: $reply");

  print("Received args:");
  for (final arg in reply.arguments) {
  print("type: ${arg.runtimeType}");
  print("arg: $arg");
  }

  return reply.arguments[0];
}
*/
