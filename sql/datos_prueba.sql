-- =====================================================================
--  Datos de prueba - Sistema de Gestión de Trabajos de Grado
--  Ejecutar después de gestion_grados.sql
--  Todas las cuentas usan la contraseña: clave123
-- =====================================================================
USE gestion_grados;

-- ---------------------------------------------------------------------
-- Usuarios (la contraseña se calcula al final con salt + SHA-256)
-- ---------------------------------------------------------------------
INSERT INTO usuario (id_usuario, codigo, nombres, apellidos, correo, telefono, rol, salt, contrasena) VALUES
( 1, '1000000001', 'Administrador', 'del Sistema', 'admin@uts.edu.co',             '3000000001', 'ADMIN',        '', ''),
( 2, '1000000002', 'María Fernanda', 'Ortiz Ruiz', 'coordinacion@uts.edu.co',      '3000000002', 'COORDINACION', '', ''),
( 3, '9100000003', 'Carlos Andrés', 'Rueda Peña',  'crueda@uts.edu.co',            '3100000003', 'DIRECTOR',     '', ''),
( 4, '9100000004', 'Laura Patricia', 'Méndez Gil', 'lmendez@uts.edu.co',           '3100000004', 'EVALUADOR',    '', ''),
( 5, '9100000005', 'Andrés Felipe', 'Pinto Mora',  'apinto@uts.edu.co',            '3100000005', 'DIRECTOR',     '', ''),
( 6, '9100000006', 'Sandra Milena', 'Gómez Vera',  'sgomez@uts.edu.co',            '3100000006', 'EVALUADOR',    '', ''),
( 7, '1095000007', 'Juan David', 'Pérez Lozano',   'jperez@correo.uts.edu.co',     '3200000007', 'ESTUDIANTE',   '', ''),
( 8, '1095000008', 'Valentina', 'Rojas Cárdenas',  'vrojas@correo.uts.edu.co',     '3200000008', 'ESTUDIANTE',   '', ''),
( 9, '1095000009', 'Santiago', 'Díaz Quintero',    'sdiaz@correo.uts.edu.co',      '3200000009', 'ESTUDIANTE',   '', ''),
(10, '1095000010', 'Camila Andrea', 'Torres Niño', 'ctorres@correo.uts.edu.co',    '3200000010', 'ESTUDIANTE',   '', ''),
(11, '1095000011', 'Daniel Esteban', 'Herrera Silva', 'dherrera@correo.uts.edu.co', '3200000011', 'ESTUDIANTE',  '', ''),
(12, '1095000012', 'Mariana', 'López Acevedo',     'mlopez@correo.uts.edu.co',     '3200000012', 'ESTUDIANTE',   '', ''),
(13, '1095000013', 'Sebastián', 'Castro Prada',    'scastro@correo.uts.edu.co',    '3200000013', 'ESTUDIANTE',   '', ''),
(14, '1095000014', 'Natalia', 'Vargas Duarte',     'nvargas@correo.uts.edu.co',    '3200000014', 'ESTUDIANTE',   '', '');

UPDATE usuario
   SET salt = MD5(CONCAT('semilla-', correo)),
       contrasena = SHA2(CONCAT(MD5(CONCAT('semilla-', correo)), 'clave123'), 256);

-- ---------------------------------------------------------------------
-- Banco de ideas
-- ---------------------------------------------------------------------
INSERT INTO idea (id_idea, titulo, descripcion, linea, id_autor, estado, observacion, creado_en) VALUES
( 1, 'Sistema de gestión de inventarios para MiPymes', 'Aplicación web para controlar entradas, salidas y existencias de pequeños comercios de Bucaramanga.', 'Ingeniería de software', 3, 'Tomada', NULL, '2026-07-01 09:00:00'),
( 2, 'App móvil de seguimiento académico', 'Aplicación móvil para que los estudiantes consulten notas, horarios y alertas tempranas de bajo rendimiento.', 'Desarrollo móvil', 4, 'Tomada', NULL, '2026-07-02 10:00:00'),
( 3, 'Plataforma IoT para monitoreo de cultivos', 'Red de sensores de humedad y temperatura con tablero web para pequeños agricultores de Santander.', 'Internet de las cosas', 9, 'Tomada', NULL, '2026-07-03 11:00:00'),
( 4, 'Chatbot de atención estudiantil con IA', 'Asistente conversacional que responde preguntas frecuentes sobre trámites académicos de la UTS.', 'Inteligencia artificial', 5, 'Tomada', NULL, '2026-07-04 08:30:00'),
( 5, 'Sistema de reservas de laboratorios', 'Módulo web para reservar salas y equipos de laboratorio con control de disponibilidad.', 'Ingeniería de software', 6, 'Tomada', NULL, '2026-07-05 14:00:00'),
( 6, 'Análisis de deserción estudiantil con aprendizaje automático', 'Modelo predictivo que identifica factores de riesgo de deserción a partir de datos académicos.', 'Ciencia de datos', 3, 'Tomada', NULL, '2026-03-10 09:00:00'),
( 7, 'Portal de egresados UTS', 'Portal para mantener contacto con egresados, publicar ofertas laborales y eventos.', 'Ingeniería de software', 4, 'Aprobada', NULL, '2026-08-01 09:00:00'),
( 8, 'Control de asistencia con códigos QR', 'Registro de asistencia a clases mediante códigos QR dinámicos generados por el docente.', 'Desarrollo móvil', 14, 'Pendiente', NULL, '2026-10-10 16:00:00'),
( 9, 'Gamificación para la enseñanza de programación', 'Plataforma con retos y puntos para motivar el aprendizaje de algoritmos en primer semestre.', 'Educación y TIC', 5, 'Tomada', NULL, '2026-04-15 10:00:00'),
(10, 'Red social académica', 'Red social para compartir apuntes entre estudiantes.', 'Ingeniería de software', 12, 'Rechazada', 'La propuesta no define un problema delimitado ni un alcance medible.', '2026-02-20 10:00:00'),
(11, 'Sistema de turnos para bienestar universitario', 'Asignación de turnos en línea para servicios de psicología, enfermería y odontología.', 'Ingeniería de software', 6, 'Aprobada', NULL, '2026-09-05 09:00:00');

-- ---------------------------------------------------------------------
-- Proyectos en distintas fases
-- ---------------------------------------------------------------------
INSERT INTO proyecto (id_proyecto, codigo, id_idea, id_estudiante, id_director, id_evaluador, fase, responsable, radicado, creado_en) VALUES
(1, 'GRA-00001', 1,  7, NULL, NULL, 1, 'ESTUDIANTE',   NULL,             '2026-10-01 08:00:00'),
(2, 'GRA-00002', 2,  8, NULL, NULL, 1, 'COORDINACION', NULL,             '2026-09-20 08:00:00'),
(3, 'GRA-00003', 3,  9, 3,    4,    2, 'DIRECTOR',     NULL,             '2026-08-15 08:00:00'),
(4, 'GRA-00004', 4, 10, 5,    6,    3, 'EVALUADOR',    NULL,             '2026-08-01 08:00:00'),
(5, 'GRA-00005', 5, 11, 3,    4,    4, 'ESTUDIANTE',   NULL,             '2026-07-20 08:00:00'),
(6, 'GRA-00006', 6, 12, 5,    6,    6, 'FINALIZADO',   'RAD-2026-00006', '2026-03-15 08:00:00'),
(7, 'GRA-00007', 9, 13, 3,    4,    5, 'COMITE',       NULL,             '2026-05-01 08:00:00');

-- ---------------------------------------------------------------------
-- Documentos (PDF de ejemplo incluidos en /uploads)
-- ---------------------------------------------------------------------
INSERT INTO documento (id_proyecto, tipo, nombre_original, ruta, subido_en) VALUES
(2, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-09-22 10:00:00'),
(3, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-08-16 10:00:00'),
(3, 'ANTEPROYECTO',  'anteproyecto_iot.pdf','uploads/anteproyectos/ejemplo_anteproyecto.pdf', '2026-09-10 10:00:00'),
(4, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-08-02 10:00:00'),
(4, 'ANTEPROYECTO',  'anteproyecto_chatbot.pdf', 'uploads/anteproyectos/ejemplo_anteproyecto.pdf', '2026-08-25 10:00:00'),
(5, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-07-21 10:00:00'),
(5, 'ANTEPROYECTO',  'anteproyecto_reservas.pdf', 'uploads/anteproyectos/ejemplo_anteproyecto.pdf', '2026-08-05 10:00:00'),
(6, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-03-16 10:00:00'),
(6, 'ANTEPROYECTO',  'anteproyecto_desercion.pdf', 'uploads/anteproyectos/ejemplo_anteproyecto.pdf', '2026-04-01 10:00:00'),
(6, 'INFORME_FINAL', 'informe_final_desercion.pdf', 'uploads/informes/ejemplo_informe.pdf',     '2026-08-20 10:00:00'),
(7, 'PAGO',          'recibo_pago.pdf',     'uploads/pagos/ejemplo_pago.pdf',                 '2026-05-02 10:00:00'),
(7, 'ANTEPROYECTO',  'anteproyecto_gamificacion.pdf', 'uploads/anteproyectos/ejemplo_anteproyecto.pdf', '2026-05-20 10:00:00'),
(7, 'INFORME_FINAL', 'informe_final_gamificacion.pdf', 'uploads/informes/ejemplo_informe.pdf', '2026-09-28 10:00:00');

-- ---------------------------------------------------------------------
-- Evaluaciones (director, evaluador y decisiones del comité)
-- ---------------------------------------------------------------------
INSERT INTO evaluacion (id_proyecto, id_usuario, rol_evaluador, fase, nota, observaciones, decision, fecha) VALUES
(4, 5, 'DIRECTOR',  2, 4.2, 'Propuesta clara. Ajustar el cronograma antes de la evaluación.', 'APROBADO', '2026-09-01 15:00:00'),
(5, 3, 'DIRECTOR',  2, 4.5, 'Buen planteamiento del problema y objetivos medibles.',          'APROBADO', '2026-08-10 15:00:00'),
(5, 4, 'EVALUADOR', 3, 4.0, 'Se aprueba. Ampliar el estado del arte.',                         'APROBADO', '2026-08-20 15:00:00'),
(5, 2, 'COMITE',    3, NULL, 'Acta de comité No. 14: propuesta aprobada.',                     'APROBADO', '2026-08-28 15:00:00'),
(6, 5, 'DIRECTOR',  2, 4.6, 'Excelente propuesta.',                                            'APROBADO', '2026-04-05 15:00:00'),
(6, 6, 'EVALUADOR', 3, 4.4, 'Metodología adecuada.',                                           'APROBADO', '2026-04-15 15:00:00'),
(6, 2, 'COMITE',    3, NULL, 'Acta de comité No. 6: propuesta aprobada.',                      'APROBADO', '2026-04-22 15:00:00'),
(6, 5, 'DIRECTOR',  4, 4.7, 'Informe final completo, listo para evaluador.',                   'APROBADO', '2026-08-25 15:00:00'),
(6, 6, 'EVALUADOR', 5, 4.5, 'Resultados bien sustentados.',                                    'APROBADO', '2026-09-05 15:00:00'),
(6, 2, 'COMITE',    5, NULL, 'Acta de comité No. 18: informe final aprobado. Se autoriza cierre.', 'APROBADO', '2026-09-12 15:00:00'),
(7, 3, 'DIRECTOR',  2, 4.3, 'Propuesta pertinente.',                                           'APROBADO', '2026-05-25 15:00:00'),
(7, 4, 'EVALUADOR', 3, 4.1, 'Aprobada con observaciones menores.',                             'APROBADO', '2026-06-05 15:00:00'),
(7, 2, 'COMITE',    3, NULL, 'Acta de comité No. 9: propuesta aprobada.',                      'APROBADO', '2026-06-12 15:00:00'),
(7, 3, 'DIRECTOR',  4, 4.4, 'Informe final aprobado para revisión del evaluador.',             'APROBADO', '2026-10-01 15:00:00'),
(7, 4, 'EVALUADOR', 5, 4.2, 'Informe final aprobado. Pasa a comité.',                          'APROBADO', '2026-10-08 15:00:00');

-- ---------------------------------------------------------------------
-- Historial de fases
-- ---------------------------------------------------------------------
INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion, fecha) VALUES
(1, 0, 1,  7, 'Selección de idea del banco',                    '2026-10-01 08:00:00'),
(2, 0, 1,  8, 'Selección de idea del banco',                    '2026-09-20 08:00:00'),
(3, 0, 1,  9, 'Selección de idea del banco',                    '2026-08-15 08:00:00'),
(3, 1, 2,  2, 'Pago validado y director/evaluador asignados',   '2026-08-20 09:00:00'),
(4, 0, 1, 10, 'Selección de idea del banco',                    '2026-08-01 08:00:00'),
(4, 1, 2,  2, 'Pago validado y director/evaluador asignados',   '2026-08-05 09:00:00'),
(4, 2, 3,  5, 'Anteproyecto aprobado por el director',          '2026-09-01 15:00:00'),
(5, 0, 1, 11, 'Selección de idea del banco',                    '2026-07-20 08:00:00'),
(5, 1, 2,  2, 'Pago validado y director/evaluador asignados',   '2026-07-25 09:00:00'),
(5, 2, 3,  3, 'Anteproyecto aprobado por el director',          '2026-08-10 15:00:00'),
(5, 3, 4,  2, 'Propuesta aprobada por el comité',               '2026-08-28 15:00:00'),
(6, 0, 1, 12, 'Selección de idea del banco',                    '2026-03-15 08:00:00'),
(6, 1, 2,  2, 'Pago validado y director/evaluador asignados',   '2026-03-20 09:00:00'),
(6, 2, 3,  5, 'Anteproyecto aprobado por el director',          '2026-04-05 15:00:00'),
(6, 3, 4,  2, 'Propuesta aprobada por el comité',               '2026-04-22 15:00:00'),
(6, 4, 5,  5, 'Informe final aprobado por el director',         '2026-08-25 15:00:00'),
(6, 5, 6,  2, 'Cierre definitivo y radicado RAD-2026-00006',    '2026-09-12 15:00:00'),
(7, 0, 1, 13, 'Selección de idea del banco',                    '2026-05-01 08:00:00'),
(7, 1, 2,  2, 'Pago validado y director/evaluador asignados',   '2026-05-05 09:00:00'),
(7, 2, 3,  3, 'Anteproyecto aprobado por el director',          '2026-05-25 15:00:00'),
(7, 3, 4,  2, 'Propuesta aprobada por el comité',               '2026-06-12 15:00:00'),
(7, 4, 5,  3, 'Informe final aprobado por el director',         '2026-10-01 15:00:00');

-- ---------------------------------------------------------------------
-- Base documental: calendario académico oficial UTS y carpeta de documentos de grado
-- ---------------------------------------------------------------------
INSERT INTO recurso_documental (titulo, descripcion, url, icono, orden) VALUES
('Calendario académico',          'Consulta las fechas de los eventos académicos.',                 'https://www.uts.edu.co/calendario-academico/', 'bi-calendar3',          1),
('Formatos institucionales',      'Accede a todos los formatos de grado de manera eficiente.',      'https://www.dropbox.com/scl/fo/pudgcaq639agy7t06ahjs/AN084HnuyHffgYL5i--v_Ks/DOCUMENTOS%20DE%20GRADO?dl=0&rlkey=6s0b9ajweteyx2ang7ywvk6xm&subfolder_nav_tracking=1', 'bi-book',               2),
('Presentación de propuestas',    'Procedimiento a seguir para la presentación de la propuesta.',   'https://www.dropbox.com/scl/fo/pudgcaq639agy7t06ahjs/AN084HnuyHffgYL5i--v_Ks/DOCUMENTOS%20DE%20GRADO?dl=0&rlkey=6s0b9ajweteyx2ang7ywvk6xm&subfolder_nav_tracking=1', 'bi-journal-text',       3),
('Presentación de informe final', 'Procedimiento a seguir para la presentación del informe final.', 'https://www.dropbox.com/scl/fo/pudgcaq639agy7t06ahjs/AN084HnuyHffgYL5i--v_Ks/DOCUMENTOS%20DE%20GRADO?dl=0&rlkey=6s0b9ajweteyx2ang7ywvk6xm&subfolder_nav_tracking=1', 'bi-file-earmark-check', 4),
('Reglamento de estímulos',       'Procedimiento a seguir para obtener distinciones o estímulos.',  'https://www.uts.edu.co/sitio/wp-content/uploads/normatividad/reglamento-de-estimulos-y-distinciones.pdf', 'bi-trophy',             5),
('Reglamento de trabajos de grado','Procedimiento para elaborar un trabajo de grado.',              'https://www.uts.edu.co/sitio/wp-content/uploads/normatividad/reglamento_trabajo_grado.pdf', 'bi-list-check',         6);
