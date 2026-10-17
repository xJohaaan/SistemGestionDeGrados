# Sistema de Gestión de Trabajos de Grado – UTS

Aplicación web para gestionar los trabajos de grado de Ingeniería de Sistemas, desde la selección de la idea en el banco hasta el cierre y radicado del proyecto.

**Tecnologías:** JSP + JSPF + JSTL (core, sql, fn, fmt) + MySQL 8, desplegado en el Tomcat 8.5 de XAMPP.
**Restricciones del parcial:** sin Maven, sin Servlets y sin scriptlets (`<% %>`). En `WEB-INF/web.xml`, `scripting-invalid=true` hace que cualquier scriptlet impida compilar la página.

## Instalación

1. **Base de datos:** ejecutar en MySQL Workbench (o consola), en este orden:
   - `sql/gestion_grados.sql` crea la base `gestion_grados`, las tablas y el catálogo de fases.
   - `sql/datos_prueba.sql` carga usuarios, ideas y proyectos de ejemplo en todas las fases.
2. **Credenciales:** copiar `META-INF/context.example.xml` como `META-INF/context.xml` y escribir el usuario y la contraseña de MySQL. Ese archivo no se sube al repositorio. La URL de conexión está en `WEB-INF/web.xml`.
3. **Driver:** `WEB-INF/lib/mysql-connector-j-8.0.33.jar` (JSTL ya viene en `C:\xampp\tomcat\lib\jstl.jar`).
4. **Filtro de seguridad:** solo hay que recompilarlo si se modifica `AuthFilter.java`:
   ```
   javac --release 8 -encoding UTF-8 -cp "C:\xampp\tomcat\lib\servlet-api.jar" -d WEB-INF/classes src\co\edu\uts\grados\filtro\AuthFilter.java
   ```
5. Iniciar Tomcat desde el panel de XAMPP y abrir `http://localhost:8080/SistemGestionDeGrados/`.
   Tras cambiar `web.xml` o el filtro, reiniciar Tomcat.

## Usuarios de prueba (contraseña `clave123`)

| Rol | Correo |
|---|---|
| Administrador | admin@uts.edu.co |
| Coordinación (registra también las decisiones del Comité) | coordinacion@uts.edu.co |
| Docente Director | crueda@uts.edu.co, apinto@uts.edu.co |
| Docente Evaluador | lmendez@uts.edu.co, sgomez@uts.edu.co |
| Estudiante | jperez@correo.uts.edu.co (Fase 1), vrojas@ (Fase 1, pago enviado), sdiaz@ (Fase 2), ctorres@ (Fase 3), dherrera@ (Fase 4), mlopez@ (Finalizado), scastro@ (Fase 5, comité), nvargas@ (sin proyecto) |

## Estructura

```
SistemGestionDeGrados/
├── index.jsp, login.jsp, logout.jsp, acceso.jsp, error.jsp, perfil.jsp, controlador_perfil.jsp
├── admin/          panel y CRUD de usuarios
├── coordinacion/   banco de ideas, asignaciones, comité y reportes
├── director/       módulo "Docente Director" (califica anteproyecto e informe final)
├── evaluador/      módulo "Docente Evaluador" (evalúa propuesta e informe final)
├── estudiante/     seguimiento por fases, banco de ideas y entregas
├── ideas/          banco de ideas: consultar, proponer, mis propuestas y seleccionar idea
├── documental/     base documental (calendario, formatos, reglamentos)
├── css/ js/        estilos UTS y comportamiento común (DataTables, validaciones)
├── uploads/        PDF subidos (protegidos por AuthFilter)
├── sql/            script de la BD y datos de prueba
├── src/            código fuente de AuthFilter (única clase Java)
├── docs/ diagramas/
└── WEB-INF/
    ├── web.xml     conexión, filtro, multipart, scripting-invalid, timeout
    ├── classes/    AuthFilter compilado
    ├── lib/        driver MySQL
    └── jspf/       conexion, seguridad, cabecera, pie, alertas, estado_proyecto
```

## Roles

Cada usuario tiene **un solo rol**: `ADMIN`, `COORDINACION`, `DIRECTOR`, `EVALUADOR` o `ESTUDIANTE`.

- Un Docente Director no puede ser Docente Evaluador, ni al revés. Son cuentas distintas.
- La base de datos lo garantiza con triggers: `id_director` solo acepta usuarios `DIRECTOR`, `id_evaluador` solo acepta `EVALUADOR`, y no se puede cambiar el rol de un usuario que ya participa en proyectos.
- El Comité de Trabajos de Grado no es un usuario. Sus decisiones las registra Coordinación.

## Convenciones

- **Vistas** (`*.jsp`): consultan con `<sql:query>` y muestran los datos con `<c:forEach>` y `<c:out>`.
- **Controladores** (`controlador_*.jsp`): reciben el POST, validan, escriben con `<sql:update>` o `<sql:transaction>`, guardan `msgExito` o `msgError` en sesión y redirigen con `<c:redirect>`. No generan HTML.
- Todo valor que viene del usuario va en `<sql:param>` (consultas preparadas). Nunca se concatena dentro del SQL.
- Todo dato se muestra con `<c:out>` o `fn:escapeXml` (protección XSS).
- Includes con ruta absoluta: `<%@ include file="/WEB-INF/jspf/..." %>`.
- Cada página privada fija `<c:set var="rolRequerido" value="..."/>` antes de incluir `seguridad.jspf`.

## Flujo de fases

| Fase | Responsable | Al aprobar | Al rechazar |
|---|---|---|---|
| 1 Pago | Estudiante, luego Coordinación | Asigna director y evaluador → Fase 2 | – |
| 2 Anteproyecto | Estudiante, luego Director | → Fase 3 | Vuelve al estudiante |
| 3 Evaluación de propuesta | Evaluador, luego Comité | → Fase 4 | Vuelve a Fase 2 |
| 4 Informe final | Estudiante, luego Director | → Fase 5 | Vuelve al estudiante |
| 5 Revisión final | Evaluador, luego Comité | → Fase 6 Cierre, con radicado | Vuelve a Fase 4 |

Cada transición se guarda en `historial_fase` con fecha y hora.

## Banco de ideas

1. Un estudiante o docente entra a **Banco de ideas → Proponer idea**. La idea queda *Pendiente* y puede retirarla mientras siga así.
2. Coordinación (en nombre del comité) la **aprueba** o la **rechaza con un motivo** en *Banco de ideas*. También puede crear, editar y eliminar ideas. Las que tienen proyecto no se pueden editar ni eliminar.
3. Las ideas *Aprobadas* aparecen en el banco. Un estudiante **sin proyecto** pulsa **Seleccionar**. La idea pasa a *Tomada* y se crea su proyecto `GRA-NNNNN` en Fase 1. Desde ahí sigue el flujo de fases. Para probarlo, `nvargas@correo.uts.edu.co` no tiene proyecto.

## Recorrer el flujo completo (GRA-00001, Juan Pérez)

| # | Quién entra | Pantalla | Acción | Resultado |
|---|---|---|---|---|
| 1 | jperez (estudiante) | Entregas | Sube el recibo de pago (PDF) | Fase 1, a cargo de Coordinación |
| 2 | coordinacion | Asignar docentes | Elige director (Rueda o Pinto) y evaluador (Méndez o Gómez) | Fase 2 |
| 3 | jperez | Entregas | Sube el anteproyecto | A cargo del director |
| 4 | director asignado | Docente Director → Calificar | Nota, observaciones y Aprobar (o Devolver) | Fase 3 |
| 5 | evaluador asignado | Docente Evaluador → Evaluar | Aprobar (o Rechazar, vuelve a Fase 2) | A cargo del comité |
| 6 | coordinacion | Comité → Decidir | Acta y Aprobar | Fase 4 |
| 7 | jperez | Entregas | Sube el informe final | A cargo del director |
| 8 | director | Calificar | Aprobar | Fase 5 |
| 9 | evaluador | Evaluar | Aprobar (o Rechazar, vuelve a Fase 4) | A cargo del comité |
| 10 | coordinacion | Comité → Decidir | Acta y Aprobar y cerrar | Fase 6 Final, radicado `RAD-2026-00001` |

Para reiniciar los datos, vuelva a ejecutar `sql/gestion_grados.sql` y `sql/datos_prueba.sql`.
