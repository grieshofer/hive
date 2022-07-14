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
  final HiveCipher? _cipher;

  final ReadWriteSync _sync;

  Uint8List _bytes;

  TypeRegistry? typeRegistry;

  Keystore? keystore;

  int writeOffset = 0;

  /// Not part of public API
  StorageBackendMemory(Uint8List? bytes, this._cipher)
      : _bytes = bytes ?? Uint8List(0),
        _sync = ReadWriteSync();

  @override
  String? get path => null;

  @override
  bool get supportsCompaction => false;

  @override
  Future<void> initialize(TypeRegistry registry, Keystore keystore,
      bool lazy) async {
    typeRegistry = registry;
    this.keystore = keystore;
    writeOffset = _bytes.offsetInBytes;
    print("Hello from StorageBackendMemory");
  }

  @override
  Future<dynamic> readValue(Frame frame) {
    return _sync.syncRead(() async {
      var keystoreFrame = keystore!.get(frame.key)!;

      print("I'm reading the value of ${frame.key}");
      print("offset: ${keystoreFrame.offset}, length: {keystoreFrame.length}");

      var bytes = _bytes.sublist(keystoreFrame.offset, keystoreFrame.length);
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
      print("Write frames in StorageBackendMemory");

      var writer = BinaryWriterImpl(typeRegistry!);

      for (var frame in frames) {
        frame.length = writer.writeFrame(frame, cipher: _cipher);
      }

      _bytes = Uint8List.fromList(_bytes + writer.toBytes());

      for (var frame in frames) {
        frame.offset = writeOffset;
        writeOffset += frame.length!;
      }
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
    _bytes = Uint8List(0);
    writeOffset = 0;
  }
}
