<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/ideas.jsp: gestión del Banco de Ideas institucional.
      - Aprobar o rechazar propuestas pendientes (RF-13)
      - Crear, editar y eliminar ideas (RF-15)
    Filtro por estado: ?estado=Pendiente | Aprobada | Tomada | Rechazada
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="filtro" value="${empty param.estado ? '' : param.estado}"/>
<sql:query var="conteo" dataSource="${bd}">
    SELECT COALESCE(SUM(estado = 'Pendiente'), 0) AS pendientes, COALESCE(SUM(estado = 'Aprobada'), 0) AS aprobadas,
           COALESCE(SUM(estado = 'Tomada'), 0) AS tomadas, COALESCE(SUM(estado = 'Rechazada'), 0) AS rechazadas
    FROM idea
</sql:query>
<sql:query var="ideas" dataSource="${bd}">
    SELECT i.id_idea, i.titulo, i.descripcion, i.linea, i.estado, i.observacion, i.creado_en,
           CONCAT(u.nombres, ' ', u.apellidos) AS autor, u.rol AS rol_autor,
           p.codigo AS proyecto
    FROM idea i
    JOIN usuario u ON u.id_usuario = i.id_autor
    LEFT JOIN proyecto p ON p.id_idea = i.id_idea
    WHERE (? = '' OR i.estado = ?)
    ORDER BY FIELD(i.estado, 'Pendiente', 'Aprobada', 'Tomada', 'Rechazada'), i.creado_en DESC
    <sql:param value="${filtro}"/>
    <sql:param value="${filtro}"/>
</sql:query>
<c:set var="k" value="${conteo.rows[0]}"/>
<c:set var="tituloPagina" value="Banco de"/>
<c:set var="resalte" value="IDEAS"/>
<c:set var="menu" value="ideas"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
    <div class="btn-group flex-wrap" role="group" aria-label="Filtrar por estado">
        <a class="btn btn-sm ${filtro eq '' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/coordinacion/ideas.jsp">Todas</a>
        <a class="btn btn-sm ${filtro eq 'Pendiente' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/coordinacion/ideas.jsp?estado=Pendiente">Pendientes (<c:out value="${k.pendientes}"/>)</a>
        <a class="btn btn-sm ${filtro eq 'Aprobada' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/coordinacion/ideas.jsp?estado=Aprobada">Aprobadas (<c:out value="${k.aprobadas}"/>)</a>
        <a class="btn btn-sm ${filtro eq 'Tomada' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/coordinacion/ideas.jsp?estado=Tomada">Tomadas (<c:out value="${k.tomadas}"/>)</a>
        <a class="btn btn-sm ${filtro eq 'Rechazada' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/coordinacion/ideas.jsp?estado=Rechazada">Rechazadas (<c:out value="${k.rechazadas}"/>)</a>
    </div>
    <a class="btn btn-uts" href="${ctx}/coordinacion/form_idea.jsp"><i class="bi bi-plus-lg"></i> Nueva idea</a>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>Idea</th><th>Propuesta por</th><th>Estado</th><th class="text-end" style="min-width:260px">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="i" items="${ideas.rows}">
            <tr>
                <td style="min-width:280px">
                    <div class="fw-semibold"><c:out value="${i.titulo}"/></div>
                    <small class="text-muted d-block"><c:out value="${i.descripcion}"/></small>
                    <span class="badge badge-fase mt-1"><c:out value="${i.linea}"/></span>
                    <c:if test="${not empty i.observacion}"><small class="d-block mt-1"><i class="bi bi-chat-left-text"></i> <c:out value="${i.observacion}"/></small></c:if>
                </td>
                <td class="small"><c:out value="${i.autor}"/>
                    <span class="d-block text-muted">
                        <c:choose>
                            <c:when test="${i.rol_autor eq 'ESTUDIANTE'}">Estudiante</c:when>
                            <c:when test="${i.rol_autor eq 'COORDINACION'}">Coordinación</c:when>
                            <c:otherwise>Docente</c:otherwise>
                        </c:choose>
                        &middot; <fmt:formatDate value="${i.creado_en}" pattern="dd/MM/yyyy"/>
                    </span>
                </td>
                <td>
                    <c:choose>
                        <c:when test="${i.estado eq 'Pendiente'}"><span class="badge badge-resp">Pendiente</span></c:when>
                        <c:when test="${i.estado eq 'Aprobada'}"><span class="badge badge-fin">Aprobada</span></c:when>
                        <c:when test="${i.estado eq 'Tomada'}"><span class="badge badge-fase">Tomada</span><small class="d-block text-muted"><c:out value="${i.proyecto}"/></small></c:when>
                        <c:otherwise><span class="badge text-bg-danger">Rechazada</span></c:otherwise>
                    </c:choose>
                </td>
                <td class="text-end">
                    <c:if test="${i.estado eq 'Pendiente'}">
                        <form method="POST" action="${ctx}/coordinacion/controlador_idea.jsp" class="d-inline-flex gap-1 mb-1">
                            <input type="hidden" name="accion" value="aprobar">
                            <input type="hidden" name="id" value="${i.id_idea}">
                            <button class="btn btn-sm btn-uts" type="submit"><i class="bi bi-check-lg"></i> Aprobar</button>
                        </form>
                        <form method="POST" action="${ctx}/coordinacion/controlador_idea.jsp" class="d-inline-flex gap-1 mb-1 needs-validation" novalidate>
                            <input type="hidden" name="accion" value="rechazar">
                            <input type="hidden" name="id" value="${i.id_idea}">
                            <input type="text" class="form-control form-control-sm" name="observacion" placeholder="Motivo del rechazo" maxlength="300" required style="max-width:170px">
                            <button class="btn btn-sm btn-outline-danger" type="submit"><i class="bi bi-x-lg"></i></button>
                        </form>
                    </c:if>
                    <div>
                        <c:if test="${i.estado ne 'Tomada'}">
                            <a class="btn btn-sm btn-light btn-accion" title="Editar" href="${ctx}/coordinacion/form_idea.jsp?id=${i.id_idea}"><i class="bi bi-pencil"></i></a>
                            <form method="POST" action="${ctx}/coordinacion/controlador_idea.jsp" class="d-inline" data-confirmar="¿Eliminar esta idea del banco?">
                                <input type="hidden" name="accion" value="eliminar">
                                <input type="hidden" name="id" value="${i.id_idea}">
                                <button class="btn btn-sm btn-light btn-accion text-danger" title="Eliminar" type="submit"><i class="bi bi-trash"></i></button>
                            </form>
                        </c:if>
                    </div>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
