import 'package:flutter/material.dart';

/// Баннер, показываемый когда нет интернета.
/// Использовать как верхний элемент в Column внутри body Scaffold.
class OfflineBanner extends StatefulWidget {
  final bool isOffline;
  final String? lastUpdatedText;

  const OfflineBanner({
    super.key,
    required this.isOffline,
    this.lastUpdatedText,
  });

  @override
  State<OfflineBanner> createState() => _OfflineBannerState();
}

class _OfflineBannerState extends State<OfflineBanner>
    with SingleTickerProviderStateMixin {
  late AnimationController _animCtrl;
  late Animation<double> _heightAnim;

  @override
  void initState() {
    super.initState();
    _animCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _heightAnim = CurvedAnimation(
      parent: _animCtrl,
      curve: Curves.easeInOut,
    );

    if (widget.isOffline) {
      _animCtrl.forward();
    }
  }

  @override
  void didUpdateWidget(covariant OfflineBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOffline && !oldWidget.isOffline) {
      _animCtrl.forward();
    } else if (!widget.isOffline && oldWidget.isOffline) {
      _animCtrl.reverse();
    }
  }

  @override
  void dispose() {
    _animCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizeTransition(
      sizeFactor: _heightAnim,
      axisAlignment: -1,
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Colors.orange[800]!,
                Colors.deepOrange[700]!,
              ],
            ),
          ),
          child: SafeArea(
            bottom: false,
            child: Row(
              children: [
                const Icon(
                  Icons.wifi_off_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'Нет подключения к интернету',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                        ),
                      ),
                      if (widget.lastUpdatedText != null)
                        Text(
                          'Кэш от: ${widget.lastUpdatedText}',
                          style: const TextStyle(
                            color: Colors.white70,
                            fontSize: 11.5,
                          ),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white24,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: const Text(
                    'Офлайн',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Полноэкранная заглушка для страниц, недоступных офлайн
class OfflinePageBlock extends StatelessWidget {
  final String pageName;
  final VoidCallback? onRetry;

  const OfflinePageBlock({
    super.key,
    required this.pageName,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.cloud_off_rounded,
                size: 80,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 24),
              Text(
                'Нет подключения',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[700],
                    ),
              ),
              const SizedBox(height: 12),
              Text(
                'Страница "$pageName" недоступна без интернета.\n\nДля просмотра бронирований перейдите в раздел «Брони» — там доступны кэшированные данные.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600], fontSize: 15),
              ),
              const SizedBox(height: 32),
              if (onRetry != null)
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Повторить'),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
