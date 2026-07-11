import 'package:geolocator/geolocator.dart';

// Servicio Core para el manejo de ubicación.
// Aislado del feature Discovery para poder ser reutilizado por el resto del proyecto.

class LocationService {
  /// Retorna la posición actual del usuario.
  /// Maneja todo el flujo de verificación de servicios de ubicación y permisos.
  /// Si el usuario deniega el permiso permanentemente, o si el GPS está apagado, retorna null.
  Future<Position?> getCurrentPosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // 1. Verificar si el servicio de GPS del dispositivo está habilitado
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Los servicios de ubicación están deshabilitados.
      return null;
    }

    // 2. Verificar el estado actual de los permisos
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Si están denegados, solicitar el permiso
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Los permisos fueron denegados nuevamente
        return null;
      }
    }
    
    if (permission == LocationPermission.deniedForever) {
      // Permisos denegados permanentemente, no se puede pedir de nuevo.
      return null;
    } 

    // 3. Obtener la posición (solo se llega aquí si hay permisos)
    try {
      return await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          distanceFilter: 10,
        ),
      );
    } catch (e) {
      return null;
    }
  }

  /// Calcula la distancia en kilómetros entre dos coordenadas.
  double calculateDistanceInKm(double startLat, double startLng, double endLat, double endLng) {
    final distanceInMeters = Geolocator.distanceBetween(startLat, startLng, endLat, endLng);
    return distanceInMeters / 1000.0;
  }
}
