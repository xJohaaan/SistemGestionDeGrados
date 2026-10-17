<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    director/index.jsp: panel del Docente Director (RF-19).
    Muestra solo los proyectos donde el usuario es el director asignado.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="DIRECTOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="pend" dataSource="${bd}">
    SELECT COUNT(*)                                          AS total,
           COALESCE(SUM(responsable = 'DIRECTOR' AND fase = 2), 0) AS anteproyectos,
           COALESCE(SUM(responsable = 'DIRECTOR' AND fase = 4), 0) AS informes,
           COALESCE(SUM(responsable = 'FINALIZADO'), 0)       AS finalizados
    FROM proyecto WHERE id_director = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<sql:query var="proyectos" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, i.titulo, p.fase, p.responsable,
           CONCAT(e.nombres, ' ', e.apellidos) AS estudiante, e.codigo AS codigo_estudiante,
           CONCAT(v.nombres, ' ', v.apellidos) AS evaluador
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    JOIN usuario e ON e.id_usuario = p.id_estudiante
    LEFT JOIN usuario v ON v.id_usuario = p.id_evaluador
    WHERE p.id_director = ?
    ORDER BY (p.responsable = 'DIRECTOR') DESC, p.actualizado_en DESC
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="t" value="${pend.rows[0]}"/>
<c:set var="tituloPagina" value="Proyectos de"/>
<c:set var="resalte" value="GRADO"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-person-workspace"></i></div>
            <div class="numero"><c:out value="${t.total}"/></div><div class="etiqueta">Proyectos que dirijo</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-file-earmark-text"></i></div>
            <div class="numero"><c:out value="${t.anteproyectos}"/></div><div class="etiqueta">Anteproyectos por calificar</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-journal-richtext"></i></div>
            <div class="numero"><c:out value="${t.informes}"/></div><div class="etiqueta">Informes finales por revisar</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-award"></i></div>
            <div class="numero"><c:out value="${t.finalizados}"/></div><div class="etiqueta">Proyectos finalizados</div></div>
    </div>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>ID</th><th>Descripción</th><th>Estudiante</th><th>Evaluador</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="p" items="${proyectos.rows}">
            <tr>
                <td class="fw-semibold"><c:out value="${p.codigo}"/></td>
                <td><c:out value="${p.titulo}"/></td>
                <td><c:out value="${p.estudiante}"/><small class="d-block text-muted"><c:out value="${p.codigo_estudiante}"/></small></td>
                <td><c:out value="${empty p.evaluador ? 'Sin asignar' : p.evaluador}"/></td>
                <td class="text-nowrap">
                    <c:set var="faseActual" value="${p.fase}"/><c:set var="resp" value="${p.responsable}"/>
                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                </td>
                <td class="text-end">
                    <c:choose>
                        <c:when test="${p.responsable eq 'DIRECTOR'}">
                            <a class="btn btn-sm btn-uts" href="${ctx}/director/calificar.jsp?id=${p.id_proyecto}"><i class="bi bi-pencil-square"></i> Calificar</a>
                        </c:when>
                        <c:otherwise>
                            <a class="btn btn-sm btn-light btn-accion" title="Ver" href="${ctx}/director/calificar.jsp?id=${p.id_proyecto}"><i class="bi bi-eye"></i></a>
                        </c:otherwise>
                    </c:choose>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
