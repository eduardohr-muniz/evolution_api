class ClientAdapter {
  static ClientAdapter? _instance;

  ClientAdapter._();
  static ClientAdapter get instance => _instance ??= ClientAdapter._();

  bool _isWeb = false;
  bool get isWeb => _isWeb;

  void initialize({required bool isWeb}) {
    _isWeb = isWeb;
  }
}
