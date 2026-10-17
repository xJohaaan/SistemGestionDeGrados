<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    director/calificar.jsp: ficha del proyecto y calificación del director (RF-20, RF-21, RF-27).
    Solo el director asignado puede verlo; el formulario aparece cuando el proyecto está a su cargo.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="DIRECTOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="chk" dataSource="${bd}">
    SELECT id_proyecto, fase, responsable FROM proyecto WHERE id_proyecto = ? AND id_director = ?
    <sql:param value="${param.id}"/>
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${chk.rowCount == 0}">
    <c:set var="msgError" value="El proyecto no existe o no está asignado a usted." scope="session"/>
    <c:redirect url="/director/index.jsp"/>
</c:if>
<c:set var="idProy" value="${chk.rows[0].id_proyecto}"/>
<c:set var="puedeCalificar" value="${chk.rows[0].responsable eq 'DIRECTOR'}"/>
<c:set var="faseDir" value="${chk.rows[0].fase}"/>
<c:set var="tituloPagina" value="Revisión del"/>
<c:set var="resalte" value="DIRECTOR"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>

<c:choose>
    <c:when test="${puedeCalificar}">
        <c:set var="accionForm" value="${ctx}/director/controlador_evaluacion.jsp"/>
        <c:set var="tituloForm" value="${faseDir == 2 ? 'Calificar anteproyecto (Fase 2)' : 'Revisar informe final (Fase 4)'}"/>
        <c:set var="textoAprobar" value="${faseDir == 2 ? 'Aprobar y enviar al evaluador (pasa a Fase 3)' : 'Aprobar y enviar al evaluador (pasa a Fase 5)'}"/>
        <c:set var="textoRechazar" value="Devolver al estudiante con observaciones"/>
        <%@ include file="/WEB-INF/jspf/form_calificacion.jspf" %>
    </c:when>
    <c:otherwise>
        <div class="alert alert-light border"><i class="bi bi-info-circle"></i> Este proyecto no tiene revisiones pendientes de su parte.</div>
    </c:otherwise>
</c:choose>
<a class="btn btn-light mt-3" href="${ctx}/director/index.jsp"><i class="bi bi-arrow-left"></i> Volver</a>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
