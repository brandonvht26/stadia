import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:stadia/features/lobby/screens/lobby_screen.dart';
import 'package:stadia/features/auth/screens/register_screen.dart';
import 'package:stadia/features/auth/screens/reset_password_screen.dart';
import 'package:stadia/core/services/push_notification_service.dart';
import 'package:stadia/core/services/onboarding_service.dart';
import 'package:stadia/core/auth_gate.dart';
import 'package:stadia/features/onboarding/presentation/widgets/onboarding_background.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  
  bool _isLoading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final authResponse = await Supabase.instance.client.auth.signInWithPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      final user = authResponse.user;
      if (user != null) {
        // ignore: unawaited_futures
        OnboardingService.syncTermsAccepted(user.id).catchError((e) {
          debugPrint('Error al sincronizar términos (no crítico): $e');
        });
      }
      
      // Inicializar notificaciones push después de login exitoso sin bloquear la navegación
      // ignore: unawaited_futures
      PushNotificationService().initialize().catchError((e) {
        debugPrint('Error al inicializar push notifications (no crítico): $e');
      });

      if (authResponse.session != null) {
        if (mounted) {
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthGate()),
            (route) => false,
          );
        }
      }
    } on AuthException catch (e) {
      if (!mounted) return;
      String errorMessage = 'Ocurrió un error inesperado';
      if (e.message.contains('Invalid login credentials')) {
        errorMessage = 'Correo o contraseña incorrectos';
      } else {
        errorMessage = e.message;
      }
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(errorMessage),
          backgroundColor: Colors.black87,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ocurrió un error inesperado'),
          backgroundColor: Colors.black87,
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    // Colores para el efecto Glassmorfismo
    final glassColor = isDark ? Colors.white.withOpacity(0.08) : Colors.white.withOpacity(0.4);
    final glassBorder = isDark ? Colors.white.withOpacity(0.2) : Colors.white.withOpacity(0.6);
    final inputFill = isDark ? Colors.white.withOpacity(0.05) : Colors.white.withOpacity(0.5);

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: OnboardingBackground(
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(32),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                  child: Container(
                    padding: const EdgeInsets.all(32.0),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          glassColor,
                          glassColor.withOpacity(0.02),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: glassBorder, width: 1.5),
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          // Título de la app y pantalla
                          Text(
                            'STADIA',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                              fontWeight: FontWeight.w900,
                              letterSpacing: 4,
                              color: colorScheme.primary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'INICIAR SESIÓN',
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.5,
                              color: colorScheme.onSurface.withOpacity(0.8),
                            ),
                          ),
                          const SizedBox(height: 48),

                          // Input de Correo
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Correo electrónico',
                              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                              prefixIcon: Icon(Icons.email_outlined, color: colorScheme.onSurface.withOpacity(0.6)),
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Ingresa tu correo';
                              if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                                return 'Correo inválido';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 20),

                          // Input de Contraseña
                          TextFormField(
                            controller: _passwordController,
                            obscureText: _obscurePassword,
                            style: TextStyle(color: colorScheme.onSurface),
                            decoration: InputDecoration(
                              labelText: 'Contraseña',
                              labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.6)),
                              prefixIcon: Icon(Icons.lock_outline, color: colorScheme.onSurface.withOpacity(0.6)),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePassword ? Icons.visibility_off : Icons.visibility,
                                  color: colorScheme.onSurface.withOpacity(0.6),
                                ),
                                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                              ),
                              filled: true,
                              fillColor: inputFill,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide.none,
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: BorderSide(color: colorScheme.primary.withOpacity(0.5), width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(vertical: 20),
                            ),
                            validator: (value) {
                              if (value == null || value.isEmpty) return 'Ingresa tu contraseña';
                              return null;
                            },
                          ),
                          
                          // Olvidaste la contraseña
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () {
                                Navigator.push(context, MaterialPageRoute(builder: (_) => const ResetPasswordScreen()));
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                                foregroundColor: colorScheme.primary,
                                textStyle: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                              ),
                              child: const Text('¿Olvidaste tu contraseña?'),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Botón de Inicio de sesión
                          SizedBox(
                            height: 56,
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : _login,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: colorScheme.primary,
                                foregroundColor: colorScheme.onPrimary,
                                elevation: 8,
                                shadowColor: colorScheme.primary.withOpacity(0.4),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(16),
                                ),
                              ),
                              child: _isLoading
                                  ? SizedBox(
                                      height: 24, width: 24,
                                      child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
                                    )
                                  : const Text(
                                      'INICIAR SESIÓN',
                                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, letterSpacing: 1),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 32),

                          // Registro
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text('¿No tienes cuenta?', style: TextStyle(color: colorScheme.onSurface.withOpacity(0.7))),
                              TextButton(
                                onPressed: () {
                                  Navigator.push(context, MaterialPageRoute(builder: (_) => const RegisterScreen()));
                                },
                                style: TextButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                  foregroundColor: colorScheme.primary,
                                ),
                                child: const Text('Crear cuenta', style: TextStyle(fontWeight: FontWeight.bold)),
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
          ),
        ),
      ),
    );
  }
}
