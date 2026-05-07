import '../domain/tv_device.dart';
import '../domain/tv_pairing_info.dart';

class TvPairingService {
  TvDevice fromPairingInfo(TvPairingInfo pairingInfo) {
    return TvDevice(
      name: 'Marlin Cast TV',
      address: pairingInfo.address,
      online: true,
    );
  }
}
