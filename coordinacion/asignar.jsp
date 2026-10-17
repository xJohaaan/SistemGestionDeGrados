<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/asignar.jsp: proyectos con el pago enviado (Fase 1) esperando que Coordinación
    valide el recibo y asigne Docente Director y Docente Evaluador (RF-17).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="pendientes" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, i.titulo, CONCAT(e.nombres, ' ', e.apellidos) AS estudiante, e.codigo AS codigo_estudiante,
           (SELECT d.ruta FROM documento d WHERE d.id_proyecto = p.id_proyecto AND d.tipo = 'PAGO'
             ORDER BY d.subido_en DESC, d.id_documento DESC LIMIT 1) AS ruta_pago
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    JOIN usuario e ON e.id_usuario = p.id_estudiante
    WHERE p.fase = 1 AND p.responsable = 'COORDINACION'
    ORDER BY p.actualizado_en
</sql:query>
<sql:query var="directores" dataSource="${bd}">
    SELECT id_usuario, CONCAT(nombres, ' ', apellidos) AS nombre,
           (SELECT COUNT(*) FROM proyecto p WHERE p.id_director = u.id_usuario AND p.responsable <> 'FINALIZADO') AS carga
    FROM usuario u WHERE rol = 'DIRECTOR' AND estado = 'Activo' ORDER BY apellidos, nombres
</sql:query>
<sql:query var="evaluadores" dataSource="${bd}">
    SELECT id_usuario, CONCAT(nombres, ' ', apellidos) AS nombre,
           (SELECT COUNT(*) FROM proyecto p WHERE p.id_evaluador = u.id_usuario AND p.responsable <> 'FINALIZADO') AS carga
    FROM usuario u WHERE rol = 'EVALUADOR' AND estado = 'Activo' ORDER BY apellidos, nombres
</sql:query>
<c:set var="tituloPagina" value="Asignar"/>
<c:set var="resalte" value="DOCENTES"/>
<c:set var="menu" value="asignar"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<p class="text-muted">Valide el recibo de pago y asigne el Docente Director y el Docente Evaluador. El proyecto pasará a la Fase 2.</p>
<c:if test="${pendientes.rowCount == 0}">
    <div class="tarjeta-dato text-center text-muted py-4"><i class="bi bi-check2-all fs-3 d-block"></i> No hay proyectos pendientes de asignación.</div>
</c:if>
<div class="row g-3">
    <c:forEach var="p" items="${pendientes.rows}">
        <div class="col-12 col-xl-6">
            <form class="tarjeta-dato needs-validation" method="POST" action="${ctx}/coordinacion/controlador_asignacion.jsp" novalidate>
                <input type="hidden" name="id" value="${p.id_proyecto}">
                <div class="d-flex justify-content-between mb-1">
                    <span class="fw-semibold"><c:out value="${p.codigo}"/></span>
                    <c:if test="${not empty p.ruta_pago}">
                        <a class="small text-uts" href="${ctx}/${fn:escapeXml(p.ruta_pago)}" target="_blank" rel="noopener"><i class="bi bi-file-earmark-pdf"></i> Ver recibo de pago</a>
                    </c:if>
                </div>
                <p class="mb-1"><c:out value="${p.titulo}"/></p>
                <p class="small text-muted"><c:out value="${p.estudiante}"/> &middot; <c:out value="${p.codigo_estudiante}"/></p>
                <div class="row g-2">
                    <div class="col-12 col-md-6">
                        <label class="form-label small">Docente director</label>
                        <select class="form-select" name="director" required>
                            <option value="">Seleccione…</option>
                            <c:forEach var="d" items="${directores.rows}">
                                <option value="${d.id_usuario}"><c:out value="${d.nombre}"/> (<c:out value="${d.carga}"/> activos)</option>
                            </c:forEach>
                        </select>
                    </div>
                    <div class="col-12 col-md-6">
                        <label class="form-label small">Docente evaluador</label>
                        <select class="form-select" name="evaluador" required>
                            <option value="">Seleccione…</option>
                            <c:forEach var="v" items="${evaluadores.rows}">
                                <option value="${v.id_usuario}"><c:out value="${v.nombre}"/> (<c:out value="${v.carga}"/> activos)</option>
                            </c:forEach>
                        </select>
                    </div>
                </div>
                <button type="submit" class="btn btn-uts mt-3"><i class="bi bi-person-check"></i> Validar pago y asignar</button>
            </form>
        </div>
    </c:forEach>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
