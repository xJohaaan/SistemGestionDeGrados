-- =====================================================================
--  Sistema de Gestión de Trabajos de Grado - UTS
--  Script de creación de la base de datos (MySQL 8)
--  Ejecutar primero este script y luego datos_prueba.sql
-- =====================================================================
CREATE DATABASE IF NOT EXISTS gestion_grados
    CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE gestion_grados;

SET FOREIGN_KEY_CHECKS = 0;
DROP TABLE IF EXISTS historial_fase;
DROP TABLE IF EXISTS evaluacion;
DROP TABLE IF EXISTS documento;
DROP TABLE IF EXISTS proyecto;
DROP TABLE IF EXISTS idea;
DROP TABLE IF EXISTS fase;
DROP TABLE IF EXISTS recurso_documental;
DROP TABLE IF EXISTS usuario;
SET FOREIGN_KEY_CHECKS = 1;

-- ---------------------------------------------------------------------
-- Usuarios del sistema. La contraseña se guarda como SHA-256(salt + clave).
-- Cada usuario tiene UN solo rol: un Docente Director no puede ser
-- Docente Evaluador y viceversa.
-- El Comité de Trabajos de Grado no es un usuario: sus decisiones las
-- registra Coordinación desde el módulo "Comité" (rol_evaluador = 'COMITE').
-- ---------------------------------------------------------------------
CREATE TABLE usuario (
    id_usuario   INT AUTO_INCREMENT PRIMARY KEY,
    codigo       VARCHAR(20)  NOT NULL,
    nombres      VARCHAR(80)  NOT NULL,
    apellidos    VARCHAR(80)  NOT NULL,
    correo       VARCHAR(120) NOT NULL,
    telefono     VARCHAR(20)  NULL,
    rol          ENUM('ADMIN','COORDINACION','DIRECTOR','EVALUADOR','ESTUDIANTE') NOT NULL,
    salt         CHAR(32)     NOT NULL,
    contrasena   CHAR(64)     NOT NULL,
    estado       ENUM('Activo','Inactivo') NOT NULL DEFAULT 'Activo',
    creado_en    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT uq_usuario_codigo UNIQUE (codigo),
    CONSTRAINT uq_usuario_correo UNIQUE (correo),
    INDEX idx_usuario_rol (rol),
    INDEX idx_usuario_nombre (apellidos, nombres)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Catálogo de fases del proyecto de grado
-- ---------------------------------------------------------------------
CREATE TABLE fase (
    id_fase      TINYINT PRIMARY KEY,
    nombre       VARCHAR(60)  NOT NULL,
    descripcion  VARCHAR(200) NOT NULL,
    icono        VARCHAR(40)  NOT NULL
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Banco de ideas
-- ---------------------------------------------------------------------
CREATE TABLE idea (
    id_idea      INT AUTO_INCREMENT PRIMARY KEY,
    titulo       VARCHAR(150) NOT NULL,
    descripcion  TEXT         NOT NULL,
    linea        VARCHAR(80)  NOT NULL,
    id_autor     INT          NOT NULL,
    estado       ENUM('Pendiente','Aprobada','Rechazada','Tomada') NOT NULL DEFAULT 'Pendiente',
    observacion  VARCHAR(300) NULL,
    creado_en    TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_idea_autor FOREIGN KEY (id_autor) REFERENCES usuario(id_usuario)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_idea_estado (estado)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Proyectos de grado.
--   fase: 1 Pago, 2 Anteproyecto, 3 Evaluación de propuesta,
--         4 Informe final, 5 Revisión final, 6 Cierre (Final)
--   responsable: quién debe actuar ahora sobre el proyecto
-- ---------------------------------------------------------------------
CREATE TABLE proyecto (
    id_proyecto     INT AUTO_INCREMENT PRIMARY KEY,
    codigo          VARCHAR(12)  NULL,
    id_idea         INT          NOT NULL,
    id_estudiante   INT          NOT NULL,
    id_director     INT          NULL,
    id_evaluador    INT          NULL,
    fase            TINYINT      NOT NULL DEFAULT 1,
    responsable     ENUM('ESTUDIANTE','COORDINACION','DIRECTOR','EVALUADOR','COMITE','FINALIZADO') NOT NULL DEFAULT 'ESTUDIANTE',
    radicado        VARCHAR(20)  NULL,
    creado_en       TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    actualizado_en  TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT uq_proyecto_codigo     UNIQUE (codigo),
    CONSTRAINT uq_proyecto_idea       UNIQUE (id_idea),
    CONSTRAINT uq_proyecto_estudiante UNIQUE (id_estudiante),
    CONSTRAINT uq_proyecto_radicado   UNIQUE (radicado),
    CONSTRAINT fk_proyecto_idea       FOREIGN KEY (id_idea)       REFERENCES idea(id_idea)       ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_proyecto_estudiante FOREIGN KEY (id_estudiante) REFERENCES usuario(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_proyecto_director   FOREIGN KEY (id_director)   REFERENCES usuario(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_proyecto_evaluador  FOREIGN KEY (id_evaluador)  REFERENCES usuario(id_usuario) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_proyecto_fase       FOREIGN KEY (fase)          REFERENCES fase(id_fase)       ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_proyecto_fase (fase, responsable),
    INDEX idx_proyecto_director (id_director),
    INDEX idx_proyecto_evaluador (id_evaluador)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Documentos subidos por el estudiante (solo PDF)
-- ---------------------------------------------------------------------
CREATE TABLE documento (
    id_documento     INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto      INT          NOT NULL,
    tipo             ENUM('PAGO','ANTEPROYECTO','INFORME_FINAL') NOT NULL,
    nombre_original  VARCHAR(200) NOT NULL,
    ruta             VARCHAR(255) NOT NULL,
    subido_en        TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_documento_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto)
        ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_documento_tipo (id_proyecto, tipo)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Calificaciones / conceptos del director, evaluador y comité
-- ---------------------------------------------------------------------
CREATE TABLE evaluacion (
    id_evaluacion   INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto     INT          NOT NULL,
    id_usuario      INT          NOT NULL,
    rol_evaluador   ENUM('DIRECTOR','EVALUADOR','COMITE') NOT NULL,
    fase            TINYINT      NOT NULL,
    nota            DECIMAL(3,1) NULL,
    observaciones   TEXT         NOT NULL,
    decision        ENUM('APROBADO','RECHAZADO') NOT NULL,
    fecha           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_evaluacion_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_evaluacion_usuario  FOREIGN KEY (id_usuario)  REFERENCES usuario(id_usuario)   ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT ck_evaluacion_nota CHECK (nota IS NULL OR (nota >= 0 AND nota <= 5)),
    INDEX idx_evaluacion_proyecto (id_proyecto, fase)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Historial de cambios de fase (fecha y hora exacta de cada transición)
-- ---------------------------------------------------------------------
CREATE TABLE historial_fase (
    id_historial    INT AUTO_INCREMENT PRIMARY KEY,
    id_proyecto     INT          NOT NULL,
    fase_anterior   TINYINT      NOT NULL,
    fase_nueva      TINYINT      NOT NULL,
    id_usuario      INT          NOT NULL,
    descripcion     VARCHAR(200) NOT NULL,
    fecha           TIMESTAMP    NOT NULL DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_historial_proyecto FOREIGN KEY (id_proyecto) REFERENCES proyecto(id_proyecto) ON DELETE RESTRICT ON UPDATE CASCADE,
    CONSTRAINT fk_historial_usuario  FOREIGN KEY (id_usuario)  REFERENCES usuario(id_usuario)   ON DELETE RESTRICT ON UPDATE CASCADE,
    INDEX idx_historial_proyecto (id_proyecto, fecha)
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Base documental (calendario, formatos, reglamentos)
-- ---------------------------------------------------------------------
CREATE TABLE recurso_documental (
    id_recurso   INT AUTO_INCREMENT PRIMARY KEY,
    titulo       VARCHAR(100) NOT NULL,
    descripcion  VARCHAR(200) NOT NULL,
    url          VARCHAR(255) NOT NULL,
    icono        VARCHAR(40)  NOT NULL,
    orden        TINYINT      NOT NULL DEFAULT 0
) ENGINE=InnoDB;

-- ---------------------------------------------------------------------
-- Integridad de roles en los proyectos:
--   id_estudiante -> usuario con rol ESTUDIANTE
--   id_director   -> usuario con rol DIRECTOR
--   id_evaluador  -> usuario con rol EVALUADOR
-- y no se permite cambiar el rol de un usuario que ya participa en proyectos.
-- ---------------------------------------------------------------------
DROP TRIGGER IF EXISTS trg_proyecto_roles_ins;
DROP TRIGGER IF EXISTS trg_proyecto_roles_upd;
DROP TRIGGER IF EXISTS trg_usuario_rol_upd;

DELIMITER $$
CREATE TRIGGER trg_proyecto_roles_ins BEFORE INSERT ON proyecto FOR EACH ROW
BEGIN
    IF (SELECT rol FROM usuario WHERE id_usuario = NEW.id_estudiante) <> 'ESTUDIANTE' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El proyecto debe pertenecer a un usuario con rol ESTUDIANTE';
    END IF;
    IF NEW.id_director IS NOT NULL AND (SELECT rol FROM usuario WHERE id_usuario = NEW.id_director) <> 'DIRECTOR' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El director asignado debe tener rol DIRECTOR';
    END IF;
    IF NEW.id_evaluador IS NOT NULL AND (SELECT rol FROM usuario WHERE id_usuario = NEW.id_evaluador) <> 'EVALUADOR' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evaluador asignado debe tener rol EVALUADOR';
    END IF;
END$$

CREATE TRIGGER trg_proyecto_roles_upd BEFORE UPDATE ON proyecto FOR EACH ROW
BEGIN
    IF NEW.id_director IS NOT NULL AND (SELECT rol FROM usuario WHERE id_usuario = NEW.id_director) <> 'DIRECTOR' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El director asignado debe tener rol DIRECTOR';
    END IF;
    IF NEW.id_evaluador IS NOT NULL AND (SELECT rol FROM usuario WHERE id_usuario = NEW.id_evaluador) <> 'EVALUADOR' THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'El evaluador asignado debe tener rol EVALUADOR';
    END IF;
END$$

CREATE TRIGGER trg_usuario_rol_upd BEFORE UPDATE ON usuario FOR EACH ROW
BEGIN
    IF NEW.rol <> OLD.rol AND EXISTS (SELECT 1 FROM proyecto
            WHERE id_estudiante = OLD.id_usuario OR id_director = OLD.id_usuario OR id_evaluador = OLD.id_usuario) THEN
        SIGNAL SQLSTATE '45000' SET MESSAGE_TEXT = 'No se puede cambiar el rol de un usuario con proyectos asociados';
    END IF;
END$$
DELIMITER ;

INSERT INTO fase (id_fase, nombre, descripcion, icono) VALUES
(1, 'Pago',                    'Carga del recibo de pago institucional.',                       'bi-cash-coin'),
(2, 'Anteproyecto',            'El estudiante radica la propuesta y el director la califica.',  'bi-file-earmark-text'),
(3, 'Evaluación de propuesta', 'El evaluador y el comité aprueban la propuesta.',               'bi-clipboard-check'),
(4, 'Informe final',           'El estudiante sube el informe final y el director lo revisa.',  'bi-journal-richtext'),
(5, 'Revisión final',          'El evaluador y el comité revisan el informe final.',            'bi-patch-check'),
(6, 'Cierre',                  'Cierre definitivo del proyecto y radicado de grado.',           'bi-mortarboard');
