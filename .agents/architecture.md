# Arquitectura del Proyecto: Clean Architecture + Vertical Slicing

Este documento describe la arquitectura utilizada en el proyecto **Spoti**. Está diseñado para contextualizar a los modelos de IA sobre cómo deben gestionar la comunicación y el flujo de archivos a nivel de proyecto.

## Principios Fundamentales
El proyecto combina dos enfoques arquitectónicos poderosos:

1. **Clean Architecture (Arquitectura Limpia)**: Separa las responsabilidades en capas concéntricas (Dominio, Casos de Uso, Adaptadores de Interfaz, Frameworks/Drivers). La regla fundamental de dependencia establece que el código fuente solo puede apuntar hacia adentro; las capas internas (como las Entidades o Casos de Uso) no deben saber absolutamente nada de las capas externas (como la UI o la Base de Datos).
2. **Vertical Slicing (Cortes Verticales)**: En lugar de agrupar archivos por su capa técnica (por ejemplo, todos los controladores en una carpeta, todos los repositorios en otra), agrupamos por *funcionalidad* o *feature* (ej. "Reservas", "Usuarios", "Recepciones"). Cada "rebanada" vertical contiene todas las capas de Clean Architecture necesarias para esa funcionalidad en específico.

## Flujo de Comunicación y Archivos
Al trabajar con IA o cambiar de modelos durante el desarrollo, se deben seguir estrictamente estas pautas:

- **Agrupación por Feature**: Al crear o modificar una funcionalidad, trabaja dentro de la carpeta dedicada a ese feature. Implementa las capas de Clean Architecture dentro de ese contexto específico.
- **Independencia de Features**: Los diferentes "slices" verticales deben ser lo más independientes posible. Si un feature necesita comunicarse con otro, debe hacerlo a través de interfaces bien definidas en la capa de dominio o mediante eventos, evitando acoplamientos directos entre controladores o repositorios de distintos features.
- **Flujo de Datos Estricto**:
  1. `UI/Frameworks` recibe la interacción.
  2. Llama a `Controladores/Presenters`.
  3. Ejecuta `Casos de Uso (Interactors)`.
  4. Interactúa con `Entidades/Dominio` y puertos (interfaces) de Repositorios.
  5. La implementación de la base de datos (Infraestructura) cumple con la interfaz del puerto.
  - *El retorno de los datos sigue el camino inverso sin saltarse capas.*
- **Inyección de Dependencias**: Los modelos de IA deben priorizar el uso de inyección de dependencias para conectar las capas externas con los casos de uso y repositorios, asegurando que el código de dominio se mantenga testeable y puro.
