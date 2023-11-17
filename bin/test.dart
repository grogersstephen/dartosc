import 'dart:math';

void main() {
  print(doThing());
  // prints "still running finaly block" then 42
}

doThing() {
  try {
    return aux();
  } catch (e) {
    rethrow;
  } finally {
    print('still running finally block');
  }
}

int aux() {
  final num = Random().nextInt(2) + 1;
  print("$num");
  if (num % 2 == 0) {
    throw Error.safeToString("we randomly errored");
  }
  return 42;
}
