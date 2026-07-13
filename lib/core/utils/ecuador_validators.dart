bool esCedulaValida(String cedula) {
  if (cedula.length != 10) return false;
  
  // Convertir string a lista de enteros
  final digitos = [];
  for (int i = 0; i < cedula.length; i++) {
    final digito = int.tryParse(cedula[i]);
    if (digito == null) return false; // si hay algún carácter no numérico
    digitos.add(digito);
  }
  
  final provincia = int.parse(cedula.substring(0, 2));
  if (provincia < 1 || (provincia > 24 && provincia != 30)) return false;
  
  final tercerDigito = digitos[2];
  if (tercerDigito >= 6) return false; // debe ser 0-5 para personas naturales
  
  final coeficientes = [2, 1, 2, 1, 2, 1, 2, 1, 2];
  int suma = 0;
  for (int i = 0; i < 9; i++) {
    int valor = digitos[i] * coeficientes[i];
    if (valor >= 10) valor -= 9;
    suma += valor;
  }
  
  final digitoVerificador = digitos[9];
  final residuo = suma % 10;
  final resultado = residuo == 0 ? 0 : 10 - residuo;
  
  return resultado == digitoVerificador;
}
