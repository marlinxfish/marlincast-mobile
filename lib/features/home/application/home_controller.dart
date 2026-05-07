import 'package:flutter/foundation.dart';

import '../domain/tv_device.dart';
import '../domain/tv_pairing_info.dart';
import 'tv_discovery_service.dart';
import 'tv_pairing_service.dart';

class HomeController extends ChangeNotifier {
  HomeController({
    TvDiscoveryService? discoveryService,
    TvPairingService? pairingService,
  }) : _discoveryService = discoveryService ?? LocalNetworkTvDiscoveryService(),
       _pairingService = pairingService ?? TvPairingService();

  final TvDiscoveryService _discoveryService;
  final TvPairingService _pairingService;

  List<TvDevice> _devices = const [];
  TvDevice? _connectedDevice;
  bool _isScanning = false;

  List<TvDevice> get devices => List.unmodifiable(_devices);
  TvDevice? get connectedDevice => _connectedDevice;
  bool get isScanning => _isScanning;

  Future<void> discoverDevices() async {
    _isScanning = true;
    notifyListeners();

    try {
      _devices = await _discoveryService.discover();
    } finally {
      _isScanning = false;
      notifyListeners();
    }
  }

  bool pairFromQr(String value) {
    final pairingInfo = TvPairingInfo.parse(value);
    if (pairingInfo == null) {
      return false;
    }

    final device = _pairingService.fromPairingInfo(pairingInfo);
    _connectedDevice = device;
    _devices = [
      device,
      ..._devices.where((item) => item.address != device.address),
    ];
    notifyListeners();
    return true;
  }

  void connect(TvDevice device) {
    if (!device.online) {
      return;
    }

    _connectedDevice = device;
    notifyListeners();
  }
}
