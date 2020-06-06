import 'package:json_class/json_class.dart';
import 'package:test/test.dart';

void main() {
  test('JsonClass.parseBool', () {
    expect(false, JsonClass.parseBool('false'));
    expect(false, JsonClass.parseBool('FALSE'));
    expect(false, JsonClass.parseBool('NO'));
    expect(false, JsonClass.parseBool('no'));
    expect(false, JsonClass.parseBool(0));
    expect(false, JsonClass.parseBool(false));
    expect(false, JsonClass.parseBool(null));

    expect(true, JsonClass.parseBool('true'));
    expect(true, JsonClass.parseBool('TRUE'));
    expect(true, JsonClass.parseBool('YES'));
    expect(true, JsonClass.parseBool('yes'));
    expect(true, JsonClass.parseBool(1));
    expect(true, JsonClass.parseBool(true));
  });

  test('JsonClass.parseDouble', () {
    expect(null, JsonClass.parseDouble(null));
    expect(1.23, JsonClass.parseDouble(1.23));
    expect(1.23, JsonClass.parseDouble('1.23'));
    expect(1.0, JsonClass.parseDouble('1.0'));
    expect(1.0, JsonClass.parseDouble(1.0));
    expect(1.0, JsonClass.parseDouble(1));
  });

  test('JsonClass.parseDurationFromMillis', () {
    expect(null, JsonClass.parseDurationFromMillis(null));
    expect(Duration(milliseconds: 123), JsonClass.parseDurationFromMillis(123));
    expect(
      Duration(milliseconds: 123),
      JsonClass.parseDurationFromMillis(123.5),
    );
    expect(
      Duration(milliseconds: 123),
      JsonClass.parseDurationFromMillis('123'),
    );
    expect(
      Duration(milliseconds: 123),
      JsonClass.parseDurationFromMillis('123.5'),
    );
  });

  test('JsonClass.parseDurationFromSeconds', () {
    expect(null, JsonClass.parseDurationFromSeconds(null));
    expect(Duration(seconds: 123), JsonClass.parseDurationFromSeconds(123));
    expect(Duration(seconds: 123), JsonClass.parseDurationFromSeconds(123.5));
    expect(Duration(seconds: 123), JsonClass.parseDurationFromSeconds('123'));
    expect(Duration(seconds: 123), JsonClass.parseDurationFromSeconds('123.5'));
  });

  test('JsonClass.parseInt', () {
    expect(null, JsonClass.parseInt(null));
    expect(1, JsonClass.parseInt(1.23));
    expect(1, JsonClass.parseInt('1.23'));
    expect(1, JsonClass.parseInt('1.0'));
    expect(1, JsonClass.parseInt(1.0));
    expect(1, JsonClass.parseInt(1));
  });

  test('JsonClass.parseUtcMillis', () {
    const millis = 1586717564014;

    expect(null, JsonClass.parseDurationFromMillis(null));
    expect(millis, JsonClass.parseUtcMillis(millis).millisecondsSinceEpoch);
    expect(millis, JsonClass.parseUtcMillis('$millis').millisecondsSinceEpoch);
    expect(true, JsonClass.parseUtcMillis(millis).isUtc);
  });

  test('JsonClass.removeNull', () {
    var data = {
      'foo': 'bar',
      'other': null,
      'list': [],
      'map': {'value': null},
    };

    expect({'foo': 'bar'}, JsonClass.removeNull(data));
    expect(
      {'foo': 'bar', 'list': [], 'map': {}},
      JsonClass.removeNull(data, false),
    );
  });
}
