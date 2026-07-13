---
name: Stadia UI Pattern
description: Skill en el que se definirá el patrón de diseño que seguirá la aplicación Stadia.
---

# Patrón de Diseño UI - Stadia

Este documento (Skill) contiene las guías visuales y de interacción del usuario que deben seguirse para mantener coherencia en toda la aplicación Stadia.

*(Este archivo será expandido con las reglas específicas de componentes, colores, tipografía y flujos de navegación a medida que se defina el stack y las librerías gráficas del proyecto).*

## Principios Iniciales
- **Consistencia Visual**: Asegurar que botones, formularios, y tarjetas de recepciones utilicen un lenguaje de diseño único a través de toda la app.
- **Experiencia de Usuario (UX)**: Priorizar un flujo de reserva de recepciones intuitivo y sin fricciones, adaptado al contexto de la ciudad de Quito.
- **Componentes Reutilizables**: Todo diseño de UI debe construirse pensando en su modularidad para encajar dentro de la filosofía de *Vertical Slicing* del proyecto.

## Sistema de Diseño (Design System)

### Paleta de Colores
- **Primario (Concha de Vino):** `#6D1432` - Uso: Botones principales, acentos, headers.
- **Fondo (Perla):** `#F6F4F0` - Uso: Color de fondo general de la aplicación (Scaffolds).
- **Superficie:** `#FFFFFF` - Uso: Tarjetas, Bottom Sheets, Modales.
- **Texto Principal:** `#1A1A1A` - Uso: Títulos y textos descriptivos.
- **Texto Secundario:** `#757575` - Uso: Subtítulos, hints, texto de soporte.

### Tipografía
- **Fuente Principal:** `Raleway`
- **Pesos:** Light (300) para descripciones sutiles, Regular (400) para cuerpo de texto, Bold (700) para Títulos.

### Estilo de UI (Fusión)
1. **Glassmorfismo (Para Discovery Feed):** En pantallas donde la imagen es a pantalla completa (estilo TikTok), los paneles informativos, barras inferiores y botones flotantes deben usar fondos translúcidos con efecto "Blur" (desenfoque) para no tapar la estética visual del local.
2. **Minimalismo Soft (Resto de la app):** El resto de la app (estilo Mercado Libre) debe ser limpia. Se utilizarán tarjetas de fondo blanco puro (`#FFFFFF`) sobre el fondo perla (`#F6F4F0`) con sombras muy suaves (`BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10)`), y bordes muy redondeados (`BorderRadius.circular(16)` o mayor).
