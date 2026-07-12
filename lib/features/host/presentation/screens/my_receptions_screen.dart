import 'package:flutter/material.dart';
import '../../../discovery/domain/entities/reception_entity.dart';
import '../../data/repositories/host_repository_impl.dart';
import 'create_reception_screen.dart';
import 'verification_payment_screen.dart';
import 'manage_photos_screen.dart';

class MyReceptionsScreen extends StatefulWidget {
  const MyReceptionsScreen({super.key});

  @override
  State<MyReceptionsScreen> createState() => _MyReceptionsScreenState();
}

class _MyReceptionsScreenState extends State<MyReceptionsScreen> {
  final HostRepositoryImpl _repository = HostRepositoryImpl();
  late Future<List<ReceptionEntity>> _receptionsFuture;

  @override
  void initState() {
    super.initState();
    _loadReceptions();
  }

  void _loadReceptions() {
    setState(() {
      _receptionsFuture = _repository.getMyReceptions();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Recepciones'),
      ),
      body: FutureBuilder<List<ReceptionEntity>>(
        future: _receptionsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final receptions = snapshot.data;
          if (receptions == null || receptions.isEmpty) {
            return const Center(
              child: Text('Aún no has publicado ninguna recepción.'),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: receptions.length,
            itemBuilder: (context, index) {
              final reception = receptions[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 16),
                child: ListTile(
                  title: Text(reception.title, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Precio base: \$${reception.basePrice.toStringAsFixed(2)}'),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (!reception.isVerified)
                            ElevatedButton(
                              onPressed: () async {
                                final result = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => VerificationPaymentScreen(receptionId: reception.id),
                                  ),
                                );
                                if (result == true) {
                                  _loadReceptions();
                                }
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                minimumSize: Size.zero,
                              ),
                              child: const Text('Verificar por \$20'),
                            ),
                          ElevatedButton.icon(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) => ManagePhotosScreen.route(receptionId: reception.id),
                                ),
                              );
                            },
                            icon: const Icon(Icons.photo_library, size: 18),
                            label: const Text('Gestionar fotos'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              minimumSize: Size.zero,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: reception.isVerified ? Colors.green.shade100 : Colors.grey.shade200,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      reception.isVerified ? 'Verificado' : 'No verificado',
                      style: TextStyle(
                        color: reception.isVerified ? Colors.green.shade800 : Colors.grey.shade800,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          final result = await Navigator.push(
            context,
            MaterialPageRoute(builder: (_) => const CreateReceptionScreen()),
          );
          if (result == true) {
            _loadReceptions();
          }
        },
        child: const Icon(Icons.add),
      ),
    );
  }
}
