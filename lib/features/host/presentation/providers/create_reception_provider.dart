import 'dart:io';
import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart';
import '../../domain/entities/new_reception_entity.dart';
import '../../domain/entities/new_service_entity.dart';
import '../../domain/repositories/host_repository.dart';

class CreateReceptionProvider extends ChangeNotifier {
  final HostRepository _repository;

  CreateReceptionProvider(this._repository);

  String title = '';
  String description = '';
  double? basePrice;
  LatLng? selectedLocation;

  final List<NewServiceEntity> _services = [];
  List<NewServiceEntity> get services => List.unmodifiable(_services);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _statusText;
  String? get statusText => _statusText;

  String? _error;
  String? get error => _error;

  final List<File> _pendingPhotos = [];
  List<File> get pendingPhotos => List.unmodifiable(_pendingPhotos);

  void addPhoto(File file) {
    _pendingPhotos.add(file);
    notifyListeners();
  }

  void removePhoto(int index) {
    _pendingPhotos.removeAt(index);
    notifyListeners();
  }

  void reorderPhotos(int oldIndex, int newIndex) {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    final item = _pendingPhotos.removeAt(oldIndex);
    _pendingPhotos.insert(newIndex, item);
    notifyListeners();
  }

  void setTitle(String value) {
    title = value;
    notifyListeners();
  }

  void setDescription(String value) {
    description = value;
    notifyListeners();
  }

  void setBasePrice(double value) {
    basePrice = value;
    notifyListeners();
  }

  void setLocation(LatLng location) {
    selectedLocation = location;
    notifyListeners();
  }

  void addService(String name, double price) {
    _services.add(NewServiceEntity(name: name, price: price));
    notifyListeners();
  }

  void removeService(int index) {
    _services.removeAt(index);
    notifyListeners();
  }

  Future<String?> submit() async {
    if (title.trim().isEmpty || basePrice == null || selectedLocation == null) {
      _error = 'Por favor completa todos los campos requeridos y selecciona una ubicación.';
      notifyListeners();
      return null;
    }

    _isLoading = true;
    _error = null;
    _statusText = 'Creando recepción...';
    notifyListeners();

    try {
      final newReception = NewReceptionEntity(
        title: title.trim(),
        description: description.trim(),
        basePrice: basePrice!,
        latitude: selectedLocation!.latitude,
        longitude: selectedLocation!.longitude,
        services: _services,
      );

      final receptionId = await _repository.createReception(newReception);
      
      if (_services.isNotEmpty) {
        await _repository.addServicesToReception(receptionId, _services);
      }

      if (_pendingPhotos.isNotEmpty) {
        _statusText = 'Subiendo fotos...';
        notifyListeners();
        await _uploadPendingPhotos(receptionId);
      }

      _isLoading = false;
      _statusText = null;
      notifyListeners();
      return receptionId;
    } catch (e) {
      _error = e.toString();
      _isLoading = false;
      _statusText = null;
      notifyListeners();
      return null;
    }
  }

  Future<void> _uploadPendingPhotos(String receptionId) async {
    // Si falla la subida de fotos, no hacemos rollback de la recepción creada.
    // Queda a documentar y/o posteriormente agregar mecanismo de reintento.
    try {
      for (int i = 0; i < _pendingPhotos.length; i++) {
        await _repository.uploadReceptionPhoto(receptionId, _pendingPhotos[i], i);
      }
    } catch (e) {
      // TODO: Implementar mecanismo de reintento en caso de fallo parcial o total
      throw Exception('La recepción fue creada, pero hubo un error al subir las fotos: $e');
    }
  }
}
