import 'package:flutter/material.dart';
import 'package:dotlottie_loader/dotlottie_loader.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:lottie/lottie.dart';

import '../../../shared/presentation/widgets/menu_button.dart';
import '../application/home_controller.dart';
import '../domain/tv_device.dart';
import 'qr_pairing_page.dart';
import 'widgets/home_drawer.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _controller = HomeController();

  @override
  void initState() {
    super.initState();
    _controller.discoverDevices();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      body: SafeArea(
        child: AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              children: [
                _HomeHeader(onScan: _openQrPairing),
                const SizedBox(height: 14),
                const _WelcomeAnimation(),
                const SizedBox(height: 8),
                const _ConnectionCard(),
                const SizedBox(height: 14),
                _AvailableTvSection(
                  devices: _controller.devices,
                  isScanning: _controller.isScanning,
                  onConnect: _controller.connect,
                  onRefresh: _controller.discoverDevices,
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Future<void> _openQrPairing() async {
    final rawValue = await Navigator.of(context).push<String>(
      MaterialPageRoute(builder: (_) => const QrPairingPage()),
    );
    if (rawValue == null) {
      return;
    }

    final paired = _controller.pairFromQr(rawValue);
    if (!mounted) {
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(paired ? 'TV berhasil terhubung' : 'QR TV tidak valid'),
      ),
    );
  }
}

class _HomeHeader extends StatelessWidget {
  const _HomeHeader({required this.onScan});

  final Future<void> Function() onScan;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        const Align(alignment: Alignment.centerLeft, child: MenuButton()),
        const Spacer(),
        IconButton.filledTonal(
          tooltip: 'Scan TV',
          onPressed: () => onScan(),
          icon: const Icon(LucideIcons.scanQrCode),
        ),
      ],
    );
  }
}

class _WelcomeAnimation extends StatelessWidget {
  const _WelcomeAnimation();

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: DotLottieLoader.fromAsset(
        'assets/animations/Welcome Animation.lottie',
        frameBuilder: (context, dotLottie) {
          if (dotLottie == null) {
            return const SizedBox.shrink();
          }

          return Lottie.memory(
            dotLottie.animations.values.first,
            fit: BoxFit.contain,
            repeat: true,
          );
        },
        errorBuilder: (context, error, stackTrace) {
          return const SizedBox.shrink();
        },
      ),
    );
  }
}

class _ConnectionCard extends StatelessWidget {
  const _ConnectionCard();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(26),
        color: colorScheme.surface,
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(LucideIcons.cast, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'TV belum terhubung',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.3,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  'Pilih TV yang tersedia atau scan QR dari layar TV.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _AvailableTvSection extends StatelessWidget {
  const _AvailableTvSection({
    required this.devices,
    required this.isScanning,
    required this.onConnect,
    required this.onRefresh,
  });

  final List<TvDevice> devices;
  final bool isScanning;
  final ValueChanged<TvDevice> onConnect;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.tv, color: colorScheme.primary, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'TV tersedia di jaringan ini',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ),
              IconButton(
                tooltip: 'Refresh',
                onPressed: isScanning ? null : onRefresh,
                icon: isScanning
                    ? const SizedBox.square(
                        dimension: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(LucideIcons.refreshCcw, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (devices.isEmpty && !isScanning)
            const _EmptyDeviceState()
          else
            for (final device in devices) ...[
              _TvDeviceTile(device: device, onConnect: onConnect),
              if (device != devices.last) const SizedBox(height: 8),
            ],
        ],
      ),
    );
  }
}

class _EmptyDeviceState extends StatelessWidget {
  const _EmptyDeviceState();

  @override
  Widget build(BuildContext context) {
    return Text(
      'Belum ada TV ditemukan. Pastikan TV dan HP berada di WiFi yang sama.',
      style: Theme.of(context).textTheme.bodySmall?.copyWith(
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class _TvDeviceTile extends StatelessWidget {
  const _TvDeviceTile({required this.device, required this.onConnect});

  final TvDevice device;
  final ValueChanged<TvDevice> onConnect;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      children: [
        Container(
          width: 9,
          height: 9,
          decoration: BoxDecoration(
            color: device.online ? Colors.green : colorScheme.outline,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                device.name,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                device.address,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        TextButton(
          onPressed: device.online ? () => onConnect(device) : null,
          child: const Text('Connect'),
        ),
      ],
    );
  }
}
