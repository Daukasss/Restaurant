import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:restauran/presentation/widgets/custom_text_field.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../../../data/services/service_locator.dart';
import '../../../../../../data/services/abstract/abstract_auth_services.dart';
import '../../../very/verification_page.dart';
import '../cubit/register_cubit.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _phoneController = TextEditingController(text: '+7 ');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _agree = false;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> linkPolicy() async {
    final Uri _url = Uri.parse(
        'https://sites.google.com/view/policy-aqtoi/политика-конфиденциальности');
    if (!await launchUrl(_url, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $_url';
    }
  }

  void _navigateToVerification() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => VerificationPage(
          phone: _phoneController.text,
          password: _passwordController.text,
          name: _nameController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => RegisterCubit(getIt<AbstractAuthServices>()),
      child: BlocListener<RegisterCubit, RegisterState>(
        listener: (context, state) {
          if (state is RegisterOtpSent) {
            _navigateToVerification();
          } else if (state is RegisterError) {
            showResultDialog(
              context: context,
              isSuccess: false,
              title: 'Ошибка',
              message: state.error,
            );
          }
        },
        child: Scaffold(
          appBar: AppBar(title: const Text('Создать аккаунт')),
          body: Center(
            child: SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: SingleChildScrollView(
                  child: BlocBuilder<RegisterCubit, RegisterState>(
                    builder: (context, state) {
                      final isLoading = state is RegisterLoading;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Создать аккаунт',
                              style: TextStyle(
                                  fontSize: 32, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          const Text(
                              'Зарегистрируйтесь с помощью номера телефона',
                              style:
                                  TextStyle(fontSize: 16, color: Colors.grey)),
                          const SizedBox(height: 32),

                          CustomTextField(
                            hintText: 'Имя',
                            prefixIcon: Icons.person,
                            controller: _nameController,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _phoneController,
                            hintText: '+7 777 777 77 77',
                            prefixIcon: Icons.phone,
                            isPhoneNumber: true,
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _passwordController,
                            hintText: 'Пароль',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscurePassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(
                                  () => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                          const SizedBox(height: 16),
                          CustomTextField(
                            controller: _confirmPasswordController,
                            hintText: 'Подтвердите пароль',
                            prefixIcon: Icons.lock_outline,
                            obscureText: _obscureConfirmPassword,
                            suffixIcon: IconButton(
                              icon: Icon(_obscureConfirmPassword
                                  ? Icons.visibility
                                  : Icons.visibility_off),
                              onPressed: () => setState(() =>
                                  _obscureConfirmPassword =
                                      !_obscureConfirmPassword),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // ✅ Галочка согласия
                          Row(
                            children: [
                              Checkbox(
                                value: _agree,
                                onChanged: (value) {
                                  setState(() => _agree = value!);
                                },
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () {
                                    linkPolicy();
                                  },
                                  child: const Text.rich(
                                    TextSpan(
                                      text: 'Я согласен с ',
                                      children: [
                                        TextSpan(
                                          text: 'политикой конфиденциальности',
                                          style: TextStyle(
                                            color: Colors.blue,
                                            decoration:
                                                TextDecoration.underline,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),

                          const SizedBox(height: 8),

                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: !_agree || isLoading
                                  ? null
                                  : () {
                                      if (_phoneController.text.isEmpty ||
                                          _passwordController.text.isEmpty ||
                                          _confirmPasswordController
                                              .text.isEmpty ||
                                          _nameController.text.isEmpty) {
                                        showResultDialog(
                                          context: context,
                                          isSuccess: false,
                                          title: 'Ошибка',
                                          message: 'Заполните все поля',
                                        );
                                        return;
                                      }
                                      if (_passwordController.text !=
                                          _confirmPasswordController.text) {
                                        showResultDialog(
                                          context: context,
                                          isSuccess: false,
                                          title: 'Ошибка',
                                          message: 'Пароли не совпадают',
                                        );
                                        return;
                                      }
                                      context.read<RegisterCubit>().sendOtp(
                                          phone: _phoneController.text);
                                    },
                              child: isLoading
                                  ? const CircularProgressIndicator(
                                      color: Colors.white)
                                  : const Text('Отправить код'),
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
