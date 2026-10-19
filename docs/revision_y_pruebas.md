# Revisión del sistema y pruebas

Fecha: 19/10/2026 · Sistema de Gestión de Trabajos de Grado UTS

## 1. Qué se revisó

| Revisión | Cómo se hizo | Resultado |
|---|---|---|
| Archivos accesibles por URL | Petición directa a `/.git`, `/src`, `/sql`, `/README.md`, `META-INF`, `WEB-INF` | **Se encontró exposición** (ver hallazgo H1) |
| Enlaces rotos | Rastreador automático que inicia sesión con cada rol y recorre todos los enlaces | 83 páginas: **0 enlaces rotos** |
| Parámetros inválidos | Cada página y controlador recibió `abc`, `-1`, `999999`, `1'--`, `<x>` y vacío (3 786 peticiones) | **Se encontraron errores 500** (H2); tras corregir: 0 |
| XSS | Análisis estático de toda expresión EL que se imprime en HTML; prueba con `<script>` guardado | Todo dato de usuario sale con `<c:out>` o `fn:escapeXml` |
| Inyección SQL | Análisis de las consultas; login con `' OR '1'='1` | Todas usan `<sql:param>` (consultas preparadas) |
| Scriptlets | Búsqueda de `<%` y `scripting-invalid=true` en `web.xml` | 0 scriptlets; una página con `<% %>` no compila |
| Codificación | Validación UTF-8 de todos los archivos fuente | Correcta |
| Integridad de datos | Comparación de conteos de la BD antes y después del rastreo | Sin cambios |

## 2. Hallazgos y correcciones

| # | Severidad | Hallazgo | Corrección |
|---|---|---|---|
| H1 | **Crítica** | Se podía descargar el repositorio completo (`/.git/config`, historial), el código fuente (`/src`), los scripts SQL con las contraseñas de prueba y el README. | `security-constraint` en `web.xml` que niega `/.git/*`, `/src/*`, `/sql/*`, `/test/*`, `/docs/*`, `/diagramas/*`, `README.md`, `.gitignore`, `.gitattributes` (HTTP 403, mostrado como "página no encontrada"). |
| H2 | Media | Error 500 en 4 controladores si el `id` no era numérico (MySQL en modo estricto rechaza `WHERE id = 'abc'` en `UPDATE`/`DELETE`). | Nuevo fragmento `WEB-INF/jspf/id_seguro.jspf`: convierte `param.id` a número con `<c:catch>`. Si no es numérico queda en 0 y no afecta registros. Se usa en los 7 controladores. |
| H3 | Media | Solo se validaba la extensión `.pdf`: un `.exe` renombrado se aceptaba. | Se leen los 4 primeros bytes del archivo (`%PDF`) desde EL (`archivo.inputStream.read()`) y se rechaza si no coinciden. |
| H4 | Media | Sin protección CSRF: otro sitio podía enviar formularios POST con la sesión del usuario. | Cookie de sesión con `SameSite=Lax` (`<CookieProcessor sameSiteCookies="lax"/>` en `META-INF/context.xml`), además de `HttpOnly` y solo cookie (sin `;jsessionid` en la URL). |
| H5 | Baja | La asignación de docentes solo validaba el rol (trigger), no que el docente estuviera **activo**. Un POST manual podía asignar un docente dado de baja. | El `UPDATE` exige `EXISTS (... rol = 'DIRECTOR' AND estado = 'Activo')` y lo mismo para el evaluador. |

### Observaciones (no corregidas, para tener en cuenta)

- **Intentos de login ilimitados**: no hay bloqueo tras varios intentos fallidos.
- **Dar de baja a un docente con proyectos en curso**: se permite y sus proyectos quedan detenidos, porque aún no existe la opción de reasignar director o evaluador.
- **Un usuario dado de baja conserva su sesión abierta** hasta que expira (20 minutos) o cierra sesión.
- **Archivos de más de 25 MB**: Tomcat corta la conexión antes de llegar a la JSP. La validación en el navegador (máximo 20 MB) lo evita en el uso normal.

## 3. Pruebas automatizadas (JUnit 5)

Ubicación: `test/`. Se ejecutan con `test\ejecutar_pruebas.bat`, sin Maven; JUnit está en `test/lib`.

| Clase | Tipo | Pruebas | Qué verifica |
|---|---|---|---|
| `AuthFilterTest` | Unitarias, sin servidor (proxies) | 19 | Sin sesión va al login; cada rol entra solo a su carpeta (5 casos); los roles ajenos van a acceso denegado (6 casos); las rutas comunes son para cualquier rol autenticado; los PDF exigen sesión; cabeceras sin caché. |
| `ReglasBaseDatosTest` | Integración con MySQL; cada prueba hace `rollback` | 13 | Hash SHA-256 con salt (clave correcta, incorrecta y SQLi); salt distinto por usuario; triggers de rol (director, evaluador, estudiante, cambio de rol con proyectos); un proyecto por estudiante y por idea; código `GRA-NNNNN`; radicado `RAD-AAAA-NNNNN`; nota de 0 a 5; `ON DELETE RESTRICT`; fecha automática en el historial; correo y código únicos. |
| `FlujoSistemaTest` | Extremo a extremo por HTTP contra Tomcat | 11 | Login y SQLi; matriz de acceso; selección de idea → proyecto; rechazo de no-PDF y falso PDF; asignación con roles cruzados; devolución del director; nota fuera de rango; comité sin acta; rechazo del evaluador en Fase 5 → Fase 4; cierre con radicado; conteo de documentos, evaluaciones e historial; XSS escapado; ids inválidos sin 500; archivos internos con 403; logout; cookie `HttpOnly` y `SameSite`. Crea usuarios `@test.local` y los borra al terminar. |

**Resultado: 43 pruebas, 43 exitosas, 0 fallidas.**

## 4. Cómo repetir la revisión

1. Iniciar MySQL y Tomcat.
2. Ejecutar `test\ejecutar_pruebas.bat`.
3. Abrir `http://localhost:8080/SistemGestionDeGrados/.git/config`: debe mostrar "Página no encontrada".
