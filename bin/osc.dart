import 'dart:convert' show utf8;
import 'dart:io';
import 'package:osc/osc.dart';
import 'package:osc/message.dart';
import 'package:args/args.dart';

enum Options { target, message, timeout, oscFlags, oscValues }

enum Flags { mustMatchRootContainer }

enum Commands { main, send, request, stream }

typedef Parser = ({Commands command, ArgParser parser});

class Parsers {
  final List<Parser> _parsers;

  Parsers()
      : _parsers = List<Parser>.generate(Commands.values.length,
            (i) => (command: Commands.values[i], parser: ArgParser()));

  ArgParser get main => _parsers[0].parser;
  ArgParser get send => _parsers[1].parser;
  ArgParser get request => _parsers[2].parser;
  ArgParser get stream => _parsers[3].parser;

  set main(ArgParser val) =>
      _parsers[0] = (command: _parsers[0].command, parser: val);
  set send(ArgParser val) =>
      _parsers[1] = (command: _parsers[1].command, parser: val);
  set request(ArgParser val) =>
      _parsers[2] = (command: _parsers[2].command, parser: val);
  set stream(ArgParser val) =>
      _parsers[3] = (command: _parsers[2].command, parser: val);
}

void main(List<String> arguments) {
  exitCode = 0; // Presume success
  final parsers = Parsers();
  parsers.main.addOption(Options.target.name, mandatory: true, abbr: 't');
  // SEND
  parsers.send = parsers.main.addCommand(Commands.send.name, ArgParser());
  parsers.send.addOption(Options.message.name, abbr: 'm');
  parsers.send.addOption(Options.oscFlags.name, abbr: 'f');
  parsers.send.addMultiOption(Options.oscValues.name, abbr: 'v');
  /*
  parsers.send.addMultiOption(Options.string.name, abbr: 's');
  parsers.send.addMultiOption(Options.float.name, abbr: 'f');
  parsers.send.addMultiOption(Options.int.name, abbr: 'i');
  parsers.send.addMultiOption(Options.blob.name, abbr: 'b');
  */
  // REQUEST
  parsers.request = parsers.main.addCommand(Commands.request.name, ArgParser());
  parsers.request.addOption(Options.message.name, abbr: 'm');
  parsers.request.addOption(Options.oscFlags.name, abbr: 'f');
  parsers.request.addMultiOption(Options.oscValues.name, abbr: 'v');
  /*
  parsers.request.addMultiOption(Options.string.name, abbr: 's');
  parsers.request.addMultiOption(Options.float.name, abbr: 'f');
  parsers.request.addMultiOption(Options.int.name, abbr: 'i');
  parsers.request.addMultiOption(Options.blob.name, abbr: 'b');
  */
  // STREAM REQUEST
  parsers.stream = parsers.main.addCommand(Commands.stream.name, ArgParser());
  parsers.stream.addOption(Options.message.name, abbr: 'm');
  parsers.stream.addOption(Options.timeout.name, abbr: 'x');
  parsers.stream.addFlag(Flags.mustMatchRootContainer.name, abbr: 'r');
  parsers.stream.addOption(Options.oscFlags.name, abbr: 'f');
  parsers.stream.addMultiOption(Options.oscValues.name, abbr: 'v');
  /*
  parsers.stream.addMultiOption(Options.string.name, abbr: 's');
  parsers.stream.addMultiOption(Options.float.name, abbr: 'f');
  parsers.stream.addMultiOption(Options.int.name, abbr: 'i');
  parsers.stream.addMultiOption(Options.blob.name, abbr: 'b');
  */

  ArgResults argResults = parsers.main.parse(arguments);
  final targetSplit = argResults[Options.target.name].split(":");
  final Target target =
      (address: targetSplit[0], port: int.parse(targetSplit[1]));

  final command =
      Commands.values.firstWhere((val) => val.name == argResults.command?.name);
  switch (command) {
    case Commands.request:
      _handleRequest(argResults, target);
    case Commands.send:
      _handleSend(argResults, target);
    case Commands.stream:
      _handleStreamRequest(argResults, target);
    case Commands.main:
      null;
  }
}

Future _handleRequest(ArgResults argResults, Target target) {
  final message = argResults.command?[Options.message.name];
  final String? oscFlags = argResults.command?[Options.oscFlags.name];
  final List<String> oscValues = argResults.command?[Options.oscValues.name];
  final args = <OSCArgument>[];
  final List<String> flags = oscFlags != null
      ? (oscFlags.codeUnits).map((i) => String.fromCharCode(i)).toList()
      : [];
  for (int i = 0; i < flags.length; i++) {
    switch (flags[i]) {
      case "f":
        args.add(OSCFloat(double.parse(oscValues[i])));
      case "i":
        args.add(OSCInt(int.parse(oscValues[i])));
      case "s":
        args.add(OSCString(oscValues[i]));
      case "b":
        throw UnimplementedError();
      default:
        null;
    }
  }
  final msg = Message(message, args);
  return Client.request(
      address: target.address, port: target.port, message: msg);
}

Future _handleStreamRequest(ArgResults argResults, Target target) {
  final message = argResults.command?[Options.message.name];
  final bool mustMatchRootContainer =
      argResults.command?[Flags.mustMatchRootContainer.name];
  final String? oscFlags = argResults.command?[Options.oscFlags.name];
  final List<String> oscValues = argResults.command?[Options.oscValues.name];
  final args = <OSCArgument>[];
  final List<String> flags = oscFlags != null
      ? (oscFlags.codeUnits).map((i) => String.fromCharCode(i)).toList()
      : [];
  for (int i = 0; i < flags.length; i++) {
    switch (flags[i]) {
      case "f":
        args.add(OSCFloat(double.parse(oscValues[i])));
      case "i":
        args.add(OSCInt(int.parse(oscValues[i])));
      case "s":
        args.add(OSCString(oscValues[i]));
      case "b":
        throw UnimplementedError();
      default:
        null;
    }
  }
  final timeoutString = argResults.command?[Options.timeout.name];
  final timeout = timeoutString != null
      ? Duration(seconds: int.parse(timeoutString))
      : null;
  final msg = Message(message, args);
  return Client.requestStream(
      address: target.address,
      port: target.port,
      mustMatchRootContainer: mustMatchRootContainer,
      message: msg,
      timeout: timeout);
}

Future _handleSend(ArgResults argResults, Target target) {
  final message = argResults.command?[Options.message.name];
  final String? oscFlags = argResults.command?[Options.oscFlags.name];
  final List<String> oscValues = argResults.command?[Options.oscValues.name];
  final args = <OSCArgument>[];
  final List<String> flags = oscFlags != null
      ? (oscFlags.codeUnits).map((i) => String.fromCharCode(i)).toList()
      : [];
  for (int i = 0; i < flags.length; i++) {
    switch (flags[i]) {
      case "f":
        args.add(OSCFloat(double.parse(oscValues[i])));
      case "i":
        args.add(OSCInt(int.parse(oscValues[i])));
      case "s":
        args.add(OSCString(oscValues[i]));
      case "b":
        throw UnimplementedError();
      default:
        null;
    }
  }
  final msg = Message(message, args);
  return Client.send(address: target.address, port: target.port, message: msg);
}

typedef Target = ({String address, int port});

class Client {
  static Future<void> send(
      {required String address,
      required int port,
      required Message message}) async {
    final Conn conn;
    try {
      conn = await Conn.init(
        remoteHost: address,
        remotePort: port,
        // localPort: 10023,
      );
    } catch (e) {
      stdout.addError(e);
      return;
    }
    try {
      await conn.send(message);
    } catch (e) {
      stdout.addError("send failed: $e");
    }
    stdout.writeln("sent");
    conn.close();
  }

  static Future<void> request(
      {required String address,
      required int port,
      required Message message}) async {
    final Conn conn;
    try {
      conn = await Conn.init(
        remoteHost: address,
        remotePort: port,
        // localPort: 10023,
      );
    } catch (e) {
      stdout.addError(e);
      return;
    }
    Message? response;
    try {
      response = await conn.request(message);
    } catch (e) {
      stdout.addError("request failed: $e");
    }
    stdout.writeln("receiving...");
    stdout.writeln(response?.packet);
    stdout.writeln(response.toString());
    conn.close();
  }

  static Future<void> requestStream({
    required String address,
    required int port,
    required Message message,
    bool mustMatchRootContainer = true,
    Duration? timeout,
  }) async {
    final Conn conn;
    try {
      conn = await Conn.init(
        remoteHost: address,
        remotePort: port,
        // localPort: 10023,
      );
    } catch (e) {
      stdout.addError(e);
      return;
    }
    Stream<Message> stream;
    try {
      stream = conn.requestStream(message,
          timeout: timeout, mustMatchRootContainer: mustMatchRootContainer);
    } catch (e) {
      stdout.addError("request failed: $e");
      return;
    }
    stdout.writeln("receiving...");
    await for (final Message event in stream) {
      stdout.writeln(event.packet);
      stdout.writeln(event.toString());
    }
    conn.close();
  }
}
