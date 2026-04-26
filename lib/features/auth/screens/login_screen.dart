import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../models/auth_models.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final authService = AuthService();

  final emailController = TextEditingController();
  final passwordController = TextEditingController();

  bool loading = false;
  String errorMessage = '';

  Future<void> login() async {
    final email = emailController.text.trim();
    final password = passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => errorMessage = 'Completa correo y contraseña');
      return;
    }

    setState(() {
      loading = true;
      errorMessage = '';
    });

    try {
      await authService.login(
        LoginRequest(
          email: email,
          password: password,
        ),
      );

      if (!mounted) return;
      context.go('/home');
    } on DioException catch (error) {
      final data = error.response?.data;

      setState(() {
        errorMessage =
            data?['message'] ?? data?['error'] ?? 'Correo o contraseña incorrectos';
      });
    } catch (_) {
      setState(() {
        errorMessage = 'Error inesperado al iniciar sesión';
      });
    } finally {
      if (mounted) {
        setState(() => loading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Card(
            elevation: 0,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.account_tree, size: 56),
                  const SizedBox(height: 16),
                  const Text(
                    'Iniciar sesión',
                    style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 24),

                  TextField(
                    controller: emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      labelText: 'Correo',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextField(
                    controller: passwordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Contraseña',
                      border: OutlineInputBorder(),
                    ),
                  ),

                  if (errorMessage.isNotEmpty) ...[
                    const SizedBox(height: 14),
                    Text(
                      errorMessage,
                      style: const TextStyle(color: Colors.red),
                    ),
                  ],

                  const SizedBox(height: 20),

                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: FilledButton(
                      onPressed: loading ? null : login,
                      child: loading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Ingresar'),
                    ),
                  ),

                  TextButton(
                    onPressed: () => context.push('/register'),
                    child: const Text('Crear cuenta'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}