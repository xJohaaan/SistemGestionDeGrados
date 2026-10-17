<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/index.jsp: panel de Coordinación (también registra las decisiones del Comité).
    Muestra pendientes y el número de proyectos en cada fase.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="pend" dataSource="${bd}">
    SELECT (SELECT COUNT(*) FROM idea WHERE estado = 'Pendiente')              AS ideas,
           (SELECT COUNT(*) FROM proyecto WHERE responsable = 'COORDINACION')  AS asignaciones,
           (SELECT COUNT(*) FROM proyecto WHERE responsable = 'COMITE')        AS comite,
           (SELECT COUNT(*) FROM proyecto WHERE responsable = 'FINALIZADO')    AS finalizados
</sql:query>
<sql:query var="porFase" dataSource="${bd}">
    SELECT f.id_fase, f.nombre, f.icono, COUNT(p.id_proyecto) AS total
    FROM fase f LEFT JOIN proyecto p ON p.fase = f.id_fase
    GROUP BY f.id_fase, f.nombre, f.icono ORDER BY f.id_fase
</sql:query>
<sql:query var="proyectos" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, i.titulo, p.fase, p.responsable,
           CONCAT(e.nombres, ' ', e.apellidos) AS estudiante, e.codigo AS codigo_estudiante,
           CONCAT(d.nombres, ' ', d.apellidos) AS director
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    JOIN usuario e ON e.id_usuario = p.id_estudiante
    LEFT JOIN usuario d ON d.id_usuario = p.id_director
    ORDER BY p.actualizado_en DESC
</sql:query>
<c:set var="t" value="${pend.rows[0]}"/>
<c:set var="tituloPagina" value="Proyectos de"/>
<c:set var="resalte" value="GRADO"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-lightbulb"></i></div>
            <div class="numero"><c:out value="${t.ideas}"/></div><div class="etiqueta">Ideas por aprobar</div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-person-plus"></i></div>
            <div class="numero"><c:out value="${t.asignaciones}"/></div><div class="etiqueta"><a class="text-uts" href="${ctx}/coordinacion/asignar.jsp">Pagos por validar / asignar docentes</a></div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-people"></i></div>
            <div class="numero"><c:out value="${t.comite}"/></div><div class="etiqueta"><a class="text-uts" href="${ctx}/coordinacion/comite.jsp">Pendientes del comité</a></div></div>
    </div>
    <div class="col-6 col-lg-3">
        <div class="tarjeta-dato"><div class="icono"><i class="bi bi-award"></i></div>
            <div class="numero"><c:out value="${t.finalizados}"/></div><div class="etiqueta">Proyectos finalizados</div></div>
    </div>
</div>

<h5 class="mb-3">Proyectos por fase</h5>
<div class="row g-2 mb-4">
    <c:forEach var="f" items="${porFase.rows}">
        <div class="col-6 col-md-4 col-xl-2">
            <div class="tarjeta-dato text-center py-3">
                <i class="bi ${f.icono} fs-4 text-uts"></i>
                <div class="numero mt-1"><c:out value="${f.total}"/></div>
                <div class="etiqueta">Fase <c:out value="${f.id_fase}"/>: <c:out value="${f.nombre}"/></div>
            </div>
        </div>
    </c:forEach>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>ID</th><th>Título</th><th>Estudiante</th><th>Director</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="p" items="${proyectos.rows}">
            <tr>
                <td class="fw-semibold"><c:out value="${p.codigo}"/></td>
                <td><c:out value="${p.titulo}"/></td>
                <td><c:out value="${p.estudiante}"/><small class="d-block text-muted"><c:out value="${p.codigo_estudiante}"/></small></td>
                <td><c:out value="${empty p.director ? 'Sin asignar' : p.director}"/></td>
                <td class="text-nowrap">
                    <c:set var="faseActual" value="${p.fase}"/><c:set var="resp" value="${p.responsable}"/>
                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                </td>
                <td class="text-end text-nowrap">
                    <c:if test="${p.responsable eq 'COORDINACION'}">
                        <a class="btn btn-sm btn-uts" href="${ctx}/coordinacion/asignar.jsp"><i class="bi bi-person-plus"></i> Asignar</a>
                    </c:if>
                    <c:if test="${p.responsable eq 'COMITE'}">
                        <a class="btn btn-sm btn-uts" href="${ctx}/coordinacion/decision_comite.jsp?id=${p.id_proyecto}"><i class="bi bi-hammer"></i> Comité</a>
                    </c:if>
                    <a class="btn btn-sm btn-light btn-accion" title="Ver detalle" href="${ctx}/coordinacion/proyecto.jsp?id=${p.id_proyecto}"><i class="bi bi-eye"></i></a>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
