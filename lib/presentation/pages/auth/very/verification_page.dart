import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:restauran/presentation/widgets/result_diolog.dart';
import 'package:restauran/theme/app_colors.dart';
import '../../../../../../data/services/abstract/abstract_auth_services.dart';
import '../../../../data/services/service_locator.dart';
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
  final PinInputController _otpController = PinInputController();
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
          surfaceTintColor: AppColors.surface,
          // title: const Text('Подтверждение номера'),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios),
            onPressed: () => Navigator.of(context).pop(),
          ),
          backgroundColor: AppColors.surface,
        ),
        backgroundColor: AppColors.surface,
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16.0, 130, 16.0, 170),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
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
                        LayoutBuilder(
                          builder: (context, constraints) {
                            final cellWidth = (constraints.maxWidth - 40) / 6;
                            return MaterialPinField(
                              length: 6,
                              pinController: _otpController,
                              theme: MaterialPinTheme(
                                shape: MaterialPinShape.filled,
                                cellSize: Size(cellWidth, 56),
                                spacing: 8,
                                borderRadius: BorderRadius.circular(8),
                                fillColor: AppColors.surface,
                                focusedFillColor: Colors.white,
                                borderColor: Colors.grey.withOpacity(0.3),
                                focusedBorderColor: Colors.grey
                                    .withOpacity(0.6), // чуть ярче при фокусе
                                filledBorderColor: Colors.grey.withOpacity(0.3),
                              ),
                              onCompleted: (_) => _verifyOtp(),
                            );
                          },
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
                                            child: CircularProgressIndicator
                                                .adaptive(
                                              valueColor:
                                                  AlwaysStoppedAnimation<Color>(
                                                Colors.white,
                                              ),
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
        ),
      ),
    );
  }
}
