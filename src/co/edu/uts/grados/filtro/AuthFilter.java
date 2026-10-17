package co.edu.uts.grados.filtro;

import java.io.IOException;

import javax.servlet.Filter;
import javax.servlet.FilterChain;
import javax.servlet.FilterConfig;
import javax.servlet.ServletException;
import javax.servlet.ServletRequest;
import javax.servlet.ServletResponse;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;
import javax.servlet.http.HttpSession;

/**
 * Filtro de autenticación y autorización del Sistema de Gestión de Trabajos de Grado.
 * <p>
 * Se aplica a las carpetas privadas declaradas en {@code WEB-INF/web.xml}
 * ({@code /admin/*}, {@code /coordinacion/*}, {@code /director/*}, {@code /evaluador/*},
 * {@code /estudiante/*},
 * {@code /documental/*}, {@code /ideas/*}, {@code /uploads/*} y {@code /perfil.jsp}).
 * </p>
 * <ul>
 *   <li>Sin sesión activa redirige a {@code login.jsp}.</li>
 *   <li>Si la carpeta pertenece a otro rol redirige a {@code acceso.jsp}.</li>
 *   <li>Marca las respuestas como no almacenables en caché para que el botón
 *       "Atrás" no muestre páginas privadas después de cerrar sesión.</li>
 * </ul>
 * No es un Servlet: solo intercepta la petición antes de que llegue a la JSP.
 */
public class AuthFilter implements Filter {

    @Override
    public void init(FilterConfig filterConfig) throws ServletException {
    }

    /**
     * Verifica la sesión y el rol del usuario antes de dejar pasar la petición.
     *
     * @param request  petición entrante
     * @param response respuesta
     * @param chain    cadena de filtros
     * @throws IOException      si falla la redirección
     * @throws ServletException si falla el procesamiento de la cadena
     */
    @Override
    public void doFilter(ServletRequest request, ServletResponse response, FilterChain chain)
            throws IOException, ServletException {
        HttpServletRequest req = (HttpServletRequest) request;
        HttpServletResponse res = (HttpServletResponse) response;
        String ctx = req.getContextPath();

        res.setHeader("Cache-Control", "no-cache, no-store, must-revalidate");
        res.setHeader("Pragma", "no-cache");
        res.setDateHeader("Expires", 0);

        HttpSession session = req.getSession(false);
        String rol = (session == null) ? null : (String) session.getAttribute("rol");
        if (rol == null) {
            res.sendRedirect(ctx + "/login.jsp");
            return;
        }

        String requerido = rolDeRuta(req.getRequestURI().substring(ctx.length()));
        if (requerido != null && !requerido.equals(rol)) {
            res.sendRedirect(ctx + "/acceso.jsp");
            return;
        }
        chain.doFilter(request, response);
    }

    /**
     * Indica qué rol exige una ruta según la carpeta en la que está.
     *
     * @param ruta ruta relativa al contexto, por ejemplo {@code /admin/usuarios.jsp}
     * @return el rol requerido, o {@code null} si cualquier usuario autenticado puede entrar
     */
    private String rolDeRuta(String ruta) {
        if (ruta.startsWith("/admin/")) return "ADMIN";
        if (ruta.startsWith("/coordinacion/")) return "COORDINACION";
        if (ruta.startsWith("/director/")) return "DIRECTOR";
        if (ruta.startsWith("/evaluador/")) return "EVALUADOR";
        if (ruta.startsWith("/estudiante/")) return "ESTUDIANTE";
        return null;
    }

    @Override
    public void destroy() {
    }
}
