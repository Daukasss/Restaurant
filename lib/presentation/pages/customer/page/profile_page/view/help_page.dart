import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher_string.dart';
import 'package:restauran/theme/app_colors.dart';

class HelpPage extends StatelessWidget {
  const HelpPage({super.key});

  // TODO: замените на реальные контакты
  static const String _supportEmail = 'support@restauran.app';
  static const String _supportTelegram = 'https://t.me/restauran_support';
  static const String _supportWhatsApp = 'https://wa.me/77001234567';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        title: const Text(
          'Помощь',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 40),
        children: [
          // ─── Приветствие
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.06),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.support_agent_rounded,
                    color: AppColors.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Служба поддержки',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textMain,
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Ответим в течение 24 часов',
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSub,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── Контакты
          _SectionLabel('Связаться с нами'),
          const SizedBox(height: 10),
          _ContactGroup(
            children: [
              _ContactTile(
                icon: Icons.email_outlined,
                iconColor: AppColors.primary,
                title: 'Написать на email',
                // subtitle: _supportEmail,
                onTap: () => launchUrlString('mailto:$_supportEmail'),
                onLongPress: () {
                  Clipboard.setData(const ClipboardData(text: _supportEmail));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Email скопирован'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                },
              ),
              _ContactTile(
                icon: Icons.send_rounded,
                iconColor: const Color(0xFF229ED9),
                title: 'Telegram',
                // subtitle: '@restauran_support',
                onTap: () => launchUrlString(_supportTelegram),
              ),
              _ContactTile(
                icon: Icons.chat_bubble_outline_rounded,
                iconColor: const Color(0xFF25D366),
                title: 'WhatsApp',
                // subtitle: '+7 700 123-45-67',
                onTap: () => launchUrlString(_supportWhatsApp),
              ),
            ],
          ),

          const SizedBox(height: 24),

          // ─── FAQ
          _SectionLabel('Частые вопросы'),
          const SizedBox(height: 10),
          const _FaqItem(
            question: 'Как отменить бронирование?',
            answer:
                'Зайдите в «Мои бронирования», выберите нужную запись и нажмите «Удалить». '
                'Отмена доступна за 48 часов до даты.',
          ),
          const SizedBox(height: 8),
          const _FaqItem(
            question: 'Можно ли изменить дату или время?',
            answer: 'Да. Нажмите «Изменить» в карточке бронирования. '
                'Редактирование доступно за 48 часов до визита.',
          ),
          const SizedBox(height: 8),
          const _FaqItem(
            question: 'Как добавить ресторан в избранное?',
            answer:
                'На странице ресторана нажмите на иконку сердечка в правом верхнем углу. '
                'Заведение появится в разделе «Избранное».',
          ),
          const SizedBox(height: 8),
          const _FaqItem(
            question: 'Как зарегистрировать своё заведение?',
            answer: 'Свяжитесь с нашей командой через email или Telegram — '
                'мы подключим вас в течение 1 рабочего дня.',
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────
// Widgets
// ─────────────────────────────────────────────────────────
class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Text(
        text.toUpperCase(),
        style: const TextStyle(
          fontSize: 11,
          letterSpacing: 0.9,
          fontWeight: FontWeight.w700,
          color: AppColors.textSub,
        ),
      ),
    );
  }
}

class _ContactGroup extends StatelessWidget {
  final List<Widget> children;
  const _ContactGroup({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppColors.softShadow,
      ),
      child: Column(
        children: [
          for (int i = 0; i < children.length; i++) ...[
            children[i],
            if (i != children.length - 1)
              const Divider(
                height: 1,
                thickness: 1,
                indent: 60,
                endIndent: 0,
                color: AppColors.divider,
              ),
          ],
        ],
      ),
    );
  }
}

class _ContactTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final VoidCallback? onLongPress;

  const _ContactTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      onLongPress: onLongPress,
      borderRadius: BorderRadius.circular(18),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: iconColor.withOpacity(0.10),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textMain,
                    ),
                  ),
                  const SizedBox(height: 2),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSub,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_outward_rounded,
              color: AppColors.textSub.withOpacity(0.4),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String question;
  final String answer;

  const _FaqItem({required this.question, required this.answer});

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem>
    with SingleTickerProviderStateMixin {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      decoration: BoxDecoration(
        color: AppColors.cardBg,
        borderRadius: BorderRadius.circular(16),
        boxShadow: AppColors.softShadow,
      ),
      child: InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.question,
                      style: const TextStyle(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textMain,
                      ),
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: AppColors.textSub,
                      size: 22,
                    ),
                  ),
                ],
              ),
              if (_expanded) ...[
                const SizedBox(height: 10),
                Text(
                  widget.answer,
                  style: const TextStyle(
                    fontSize: 13.5,
                    color: AppColors.textSub,
                    height: 1.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
