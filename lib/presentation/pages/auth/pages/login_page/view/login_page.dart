import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/pages/auth/pages/register_page/view/register_page.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import '../../../../../widgets/custom_text_field.dart';
import '../../../../admin/view/admin_panel_page.dart';
import '../../../../customer/page/home_page/view/home_page.dart';
import '../../../../seller/page/seller_dashboard/view/seller_dashboard_page.dart';
import '../cubit/login_cubit.dart';
import '../cubit/login_state.dart';

class LoginPage extends StatelessWidget {
  const LoginPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit()..checkCurrentSession(),
      child: const LoginView(),
    );
  }
}

class LoginView extends StatefulWidget {
  const LoginView({super.key});

  @override
  State<LoginView> createState() => _LoginViewState();
}

class _LoginViewState extends State<LoginView> {
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  @override
  void initState() {
    super.initState();
    _phoneController.text = '+7 ';
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _navigateToPage(String role) {
    Widget page;

    if (role.toLowerCase() == 'admin') {
      page = const AdminPanelPage();
    } else if (role.toLowerCase() == 'seller') {
      page = const SellerDashboardPage();
    } else {
      page = const HomePage();
    }

    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (context) => page),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          _navigateToPage(state.role);
        } else if (state is AuthError) {
          showResultDialog(
            context: context,
            isSuccess: false,
            title: 'Ошибка',
            message:
                'Неверный номер телефона или пароль,может быть слабое соединение. Попробуйте еще раз.',
          );
          debugPrint('Auth Error: ${state.message}');
        }
      },
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Center(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'С возвращением!',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Войдите с помощью номера телефона и пароля',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 48),
                    CustomTextField(
                      controller: _phoneController,
                      hintText: '+7 777 777 77 77',
                      prefixIcon: Icons.phone,
                      keyboardType: TextInputType.phone,
                      isPhoneNumber: true,
                    ),
                    const SizedBox(height: 16),
                    CustomTextField(
                      controller: _passwordController,
                      hintText: 'Пароль',
                      prefixIcon: Icons.lock_outline,
                      obscureText: _obscurePassword,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword
                              ? Icons.visibility
                              : Icons.visibility_off,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return SizedBox(
                          width: double.infinity,
                          child: ElevatedButton(
                            onPressed: isLoading
                                ? null
                                : () {
                                    if (_phoneController.text.isEmpty ||
                                        _passwordController.text.isEmpty) {
                                      showResultDialog(
                                        context: context,
                                        isSuccess: false,
                                        title: 'Ошибка',
                                        message:
                                            'Введите номер телефона и пароль',
                                      );
                                      return;
                                    }
                                    context
                                        .read<AuthCubit>()
                                        .signInWithPhoneAndPassword(
                                          phone: _phoneController.text,
                                          password: _passwordController.text,
                                        );
                                  },
                            child: isLoading
                                ? const CircularProgressIndicator(
                                    color: Colors.white)
                                : const Text('Войти'),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text('Нет аккаунта?'),
                        TextButton(
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (context) => const RegisterPage(),
                              ),
                            );
                          },
                          child: const Text('Зарегистрироваться'),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
