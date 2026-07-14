import 'dart:io';
import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:stadia/core/utils/ecuador_validators.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:stadia/core/providers/user_provider.dart';
import 'package:stadia/core/widgets/protected_route.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

// TODO: Refactorizar paddings fijos a AppSpacing.scaled(context, AppSpacing.md) cuando se generalice el escalado a todo el proyecto.

class PersonalDataScreen extends StatefulWidget {
  const PersonalDataScreen({super.key});

  @override
  State<PersonalDataScreen> createState() => _PersonalDataScreenState();
}

class _PersonalDataScreenState extends State<PersonalDataScreen> {
  final _formKey = GlobalKey<FormState>();
  final _firstNameController = TextEditingController();
  final _lastNameController = TextEditingController();
  final _bioController = TextEditingController();
  final _phoneController = TextEditingController();
  final _cedulaController = TextEditingController();

  bool _isSaving = false;
  bool _initialized = false;
  bool _isUploadingAvatar = false;

  @override
  void dispose() {
    _firstNameController.dispose();
    _lastNameController.dispose();
    _bioController.dispose();
    _phoneController.dispose();
    _cedulaController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile == null) return;

    final file = File(pickedFile.path);

    setState(() {
      _isUploadingAvatar = true;
    });

    try {
      final userId = Supabase.instance.client.auth.currentUser!.id;
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filePath = '$userId/avatar_$timestamp.jpg';

      await Supabase.instance.client.storage
          .from('avatars')
          .upload(
            filePath,
            file,
            fileOptions: const FileOptions(upsert: true),
          );

      final publicUrl = Supabase.instance.client.storage
          .from('avatars')
          .getPublicUrl(filePath);

      final newAvatarUrl = publicUrl;

      if (mounted) {
        await context.read<UserProvider>().updateProfile({'avatar_url': newAvatarUrl});
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Avatar actualizado correctamente'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al actualizar avatar'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isUploadingAvatar = false;
        });
      }
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final updates = {
        'first_name': _firstNameController.text.trim(),
        'last_name': _lastNameController.text.trim(),
        'bio': _bioController.text.trim(),
        'phone': _phoneController.text.trim(),
        'cedula': _cedulaController.text.trim(),
      };

      await context.read<UserProvider>().updateProfile(updates);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Perfil actualizado'),
            backgroundColor: Colors.black87,
          ),
        );
        Navigator.pop(context); // Volver después de guardar
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error al guardar los cambios'),
            backgroundColor: Colors.black87,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      filled: true,
      fillColor: colorScheme.surface.withOpacity(0.5),
      labelStyle: TextStyle(color: colorScheme.onSurface.withOpacity(0.7)),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.outlineVariant.withOpacity(0.5)),
        borderRadius: BorderRadius.circular(12),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error),
        borderRadius: BorderRadius.circular(12),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: BorderSide(color: colorScheme.error, width: 2),
        borderRadius: BorderRadius.circular(12),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final profile = userProvider.profile;
    final colorScheme = Theme.of(context).colorScheme;

    if (userProvider.isLoading || profile == null) {
      return const ProtectedRoute(
        child: OnboardingBackground(
          child: Scaffold(
            backgroundColor: Colors.transparent,
            appBar: null,
            body: Center(
              child: CircularProgressIndicator(),
            ),
          ),
        ),
      );
    }

    if (!_initialized) {
      _firstNameController.text = profile['first_name'] ?? '';
      _lastNameController.text = profile['last_name'] ?? '';
      _bioController.text = profile['bio'] ?? '';
      _phoneController.text = profile['phone'] ?? '';
      _cedulaController.text = profile['cedula'] ?? '';
      _initialized = true;
    }

    final avatarUrl = profile['avatar_url'] as String?;

    return ProtectedRoute(
      child: OnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: AppBar(
            backgroundColor: Colors.transparent,
            elevation: 0,
            title: const Text('Datos Personales', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  padding: const EdgeInsets.all(24.0),
                  decoration: BoxDecoration(
                    color: Color.alphaBlend(
                      colorScheme.primary.withOpacity(0.1),
                      colorScheme.surface.withOpacity(0.85),
                    ),
                    border: Border.all(color: colorScheme.primary.withOpacity(0.1)),
                  ),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      children: [
                        Stack(
                          alignment: Alignment.bottomRight,
                          children: [
                            ClipOval(
                              child: Container(
                                width: 100,
                                height: 100,
                                color: colorScheme.surface.withOpacity(0.5),
                                child: avatarUrl != null && avatarUrl.isNotEmpty
                                    ? Image.network(
                                        avatarUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) {
                                          return Icon(Icons.person, size: 50, color: colorScheme.onSurface.withOpacity(0.5));
                                        },
                                      )
                                    : Icon(
                                        Icons.person,
                                        size: 50,
                                        color: colorScheme.onSurface.withOpacity(0.5),
                                      ),
                              ),
                            ),
                            if (_isUploadingAvatar)
                              const Positioned.fill(
                                child: CircularProgressIndicator(),
                              ),
                            Container(
                              decoration: BoxDecoration(
                                color: colorScheme.primary,
                                shape: BoxShape.circle,
                              ),
                              child: IconButton(
                                icon: Icon(Icons.camera_alt, color: colorScheme.onPrimary, size: 20),
                                onPressed: _isUploadingAvatar ? null : _pickAndUploadImage,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _firstNameController,
                          decoration: _buildInputDecoration('Nombre', colorScheme),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿñÑ ]'))],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Este campo es requerido';
                            if (!RegExp(r'^[a-zA-ZÀ-ÿñÑ ]+$').hasMatch(value)) return 'Solo se permiten letras';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _lastNameController,
                          decoration: _buildInputDecoration('Apellido', colorScheme),
                          inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿñÑ ]'))],
                          validator: (value) {
                            if (value == null || value.trim().isEmpty) return 'Este campo es requerido';
                            if (!RegExp(r'^[a-zA-ZÀ-ÿñÑ ]+$').hasMatch(value)) return 'Solo se permiten letras';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _phoneController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration('Teléfono', colorScheme),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || value.length != 10) return 'El teléfono debe tener 10 dígitos';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _cedulaController,
                          keyboardType: TextInputType.number,
                          decoration: _buildInputDecoration('Cédula', colorScheme),
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                            LengthLimitingTextInputFormatter(10),
                          ],
                          validator: (value) {
                            if (value == null || !esCedulaValida(value)) return 'Cédula inválida';
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _bioController,
                          maxLines: 3,
                          maxLength: 50,
                          decoration: _buildInputDecoration('Biografía', colorScheme),
                          inputFormatters: [LengthLimitingTextInputFormatter(50)],
                          validator: (value) {
                            if (value != null && value.length > 50) return 'Máximo 50 caracteres';
                            return null;
                          },
                        ),
                        const SizedBox(height: 32),
                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveChanges,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: colorScheme.primary,
                              foregroundColor: colorScheme.onPrimary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? SizedBox(
                                    height: 24,
                                    width: 24,
                                    child: CircularProgressIndicator(
                                      color: colorScheme.onPrimary,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Guardar cambios',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      letterSpacing: 0.5,
                                    ),
                                  ),
                          ),
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
