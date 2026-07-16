# Stadia

Aplicación móvil desarrollada en Flutter que conecta anfitriones con usuarios para la reserva de espacios/servicios de recepción, con chat, pagos, reseñas y notificaciones push.

## Instalación

1. Clonar el repositorio
   ```bash
   git clone https://github.com/brandonvht26/stadia.git
   cd stadia
   ```

2. Instalar dependencias
   ```bash
   flutter pub get
   ```

## Configuración

### Base de datos (Supabase)

En el proyecto de Supabase se deben crear las tablas del esquema (`profiles`, `receptions`, `reception_media`, `favorites`, `reviews`, `services`, `reservations`, `reservation_services`, `host_payments`, `bank_accounts`, `chats`, `messages`, `device_tokens`), junto con sus relaciones, así como los triggers, funciones, políticas de RLS (Row Level Security) y buckets de storage necesarios para el funcionamiento de la app.

### Variables de entorno / claves necesarias

- `SUPABASE_URL`
- `SUPABASE_ANON_KEY`
- `STRIPE_PUBLISHABLE_KEY`
- `GOOGLE_API_KEY` (claves de Google usadas para el envío de correos vía Gmail; ya configuradas como secretos en Supabase)

### Notificaciones push (Firebase)

Se necesita el archivo `google-services.json` en `android/app/` (ya incluido en el repo).

### Mini backend (stadia-backend)

El proyecto incluye un mini backend independiente (`stadia-backend/`), desplegado en Vercel, encargado del envío de correos (verificación de cuenta y restablecimiento de contraseña) mediante `nodemailer`. Requiere sus propias variables de entorno:

- `EMAIL_USER`
- `EMAIL_PASS`

## Ejecución

Modo desarrollo:
```bash
flutter run
```

Build de producción:
```bash
flutter build apk --release
```

### Ejecutar el mini backend (opcional, solo para desarrollo local)

El backend ya está desplegado en Vercel, por lo que la app funciona sin necesidad de correrlo localmente. Solo es necesario si vas a modificarlo o probarlo en local:

```bash
cd stadia-backend
npm install
npm start
```
