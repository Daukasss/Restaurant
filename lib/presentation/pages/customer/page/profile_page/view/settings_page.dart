import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../widgets/profile_menu_tile.dart';
import '../bloc/profil_bloc.dart';
import '../bloc/profil_event.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  // Локальные переключатели (UI). Подключите к своему хранилищу при необходимости.
  bool _pushNotifications = true;
  bool _emailNotifications = false;

  @override
  Widget build(BuildContext context) {
    final bloc = context.read<ProfileBloc>();

    return Scaffold(
      backgroundColor: AppColors.surface,
      appBar: AppBar(
        backgroundColor: AppColors.surface,
        elevation: 0,
        scrolledUnderElevation: 0,
        iconTheme: const IconThemeData(color: AppColors.textMain),
        title: const Text(
          'Настройки',
          style: TextStyle(
            color: AppColors.textMain,
            fontWeight: FontWeight.w700,
            fontSize: 18,
          ),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 32),
        children: [
          // --- Уведомления
          ProfileMenuGroup(
            label: 'Уведомления',
            children: [
              ProfileMenuTile(
                icon: Icons.notifications_none_rounded,
                title: 'Push-уведомления',
                // subtitle: 'Напоминания о бронированиях',

                trailing: Transform.scale(
                  scale: 0.9,
                  child: Switch(
                    value: _pushNotifications,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _pushNotifications = v),
                  ),
                ),
                onTap: () =>
                    setState(() => _pushNotifications = !_pushNotifications),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Предпочтения
          ProfileMenuGroup(
            label: 'Предпочтения',
            children: [
              ProfileMenuTile(
                icon: Icons.language_outlined,
                title: 'Язык',
                subtitle: 'Русский',
                onTap: () => _soon(context),
              ),
              ProfileMenuTile(
                icon: Icons.dark_mode_outlined,
                title: 'Тема',
                subtitle: 'Светлая',
                onTap: () => _soon(context),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // --- Аккаунт
          ProfileMenuGroup(
            label: 'Аккаунт',
            children: [
              ProfileMenuTile(
                icon: Icons.logout_rounded,
                title: 'Выйти из аккаунта',
                onTap: () => _confirmSignOut(context, bloc),
              ),
              ProfileMenuTile(
                icon: Icons.delete_outline_rounded,
                title: 'Удалить аккаунт',
                // subtitle: 'Безвозвратное удаление данных',
                iconColor: AppColors.danger,
                titleColor: AppColors.danger,
                onTap: () => _confirmDelete(context, bloc),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _soon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Скоро будет доступно')),
    );
  }

  void _confirmSignOut(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Выйти из аккаунта?',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.textMain,
              fontSize: 17),
        ),
        content: const Text(
          'Вы сможете войти снова в любой момент.',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(SignOut());
            },
            child: const Text('Выйти'),
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, ProfileBloc bloc) {
    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
        title: const Text(
          'Удалить аккаунт?',
          style: TextStyle(
              fontWeight: FontWeight.w700,
              color: AppColors.danger,
              fontSize: 17),
        ),
        content: const Text(
          'Все данные будут удалены безвозвратно. Это действие нельзя отменить.',
          style: TextStyle(fontSize: 14, color: AppColors.textSub),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Отмена',
                style: TextStyle(color: AppColors.textSub)),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.danger,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10)),
            ),
            onPressed: () {
              Navigator.pop(dialogContext);
              bloc.add(DeleteAccount());
            },
            child: const Text('Удалить'),
          ),
        ],
      ),
    );
  }
}
