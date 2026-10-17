<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/reportes.jsp: reportes consolidados del estado de los proyectos.
      ?tipo=alumnos      perspectiva de los estudiantes (RF-40)
      ?tipo=directores   perspectiva de los docentes directores (RF-41)
      ?tipo=evaluadores  perspectiva de los docentes evaluadores (RF-42)
    Se pueden imprimir o guardar como PDF desde el navegador.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="tipo" value="${param.tipo eq 'directores' or param.tipo eq 'evaluadores' ? param.tipo : 'alumnos'}"/>

<c:choose>
    <c:when test="${tipo eq 'alumnos'}">
        <sql:query var="resumen" dataSource="${bd}">
            SELECT COUNT(*) AS estudiantes,
                   COALESCE(SUM(p.id_proyecto IS NULL), 0) AS sin_proyecto,
                   COALESCE(SUM(p.responsable IS NOT NULL AND p.responsable <> 'FINALIZADO'), 0) AS en_curso,
                   COALESCE(SUM(p.responsable = 'FINALIZADO'), 0) AS finalizados
            FROM usuario e LEFT JOIN proyecto p ON p.id_estudiante = e.id_usuario
            WHERE e.rol = 'ESTUDIANTE' AND e.estado = 'Activo'
        </sql:query>
        <sql:query var="filas" dataSource="${bd}">
            SELECT e.codigo AS codigo_estudiante, CONCAT(e.apellidos, ' ', e.nombres) AS estudiante,
                   p.id_proyecto, p.codigo, p.fase, p.responsable, p.radicado,
                   CONCAT(d.nombres, ' ', d.apellidos) AS director,
                   CONCAT(v.nombres, ' ', v.apellidos) AS evaluador,
                   (SELECT ev.nota FROM evaluacion ev WHERE ev.id_proyecto = p.id_proyecto AND ev.nota IS NOT NULL
                     ORDER BY ev.fecha DESC, ev.id_evaluacion DESC LIMIT 1) AS ultima_nota,
                   DATEDIFF(NOW(), (SELECT MAX(h.fecha) FROM historial_fase h WHERE h.id_proyecto = p.id_proyecto)) AS dias_sin_movimiento
            FROM usuario e
            LEFT JOIN proyecto p ON p.id_estudiante = e.id_usuario
            LEFT JOIN usuario d ON d.id_usuario = p.id_director
            LEFT JOIN usuario v ON v.id_usuario = p.id_evaluador
            WHERE e.rol = 'ESTUDIANTE' AND e.estado = 'Activo'
            ORDER BY (p.id_proyecto IS NULL), p.fase, e.apellidos
        </sql:query>
    </c:when>
    <c:when test="${tipo eq 'directores'}">
        <sql:query var="filas" dataSource="${bd}">
            SELECT CONCAT(u.nombres, ' ', u.apellidos) AS docente, u.correo,
                   COUNT(p.id_proyecto) AS asignados,
                   COALESCE(SUM(p.responsable <> 'FINALIZADO'), 0) AS en_curso,
                   COALESCE(SUM(p.responsable = 'DIRECTOR' AND p.fase = 2), 0) AS anteproyectos_pend,
                   COALESCE(SUM(p.responsable = 'DIRECTOR' AND p.fase = 4), 0) AS informes_pend,
                   COALESCE(SUM(p.responsable = 'FINALIZADO'), 0) AS finalizados,
                   (SELECT COUNT(*) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario AND ev.decision = 'APROBADO') AS aprobaciones,
                   (SELECT COUNT(*) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario AND ev.decision = 'RECHAZADO') AS devoluciones,
                   (SELECT ROUND(AVG(ev.nota), 1) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario) AS promedio
            FROM usuario u LEFT JOIN proyecto p ON p.id_director = u.id_usuario
            WHERE u.rol = 'DIRECTOR'
            GROUP BY u.id_usuario, u.nombres, u.apellidos, u.correo
            ORDER BY u.apellidos
        </sql:query>
        <sql:query var="detalle" dataSource="${bd}">
            SELECT CONCAT(u.nombres, ' ', u.apellidos) AS docente, p.codigo, p.fase, p.responsable,
                   CONCAT(e.nombres, ' ', e.apellidos) AS estudiante
            FROM proyecto p JOIN usuario u ON u.id_usuario = p.id_director JOIN usuario e ON e.id_usuario = p.id_estudiante
            ORDER BY u.apellidos, p.fase
        </sql:query>
    </c:when>
    <c:otherwise>
        <sql:query var="filas" dataSource="${bd}">
            SELECT CONCAT(u.nombres, ' ', u.apellidos) AS docente, u.correo,
                   COUNT(p.id_proyecto) AS asignados,
                   COALESCE(SUM(p.fase >= 3 AND p.responsable <> 'FINALIZADO'), 0) AS en_evaluacion,
                   COALESCE(SUM(p.responsable = 'EVALUADOR' AND p.fase = 3), 0) AS propuestas_pend,
                   COALESCE(SUM(p.responsable = 'EVALUADOR' AND p.fase = 5), 0) AS informes_pend,
                   COALESCE(SUM(p.responsable = 'FINALIZADO'), 0) AS finalizados,
                   (SELECT COUNT(*) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario AND ev.decision = 'APROBADO') AS aprobaciones,
                   (SELECT COUNT(*) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario AND ev.decision = 'RECHAZADO') AS rechazos,
                   (SELECT ROUND(AVG(ev.nota), 1) FROM evaluacion ev WHERE ev.id_usuario = u.id_usuario) AS promedio
            FROM usuario u LEFT JOIN proyecto p ON p.id_evaluador = u.id_usuario
            WHERE u.rol = 'EVALUADOR'
            GROUP BY u.id_usuario, u.nombres, u.apellidos, u.correo
            ORDER BY u.apellidos
        </sql:query>
        <sql:query var="detalle" dataSource="${bd}">
            SELECT CONCAT(u.nombres, ' ', u.apellidos) AS docente, p.codigo, p.fase, p.responsable,
                   CONCAT(e.nombres, ' ', e.apellidos) AS estudiante
            FROM proyecto p JOIN usuario u ON u.id_usuario = p.id_evaluador JOIN usuario e ON e.id_usuario = p.id_estudiante
            ORDER BY u.apellidos, p.fase
        </sql:query>
    </c:otherwise>
</c:choose>

<c:set var="tituloPagina" value="Reportes de"/>
<c:set var="resalte" value="PROYECTOS"/>
<c:set var="menu" value="reportes"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3 no-imprimir">
    <ul class="nav nav-pills">
        <li class="nav-item"><a class="nav-link ${tipo eq 'alumnos' ? 'active bg-uts' : 'text-uts'}" href="${ctx}/coordinacion/reportes.jsp?tipo=alumnos"><i class="bi bi-mortarboard"></i> Por alumnos</a></li>
        <li class="nav-item"><a class="nav-link ${tipo eq 'directores' ? 'active bg-uts' : 'text-uts'}" href="${ctx}/coordinacion/reportes.jsp?tipo=directores"><i class="bi bi-person-workspace"></i> Por directores</a></li>
        <li class="nav-item"><a class="nav-link ${tipo eq 'evaluadores' ? 'active bg-uts' : 'text-uts'}" href="${ctx}/coordinacion/reportes.jsp?tipo=evaluadores"><i class="bi bi-clipboard-check"></i> Por evaluadores</a></li>
    </ul>
    <button type="button" class="btn btn-outline-uts" onclick="window.print()"><i class="bi bi-printer"></i> Imprimir / PDF</button>
</div>
<jsp:useBean id="hoy" class="java.util.Date"/>
<p class="small text-muted">Generado el <fmt:formatDate value="${hoy}" pattern="dd/MM/yyyy HH:mm"/> por <c:out value="${sessionScope.usuario.nombres} ${sessionScope.usuario.apellidos}"/></p>

<c:choose>
    <%-- ===================== POR ALUMNOS ===================== --%>
    <c:when test="${tipo eq 'alumnos'}">
        <c:set var="k" value="${resumen.rows[0]}"/>
        <div class="row g-3 mb-4">
            <div class="col-6 col-lg-3"><div class="tarjeta-dato"><div class="numero"><c:out value="${k.estudiantes}"/></div><div class="etiqueta">Estudiantes activos</div></div></div>
            <div class="col-6 col-lg-3"><div class="tarjeta-dato"><div class="numero"><c:out value="${k.en_curso}"/></div><div class="etiqueta">Con proyecto en curso</div></div></div>
            <div class="col-6 col-lg-3"><div class="tarjeta-dato"><div class="numero"><c:out value="${k.finalizados}"/></div><div class="etiqueta">Finalizados</div></div></div>
            <div class="col-6 col-lg-3"><div class="tarjeta-dato"><div class="numero"><c:out value="${k.sin_proyecto}"/></div><div class="etiqueta">Sin proyecto</div></div></div>
        </div>
        <div class="table-responsive">
            <table class="table align-middle datatable small">
                <thead><tr><th>Código</th><th>Estudiante</th><th>Proyecto</th><th>Estado</th><th>Director</th><th>Evaluador</th><th>Última nota</th><th>Días sin movimiento</th></tr></thead>
                <tbody>
                <c:forEach var="r" items="${filas.rows}">
                    <tr>
                        <td><c:out value="${r.codigo_estudiante}"/></td>
                        <td><c:out value="${r.estudiante}"/></td>
                        <td>
                            <c:choose>
                                <c:when test="${empty r.id_proyecto}"><span class="text-muted">Sin proyecto</span></c:when>
                                <c:otherwise><a class="text-uts fw-semibold" href="${ctx}/coordinacion/proyecto.jsp?id=${r.id_proyecto}"><c:out value="${r.codigo}"/></a></c:otherwise>
                            </c:choose>
                        </td>
                        <td class="text-nowrap">
                            <c:if test="${not empty r.id_proyecto}">
                                <c:set var="faseActual" value="${r.fase}"/><c:set var="resp" value="${r.responsable}"/>
                                <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                            </c:if>
                        </td>
                        <td><c:out value="${empty r.director ? '—' : r.director}"/></td>
                        <td><c:out value="${empty r.evaluador ? '—' : r.evaluador}"/></td>
                        <td><c:out value="${empty r.ultima_nota ? '—' : r.ultima_nota}"/></td>
                        <td>
                            <c:choose>
                                <c:when test="${empty r.id_proyecto or r.responsable eq 'FINALIZADO'}">—</c:when>
                                <c:when test="${r.dias_sin_movimiento gt 30}"><span class="badge text-bg-danger"><c:out value="${r.dias_sin_movimiento}"/></span></c:when>
                                <c:otherwise><c:out value="${r.dias_sin_movimiento}"/></c:otherwise>
                            </c:choose>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
        <p class="small text-muted">En rojo: proyectos en curso con más de 30 días sin cambios de fase.</p>
    </c:when>

    <%-- ===================== POR DIRECTORES / EVALUADORES ===================== --%>
    <c:otherwise>
        <c:set var="esDir" value="${tipo eq 'directores'}"/>
        <div class="table-responsive mb-4">
            <table class="table align-middle small">
                <thead>
                <tr><th>Docente</th><th>Asignados</th>
                    <th><c:out value="${esDir ? 'En curso' : 'En evaluación'}"/></th>
                    <th><c:out value="${esDir ? 'Anteproyectos por calificar' : 'Propuestas por evaluar'}"/></th>
                    <th>Informes finales pendientes</th><th>Finalizados</th>
                    <th>Aprobaciones</th><th><c:out value="${esDir ? 'Devoluciones' : 'Rechazos'}"/></th><th>Nota promedio</th></tr>
                </thead>
                <tbody>
                <c:forEach var="r" items="${filas.rows}">
                    <tr>
                        <td><span class="fw-semibold"><c:out value="${r.docente}"/></span><small class="d-block text-muted"><c:out value="${r.correo}"/></small></td>
                        <td><c:out value="${r.asignados}"/></td>
                        <td><c:out value="${esDir ? r.en_curso : r.en_evaluacion}"/></td>
                        <td>
                            <c:set var="pend1" value="${esDir ? r.anteproyectos_pend : r.propuestas_pend}"/>
                            <span class="${pend1 gt 0 ? 'badge badge-resp' : ''}"><c:out value="${pend1}"/></span>
                        </td>
                        <td><span class="${r.informes_pend gt 0 ? 'badge badge-resp' : ''}"><c:out value="${r.informes_pend}"/></span></td>
                        <td><c:out value="${r.finalizados}"/></td>
                        <td><c:out value="${r.aprobaciones}"/></td>
                        <td><c:out value="${esDir ? r.devoluciones : r.rechazos}"/></td>
                        <td><c:out value="${empty r.promedio ? '—' : r.promedio}"/></td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
        <h6 class="fw-semibold">Proyectos por docente</h6>
        <div class="table-responsive">
            <table class="table align-middle datatable small">
                <thead><tr><th>Docente</th><th>Proyecto</th><th>Estudiante</th><th>Estado</th></tr></thead>
                <tbody>
                <c:forEach var="r" items="${detalle.rows}">
                    <tr>
                        <td><c:out value="${r.docente}"/></td>
                        <td class="fw-semibold"><c:out value="${r.codigo}"/></td>
                        <td><c:out value="${r.estudiante}"/></td>
                        <td class="text-nowrap">
                            <c:set var="faseActual" value="${r.fase}"/><c:set var="resp" value="${r.responsable}"/>
                            <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                        </td>
                    </tr>
                </c:forEach>
                </tbody>
            </table>
        </div>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
