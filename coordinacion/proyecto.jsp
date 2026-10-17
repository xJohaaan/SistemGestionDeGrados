<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/proyecto.jsp: ficha completa de cualquier proyecto (historial y estado).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="chk" dataSource="${bd}">
    SELECT id_proyecto FROM proyecto WHERE id_proyecto = ?
    <sql:param value="${param.id}"/>
</sql:query>
<c:if test="${chk.rowCount == 0}">
    <c:set var="msgError" value="El proyecto solicitado no existe." scope="session"/>
    <c:redirect url="/coordinacion/index.jsp"/>
</c:if>
<c:set var="idProy" value="${chk.rows[0].id_proyecto}"/>
<c:set var="tituloPagina" value="Detalle del"/>
<c:set var="resalte" value="PROYECTO"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>
<%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>
<a class="btn btn-light" href="${ctx}/coordinacion/index.jsp"><i class="bi bi-arrow-left"></i> Volver</a>
<%@ include file="/WEB-INF/jspf/pie.jspf" %>
