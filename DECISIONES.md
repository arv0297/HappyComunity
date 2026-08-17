# Decisiones de Implementación

## Casuisticas / Requisitos

### 1. Autenticación en el API

**Casuisticas:** Cómo expones el sistema hacia afuera es decisión tuya, mientras un cliente pueda consumirlo.

**Decisión:** Implementé autenticación mínima con token compartido (`ENV["SECRET_TOKEN"]`) que valida el acceso al API y/o pasa los atributos unicos del usuario (`User.email`, `User.encrypted_password`) al contexto GraphQL. Las mutaciones validan que el usuario esté autenticado o que sea el dueño de la reseña para operaciones.

**Justificación:** Permite que el sistema sea funcional para pruebas con una capa básica de seguridad sin requerir un sistema de autenticación completo (JWT, Devise, etc.). El token compartido protege el endpoint de acceso no autorizado, mientras que el contexto GraphQL permite autorización a nivel de mutación. En producción, el token debería decodificarse para obtener el usuario específico.

### 2. Concurrencia vs Performance

**Casuistica:** Si 200 usuarios distintos reseñan el mismo libro simultáneamente, al terminar el promedio y el conteo de ese libro deben ser correctos. No basta con que "casi siempre" lo sean.

**Decisión:** Usé `with_lock` (pessimistic locking) en el modelo Book para garantizar consistencia bajo alta concurrencia.

**Justificación:** Debido a la importancia del calculo instantaneo y el tiempo de desarrollo preferí la implementación inmediata con un callback para mantener la ejecución constantemente a tiempo real. El locking es la forma más simple de garantizar que 200 operaciones simultáneas produzcan un resultado correcto. El impacto en rendimiento es aceptable dado que el recálculo del promedio es una operación O(1) sobre las reseñas activas del libro.

### 3. Cálculo del promedio con usuarios baneados

**Casuistica:** Banear o desbanear debe quedar reflejado en los promedios de todos los libros que ese usuario reseñó.

**Decisión:** El promedio excluye reseñas de usuarios cuyo estado actual es `banned: true` para mantener registro de los usuarios baneados, se implemento el callback en el punto anterior.

**Justificación:** Esto permite que el desbaneo reactive automáticamente las reseñas, lo cual es más flexible para el equipo de moderación y mantiene el promedio constantemente actualizado.

### 4. Umbral mínimo de reseñas para mostrar promedio

**Casuistica:** Libros con muy pocas reseñas pueden tener promedios no representativos.

**Decisión:** Se estableció un mínimo de 3 reseñas (`MIN_REVIEWS_FOR_AVERAGE = 3`) para mostrar el promedio de calificación. Libros con menos reseñas muestran "Reseñas Insuficientes".

**Justificación:** Esto evita que libros con 1 o 2 reseñas tengan promedios que pueden ser engañosos o estadísticamente insignificantes, mejorando la confianza en el sistema de ratings.

## Trade-offs tomados y sus costos

### 1. Cálculo síncrono del promedio

**Decisión:** El promedio se recalcula síncronamente en cada callback (create, update, destroy, ban/unban).

**Costo:** Cada operación que afecta el promedio requiere una consulta adicional para calcular el nuevo promedio. En alta concurrencia, esto puede crear contention en la base de datos.

**Beneficio:** Los promedios siempre están actualizados. No hay necesidad de jobs en background ni de eventual consistency.

**Alternativa considerada:** Usar un contador cacheado que se actualiza incrementalmente. Esto sería más rápido pero más complejo de mantener consistente bajo concurrencia.

**Segunda alternativa considerada:** Usar un job asincrono que mantenga actualizado los promedio pero con un delta razonable a definir de unos segundos para que pueda encapsular los reviews que se vayan creando o actualizando debido a los baneos/desbaneos.

### 2. Callbacks en modelos

**Decisión:** Usé callbacks de ActiveRecord para actualizar los promedios automáticamente.

**Costo:** Acopla la lógica de negocio a los modelos, lo que puede hacer el código más difícil de testear en aislamiento.

**Beneficio:** Simplicidad y garantía de que los promedios siempre se actualizan, sin importar cómo se modifique la reseña o el usuario.

**Alternativa considerada:** Usar un servicio object o pattern observer. Esto desacoplaría la lógica pero añadiría complejidad y mantener mejor los principios SOLID y DRY.

### 3. GraphQL como API

**Decisión:** Exposición del sistema vía GraphQL en lugar de REST.

**Costo:** GraphQL tiene una curva de aprendizaje más steep y puede ser más complejo de cachear.

**Beneficio:** Permite a los clientes consultar exactamente los datos que necesitan además de ser versatil para ser consultado tambien de manera mobil.

**Alternativa considerada:** REST API. Sería simpler pero menos flexible para el cliente.

### 4. Validación de unicidad a nivel de base de datos

**Decisión:** Usé índice único en `(user_id, book_id)` además de validación a nivel de modelo.

**Costo:** Añade complejidad a las migraciones y requiere manejo de errores de base de datos.

**Beneficio:** Garantiza unicidad incluso bajo condiciones de race condition, cumpliendo el requisito de concurrencia.

## Qué dejaría fuera si saliera a producción mañana

1. **Sistema de autenticación real:** Reemplazar la validación de email/password en texto plano dentro de cada mutación por autenticación basada en tokens (JWT) o Devise, identificando al usuario desde el contexto en lugar de recibir credenciales en cada request.

2. **Rate limiting:** Sin rate limiting, el API es vulnerable a abuso (ej: campañas de reseñas falsas automatizadas).

3. **Caching del promedio:** Implementar Redis cache para el promedio de libros populares.

4. **Paginación en queries:** Los queries de libros y reseñas deberían tener paginación (cursor-based para GraphQL).

5. **Auditoría:** Log de cambios en reseñas y baneos para debugging y compliance.

6. **Validación de contenido:** Sanitización del texto de reseñas para prevenir XSS.

7. **Background jobs para recálculo masivo:** Si un usuario con miles de reseñas es baneado, el recálculo síncrono podría ser lento.

## Qué haría distinto con una semana más

1. **Implementar detección de anomalías:** Sistema de scoring para detectar patrones sospechosos (ej: mismas IPs, tiempos de reseña muy rápidos, distribución de ratings anormal, abrupto cambio de rating).

2. **Optimización de queries:** Usar materialized views o contadores cacheados para el home de 50 libros, eliminando completamente la necesidad de recorrer reseñas (Redis suele ser una buena opción).

3. **Tests de carga:** Implementar tests de concurrencia reales con 200+ hilos para validar el comportamiento bajo estrés.

4. **Documentación de API:** Generar documentación automática de GraphQL con GraphiQL o Apollo Studio.

5. **Métricas y monitoring:** Añadir Prometheus metrics para tiempo de respuesta de recálculo de promedios y tasa de errores.

6. **Soft delete en reseñas:** En lugar de destroy, usar soft delete para mantener historial y permitir recuperación.

7. **Validación de dominio:** Verificar que el email del usuario sea válido (no solo formato) para reducir cuentas falsas.