void main() {
  print(doThing());
  // prints "still running finaly block" then 42
}

doThing() {
  try {
    return aux();
  } finally {
    print('still running finally block');
  }
}

int aux() => 42;
