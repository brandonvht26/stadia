import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/card_number_formatter.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../providers/bank_account_provider.dart';
import '../../../../features/onboarding/presentation/widgets/onboarding_background.dart';

class BankAccountScreen extends StatefulWidget {
  const BankAccountScreen({super.key});

  static Widget route() {
    return ChangeNotifierProvider(
      create: (_) => BankAccountProvider(HostRepositoryImpl()),
      child: const BankAccountScreen(),
    );
  }

  @override
  State<BankAccountScreen> createState() => _BankAccountScreenState();
}

class _BankAccountScreenState extends State<BankAccountScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _accountNumberController;
  late TextEditingController _bankNameController;
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _accountNumberController = TextEditingController();
    _bankNameController = TextEditingController();
    _loadData();
  }

  Future<void> _loadData() async {
    Future.microtask(() async {
      if (!mounted) return;
      final provider = context.read<BankAccountProvider>();
      final hasData = await provider.loadBankAccount();
      
      if (hasData && mounted) {
        _accountNumberController.text = CardNumberInputFormatter().formatEditUpdate(
          const TextEditingValue(),
          TextEditingValue(text: provider.accountNumber),
        ).text;
        _bankNameController.text = provider.bankName;
      }
      
      if (mounted) {
        setState(() {
          _initialized = true;
        });
      }
    });
  }

  @override
  void dispose() {
    _accountNumberController.dispose();
    _bankNameController.dispose();
    super.dispose();
  }

  Widget _buildAccountTypeOption(BankAccountProvider provider, String value, String label, ColorScheme colorScheme) {
    final currentType = provider.accountType.isEmpty ? 'savings' : provider.accountType;
    final isSelected = currentType == value;
    return GestureDetector(
      onTap: () {
        FocusScope.of(context).unfocus();
        provider.setAccountType(value);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: isSelected ? colorScheme.primary.withOpacity(0.12) : colorScheme.surface.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected ? colorScheme.primary : colorScheme.outlineVariant.withOpacity(0.5),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? colorScheme.primary : colorScheme.onSurface.withOpacity(0.7),
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
      ),
    );
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      final provider = context.read<BankAccountProvider>();
      final success = await provider.save();
      
      if (success && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Datos bancarios guardados correctamente.')),
        );
        Navigator.pop(context);
      }
    }
  }

  InputDecoration _buildInputDecoration(String label, IconData icon, ColorScheme colorScheme) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: colorScheme.onSurface.withOpacity(0.7)),
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
    final provider = context.watch<BankAccountProvider>();
    final colorScheme = Theme.of(context).colorScheme;

    if (!_initialized || provider.isLoading) {
      return const OnboardingBackground(
        child: Scaffold(
          backgroundColor: Colors.transparent,
          appBar: null,
          body: Center(child: CircularProgressIndicator()),
        ),
      );
    }

    return OnboardingBackground(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          elevation: 0,
          title: const Text('Datos Bancarios', style: TextStyle(fontWeight: FontWeight.bold)),
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
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Icon(Icons.account_balance_wallet, size: 48, color: colorScheme.primary.withOpacity(0.5)),
                      const SizedBox(height: 16),
                      Text(
                        'Ingresa tus datos bancarios para recibir los pagos de tus reservas.',
                        style: TextStyle(
                          fontSize: 16,
                          color: colorScheme.onSurface.withOpacity(0.8),
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 32),
                      
                      TextFormField(
                        controller: _accountNumberController,
                        decoration: _buildInputDecoration('Número de cuenta', Icons.numbers, colorScheme),
                        keyboardType: TextInputType.number,
                        inputFormatters: [
                          FilteringTextInputFormatter.digitsOnly,
                          CardNumberInputFormatter(),
                        ],
                        onChanged: (value) => provider.setAccountNumber(value.replaceAll(' ', '')),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el número de cuenta';
                          }
                          final noSpaces = value.replaceAll(' ', '');
                          if (noSpaces.length < 8 || noSpaces.length > 16) {
                            return 'Número de cuenta inválido';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      
                      TextFormField(
                        controller: _bankNameController,
                        decoration: _buildInputDecoration('Nombre del banco', Icons.account_balance, colorScheme),
                        inputFormatters: [
                          FilteringTextInputFormatter.allow(RegExp(r'[a-zA-ZÀ-ÿñÑ ]')),
                        ],
                        onChanged: provider.setBankName,
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Ingresa el nombre del banco';
                          }
                          if (!RegExp(r'^[a-zA-ZÀ-ÿñÑ ]+$').hasMatch(value)) {
                            return 'Solo se permiten letras';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 24),
                      
                      Padding(
                        padding: const EdgeInsets.only(left: 4, bottom: 8),
                        child: Text(
                          'Tipo de cuenta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.8),
                          ),
                        ),
                      ),
                      Row(
                        children: [
                          Expanded(child: _buildAccountTypeOption(provider, 'savings', 'Ahorros', colorScheme)),
                          const SizedBox(width: 12),
                          Expanded(child: _buildAccountTypeOption(provider, 'checking', 'Corriente', colorScheme)),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: colorScheme.surface.withOpacity(0.3),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: colorScheme.outlineVariant.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.lock, size: 16, color: colorScheme.onSurface.withOpacity(0.5)),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Tu información bancaria está protegida y solo tú puedes verla.',
                                style: TextStyle(fontSize: 12, color: colorScheme.onSurface.withOpacity(0.6)),
                              ),
                            ),
                          ],
                        ),
                      ),
                      
                      if (provider.error != null) ...[
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: TextStyle(color: colorScheme.error),
                          textAlign: TextAlign.center,
                        ),
                      ],
                      
                      const SizedBox(height: 32),
                      
                      SizedBox(
                        height: 52,
                        child: ElevatedButton(
                          onPressed: provider.isSaving ? null : _submit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: colorScheme.primary,
                            foregroundColor: colorScheme.onPrimary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: provider.isSaving
                              ? SizedBox(
                                  height: 24,
                                  width: 24,
                                  child: CircularProgressIndicator(color: colorScheme.onPrimary, strokeWidth: 2),
                                )
                              : const Text(
                                  'Guardar datos bancarios',
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
    );
  }
}
