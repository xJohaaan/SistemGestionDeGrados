<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    evaluador/calificar.jsp: ficha del proyecto y evaluación del evaluador (RF-24, RF-28, RF-29).
    Solo ve proyectos asignados que ya superaron la Fase 2.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="EVALUADOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="chk" dataSource="${bd}">
    SELECT id_proyecto, fase, responsable FROM proyecto WHERE id_proyecto = ? AND id_evaluador = ? AND fase >= 3
    <sql:param value="${param.id}"/>
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${chk.rowCount == 0}">
    <c:set var="msgError" value="El proyecto no existe o no está disponible para evaluación." scope="session"/>
    <c:redirect url="/evaluador/index.jsp"/>
</c:if>
<c:set var="idProy" value="${chk.rows[0].id_proyecto}"/>
<c:set var="puedeCalificar" value="${chk.rows[0].responsable eq 'EVALUADOR'}"/>
<c:set var="faseEval" value="${chk.rows[0].fase}"/>
<c:set var="tituloPagina" value="Evaluación del"/>
<c:set var="resalte" value="PROYECTO"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>

<c:choose>
    <c:when test="${puedeCalificar}">
        <c:set var="accionForm" value="${ctx}/evaluador/controlador_evaluacion.jsp"/>
        <c:set var="tituloForm" value="${faseEval == 3 ? 'Evaluar propuesta (Fase 3)' : 'Evaluar informe final (Fase 5)'}"/>
        <c:set var="textoAprobar" value="Aprobar y enviar al comité"/>
        <c:set var="textoRechazar" value="${faseEval == 3 ? 'Rechazar (vuelve a Fase 2)' : 'Rechazar (vuelve a Fase 4 para correcciones)'}"/>
        <%@ include file="/WEB-INF/jspf/form_calificacion.jspf" %>
    </c:when>
    <c:otherwise>
        <div class="alert alert-light border"><i class="bi bi-info-circle"></i> Este proyecto no tiene evaluaciones pendientes de su parte.</div>
    </c:otherwise>
</c:choose>
<a class="btn btn-light mt-3" href="${ctx}/evaluador/index.jsp"><i class="bi bi-arrow-left"></i> Volver</a>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
