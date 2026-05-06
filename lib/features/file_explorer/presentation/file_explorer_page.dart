import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../shared/presentation/widgets/menu_button.dart';
import '../../home/presentation/widgets/home_drawer.dart';
import '../application/file_explorer_controller.dart';
import '../domain/local_media_file.dart';

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  final _controller = FileExplorerController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      drawer: const HomeDrawer(),
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(18, 10, 18, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const MenuButton(),
                  const SizedBox(height: 16),
                  _PickMediaCard(
                    isPicking: _controller.isPicking,
                    onPick: _controller.pickVideos,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'Video Lokal',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Expanded(
                    child: _controller.hasFiles
                        ? _MediaFileList(
                            files: _controller.files,
                            onRemove: _controller.remove,
                          )
                        : const _EmptyFileState(),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class _PickMediaCard extends StatelessWidget {
  const _PickMediaCard({
    required this.isPicking,
    required this.onPick,
  });

  final bool isPicking;
  final VoidCallback onPick;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colorScheme.primary, colorScheme.tertiary],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.18),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
            ),
            child: const Icon(LucideIcons.folderOpen, color: Colors.white),
          ),
          const SizedBox(height: 22),
          const Text(
            'Pilih video dari perangkat.',
            style: TextStyle(
              color: Colors.white,
              fontSize: 23,
              height: 1.12,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.9,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Ambil file lokal seperti MP4, MKV, MOV, WEBM, atau playlist M3U8 untuk dikirim ke TV nanti.',
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.78),
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: isPicking ? null : onPick,
            icon: Icon(isPicking ? LucideIcons.loader : LucideIcons.plus),
            label: Text(isPicking ? 'Membuka file...' : 'Pilih Video'),
          ),
        ],
      ),
    );
  }
}

class _MediaFileList extends StatelessWidget {
  const _MediaFileList({
    required this.files,
    required this.onRemove,
  });

  final List<LocalMediaFile> files;
  final ValueChanged<LocalMediaFile> onRemove;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: files.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final file = files[index];
        return _MediaFileTile(file: file, onRemove: () => onRemove(file));
      },
    );
  }
}

class _MediaFileTile extends StatelessWidget {
  const _MediaFileTile({
    required this.file,
    required this.onRemove,
  });

  final LocalMediaFile file;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(LucideIcons.video, color: colorScheme.primary),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  file.name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
                const SizedBox(height: 3),
                Text(
                  '${file.extension.toUpperCase()} - ${file.formattedSize}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: colorScheme.onSurfaceVariant,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: 'Hapus dari daftar',
            onPressed: onRemove,
            icon: const Icon(LucideIcons.x),
          ),
        ],
      ),
    );
  }
}

class _EmptyFileState extends StatelessWidget {
  const _EmptyFileState();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              color: colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(24),
            ),
            child: Icon(
              LucideIcons.files,
              color: colorScheme.primary,
              size: 32,
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Belum ada file dipilih',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Gunakan tombol Pilih Video di atas.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}
