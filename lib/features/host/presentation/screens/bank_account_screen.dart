import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/utils/card_number_formatter.dart';
import '../../data/repositories/host_repository_impl.dart';
import '../providers/bank_account_provider.dart';

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

  Widget _buildAccountTypeOption(BankAccountProvider provider, String value, String label) {
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
          color: isSelected ? AppColors.primary.withOpacity(0.12) : AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isSelected ? AppColors.primary : Colors.black.withOpacity(0.08),
            width: isSelected ? 1.5 : 1.0,
          ),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            color: isSelected ? AppColors.primary : AppColors.textSecondary,
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

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<BankAccountProvider>();

    if (!_initialized || provider.isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Datos Bancarios')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Datos Bancarios'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Ingresa tus datos bancarios para recibir los pagos de tus reservas.',
                style: TextStyle(fontSize: 16),
              ),
              const SizedBox(height: 24),
              
              TextFormField(
                controller: _accountNumberController,
                decoration: const InputDecoration(
                  labelText: 'Número de cuenta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.numbers),
                ),
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
                decoration: const InputDecoration(
                  labelText: 'Nombre del banco',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance),
                ),
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
              const SizedBox(height: 16),
              
              const Padding(
                padding: EdgeInsets.only(left: 4, bottom: 8),
                child: Text(
                  'Tipo de cuenta',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
              ),
              Row(
                children: [
                  Expanded(child: _buildAccountTypeOption(provider, 'savings', 'Cuenta de Ahorros')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildAccountTypeOption(provider, 'checking', 'Cuenta Corriente')),
                ],
              ),
              
              const SizedBox(height: 12),
              
              Row(
                children: [
                  const Icon(Icons.lock, size: 14, color: Colors.grey),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Tu información bancaria está protegida y solo tú puedes verla.',
                      style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
              
              if (provider.error != null) ...[
                const SizedBox(height: 16),
                Text(
                  provider.error!,
                  style: const TextStyle(color: Colors.red),
                ),
              ],
              
              const SizedBox(height: 32),
              
              SizedBox(
                height: 50,
                child: FilledButton(
                  onPressed: provider.isSaving ? null : _submit,
                  child: provider.isSaving
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Guardar datos bancarios'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
