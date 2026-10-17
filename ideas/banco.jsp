<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    ideas/banco.jsp: Banco de Ideas con las ideas aprobadas por Coordinación/Comité (RF-10).
    El estudiante sin proyecto puede seleccionar una idea para iniciar su proyecto (RF-14).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${sessionScope.rol eq 'COORDINACION'}">
    <c:redirect url="/coordinacion/ideas.jsp"/>
</c:if>
<sql:query var="ideas" dataSource="${bd}">
    SELECT i.id_idea, i.titulo, i.descripcion, i.linea, i.creado_en,
           CONCAT(u.nombres, ' ', u.apellidos) AS autor, u.rol AS rol_autor
    FROM idea i JOIN usuario u ON u.id_usuario = i.id_autor
    WHERE i.estado = 'Aprobada'
    ORDER BY i.creado_en DESC
</sql:query>
<c:if test="${sessionScope.rol eq 'ESTUDIANTE'}">
    <sql:query var="miProy" dataSource="${bd}">
        SELECT codigo FROM proyecto WHERE id_estudiante = ?
        <sql:param value="${sessionScope.idUsuario}"/>
    </sql:query>
    <c:set var="puedeSeleccionar" value="${miProy.rowCount == 0}"/>
</c:if>
<c:set var="puedeProponer" value="${sessionScope.rol eq 'ESTUDIANTE' or sessionScope.rol eq 'DIRECTOR' or sessionScope.rol eq 'EVALUADOR'}"/>
<c:set var="tituloPagina" value="Banco de"/>
<c:set var="resalte" value="IDEAS"/>
<c:set var="menu" value="banco"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
    <p class="text-muted mb-0">Ideas de proyecto aprobadas por el Comité de Trabajos de Grado.
        <c:if test="${sessionScope.rol eq 'ESTUDIANTE' and not puedeSeleccionar}">
            Ya tienes el proyecto <strong><c:out value="${miProy.rows[0].codigo}"/></strong> en curso.
        </c:if>
    </p>
    <c:if test="${puedeProponer}">
        <a class="btn btn-uts" href="${ctx}/ideas/proponer.jsp"><i class="bi bi-lightbulb"></i> Proponer idea</a>
    </c:if>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>Idea</th><th>Línea</th><th>Propuesta por</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="i" items="${ideas.rows}">
            <tr>
                <td style="min-width:280px">
                    <div class="fw-semibold"><c:out value="${i.titulo}"/></div>
                    <small class="text-muted"><c:out value="${i.descripcion}"/></small>
                </td>
                <td><span class="badge badge-fase"><c:out value="${i.linea}"/></span></td>
                <td class="small"><c:out value="${i.autor}"/>
                    <span class="d-block text-muted">
                        <c:choose>
                            <c:when test="${i.rol_autor eq 'ESTUDIANTE'}">Estudiante</c:when>
                            <c:when test="${i.rol_autor eq 'COORDINACION'}">Coordinación</c:when>
                            <c:otherwise>Docente</c:otherwise>
                        </c:choose>
                    </span>
                </td>
                <td class="text-end">
                    <c:if test="${puedeSeleccionar}">
                        <form method="POST" action="${ctx}/ideas/controlador_idea.jsp" class="d-inline"
                              data-confirmar="¿Seleccionar esta idea para tu proyecto de grado? Solo puedes tener un proyecto.">
                            <input type="hidden" name="accion" value="seleccionar">
                            <input type="hidden" name="id" value="${i.id_idea}">
                            <button class="btn btn-sm btn-uts text-nowrap" type="submit"><i class="bi bi-check2-circle"></i> Seleccionar</button>
                        </form>
                    </c:if>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
