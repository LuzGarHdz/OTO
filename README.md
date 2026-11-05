# OTO - primera iteración de Enfoque

`FocusView.swift` contiene la pantalla y su enumeración privada `FocusMode`.
Reutiliza `Screen`, `Theme`, `AppStore` y el `FocusTimer` compartido de
`MyApp.swift`. El target de `Package.swift` descubre los archivos Swift desde
la raíz; no se modificó el manifiesto generado ni la navegación.

La sesión muestra la primera tarea pendiente por fecha, conservando el criterio
existente (no hay una selección global de tarea). Si no hay pendientes, permite
una sesión libre. Seleccionar un modo o ajustar la duración pausa y reinicia el
contador. Pomodoro configura 25 minutos; extremo, 50; personalizado, 15 a 90.
La pausa breve de Pomodoro es descriptiva; no se inicia otro ciclo automáticamente.
OTO Plus conserva el desbloqueo local de demostración, sin pagos ni persistencia.

## Validación en Windows

- Se actualizó `origin` con `git fetch origin`; `main` y `origin/main` coincidían
  en `c434fb0` antes de crear `feature/focus-screen`, con el árbol limpio.
- No se encontraron `swift`, `swiftc` ni `xcodebuild` con `Get-Command` y `where.exe`.
  No se compiló ni ejecutó la app iOS, ni se instalaron herramientas de Apple.
- Se comparó el código con la base: las otras pantallas, modelos compartidos y
  navegación no cambiaron; `ContentView.swift` y `Package.swift` siguen intactos.
- Se verificaron declaraciones únicas, inyección de ambos `EnvironmentObject`
  y descubrimiento de `FocusView.swift` por el target existente.
- Revisión estática del temporizador: guarda contra arranques repetidos, pausa
  e invalidación, reinicio, límite inferior de cero y parada al finalizar.
  Estas comprobaciones no sustituyen pruebas de ejecución de Swift.

## Revisión pendiente en macOS

1. Compilar con herramientas compatibles con el paquete iOS 26 y confirmar que
   `FocusView.swift` pertenece al target al abrir o importar el proyecto.
2. Revisar las tres tarjetas, scroll, tab bar y tipografía en iPhone/iPad,
   orientación horizontal, Dynamic Type y VoiceOver.
3. Probar 25:00, 50:00 y los extremos 15:00/90:00 del selector; comprobar que cada
   cambio pausa y reinicia la sesión sin afectar el funcionamiento de las pestañas.
4. Probar Premium bloqueado, cancelar y desbloquear la demo. Cancelar debe
   conservar el modo y el contador anteriores. No se bloquean notificaciones.
5. Probar iniciar, pausar, reanudar, reiniciar y llegar a 00:00; verificar que no
   hay valores negativos ni aceleración al pulsar repetidamente o cambiar de pestaña.
   Inicio y Enfoque deben mostrar el mismo temporizador compartido.
6. Completar o eliminar todas las tareas y comprobar el estado vacío.

Se conserva el `Timer` existente: no se añade ejecución en segundo plano ni
reconciliación con el reloj al volver de una suspensión de iOS. El contador puede
quedar pausado por el sistema durante esa suspensión; revisar ese caso por separado
si se requiere medir tiempo real fuera de la app. No se añadieron widgets,
backend, servicios externos ni bloqueo real de distracciones.
