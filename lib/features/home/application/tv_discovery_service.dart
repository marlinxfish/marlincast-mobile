import '../domain/tv_device.dart';

abstract class TvDiscoveryService {
  Future<List<TvDevice>> discover();
}

class LocalNetworkTvDiscoveryService implements TvDiscoveryService {
  @override
  Future<List<TvDevice>> discover() async {
    // Placeholder until TV app broadcasts via mDNS/UDP or pairing backend exists.
    await Future<void>.delayed(const Duration(milliseconds: 300));
    return const [
      TvDevice(
        name: 'Marlin Cast TV - Living Room',
        address: '192.168.1.24:8080',
        online: true,
      ),
      TvDevice(
        name: 'Marlin Cast TV - Bedroom',
        address: '192.168.1.31:8080',
        online: false,
      ),
    ];
  }
}
