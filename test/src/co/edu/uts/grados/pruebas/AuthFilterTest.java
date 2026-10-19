package co.edu.uts.grados.pruebas;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertNull;
import static org.junit.jupiter.api.Assertions.assertTrue;

import java.lang.reflect.Proxy;
import java.util.HashMap;
import java.util.Map;

import javax.servlet.FilterChain;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

import org.junit.jupiter.api.DisplayName;
import org.junit.jupiter.api.Test;
import org.junit.jupiter.params.ParameterizedTest;
import org.junit.jupiter.params.provider.CsvSource;

import co.edu.uts.grados.filtro.AuthFilter;

/**
 * Pruebas unitarias del {@link AuthFilter}. No necesitan Tomcat: la petición, la respuesta,
 * la sesión y la cadena de filtros se simulan con {@link Proxy}.
 */
@DisplayName("AuthFilter: control de sesión y de rol por carpeta")
class AuthFilterTest {

    /** Resultado observado de una ejecución del filtro. */
    static final class Resultado {
        String redireccion;
        boolean continuo;
        final Map<String, String> cabeceras = new HashMap<>();
    }

    /**
     * Ejecuta el filtro sobre una ruta con el rol indicado.
     *
     * @param ruta ruta dentro del contexto, por ejemplo {@code /admin/index.jsp}
     * @param rol  rol en sesión, o {@code null} para simular que no hay sesión
     */
    private Resultado ejecutar(String ruta, String rol) throws Exception {
        Resultado r = new Resultado();
        HttpSession sesion = rol == null ? null : (HttpSession) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {HttpSession.class},
                (p, m, a) -> "getAttribute".equals(m.getName()) && "rol".equals(a[0]) ? rol : null);
        HttpServletRequest req = (HttpServletRequest) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {HttpServletRequest.class},
                (p, m, a) -> {
                    switch (m.getName()) {
                        case "getContextPath": return "/SistemGestionDeGrados";
                        case "getRequestURI": return "/SistemGestionDeGrados" + ruta;
                        case "getSession": return sesion;
                        default: return null;
                    }
                });
        HttpServletResponse res = (HttpServletResponse) Proxy.newProxyInstance(
                getClass().getClassLoader(), new Class<?>[] {HttpServletResponse.class},
                (p, m, a) -> {
                    switch (m.getName()) {
                        case "sendRedirect": r.redireccion = (String) a[0]; break;
                        case "setHeader": r.cabeceras.put((String) a[0], (String) a[1]); break;
                        case "setDateHeader": r.cabeceras.put((String) a[0], String.valueOf(a[1])); break;
                        default: break;
                    }
                    return null;
                });
        FilterChain cadena = (rq, rs) -> r.continuo = true;
        new AuthFilter().doFilter(req, res, cadena);
        return r;
    }

    @Test
    @DisplayName("Sin sesión redirige al login")
    void sinSesionRedirigeAlLogin() throws Exception {
        Resultado r = ejecutar("/estudiante/index.jsp", null);
        assertEquals("/SistemGestionDeGrados/login.jsp", r.redireccion);
        assertFalse(r.continuo);
    }

    @ParameterizedTest(name = "{0} puede entrar a {1}")
    @CsvSource({
        "ADMIN, /admin/usuarios.jsp",
        "COORDINACION, /coordinacion/comite.jsp",
        "DIRECTOR, /director/calificar.jsp",
        "EVALUADOR, /evaluador/index.jsp",
        "ESTUDIANTE, /estudiante/entregas.jsp"
    })
    void cadaRolEntraASuCarpeta(String rol, String ruta) throws Exception {
        Resultado r = ejecutar(ruta, rol);
        assertTrue(r.continuo);
        assertNull(r.redireccion);
    }

    @ParameterizedTest(name = "{0} NO puede entrar a {1}")
    @CsvSource({
        "ESTUDIANTE, /admin/usuarios.jsp",
        "ESTUDIANTE, /director/calificar.jsp",
        "DIRECTOR, /evaluador/calificar.jsp",
        "EVALUADOR, /director/calificar.jsp",
        "COORDINACION, /admin/index.jsp",
        "ADMIN, /coordinacion/comite.jsp"
    })
    void rolAjenoVaAAccesoDenegado(String rol, String ruta) throws Exception {
        Resultado r = ejecutar(ruta, rol);
        assertEquals("/SistemGestionDeGrados/acceso.jsp", r.redireccion);
        assertFalse(r.continuo);
    }

    @ParameterizedTest(name = "Ruta común {0} abierta a cualquier rol autenticado")
    @CsvSource({"/documental/index.jsp", "/ideas/banco.jsp", "/uploads/pagos/ejemplo_pago.pdf", "/perfil.jsp"})
    void rutasComunesParaCualquierRol(String ruta) throws Exception {
        for (String rol : new String[] {"ADMIN", "COORDINACION", "DIRECTOR", "EVALUADOR", "ESTUDIANTE"}) {
            assertTrue(ejecutar(ruta, rol).continuo, rol + " debería entrar a " + ruta);
        }
    }

    @Test
    @DisplayName("Los PDF subidos no se pueden descargar sin sesión")
    void uploadsRequierenSesion() throws Exception {
        Resultado r = ejecutar("/uploads/pagos/ejemplo_pago.pdf", null);
        assertEquals("/SistemGestionDeGrados/login.jsp", r.redireccion);
    }

    @Test
    @DisplayName("Siempre envía cabeceras sin caché (botón Atrás tras cerrar sesión)")
    void cabecerasSinCache() throws Exception {
        for (Resultado r : new Resultado[] {ejecutar("/admin/index.jsp", "ADMIN"), ejecutar("/admin/index.jsp", null)}) {
            assertEquals("no-cache, no-store, must-revalidate", r.cabeceras.get("Cache-Control"));
            assertEquals("no-cache", r.cabeceras.get("Pragma"));
            assertEquals("0", r.cabeceras.get("Expires"));
        }
    }
}
