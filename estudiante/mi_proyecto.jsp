<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    estudiante/mi_proyecto.jsp: información del director y evaluador, calificaciones,
    observaciones e historial del proyecto (RF-32, RF-33, RF-34).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto FROM proyecto WHERE id_estudiante = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="tituloPagina" value="Mi"/>
<c:set var="resalte" value="PROYECTO"/>
<c:set var="menu" value="miproyecto"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <p class="text-muted">Aún no tienes un proyecto de grado.</p>
    </c:when>
    <c:otherwise>
        <c:set var="idProy" value="${rp.rows[0].id_proyecto}"/>
        <%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>
    </c:otherwise>
</c:choose>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
