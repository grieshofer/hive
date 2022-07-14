import 'dart:math';
import 'dart:typed_data';

import 'package:hive/hive.dart';
import 'package:hive/src/backend/storage_backend.dart';
import 'package:hive/src/backend/vm/read_write_sync.dart';
import 'package:hive/src/binary/binary_reader_impl.dart';
import 'package:hive/src/binary/binary_writer_impl.dart';
import 'package:hive/src/binary/frame.dart';
import 'package:hive/src/box/keystore.dart';

/// In-memory Storage backend
class StorageBackendMemory extends StorageBackend {
  final String _identifier;

  final HiveCipher? _cipher;

  final ReadWriteSync _sync;

  Uint8List _bytes;

  TypeRegistry? typeRegistry;

  Keystore? keystore;

  int writeOffset = 0;

  /// Not part of public API
  StorageBackendMemory(Uint8List? bytes, this._cipher)
      : _bytes = bytes ?? Uint8List(0),
        _sync = ReadWriteSync(),
        _identifier = "StorageBackendMemory-${Random.secure().nextInt(65536)}";

  @override
  String? get path => null;

  @override
  bool get supportsCompaction => false;

  @override
  Future<void> initialize(
      TypeRegistry registry, Keystore keystore, bool lazy) async {
    typeRegistry = registry;
    this.keystore = keystore;
    writeOffset = _bytes.offsetInBytes;
    print("[$_identifier] Hello from $_identifier "
        "with initial offset: $writeOffset");
  }

  @override
  Future<dynamic> readValue(Frame frame) {
    return _sync.syncRead(() async {
      //var keystoreFrame = keystore!.get(frame.key)!;

      print("[$_identifier] Read frame [key=${frame.key}, value=${frame.key}, "
          "length=${frame.length}, offset= ${frame.offset}, "
          "bytes_in_storage=${_bytes.lengthInBytes}]");

      var bytes = _bytes.sublist(frame.offset, frame.length);
      var reader = BinaryReaderImpl(bytes, typeRegistry!);
      var readFrame = reader.readFrame(cipher: _cipher, lazy: false);

      if (readFrame == null) {
        throw HiveError(
            'Could not read value from box. Maybe your box is corrupted.');
      }

      return readFrame.value;
    });
  }

  @override
  Future<void> writeFrames(List<Frame> frames) {
    return _sync.syncWrite(() async {
      var writer = BinaryWriterImpl(typeRegistry!);

      print("[$_identifier] Old offset before writeFrames(): $writeOffset");

      for (var frame in frames) {
        frame.length = writer.writeFrame(frame, cipher: _cipher);
      }

      var b = BytesBuilder();
      b.add(_bytes);
      b.add(writer.toBytes());
      _bytes = b.toBytes();

      for (var frame in frames) {
        frame.offset = writeOffset;
        writeOffset += frame.length!;
        print("[$_identifier] Write frame [backend=$_identifier, "
            "key=${frame.key}, value=${frame.key}, length=${frame.length}], "
            "offset_start=${frame.offset}, offset_end=${writeOffset}");
      }

      print("[$_identifier] New offset after writeFrames(): $writeOffset");
    });
  }

  @override
  Future<void> compact(Iterable<Frame> frames) {
    throw UnsupportedError("Compact database not supported in memory");
  }

  @override
  Future<void> clear() {
    return _sync.syncReadWrite(() async {
      _clearMemoryBuffer();
    });
  }

  @override
  Future<void> close() async {
    _clearMemoryBuffer();
  }

  @override
  Future<void> deleteFromDisk() {
    return _sync.syncReadWrite(() async {
      _clearMemoryBuffer();
    });
  }

  @override
  Future<void> flush() {
    return _sync.syncWrite(() async {
      _clearMemoryBuffer();
    });
  }

  void _clearMemoryBuffer() {
    print("[$_identifier] Clearing...");
    _bytes = Uint8List(0);
    writeOffset = 0;
  }
}
