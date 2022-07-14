import 'package:hive/hive.dart';
import 'package:hive/src/hive_impl.dart';
import 'package:test/test.dart';

void main() {
  Future<HiveImpl> initHive() async {
    var hive = HiveImpl();
    hive.init(null, backendPreference: HiveStorageBackendPreference.memory);
    return hive;
  }

  test('typed box in memory', () async {
    var hive = await initHive();
    var box = await hive.openBox('TESTBOX',
        bytes: null, backend: StorageBackendMemory(null, null));

    expect(box.path, null);

    await box.put('name', 'Paul');
    await box.put('address', 'Jakominiplatz 1');
    await box.putAll({'stop1': "Jakominiplatz", "st6op2": "Zentralfriedhof"});
    await box.putAll({'dd': "Jakominiplatz", "st4op2": "Zentralfriedhof"});
    await box.putAll({'dd': "Jakominiplatz", "st5op2": "Zentralfriedhof"});
    await box.putAll({'s': "Jakominiplatz", "st3op2": "Zentralfriedhof"});
    await box
        .putAll({'stopf1': "Jakominiplatz", "stwefewop2": "Zentralfriedhof"});
    await box
        .putAll({'stofp1': "Jakominiplatz", "stopefw2": "Zentralfriedhof"});
    await box
        .putAll({'stowewfp1': "Jakominiplatz", "st2op2": "Zentralfriedhof"});

    print(box.values);
    print(box.keys);

    expect("Paul", box.get('name', defaultValue: "INVALID"));
    expect("Jakominiplatz 1", box.get('address', defaultValue: "INVALID"));
    // expect("", box.get('route'));
  });

  test('untyped box in memory', () async {
    var hive = await initHive();
    var box = await hive.openBox('TESTBOX',
        bytes: null, backend: StorageBackendMemory(null, null));

    expect(box.path, null);

    await box.compact();

    box.put('name', 'Paul');
    box.put('address', 'Jakominiplatz 1');

    expect("Paul", box.get('name', defaultValue: "INVALID"));
    expect("Jakominiplatz 1", box.get('address', defaultValue: "INVALID"));
  });
}
