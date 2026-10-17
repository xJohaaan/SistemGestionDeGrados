<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    ideas/mis_propuestas.jsp: ideas propuestas por el usuario con su estado y la observación del comité.
    Las ideas pendientes se pueden retirar.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${sessionScope.rol ne 'ESTUDIANTE' and sessionScope.rol ne 'DIRECTOR' and sessionScope.rol ne 'EVALUADOR'}">
    <c:redirect url="/acceso.jsp"/>
</c:if>
<sql:query var="ideas" dataSource="${bd}">
    SELECT id_idea, titulo, linea, estado, observacion, creado_en
    FROM idea WHERE id_autor = ? ORDER BY creado_en DESC
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="tituloPagina" value="Mis"/>
<c:set var="resalte" value="PROPUESTAS"/>
<c:set var="menu" value="propuestas"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="d-flex justify-content-end mb-3">
    <a class="btn btn-uts" href="${ctx}/ideas/proponer.jsp"><i class="bi bi-lightbulb"></i> Proponer idea</a>
</div>
<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>Fecha</th><th>Idea</th><th>Línea</th><th>Estado</th><th>Observación del comité</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="i" items="${ideas.rows}">
            <tr>
                <td class="text-nowrap small"><fmt:formatDate value="${i.creado_en}" pattern="dd/MM/yyyy"/></td>
                <td class="fw-semibold"><c:out value="${i.titulo}"/></td>
                <td><c:out value="${i.linea}"/></td>
                <td>
                    <c:choose>
                        <c:when test="${i.estado eq 'Pendiente'}"><span class="badge badge-resp">Pendiente</span></c:when>
                        <c:when test="${i.estado eq 'Aprobada'}"><span class="badge badge-fin">Aprobada</span></c:when>
                        <c:when test="${i.estado eq 'Tomada'}"><span class="badge badge-fase">Tomada</span></c:when>
                        <c:otherwise><span class="badge text-bg-danger">Rechazada</span></c:otherwise>
                    </c:choose>
                </td>
                <td class="small"><c:out value="${empty i.observacion ? '—' : i.observacion}"/></td>
                <td class="text-end">
                    <c:if test="${i.estado eq 'Pendiente'}">
                        <form method="POST" action="${ctx}/ideas/controlador_idea.jsp" class="d-inline" data-confirmar="¿Retirar esta propuesta?">
                            <input type="hidden" name="accion" value="retirar">
                            <input type="hidden" name="id" value="${i.id_idea}">
                            <button class="btn btn-sm btn-light btn-accion text-danger" title="Retirar" type="submit"><i class="bi bi-trash"></i></button>
                        </form>
                    </c:if>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
