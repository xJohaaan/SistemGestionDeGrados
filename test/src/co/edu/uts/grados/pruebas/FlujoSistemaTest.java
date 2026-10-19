package co.edu.uts.grados.pruebas;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.junit.jupiter.api.Assumptions.assumeTrue;

import java.io.ByteArrayOutputStream;
import java.io.InputStream;
import java.io.OutputStream;
import java.net.CookieManager;
import java.net.CookiePolicy;
import java.net.HttpURLConnection;
import java.net.URI;
import java.net.URL;
import java.net.URLEncoder;
import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

import org.junit.jupiter.api.AfterAll;
import org.junit.jupiter.api.BeforeAll;
import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.MethodOrderer;
import org.junit.jupiter.api.Order;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.api.TestMethodOrder;

/**
 * Prueba de extremo a extremo contra el sistema desplegado en Tomcat.
 * <p>
 * Crea sus propios usuarios (estudiante, coordinación, director y evaluador con correos
 * {@code @test.local}) y una idea, recorre el flujo completo desde la selección de la idea hasta
 * el cierre con radicado (incluyendo devoluciones y rechazos) y al final borra todo lo creado.
 * Los datos reales del sistema no se modifican.
 * </p>
 * Requiere Tomcat iniciado; si no responde, las pruebas se omiten.
 */
@TestMethodOrder(MethodOrderer.OrderAnnotation.class)
@DisplayName("Flujo completo de un trabajo de grado (HTTP)")
class FlujoSistemaTest {

    static final String CLAVE = "Prueba123";
    static final String EST = "prb.estudiante@test.local", COO = "prb.coordinacion@test.local",
            DIR = "prb.director@test.local", EVA = "prb.evaluador@test.local";
    static final byte[] PDF = ("%PDF-1.4\n1 0 obj << /Type /Catalog >> endobj\ntrailer << /Root 1 0 R >>\n%%EOF\n")
            .getBytes(StandardCharsets.US_ASCII);

    static int idIdea, idDirector, idEvaluador;
    static Integer idProyecto;
    static ClienteWeb est, coo, dir, eva;

    // ------------------------------------------------------------------ cliente HTTP mínimo

    /** Navegador mínimo: guarda cookies y no sigue redirecciones para poder verificarlas. */
    static final class ClienteWeb {
        final CookieManager cookies = new CookieManager(null, CookiePolicy.ACCEPT_ALL);
        int codigo;
        String cuerpo, ubicacion;

        ClienteWeb get(String ruta) throws Exception { return enviar("GET", ruta, null, null); }

        ClienteWeb post(String ruta, String... pares) throws Exception {
            StringBuilder sb = new StringBuilder();
            for (int i = 0; i < pares.length; i += 2) {
                if (sb.length() > 0) sb.append('&');
                sb.append(URLEncoder.encode(pares[i], "UTF-8")).append('=').append(URLEncoder.encode(pares[i + 1], "UTF-8"));
            }
            return enviar("POST", ruta, sb.toString().getBytes(StandardCharsets.UTF_8), "application/x-www-form-urlencoded; charset=UTF-8");
        }

        ClienteWeb subir(String ruta, String nombreArchivo, byte[] contenido) throws Exception {
            String limite = "----limitePrueba" + System.nanoTime();
            ByteArrayOutputStream b = new ByteArrayOutputStream();
            b.write(("--" + limite + "\r\nContent-Disposition: form-data; name=\"archivo\"; filename=\"" + nombreArchivo
                    + "\"\r\nContent-Type: application/pdf\r\n\r\n").getBytes(StandardCharsets.UTF_8));
            b.write(contenido);
            b.write(("\r\n--" + limite + "--\r\n").getBytes(StandardCharsets.UTF_8));
            return enviar("POST", ruta, b.toByteArray(), "multipart/form-data; boundary=" + limite);
        }

        ClienteWeb entrar(String correo) throws Exception {
            get("/login.jsp");
            post("/login.jsp", "correo", correo, "contrasena", CLAVE);
            return this;
        }

        /** Mensaje de éxito o error que dejó el último controlador (se lee de la página destino). */
        String mensaje() throws Exception {
            get(ubicacion.replace(Config.URL_APP, "").replaceFirst("^/SistemGestionDeGrados", ""));
            java.util.regex.Matcher m = java.util.regex.Pattern
                    .compile("-fill me-1\"></i>\\s*([^<]+)").matcher(cuerpo);
            return m.find() ? m.group(1).trim() : "";
        }

        private ClienteWeb enviar(String metodo, String ruta, byte[] datos, String tipo) throws Exception {
            URL url = new URL(Config.URL_APP + ruta);
            HttpURLConnection c = (HttpURLConnection) url.openConnection();
            c.setInstanceFollowRedirects(false);
            c.setRequestMethod(metodo);
            URI uri = url.toURI();
            cookies.get(uri, new java.util.HashMap<>()).forEach((k, v) -> v.forEach(val -> c.addRequestProperty(k, val)));
            if (datos != null) {
                c.setDoOutput(true);
                c.setRequestProperty("Content-Type", tipo);
                try (OutputStream o = c.getOutputStream()) { o.write(datos); }
            }
            codigo = c.getResponseCode();
            cookies.put(uri, c.getHeaderFields());
            ubicacion = c.getHeaderField("Location");
            try (InputStream in = codigo >= 400 ? c.getErrorStream() : c.getInputStream()) {
                cuerpo = in == null ? "" : new String(leer(in), StandardCharsets.UTF_8);
            }
            return this;
        }

        private static byte[] leer(InputStream in) throws Exception {
            ByteArrayOutputStream b = new ByteArrayOutputStream();
            byte[] buf = new byte[8192];
            for (int n; (n = in.read(buf)) > 0; ) b.write(buf, 0, n);
            return b.toByteArray();
        }
    }

    // ------------------------------------------------------------------ preparación y limpieza

    @BeforeAll
    static void prepararDatos() throws Exception {
        try {
            HttpURLConnection c = (HttpURLConnection) new URL(Config.URL_APP + "/login.jsp").openConnection();
            c.setConnectTimeout(3000);
            assumeTrue(c.getResponseCode() == 200, "Tomcat no responde");
        } catch (java.io.IOException e) {
            assumeTrue(false, "Tomcat no está iniciado: " + e.getMessage());
        }
        limpiar();
        try (Connection con = Config.conexion()) {
            String sql = "INSERT INTO usuario (codigo, nombres, apellidos, correo, rol, salt, contrasena) "
                    + "SELECT ?, ?, 'Prueba', ?, ?, s.salt, SHA2(CONCAT(s.salt, ?), 256) FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) s";
            String[][] us = {{"PRB-0001", "Estudiante", EST, "ESTUDIANTE"}, {"PRB-0002", "Coordinación", COO, "COORDINACION"},
                             {"PRB-0003", "Director", DIR, "DIRECTOR"}, {"PRB-0004", "Evaluador", EVA, "EVALUADOR"}};
            for (String[] u : us) {
                try (PreparedStatement ps = con.prepareStatement(sql)) {
                    ps.setString(1, u[0]); ps.setString(2, u[1]); ps.setString(3, u[2]); ps.setString(4, u[3]); ps.setString(5, CLAVE);
                    ps.executeUpdate();
                }
            }
            idDirector = entero(con, "SELECT id_usuario FROM usuario WHERE correo = ?", DIR);
            idEvaluador = entero(con, "SELECT id_usuario FROM usuario WHERE correo = ?", EVA);
            try (PreparedStatement ps = con.prepareStatement("INSERT INTO idea (titulo, descripcion, linea, id_autor, estado) "
                    + "SELECT 'Idea de prueba automatizada', 'Idea creada por FlujoSistemaTest para recorrer el flujo completo.', "
                    + "'Ingeniería de software', id_usuario, 'Aprobada' FROM usuario WHERE correo = ?")) {
                ps.setString(1, COO);
                ps.executeUpdate();
            }
            idIdea = entero(con, "SELECT id_idea FROM idea WHERE titulo = 'Idea de prueba automatizada'");
        }
        est = new ClienteWeb().entrar(EST);
        coo = new ClienteWeb().entrar(COO);
        dir = new ClienteWeb().entrar(DIR);
        eva = new ClienteWeb().entrar(EVA);
    }

    @AfterAll
    static void limpiar() throws Exception {
        try (Connection con = Config.conexion(); Statement st = con.createStatement()) {
            String usuarios = "(SELECT id_usuario FROM (SELECT id_usuario FROM usuario WHERE correo LIKE 'prb.%@test.local') u)";
            String proyectos = "(SELECT id_proyecto FROM (SELECT id_proyecto FROM proyecto WHERE id_estudiante IN " + usuarios + ") p)";
            List<String> archivos = new ArrayList<>();
            try (ResultSet rs = st.executeQuery("SELECT ruta FROM documento WHERE id_proyecto IN " + proyectos)) {
                while (rs.next()) archivos.add(rs.getString(1));
            }
            st.executeUpdate("DELETE FROM historial_fase WHERE id_proyecto IN " + proyectos);
            st.executeUpdate("DELETE FROM evaluacion WHERE id_proyecto IN " + proyectos);
            st.executeUpdate("DELETE FROM documento WHERE id_proyecto IN " + proyectos);
            st.executeUpdate("DELETE FROM proyecto WHERE id_estudiante IN " + usuarios);
            st.executeUpdate("DELETE FROM idea WHERE id_autor IN " + usuarios);
            st.executeUpdate("DELETE FROM usuario WHERE correo LIKE 'prb.%@test.local'");
            for (String t : new String[] {"usuario", "idea", "proyecto", "documento", "evaluacion", "historial_fase"}) {
                st.execute("ALTER TABLE " + t + " AUTO_INCREMENT = 1");
            }
            for (String r : archivos) {
                Files.deleteIfExists(Paths.get(System.getProperty("app.raiz", "."), r));
            }
        }
    }

    // ------------------------------------------------------------------ utilidades

    static int entero(Connection con, String sql, Object... p) throws Exception {
        try (PreparedStatement ps = con.prepareStatement(sql)) {
            for (int i = 0; i < p.length; i++) ps.setObject(i + 1, p[i]);
            try (ResultSet rs = ps.executeQuery()) { assertTrue(rs.next(), "sin resultado: " + sql); return rs.getInt(1); }
        }
    }

    /** Estado actual del proyecto de prueba como "fase/responsable". */
    static String estado() throws Exception {
        try (Connection con = Config.conexion();
             PreparedStatement ps = con.prepareStatement("SELECT CONCAT(fase, '/', responsable) FROM proyecto WHERE id_proyecto = ?")) {
            ps.setInt(1, idProyecto);
            try (ResultSet rs = ps.executeQuery()) { return rs.next() ? rs.getString(1) : null; }
        }
    }

    static String id() { return String.valueOf(idProyecto); }

    // ------------------------------------------------------------------ pruebas

    @Test @Order(1)
    @DisplayName("Login: credenciales válidas entran al panel de su rol; inválidas y SQLi no")
    void login() throws Exception {
        ClienteWeb c = new ClienteWeb();
        c.get("/login.jsp").post("/login.jsp", "correo", DIR, "contrasena", CLAVE);
        assertEquals(302, c.codigo);
        assertTrue(c.ubicacion.endsWith("/director/index.jsp"), c.ubicacion);
        c = new ClienteWeb();
        c.post("/login.jsp", "correo", DIR, "contrasena", "otra");
        assertEquals(200, c.codigo);
        assertTrue(c.cuerpo.contains("Correo o contraseña incorrectos"));
        c.post("/login.jsp", "correo", "' OR '1'='1", "contrasena", "' OR '1'='1");
        assertTrue(c.cuerpo.contains("Correo o contraseña incorrectos"));
    }

    @Test @Order(2)
    @DisplayName("Cada rol solo entra a su carpeta")
    void matrizDeAcceso() throws Exception {
        assertEquals(200, est.get("/estudiante/index.jsp").codigo);
        assertTrue(est.get("/director/index.jsp").ubicacion.endsWith("/acceso.jsp"));
        assertTrue(dir.get("/evaluador/index.jsp").ubicacion.endsWith("/acceso.jsp"));
        assertTrue(eva.get("/coordinacion/index.jsp").ubicacion.endsWith("/acceso.jsp"));
        assertTrue(coo.get("/admin/index.jsp").ubicacion.endsWith("/acceso.jsp"));
        assertTrue(new ClienteWeb().get("/coordinacion/index.jsp").ubicacion.endsWith("/login.jsp"));
    }

    @Test @Order(3)
    @DisplayName("Fase 0: el estudiante selecciona la idea y se crea su proyecto GRA en Fase 1")
    void seleccionarIdea() throws Exception {
        est.post("/ideas/controlador_idea.jsp", "accion", "seleccionar", "id", String.valueOf(idIdea));
        assertTrue(est.mensaje().startsWith("¡Idea seleccionada!"));
        try (Connection con = Config.conexion()) {
            idProyecto = entero(con, "SELECT id_proyecto FROM proyecto WHERE id_idea = ?", idIdea);
            assertEquals(1, entero(con, "SELECT COUNT(*) FROM proyecto WHERE id_proyecto = ? AND codigo = ?",
                    idProyecto, String.format("GRA-%05d", idProyecto)), "código GRA-NNNNN generado");
            assertEquals(1, entero(con, "SELECT COUNT(*) FROM idea WHERE id_idea = ? AND estado = 'Tomada'", idIdea));
        }
        assertEquals("1/ESTUDIANTE", estado());
        est.post("/ideas/controlador_idea.jsp", "accion", "seleccionar", "id", String.valueOf(idIdea));
        assertTrue(est.mensaje().startsWith("Ya tienes un proyecto"));
    }

    @Test @Order(4)
    @DisplayName("Fase 1: se rechaza un archivo que no es PDF y se acepta el recibo PDF")
    void subirPago() throws Exception {
        est.subir("/estudiante/controlador_documento.jsp", "recibo.txt", PDF);
        assertTrue(est.mensaje().contains("formato PDF"));
        est.subir("/estudiante/controlador_documento.jsp", "renombrado.pdf", "MZ ejecutable".getBytes(StandardCharsets.US_ASCII));
        assertTrue(est.mensaje().contains("no es un PDF válido"));
        assertEquals("1/ESTUDIANTE", estado());
        est.subir("/estudiante/controlador_documento.jsp", "recibo.pdf", PDF);
        assertTrue(est.mensaje().startsWith("Documento enviado"));
        assertEquals("1/COORDINACION", estado());
    }

    @Test @Order(5)
    @DisplayName("Coordinación asigna director y evaluador; roles cruzados se rechazan")
    void asignarDocentes() throws Exception {
        coo.post("/coordinacion/controlador_asignacion.jsp", "id", id(),
                "director", String.valueOf(idEvaluador), "evaluador", String.valueOf(idDirector));
        assertTrue(coo.mensaje().startsWith("No "), "roles cruzados deben rechazarse");
        assertEquals("1/COORDINACION", estado());
        coo.post("/coordinacion/controlador_asignacion.jsp", "id", id(),
                "director", String.valueOf(idDirector), "evaluador", String.valueOf(idEvaluador));
        assertTrue(coo.mensaje().startsWith("Docentes asignados"));
        assertEquals("2/ESTUDIANTE", estado());
    }

    @Test @Order(6)
    @DisplayName("Fase 2: el director devuelve el anteproyecto y luego lo aprueba")
    void anteproyecto() throws Exception {
        assertTrue(eva.get("/evaluador/calificar.jsp?id=" + id()).ubicacion.endsWith("/evaluador/index.jsp"),
                "el evaluador no ve proyectos antes de la Fase 3");
        est.subir("/estudiante/controlador_documento.jsp", "anteproyecto.pdf", PDF);
        assertEquals("2/DIRECTOR", estado());
        dir.post("/director/controlador_evaluacion.jsp", "id", id(), "nota", "7", "decision", "APROBADO", "observaciones", "x");
        assertTrue(dir.mensaje().startsWith("Ingrese una nota"), "nota fuera de rango");
        dir.post("/director/controlador_evaluacion.jsp", "id", id(), "nota", "2.8", "decision", "RECHAZADO", "observaciones", "Ajustar el alcance.");
        assertEquals("2/ESTUDIANTE", estado());
        est.subir("/estudiante/controlador_documento.jsp", "anteproyecto_v2.pdf", PDF);
        dir.post("/director/controlador_evaluacion.jsp", "id", id(), "nota", "4.3", "decision", "APROBADO", "observaciones", "Cumple.");
        assertEquals("3/EVALUADOR", estado());
    }

    @Test @Order(7)
    @DisplayName("Fase 3: el evaluador aprueba y el comité da la aprobación final")
    void evaluacionPropuesta() throws Exception {
        eva.post("/evaluador/controlador_evaluacion.jsp", "id", id(), "nota", "4.0", "decision", "APROBADO", "observaciones", "Viable.");
        assertEquals("3/COMITE", estado());
        coo.post("/coordinacion/controlador_comite.jsp", "id", id(), "acta", "", "decision", "APROBADO", "observaciones", "x");
        assertTrue(coo.mensaje().startsWith("Complete"), "el acta es obligatoria");
        coo.post("/coordinacion/controlador_comite.jsp", "id", id(), "acta", "PRB1", "decision", "APROBADO", "observaciones", "Aprobada.");
        assertEquals("4/ESTUDIANTE", estado());
    }

    @Test @Order(8)
    @DisplayName("Fases 4 y 5: el evaluador rechaza el informe y vuelve a Fase 4 (RF-29)")
    void informeFinalConRechazo() throws Exception {
        est.subir("/estudiante/controlador_documento.jsp", "informe.pdf", PDF);
        dir.post("/director/controlador_evaluacion.jsp", "id", id(), "nota", "4.5", "decision", "APROBADO", "observaciones", "Completo.");
        assertEquals("5/EVALUADOR", estado());
        eva.post("/evaluador/controlador_evaluacion.jsp", "id", id(), "nota", "2.5", "decision", "RECHAZADO", "observaciones", "Faltan pruebas.");
        assertEquals("4/ESTUDIANTE", estado());
        est.subir("/estudiante/controlador_documento.jsp", "informe_v2.pdf", PDF);
        dir.post("/director/controlador_evaluacion.jsp", "id", id(), "nota", "4.6", "decision", "APROBADO", "observaciones", "Corregido.");
        eva.post("/evaluador/controlador_evaluacion.jsp", "id", id(), "nota", "4.4", "decision", "APROBADO", "observaciones", "Sustentado.");
        assertEquals("5/COMITE", estado());
    }

    @Test @Order(9)
    @DisplayName("Cierre: el comité aprueba, se genera el radicado y queda el historial completo")
    void cierre() throws Exception {
        coo.post("/coordinacion/controlador_comite.jsp", "id", id(), "acta", "PRB2", "decision", "APROBADO", "observaciones", "Cierre.");
        assertTrue(coo.mensaje().startsWith("Proyecto cerrado"));
        assertEquals("6/FINALIZADO", estado());
        try (Connection con = Config.conexion()) {
            assertEquals(1, entero(con, "SELECT COUNT(*) FROM proyecto WHERE id_proyecto = ? AND radicado REGEXP '^RAD-[0-9]{4}-[0-9]{5}$'", idProyecto));
            assertEquals(5, entero(con, "SELECT COUNT(*) FROM documento WHERE id_proyecto = ?", idProyecto));
            assertEquals(9, entero(con, "SELECT COUNT(*) FROM evaluacion WHERE id_proyecto = ?", idProyecto));
            assertEquals(11, entero(con, "SELECT COUNT(*) FROM historial_fase WHERE id_proyecto = ?", idProyecto));
        }
        est.get("/estudiante/entregas.jsp");   // consume mensajes pendientes de las entregas anteriores
        est.subir("/estudiante/controlador_documento.jsp", "tarde.pdf", PDF);
        String msg = est.mensaje();
        assertTrue(msg.startsWith("No tienes entregas pendientes"), "mensaje: " + msg);
        String ficha = est.get("/estudiante/mi_proyecto.jsp").cuerpo;
        assertTrue(ficha.contains("Radicado RAD-"));
        assertTrue(ficha.contains("Ajustar el alcance."), "el estudiante ve las observaciones");
    }

    @Test @Order(10)
    @DisplayName("Seguridad: XSS escapado, ids inválidos sin error 500, archivos internos bloqueados")
    void seguridad() throws Exception {
        est.post("/ideas/controlador_idea.jsp", "accion", "proponer", "titulo", "<script>alert('xss')</script> título",
                "linea", "Ingeniería de software", "descripcion", "Descripción suficientemente larga para pasar la validación.");
        String lista = coo.get("/coordinacion/ideas.jsp?estado=Pendiente").cuerpo;
        assertFalse(lista.contains("<script>alert('xss')</script>"));
        assertTrue(lista.contains("&lt;script&gt;"));
        for (String v : new String[] {"abc", "1'--", "<x>", "-1"}) {
            assertTrue(coo.post("/coordinacion/controlador_idea.jsp", "accion", "aprobar", "id", v).codigo < 500, v);
            assertTrue(est.post("/ideas/controlador_idea.jsp", "accion", "retirar", "id", v).codigo < 500, v);
            assertTrue(coo.get("/coordinacion/proyecto.jsp?id=" + URLEncoder.encode(v, "UTF-8")).codigo < 500, v);
        }
        for (String r : new String[] {"/.git/config", "/sql/datos_prueba.sql", "/src/co/edu/uts/grados/filtro/AuthFilter.java", "/README.md"}) {
            assertEquals(403, new ClienteWeb().get(r).codigo, r);
        }
        assertTrue(new ClienteWeb().get("/uploads/pagos/ejemplo_pago.pdf").ubicacion.endsWith("/login.jsp"));
    }

    @Test @Order(11)
    @DisplayName("Logout invalida la sesión y la cookie es HttpOnly y SameSite")
    void logout() throws Exception {
        ClienteWeb c = new ClienteWeb();
        c.get("/login.jsp");
        URL u = new URL(Config.URL_APP + "/login.jsp");
        HttpURLConnection h = (HttpURLConnection) u.openConnection();
        String cookie = h.getHeaderField("Set-Cookie");
        assertNotNull(cookie);
        assertTrue(cookie.contains("HttpOnly") && cookie.contains("SameSite=Lax"), cookie);
        c.entrar(EST);
        assertEquals(200, c.get("/estudiante/index.jsp").codigo);
        c.get("/logout.jsp");
        assertTrue(c.get("/estudiante/index.jsp").ubicacion.endsWith("/login.jsp"));
    }
}
