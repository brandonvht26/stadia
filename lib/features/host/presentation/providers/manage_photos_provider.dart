import 'dart:io';
import 'package:flutter/material.dart';
import '../../domain/entities/reception_photo_entity.dart';
import '../../data/repositories/host_repository_impl.dart';

class ManagePhotosProvider extends ChangeNotifier {
  final HostRepositoryImpl _repository;
  final String receptionId;
  
  ManagePhotosProvider(this._repository, this.receptionId);

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  bool _isSaving = false;
  bool get isSaving => _isSaving;

  String? _error;
  String? get error => _error;

  List<ReceptionPhotoEntity> _photos = [];
  List<ReceptionPhotoEntity> get photos => List.unmodifiable(_photos);

  Future<void> loadPhotos() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _photos = await _repository.getReceptionPhotos(receptionId);
    } catch (e) {
      _error = e.toString();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addPhoto(File file) async {
    if (_photos.length >= 5) {
      _error = 'Máximo 5 fotos por recepción.';
      notifyListeners();
      return;
    }
    
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final orderIndex = _photos.length;
      await _repository.uploadReceptionPhoto(receptionId, file, orderIndex);
      await loadPhotos();
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
    }
  }

  Future<void> reorderPhotos(int oldIndex, int newIndex) async {
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }
    
    final backup = List<ReceptionPhotoEntity>.from(_photos);
    
    final item = _photos.removeAt(oldIndex);
    _photos.insert(newIndex, item);
    notifyListeners();

    try {
      final newIds = _photos.map((p) => p.id).toList();
      await _repository.updatePhotoOrder(newIds);
    } catch (e) {
      _error = 'Error al reordenar: $e';
      _photos = backup;
      notifyListeners();
    }
  }

  Future<void> deletePhoto(int index) async {
    _isSaving = true;
    _error = null;
    notifyListeners();

    try {
      final photo = _photos[index];
      
      final urlParts = photo.mediaUrl.split('reception-photos/');
      if (urlParts.length < 2) {
        throw Exception('URL de imagen inválida');
      }
      var relativePath = urlParts[1];
      if (relativePath.contains('?')) {
        relativePath = relativePath.split('?')[0];
      }
      
      await _repository.deleteReceptionPhoto(photo.id, relativePath);
      
      _photos.removeAt(index);
      
      final newIds = _photos.map((p) => p.id).toList();
      await _repository.updatePhotoOrder(newIds);
      
      await loadPhotos();
    } catch (e) {
      _error = e.toString();
      _isSaving = false;
      notifyListeners();
    }
  }
}
