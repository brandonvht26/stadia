# Planificación de Sprints: Proyecto Pitch Challenge - MVP Recepciones

Este documento contiene la estructura del proyecto dividida en Sprints (actualmente documentados hasta el inicio del Sprint 4). Cada módulo detalla las historias de usuario, la arquitectura de base de datos sugerida (Supabase) y los requerimientos técnicos necesarios para el desarrollo frontend y backend.

## Sprint 1: Módulo Universal (Autenticación y Perfiles)

**Objetivo:** Establecer los cimientos de la aplicación, gestionar el registro unificado y la personalización básica de perfiles.

### 1. Historias de Usuario

| ID | Historia de Usuario | Criterios de Aceptación (Definición de "Terminado") |
| :--- | :--- | :--- |
| **AUTH-01** | Como usuario nuevo, quiero registrarme usando mi correo electrónico para acceder a la app. | - Formulario con validación de formato de email.<br>- Integración exitosa con Supabase Auth.<br>- Creación automática del registro en la tabla pública de perfiles. |
| **AUTH-02** | Como usuario registrado, quiero iniciar y cerrar sesión de forma segura. | - Manejo de tokens de sesión persistentes.<br>- Redirección automática a la pantalla de login si el token expira.<br>- Botón funcional de "Cerrar Sesión". |
| **PROF-01** | Como usuario, quiero completar y editar mi perfil público. | - Opción para subir/actualizar foto usando Supabase Storage.<br>- Campos editables: Nombre, Apellido, Biografía, Teléfono. |
| **SET-01** | Como usuario, quiero personalizar la apariencia de mi aplicación. | - Selector de tema: Claro, Oscuro o Sistema.<br>- Guardado de preferencia de forma local en el dispositivo. |

### 2. Arquitectura de Datos Sugerida

- `auth.users`: Tabla interna gestionada por Supabase (UUID, email, password).
- `public.profiles`: id (FK referenciando auth.users), first_name, last_name, avatar_url, phone, role (por defecto: 'user'), theme_preference, created_at.

### 3. Requerimientos Técnicos

- Implementar un estado global (Context API, Zustand o Redux) para mantener la información del usuario autenticado en toda la app.
- Configurar rutas protegidas en la navegación móvil (si no hay sesión, obligar a ir a Login).

---

## Sprint 2: Módulo de Exploración "Discovery" (Feed TikTok/Tinder)

**Objetivo:** Crear la interfaz principal de descubrimiento de recepciones con navegación fluida, diseño inmersivo y filtros avanzados.

### 1. Historias de Usuario

| ID | Historia de Usuario | Criterios de Aceptación (Definición de "Terminado") |
| :--- | :--- | :--- |
| **DISC-01** | Como usuario, quiero ver las recepciones en un feed a pantalla completa. | - Tarjetas verticales que ocupan el 100% de la pantalla.<br>- Scroll infinito integrado (paginación de datos).<br>- Los locales "Verificados" aparecen primero en el algoritmo. |
| **DISC-02** | Como usuario, quiero interactuar con el contenido deslizando (swipe). | - Swipe vertical: Cambiar al siguiente/anterior local.<br>- Swipe horizontal: Navegar por el carrusel de fotos del mismo local. |
| **DISC-03** | Como usuario, quiero filtrar las recepciones para encontrar la ideal. | - Barra de búsqueda por texto (nombre de recepción o host).<br>- Panel de filtros (Bottom Sheet): Cercanía, precio, puntuación y servicios. |
| **DISC-04** | Como usuario, quiero dar "Me gusta" a una recepción para medir su popularidad. | - Botón de corazón funcional que actualice el contador de interacciones en tiempo real. |

### 2. Arquitectura de Datos Sugerida

- `public.receptions`: id, host_id (FK profiles), title, description, base_price, location (Coordenadas Lat/Lng), is_verified (Boolean), likes_count.
- `public.reception_media`: id, reception_id, media_url, order_index.

### 3. Requerimientos Técnicos

- Uso de librerías avanzadas de gestos y animaciones (ej. react-native-gesture-handler y react-native-reanimated).
- Implementación de consultas geoespaciales simples en la base de datos para calcular la distancia entre el usuario y la recepción.

---

## Sprint 3: Módulo de Reservas y Pagos

**Objetivo:** Gestionar el flujo completo desde la selección de servicios extras hasta el procesamiento del pago simulado.

### 1. Historias de Usuario

| ID | Historia de Usuario | Criterios de Aceptación (Definición de "Terminado") |
| :--- | :--- | :--- |
| **RES-01** | Como usuario, quiero armar mi paquete de servicios extra antes de reservar. | - Checkboxes dinámicos para añadir servicios (ej. bar, animador).<br>- Cálculo del total a pagar actualizado en tiempo real. |
| **RES-02** | Como usuario, quiero seleccionar la fecha de mi evento. | - Calendario interactivo.<br>- Bloqueo automático de fechas que ya están reservadas. |
| **PAY-01** | Como usuario, quiero pagar mi reserva de forma segura usando tarjeta. | - Integración de formulario de tarjeta con Stripe (Modo de Pruebas).<br>- Actualización del estado de la reserva a "Confirmada" tras el pago. |
| **REV-01** | Como usuario, quiero calificar la recepción después de que termine mi evento. | - Sistema de puntuación de 1 a 5 estrellas.<br>- Opción para dejar un comentario de texto. |

### 2. Arquitectura de Datos Sugerida

- `public.services`: id, reception_id, name, price, icon_url.
- `public.reservations`: id, user_id, reception_id, event_date, total_amount, status (pending, confirmed, completed).
- `public.reservation_services`: Tabla pivote (reservation_id, service_id).
- `public.reviews`: id, user_id, reception_id, rating, comment, created_at.

### 3. Requerimientos Técnicos

- Integrar SDK de Stripe para React Native.
- Crear una Supabase Edge Function (backend serverless) para procesar de forma segura el intento de pago (PaymentIntent) sin exponer llaves secretas en el frontend.

---

## Sprint 4: Módulo de Gestión de Hosts (Dueños)

**Objetivo:** Permitir a los dueños registrar su negocio, pagar su verificación y administrar el contenido que verán los usuarios.

### 1. Historias de Usuario

| ID | Historia de Usuario | Criterios de Aceptación (Definición de "Terminado") |
| :--- | :--- | :--- |
| **HST-01** | Como host, quiero crear el perfil de mi recepción. | - Formulario completo para ingresar: título, descripción, precio base y agregar servicios extra.<br>- Selector de mapa interactivo (OpenStreetMap) para fijar el pin de ubicación. |
| **HST-02** | Como host, quiero subir y ordenar las fotos de mi local. | - Carga múltiple de imágenes.<br>- Capacidad de definir el orden en el que aparecerán en el feed del usuario. |
| **HST-03** | Como host, quiero pagar una tarifa única para obtener la insignia de "Local Verificado". | - Flujo de pago de $15-$20 vía Stripe.<br>- Actualización automática del rol y estado is_verified a verdadero. |
| **HST-04** | Como host, quiero ingresar mis datos bancarios para recibir los pagos de las reservas. | - Formulario seguro de registro de cuenta bancaria. |

### 2. Arquitectura de Datos Sugerida

- `public.host_payments`: id, host_id, amount, payment_date, payment_type (verification_fee).
- `public.bank_accounts`: id, host_id, account_number, bank_name, account_type.

### 3. Requerimientos Técnicos

- Manejo de formularios complejos con validaciones estrictas (se sugiere usar librerías como React Hook Form + Zod/Yup).
- Procesamiento por lotes (batch processing) para subir múltiples imágenes a Supabase Storage de manera eficiente y asociarlas a la tabla reception_media.

---

## Sprint 5: Módulo de Comunicación y Notificaciones

**Objetivo:** Conectar a usuarios y hosts en tiempo real y mantenerlos informados de las novedades y reservas.

### 1. Historias de Usuario

| ID | Historia de Usuario | Criterios de Aceptación (Definición de "Terminado") |
| :--- | :--- | :--- |
| **CHAT-01** | Como usuario/host, quiero enviar y recibir mensajes en tiempo real. | - Actualización instantánea del chat en pantalla sin recargar la app.<br>- Burbujas de chat diferenciadas (emisor/receptor). |
| **CHAT-02** | Como usuario/host, quiero tener un buzón centralizado para ver mis conversaciones. | - Pantalla "Inbox" compartida por ambos roles.<br>- Lista ordenada por el mensaje más reciente.<br>- Indicador visual de mensajes no leídos. |
| **NOT-01** | Como usuario/host, quiero recibir notificaciones importantes. | - Alertas push o in-app para "Reserva Confirmada" y "Nuevo Mensaje". |

### 2. Arquitectura de Datos Sugerida

- `public.chats`: id, user_id, host_id, reception_id, last_message_at.
- `public.messages`: id, chat_id, sender_id, content, is_read, created_at.

### 3. Requerimientos Técnicos

- Implementación de Supabase Realtime (suscripción a canales de WebSocket) en la tabla messages para el flujo bidireccional de datos.
- Configuración de Firebase Cloud Messaging (FCM) o notificaciones nativas del entorno de desarrollo (ej. Expo Notifications) para alertas fuera de la aplicación.
