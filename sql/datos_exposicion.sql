-- =====================================================================
--  Datos para la EXPOSICIÓN: recorrer el flujo completo en vivo
--  Ejecutar después de gestion_grados.sql y datos_prueba.sql.
--  Se puede ejecutar las veces que se quiera: primero borra lo creado
--  por este mismo script (solo estos usuarios y sus ideas/proyectos) y
--  lo vuelve a crear. Los demás datos no se tocan.
--  Contraseña de todas las cuentas: clave123
-- =====================================================================
USE gestion_grados;

START TRANSACTION;

-- ---------------------------------------------------------------------
-- 1. Limpieza de una ejecución anterior (ensayos)
-- ---------------------------------------------------------------------
CREATE TEMPORARY TABLE IF NOT EXISTS expo_usuarios (id INT PRIMARY KEY);
DELETE FROM expo_usuarios;
INSERT INTO expo_usuarios
SELECT id_usuario FROM usuario
WHERE correo IN ('andrea.suarez@correo.uts.edu.co', 'kevin.ortega@correo.uts.edu.co',
                 'rblanco@uts.edu.co', 'pserrano@uts.edu.co');

DELETE FROM historial_fase WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_estudiante IN (SELECT id FROM expo_usuarios));
DELETE FROM evaluacion     WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_estudiante IN (SELECT id FROM expo_usuarios));
DELETE FROM documento      WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_estudiante IN (SELECT id FROM expo_usuarios));
DELETE FROM proyecto       WHERE id_estudiante IN (SELECT id FROM expo_usuarios);
-- Por si en el ensayo otro estudiante tomó una idea de la exposición
DELETE FROM historial_fase WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_idea IN (SELECT id_idea FROM idea WHERE id_autor IN (SELECT id FROM expo_usuarios)));
DELETE FROM evaluacion     WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_idea IN (SELECT id_idea FROM idea WHERE id_autor IN (SELECT id FROM expo_usuarios)));
DELETE FROM documento      WHERE id_proyecto IN (SELECT id_proyecto FROM proyecto WHERE id_idea IN (SELECT id_idea FROM idea WHERE id_autor IN (SELECT id FROM expo_usuarios)));
DELETE FROM proyecto       WHERE id_idea IN (SELECT id_idea FROM idea WHERE id_autor IN (SELECT id FROM expo_usuarios));
DELETE FROM idea           WHERE id_autor IN (SELECT id FROM expo_usuarios);
DELETE FROM usuario        WHERE id_usuario IN (SELECT id FROM expo_usuarios);
DROP TEMPORARY TABLE expo_usuarios;

-- ---------------------------------------------------------------------
-- 2. Usuarios de la exposición
--    Andrea: estudiante SIN proyecto y SIN idea -> hace todo el flujo
--    Kevin:  estudiante que propone una idea (para mostrar la aprobación)
--    Ricardo: Docente Director sin carga (su panel queda limpio)
--    Paola:   Docente Evaluadora sin carga
--    Coordinación (y Comité): coordinacion@uts.edu.co (ya existe)
-- ---------------------------------------------------------------------
INSERT INTO usuario (codigo, nombres, apellidos, correo, telefono, rol, salt, contrasena) VALUES
('1098765001', 'Andrea Camila',   'Suárez Rincón', 'andrea.suarez@correo.uts.edu.co', '3156667788', 'ESTUDIANTE', '', ''),
('1098765002', 'Kevin Alexander', 'Ortega Mejía',  'kevin.ortega@correo.uts.edu.co',  '3157778899', 'ESTUDIANTE', '', ''),
('9100000021', 'Ricardo Ernesto', 'Blanco Díaz',   'rblanco@uts.edu.co',              '3108889900', 'DIRECTOR',   '', ''),
('9100000022', 'Paola Andrea',    'Serrano Cruz',  'pserrano@uts.edu.co',             '3109990011', 'EVALUADOR',  '', '');

UPDATE usuario
   SET salt = MD5(CONCAT('semilla-', correo)),
       contrasena = SHA2(CONCAT(MD5(CONCAT('semilla-', correo)), 'clave123'), 256)
 WHERE correo IN ('andrea.suarez@correo.uts.edu.co', 'kevin.ortega@correo.uts.edu.co',
                  'rblanco@uts.edu.co', 'pserrano@uts.edu.co');

-- ---------------------------------------------------------------------
-- 3. Ideas
--    Dos ideas APROBADAS propuestas por el director (Andrea elige una)
--    Una idea PENDIENTE de Kevin (Coordinación la aprueba en vivo)
-- ---------------------------------------------------------------------
INSERT INTO idea (titulo, descripcion, linea, id_autor, estado)
SELECT 'Sistema de citas para el consultorio jurídico UTS',
       'Aplicación web para agendar, reprogramar y hacer seguimiento a las citas del consultorio jurídico, con recordatorios por correo y reportes de atención.',
       'Ingeniería de software', id_usuario, 'Aprobada'
FROM usuario WHERE correo = 'rblanco@uts.edu.co';

INSERT INTO idea (titulo, descripcion, linea, id_autor, estado)
SELECT 'Monitoreo del consumo energético del campus con IoT',
       'Red de medidores conectados que registra el consumo eléctrico por edificio y muestra un tablero con alertas de consumo anómalo.',
       'Internet de las cosas', id_usuario, 'Aprobada'
FROM usuario WHERE correo = 'rblanco@uts.edu.co';

INSERT INTO idea (titulo, descripcion, linea, id_autor, estado)
SELECT 'App de rutas seguras para estudiantes nocturnos',
       'Aplicación móvil que sugiere rutas iluminadas y concurridas desde la UTS hasta los paraderos, con botón de alerta a contactos de confianza.',
       'Desarrollo móvil', id_usuario, 'Pendiente'
FROM usuario WHERE correo = 'kevin.ortega@correo.uts.edu.co';

COMMIT;

-- Verificación
SELECT u.correo, u.rol,
       (SELECT COUNT(*) FROM proyecto p WHERE p.id_estudiante = u.id_usuario OR p.id_director = u.id_usuario OR p.id_evaluador = u.id_usuario) AS proyectos
FROM usuario u
WHERE u.correo IN ('andrea.suarez@correo.uts.edu.co', 'kevin.ortega@correo.uts.edu.co', 'rblanco@uts.edu.co', 'pserrano@uts.edu.co');
SELECT i.titulo, i.estado FROM idea i JOIN usuario u ON u.id_usuario = i.id_autor
WHERE u.correo IN ('rblanco@uts.edu.co', 'kevin.ortega@correo.uts.edu.co');
