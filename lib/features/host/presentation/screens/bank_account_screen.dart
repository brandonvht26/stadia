import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
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
        _accountNumberController.text = provider.accountNumber;
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
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                onChanged: provider.setAccountNumber,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el número de cuenta';
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
                onChanged: provider.setBankName,
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Ingresa el nombre del banco';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),
              
              DropdownButtonFormField<String>(
                value: provider.accountType.isEmpty ? 'savings' : provider.accountType,
                decoration: const InputDecoration(
                  labelText: 'Tipo de cuenta',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.account_balance_wallet),
                ),
                items: const [
                  DropdownMenuItem(value: 'savings', child: Text('Cuenta de Ahorros')),
                  DropdownMenuItem(value: 'checking', child: Text('Cuenta Corriente')),
                ],
                onChanged: (value) {
                  if (value != null) provider.setAccountType(value);
                },
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
