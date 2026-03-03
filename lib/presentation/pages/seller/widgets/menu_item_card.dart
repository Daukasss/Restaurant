import 'package:flutter/material.dart';

const _primary = Color(0xFF1A365D);
const _cardBg = Colors.white;
const _textMain = Color(0xFF1A2535);
const _textSub = Color(0xFF6B7A92);
const _divider = Color(0xFFE8EDF5);

// ── Fullscreen image viewer ────────────────────────────────────────────────
class _FullscreenImagePage extends StatefulWidget {
  final String imageUrl;
  final String name;

  const _FullscreenImagePage({required this.imageUrl, required this.name});

  @override
  State<_FullscreenImagePage> createState() => _FullscreenImagePageState();
}

class _FullscreenImagePageState extends State<_FullscreenImagePage> {
  final TransformationController _controller = TransformationController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.45),
              shape: BoxShape.circle,
            ),
            child:
                const Icon(Icons.close_rounded, color: Colors.white, size: 20),
          ),
        ),
        title: Text(
          widget.name,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Center(
        child: InteractiveViewer(
          transformationController: _controller,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            widget.imageUrl,
            fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => const Icon(
              Icons.broken_image_outlined,
              color: Colors.white38,
              size: 64,
            ),
            loadingBuilder: (_, child, progress) {
              if (progress == null) return child;
              return Center(
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                  value: progress.expectedTotalBytes != null
                      ? progress.cumulativeBytesLoaded /
                          progress.expectedTotalBytes!
                      : null,
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

// ── MenuItemCard ──────────────────────────────────────────────────────────
class MenuItemCard extends StatelessWidget {
  final String name;
  final String? description;
  final String? imageUrl;

  const MenuItemCard({
    super.key,
    required this.name,
    this.description,
    this.imageUrl,
  });

  void _openFullscreen(BuildContext context) {
    Navigator.push(
      context,
      PageRouteBuilder(
        opaque: false,
        barrierColor: Colors.black,
        pageBuilder: (_, __, ___) =>
            _FullscreenImagePage(imageUrl: imageUrl!, name: name),
        transitionsBuilder: (_, anim, __, child) =>
            FadeTransition(opacity: anim, child: child),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final hasImage = imageUrl != null && imageUrl!.isNotEmpty;

    return Container(
      decoration: BoxDecoration(
        color: _cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _divider),
        boxShadow: [
          BoxShadow(
            color: _primary.withOpacity(0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Image ────────────────────────────────────────────────────
            if (hasImage)
              GestureDetector(
                onTap: () => _openFullscreen(context),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: Stack(
                    children: [
                      Image.network(
                        imageUrl!,
                        width: 72,
                        height: 72,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _PlaceholderIcon(),
                        loadingBuilder: (_, child, progress) {
                          if (progress == null) return child;
                          return SizedBox(
                            width: 72,
                            height: 72,
                            child: Center(
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: _primary,
                                value: progress.expectedTotalBytes != null
                                    ? progress.cumulativeBytesLoaded /
                                        progress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                      ),
                      // Иконка-подсказка увеличения
                      Positioned(
                        right: 4,
                        bottom: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withOpacity(0.45),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.zoom_in_rounded,
                              color: Colors.white, size: 13),
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              _PlaceholderIcon(),

            const SizedBox(width: 12),

            // ── Text ─────────────────────────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textMain,
                      height: 1.3,
                    ),
                  ),
                  if (description != null && description!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      description!,
                      style: const TextStyle(
                        fontSize: 13,
                        color: _textSub,
                        height: 1.4,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PlaceholderIcon extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 72,
      decoration: BoxDecoration(
        color: _primary.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
      ),
      child: const Icon(Icons.fastfood_outlined, color: _primary, size: 28),
    );
  }
}
