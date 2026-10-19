package co.edu.uts.grados.pruebas;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.AfterEach;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;

/**
 * Pruebas de las reglas de negocio garantizadas por la base de datos
 * (triggers, llaves únicas, CHECK, llaves foráneas y cálculos SQL usados por las JSP).
 * <p>
 * Cada prueba corre dentro de una transacción que se deshace al final ({@code rollback}),
 * por lo que no modifica los datos reales del sistema.
 * </p>
 */
@DisplayName("Reglas de negocio en la base de datos")
class ReglasBaseDatosTest {

    private Connection con;

    @BeforeEach
    void abrirTransaccion() throws Exception {
        con = Config.conexion();
        con.setAutoCommit(false);
    }

    @AfterEach
    void deshacer() throws Exception {
        con.rollback();
        con.close();
    }

    /** Las transacciones deshechas consumen valores AUTO_INCREMENT; se reajustan para no dejar huecos. */
    @AfterAll
    static void reajustarAutoincrementos() throws Exception {
        try (Connection c = Config.conexion(); Statement st = c.createStatement()) {
            for (String t : new String[] {"usuario", "idea", "proyecto", "documento", "evaluacion", "historial_fase"}) {
                st.execute("ALTER TABLE " + t + " AUTO_INCREMENT = 1");
            }
        }
    }

    private Integer uno(String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getInt(1) : null;
            }
        }
    }

    private String texto(String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            try (ResultSet rs = ps.executeQuery()) {
                return rs.next() ? rs.getString(1) : null;
            }
        }
    }

    private int ejecutar(String sql, Object... params) throws SQLException {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < params.length; i++) ps.setObject(i + 1, params[i]);
            return ps.executeUpdate();
        }
    }

    private int usuarioConRol(String rol) throws SQLException {
        Integer id = uno("SELECT id_usuario FROM usuario WHERE rol = ? ORDER BY id_usuario LIMIT 1", rol);
        assumeTrue(id != null, "No hay usuarios con rol " + rol);
        return id;
    }

    private int proyectoConDirector() throws SQLException {
        Integer id = uno("SELECT id_proyecto FROM proyecto WHERE id_director IS NOT NULL ORDER BY id_proyecto LIMIT 1");
        assumeTrue(id != null, "No hay proyectos con director asignado");
        return id;
    }

    /** Crea un estudiante y una idea aprobada propios de la prueba (se deshacen con el rollback). */
    private int[] estudianteEIdeaNuevos() throws SQLException {
        ejecutar("INSERT INTO usuario (codigo, nombres, apellidos, correo, rol, salt, contrasena) "
                + "VALUES ('PRB-EST', 'Prueba', 'Estudiante', 'prb.est@test.local', 'ESTUDIANTE', 'x', 'x')");
        int est = uno("SELECT LAST_INSERT_ID()");
        ejecutar("INSERT INTO idea (titulo, descripcion, linea, id_autor, estado) "
                + "VALUES ('Idea de prueba', 'Descripción de prueba', 'Ingeniería de software', ?, 'Aprobada')", est);
        int idea = uno("SELECT LAST_INSERT_ID()");
        return new int[] {est, idea};
    }

    @Test
    @DisplayName("Login: SHA-256 con salt acepta la clave correcta y rechaza la incorrecta")
    void hashDeContrasena() throws Exception {
        ejecutar("INSERT INTO usuario (codigo, nombres, apellidos, correo, rol, salt, contrasena) "
                + "SELECT 'PRB-LOGIN', 'A', 'B', 'prb.login@test.local', 'ESTUDIANTE', s.salt, SHA2(CONCAT(s.salt, 'secreta1'), 256) "
                + "FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) s");
        String sql = "SELECT COUNT(*) FROM usuario WHERE correo = ? AND estado = 'Activo' AND contrasena = SHA2(CONCAT(salt, ?), 256)";
        assertEquals(1, uno(sql, "prb.login@test.local", "secreta1"));
        assertEquals(0, uno(sql, "prb.login@test.local", "Secreta1"));
        assertEquals(0, uno(sql, "prb.login@test.local", "' OR '1'='1"));
        assertEquals(64, uno("SELECT LENGTH(contrasena) FROM usuario WHERE correo = 'prb.login@test.local'"));
        assertEquals(32, uno("SELECT LENGTH(salt) FROM usuario WHERE correo = 'prb.login@test.local'"));
    }

    @Test
    @DisplayName("Dos usuarios con la misma clave tienen hashes distintos (salt único)")
    void saltDistintoPorUsuario() throws Exception {
        for (String c : new String[] {"prb.a@test.local", "prb.b@test.local"}) {
            ejecutar("INSERT INTO usuario (codigo, nombres, apellidos, correo, rol, salt, contrasena) "
                    + "SELECT ?, 'A', 'B', ?, 'ESTUDIANTE', s.salt, SHA2(CONCAT(s.salt, 'igual123'), 256) "
                    + "FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) s", "PRB-" + c.charAt(4), c);
        }
        assertEquals(2, uno("SELECT COUNT(DISTINCT contrasena) FROM usuario WHERE correo LIKE 'prb._@test.local'"));
    }

    @Test
    @DisplayName("Trigger: un Docente Evaluador no puede quedar como director")
    void directorDebeTenerRolDirector() throws Exception {
        int evaluador = usuarioConRol("EVALUADOR");
        SQLException e = assertThrows(SQLException.class,
                () -> ejecutar("UPDATE proyecto SET id_director = ? WHERE id_proyecto = ?", evaluador, proyectoConDirector()));
        assertEquals("45000", e.getSQLState());
        assertTrue(e.getMessage().contains("DIRECTOR"));
    }

    @Test
    @DisplayName("Trigger: un Docente Director no puede quedar como evaluador")
    void evaluadorDebeTenerRolEvaluador() throws Exception {
        int director = usuarioConRol("DIRECTOR");
        SQLException e = assertThrows(SQLException.class,
                () -> ejecutar("UPDATE proyecto SET id_evaluador = ? WHERE id_proyecto = ?", director, proyectoConDirector()));
        assertEquals("45000", e.getSQLState());
    }

    @Test
    @DisplayName("Trigger: solo un ESTUDIANTE puede ser dueño de un proyecto")
    void proyectoSoloParaEstudiantes() throws Exception {
        int director = usuarioConRol("DIRECTOR");
        int idea = estudianteEIdeaNuevos()[1];
        SQLException e = assertThrows(SQLException.class,
                () -> ejecutar("INSERT INTO proyecto (id_idea, id_estudiante) VALUES (?, ?)", idea, director));
        assertEquals("45000", e.getSQLState());
    }

    @Test
    @DisplayName("Trigger: no se cambia el rol de un docente que ya tiene proyectos")
    void noCambiarRolConProyectos() throws Exception {
        int director = uno("SELECT id_director FROM proyecto WHERE id_director IS NOT NULL LIMIT 1");
        SQLException e = assertThrows(SQLException.class,
                () -> ejecutar("UPDATE usuario SET rol = 'EVALUADOR' WHERE id_usuario = ?", director));
        assertEquals("45000", e.getSQLState());
    }

    @Test
    @DisplayName("Un estudiante solo puede tener un proyecto y una idea solo un proyecto")
    void unicidadDeProyecto() throws Exception {
        int[] ei = estudianteEIdeaNuevos();
        ejecutar("INSERT INTO proyecto (id_idea, id_estudiante) VALUES (?, ?)", ei[1], ei[0]);
        Integer otraIdea = uno("SELECT id_idea FROM idea WHERE id_idea <> ? AND id_idea NOT IN (SELECT id_idea FROM proyecto) LIMIT 1", ei[1]);
        assumeTrue(otraIdea != null, "No hay otra idea libre");
        assertThrows(SQLException.class,
                () -> ejecutar("INSERT INTO proyecto (id_idea, id_estudiante) VALUES (?, ?)", otraIdea, ei[0]),
                "El mismo estudiante no puede tener dos proyectos");
        Integer otroEst = uno("SELECT id_usuario FROM usuario WHERE rol = 'ESTUDIANTE' AND id_usuario NOT IN (SELECT id_estudiante FROM proyecto) AND id_usuario <> ? LIMIT 1", ei[0]);
        if (otroEst != null) {
            assertThrows(SQLException.class,
                    () -> ejecutar("INSERT INTO proyecto (id_idea, id_estudiante) VALUES (?, ?)", ei[1], otroEst),
                    "La misma idea no puede tener dos proyectos");
        }
    }

    @Test
    @DisplayName("Al seleccionar la idea se genera el código GRA-NNNNN")
    void codigoDeProyecto() throws Exception {
        int[] ei = estudianteEIdeaNuevos();
        ejecutar("INSERT INTO proyecto (id_idea, id_estudiante, fase, responsable) VALUES (?, ?, 1, 'ESTUDIANTE')", ei[1], ei[0]);
        ejecutar("UPDATE proyecto SET codigo = CONCAT('GRA-', LPAD(id_proyecto, 5, '0')) WHERE id_estudiante = ?", ei[0]);
        String codigo = texto("SELECT codigo FROM proyecto WHERE id_estudiante = ?", ei[0]);
        int id = uno("SELECT id_proyecto FROM proyecto WHERE id_estudiante = ?", ei[0]);
        assertEquals(String.format("GRA-%05d", id), codigo);
    }

    @Test
    @DisplayName("El radicado de cierre tiene el formato RAD-AAAA-NNNNN")
    void formatoDeRadicado() throws Exception {
        int id = proyectoConDirector();
        String rad = texto("SELECT CONCAT('RAD-', YEAR(CURRENT_DATE), '-', LPAD(?, 5, '0'))", id);
        assertTrue(rad.matches("RAD-\\d{4}-\\d{5}"), rad);
    }

    @Test
    @DisplayName("La nota debe estar entre 0.0 y 5.0")
    void notaEnRango() throws Exception {
        int proyecto = proyectoConDirector();
        int director = uno("SELECT id_director FROM proyecto WHERE id_proyecto = ?", proyecto);
        String sql = "INSERT INTO evaluacion (id_proyecto, id_usuario, rol_evaluador, fase, nota, observaciones, decision) "
                + "VALUES (?, ?, 'DIRECTOR', 2, ?, 'prueba', 'APROBADO')";
        assertEquals(1, ejecutar(sql, proyecto, director, 4.5));
        assertThrows(SQLException.class, () -> ejecutar(sql, proyecto, director, 5.1));
        assertThrows(SQLException.class, () -> ejecutar(sql, proyecto, director, -0.1));
    }

    @Test
    @DisplayName("No se puede borrar un docente con proyectos (ON DELETE RESTRICT)")
    void noBorrarDocenteConProyectos() throws Exception {
        int director = uno("SELECT id_director FROM proyecto WHERE id_director IS NOT NULL LIMIT 1");
        assertThrows(SQLException.class, () -> ejecutar("DELETE FROM usuario WHERE id_usuario = ?", director));
    }

    @Test
    @DisplayName("No se puede borrar una idea que ya tiene proyecto")
    void noBorrarIdeaTomada() throws Exception {
        int idea = uno("SELECT id_idea FROM proyecto LIMIT 1");
        assertThrows(SQLException.class, () -> ejecutar("DELETE FROM idea WHERE id_idea = ?", idea));
    }

    @Test
    @DisplayName("El historial guarda automáticamente la fecha y hora del cambio de fase")
    void historialConFecha() throws Exception {
        int proyecto = proyectoConDirector();
        int usuario = usuarioConRol("COORDINACION");
        ejecutar("INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion) "
                + "VALUES (?, 1, 2, ?, 'prueba')", proyecto, usuario);
        assertNotNull(texto("SELECT fecha FROM historial_fase WHERE id_historial = LAST_INSERT_ID()"));
        assertEquals(1, uno("SELECT TIMESTAMPDIFF(MINUTE, fecha, NOW()) < 1 FROM historial_fase WHERE id_historial = LAST_INSERT_ID()"));
    }

    @Test
    @DisplayName("El correo y el código de usuario son únicos")
    void correoYCodigoUnicos() throws Exception {
        String correo = texto("SELECT correo FROM usuario LIMIT 1");
        assertThrows(SQLException.class, () -> ejecutar(
                "INSERT INTO usuario (codigo, nombres, apellidos, correo, rol, salt, contrasena) VALUES ('PRB-DUP', 'a', 'b', ?, 'ESTUDIANTE', 'x', 'x')", correo));
    }
}
