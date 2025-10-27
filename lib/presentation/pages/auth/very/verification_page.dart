import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import '../../../../../../data/services/abstract/abstract_auth_services.dart';
import '../../../../../../data/services/service_lacator.dart';
import '../../admin/view/admin_panel_page.dart';
import '../../customer/page/home_page/view/home_page.dart';
import '../../seller/page/seller_dashboard/view/seller_dashboard_page.dart';
import '../pages/login_page/cubit/login_cubit.dart';
import '../pages/login_page/cubit/login_state.dart';

class VerificationPage extends StatelessWidget {
  final String phone;
  final String password;
  final String? name;

  const VerificationPage({
    super.key,
    required this.phone,
    required this.password,
    this.name,
  });

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => AuthCubit(
        authService: getIt<AbstractAuthServices>(),
      ),
      child: VerificationView(
        phone: phone,
        password: password,
        name: name,
      ),
    );
  }
}

class VerificationView extends StatefulWidget {
  final String phone;
  final String password;
  final String? name;

  const VerificationView({
    super.key,
    required this.phone,
    required this.password,
    required this.name,
  });

  @override
  State<VerificationView> createState() => _VerificationViewState();
}

class _VerificationViewState extends State<VerificationView> {
  final TextEditingController _otpController = TextEditingController();
  Timer? _resendTimer;
  bool _isResendEnabled = false;
  int _resendCountdown = 60;
  bool _isDisposed = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _startResendTimer();
    });
  }

  @override
  void dispose() {
    _isDisposed = true;
    _resendTimer?.cancel();
    _resendTimer = null;
    try {
      _otpController.dispose();
    } catch (e) {
      // Controller already disposed, ignore
    }
    super.dispose();
  }

  void _startResendTimer() {
    setState(() {
      _resendCountdown = 60;
      _isResendEnabled = false;
    });

    _resendTimer?.cancel();

    _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (_isDisposed || !mounted) {
        timer.cancel();
        return;
      }

      setState(() {
        if (_resendCountdown > 0) {
          _resendCountdown--;
        } else {
          _isResendEnabled = true;
          timer.cancel();
        }
      });
    });
  }

  void _sendOtp() {
    context.read<AuthCubit>().sendOtp(phone: widget.phone);
  }

  void _verifyOtp() {
    context.read<AuthCubit>().verifyOtpAndRegister(
          phone: widget.phone,
          token: _otpController.text,
          password: widget.password,
          name: widget.name,
        );
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
        if (state is AuthOtpSent) {
          showResultDialog(
            context: context,
            isSuccess: true,
            title: 'Код отправлен',
            message: 'Код подтверждения отправлен на номер ${widget.phone}',
          );
        } else if (state is AuthAuthenticated) {
          _navigateToPage(state.role);
        } else if (state is AuthError) {
          showResultDialog(
            context: context,
            isSuccess: false,
            title: 'Ошибка',
            message: state.message,
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Подтверждение номера'),
        ),
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
                      'Завершите регистрацию',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Введите код, отправленный на номер ${widget.phone}',
                      style: const TextStyle(
                        fontSize: 16,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 32),
                    PinCodeTextField(
                      appContext: context,
                      length: 6,
                      controller: _otpController,
                      pinTheme: PinTheme(
                        shape: PinCodeFieldShape.box,
                        borderRadius: BorderRadius.circular(8),
                        fieldHeight: 50,
                        fieldWidth: 40,
                        activeFillColor: Colors.white,
                        inactiveFillColor: Colors.white,
                        selectedFillColor: Colors.white,
                        activeColor: Theme.of(context).primaryColor,
                        inactiveColor: Colors.grey,
                        selectedColor: Theme.of(context).primaryColor,
                      ),
                      keyboardType: TextInputType.number,
                      enableActiveFill: true,
                      onCompleted: (value) {
                        _verifyOtp();
                      },
                      onChanged: (value) {},
                    ),
                    const SizedBox(height: 24),
                    BlocBuilder<AuthCubit, AuthState>(
                      builder: (context, state) {
                        final isLoading = state is AuthLoading;
                        return Column(
                          children: [
                            SizedBox(
                              width: double.infinity,
                              child: ElevatedButton(
                                onPressed: isLoading ? null : _verifyOtp,
                                child: isLoading
                                    ? const SizedBox(
                                        width: 24,
                                        height: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2,
                                        ),
                                      )
                                    : const Text('Подтвердить'),
                              ),
                            ),
                            const SizedBox(height: 16),
                            TextButton(
                              onPressed: _isResendEnabled && !isLoading
                                  ? () {
                                      _sendOtp();
                                      _startResendTimer();
                                    }
                                  : null,
                              child: Text(
                                _isResendEnabled
                                    ? 'Отправить код повторно'
                                    : 'Отправить повторно через $_resendCountdown сек',
                              ),
                            ),
                          ],
                        );
                      },
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
