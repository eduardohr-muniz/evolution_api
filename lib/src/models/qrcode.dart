class QRCode {
  final String instance;
  final String? pairingCode;
  final String code;
  final String base64;

  QRCode({
    required this.instance,
    this.pairingCode,
    required this.code,
    required this.base64,
  });

  factory QRCode.fromMap(Map<String, dynamic> map) {
    final qrcode = map['qrcode'] as Map<String, dynamic>;
    return QRCode(
      instance: qrcode['instance'] as String,
      pairingCode: qrcode['pairingCode'] as String?,
      code: qrcode['code'] as String,
      base64: qrcode['base64'] as String,
    );
  }

  @override
  String toString() {
    return 'QRCode(instance: $instance, pairingCode: $pairingCode, code: $code, base64: $base64)';
  }
}
