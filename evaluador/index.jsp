<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    evaluador/index.jsp: panel del Docente Evaluador (RF-23).
    Solo ve los proyectos que ya superaron la Fase 2 (aprobados por el director)
    y en los que es el evaluador asignado.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="EVALUADOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="pend" dataSource="${bd}">
    SELECT COUNT(*)                                            AS total,
           COALESCE(SUM(responsable = 'EVALUADOR' AND fase = 3), 0) AS propuestas,
           COALESCE(SUM(responsable = 'EVALUADOR' AND fase = 5), 0) AS informes,
           COALESCE(SUM(responsable = 'FINALIZADO'), 0)         AS finalizados
    FROM proyecto WHERE id_evaluador = ? AND fase >= 3
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<sql:query var="proyectos" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, i.titulo, p.fase, p.responsable,
           CONCAT(e.nombres, ' ', e.apellidos) AS estudiante, e.codigo AS codigo_estudiante,
           CONCAT(d.nombres, ' ', d.apellidos) AS director
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    JOIN usuario e ON e.id_usuario = p.id_estudiante
    JOIN usuario d ON d.id_usuario = p.id_director
    WHERE p.id_evaluador = ? AND p.fase >= 3
    ORDER BY (p.responsable = 'EVALUADOR') DESC, p.actualizado_en DESC
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="t" value="${pend.rows[0]}"/>
<c:set var="tituloPagina" value="Proyectos de"/>
<c:set var="resalte" value="GRADO"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-clipboard-check"></i></div>
            <div class="numero"><c:out value="${t.total}"/></div><div class="etiqueta">Proyectos que evalúo</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-file-earmark-text"></i></div>
            <div class="numero"><c:out value="${t.propuestas}"/></div><div class="etiqueta">Propuestas por evaluar (Fase 3)</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-patch-check"></i></div>
            <div class="numero"><c:out value="${t.informes}"/></div><div class="etiqueta">Informes finales por evaluar (Fase 5)</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-award"></i></div>
            <div class="numero"><c:out value="${t.finalizados}"/></div><div class="etiqueta">Proyectos finalizados</div></div>
    </div>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>ID</th><th>Descripción</th><th>Estudiante</th><th>Director</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="p" items="${proyectos.rows}">
            <tr>
                <td class="fw-semibold"><c:out value="${p.codigo}"/></td>
                <td><c:out value="${p.titulo}"/></td>
                <td><c:out value="${p.estudiante}"/><small class="d-block text-muted"><c:out value="${p.codigo_estudiante}"/></small></td>
                <td><c:out value="${p.director}"/></td>
                <td class="text-nowrap">
                    <c:set var="faseActual" value="${p.fase}"/><c:set var="resp" value="${p.responsable}"/>
                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                </td>
                <td class="text-end">
                    <c:choose>
                        <c:when test="${p.responsable eq 'EVALUADOR'}">
                            <a class="btn btn-sm btn-uts" href="${ctx}/evaluador/calificar.jsp?id=${p.id_proyecto}"><i class="bi bi-pencil-square"></i> Evaluar</a>
                        </c:when>
                        <c:otherwise>
                            <a class="btn btn-sm btn-light btn-accion" title="Ver" href="${ctx}/evaluador/calificar.jsp?id=${p.id_proyecto}"><i class="bi bi-eye"></i></a>
                        </c:otherwise>
                    </c:choose>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
