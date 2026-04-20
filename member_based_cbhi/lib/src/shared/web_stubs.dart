import 'dart:typed_data';

class File {
  final String path;
  File(this.path);
  
  Future<bool> exists() async => false;
  bool existsSync() => false;
  Future<File> copy(String path) async => this;
  Future<int> length() async => 0;
  Future<Uint8List> readAsBytes() async => Uint8List(0);
  Future<void> writeAsBytes(List<int> bytes) async {}
}

class Directory {
  final String path;
  Directory(this.path);
  
  Future<bool> exists() async => false;
  Future<Directory> create({bool recursive = false}) async => this;
}

class Platform {
  static bool get isWindows => false;
  static bool get isLinux => false;
  static bool get isMacOS => false;
  static bool get isAndroid => false;
  static bool get isIOS => false;
  static String get pathSeparator => '/';
}
