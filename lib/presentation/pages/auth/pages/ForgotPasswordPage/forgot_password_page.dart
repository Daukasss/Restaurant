// // ignore_for_file: use_build_context_synchronously

// import 'package:flutter/material.dart';
// import 'package:restauran/data/services/abstract/abstract_auth_services.dart';
// import 'package:restauran/data/services/service_lacator.dart';
// import 'package:restauran/presentation/widgets/custom_text_field.dart';
// import 'package:restauran/presentation/widgets/result_diolog.dart';

// class ForgotPasswordPage extends StatefulWidget {
//   const ForgotPasswordPage({super.key});

//   @override
//   State<ForgotPasswordPage> createState() => _ForgotPasswordPageState();
// }

// class _ForgotPasswordPageState extends State<ForgotPasswordPage> {
//   final TextEditingController _emailController = TextEditingController();
//   final _formKey = GlobalKey<FormState>();
//   bool _isLoading = false;

//   Future<void> _resetPassword() async {
//     if (!_formKey.currentState!.validate()) return;

//     setState(() => _isLoading = true);

//     final authService = getIt<AbstractAuthServices>();

//     try {
//       await authService.resetPassword(_emailController.text);
//       showResultDialog(
//         context: context,
//         isSuccess: true,
//         title: 'Успешно!',
//         message: 'Письмо с восстановлением пароля отправлено на почту.',
//       );
//     } catch (e) {
//       showResultDialog(
//         context: context,
//         isSuccess: false,
//         title: 'Ошибка',
//         message: e.toString().replaceAll('Exception: ', ''),
//       );
//     } finally {
//       setState(() => _isLoading = false);
//     }
//   }

//   @override
//   void dispose() {
//     _emailController.dispose();
//     super.dispose();
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(title: const Text("Восстановление пароля")),
//       body: Padding(
//         padding: const EdgeInsets.all(24.0),
//         child: Form(
//           key: _formKey,
//           child: Column(
//             children: [
//               CustomTextField(
//                 controller: _emailController,
//                 hintText: 'Введите ваш Email',
//                 prefixIcon: Icons.email_outlined,
//                 keyboardType: TextInputType.emailAddress,
//                 validator: (value) {
//                   if (value == null || value.isEmpty) {
//                     return 'Введите Email';
//                   }
//                   return null;
//                 },
//               ),
//               const SizedBox(height: 20),
//               SizedBox(
//                 width: double.infinity,
//                 child: ElevatedButton(
//                   onPressed: _isLoading ? null : _resetPassword,
//                   child: _isLoading
//                       ? const CircularProgressIndicator(color: Colors.white)
//                       : const Text("Восстановить пароль"),
//                 ),
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
