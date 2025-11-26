extension on String {
  // ignore: unused_element
  ({String name, DateTime expiry}) parseThing() {
    final [name, expiry, ...] = split(':');
    final year = int.parse(expiry.substring(0, 4));
    final month = int.parse(expiry.substring(4, 6));
    return (
      name: name,
      expiry: DateTime.utc(year, month), // should recommend .utc(year, month)
    );
  }
}
