<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    estudiante/entregas.jsp: carga de documentos PDF según la fase actual.
      Fase 1 -> recibo de pago (RF-16)
      Fase 2 -> anteproyecto (RF-18)
      Fase 4 -> informe final (RF-26)
    Solo se permite subir cuando el proyecto está a cargo del estudiante.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto, codigo, fase, responsable FROM proyecto WHERE id_estudiante = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:if test="${rp.rowCount == 1}">
    <c:set var="p" value="${rp.rows[0]}"/>
    <c:set var="puedeSubir" value="${p.responsable eq 'ESTUDIANTE' and (p.fase == 1 or p.fase == 2 or p.fase == 4)}"/>
    <c:choose>
        <c:when test="${p.fase == 1}"><c:set var="queSube" value="el recibo de pago institucional"/></c:when>
        <c:when test="${p.fase == 2}"><c:set var="queSube" value="el documento de anteproyecto"/></c:when>
        <c:when test="${p.fase == 4}"><c:set var="queSube" value="el informe final"/></c:when>
    </c:choose>
    <c:set var="idProy" value="${p.id_proyecto}"/>
</c:if>
<c:set var="tituloPagina" value="Mis"/>
<c:set var="resalte" value="ENTREGAS"/>
<c:set var="menu" value="entregas"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <p class="text-muted">Aún no tienes un proyecto de grado. <a class="text-uts" href="${ctx}/ideas/banco.jsp">Selecciona una idea del banco</a> para empezar.</p>
    </c:when>
    <c:otherwise>
        <div class="tarjeta-dato mb-4" style="max-width:720px">
            <c:choose>
                <c:when test="${puedeSubir}">
                    <h5 class="mb-1"><i class="bi bi-cloud-arrow-up text-uts"></i> Fase <c:out value="${p.fase}"/>: sube <c:out value="${queSube}"/></h5>
                    <p class="small text-muted">Solo archivos PDF de máximo 20 MB. Puedes volver a subirlo si te lo devuelven con observaciones.</p>
                    <form method="POST" action="${ctx}/estudiante/controlador_documento.jsp" enctype="multipart/form-data" class="needs-validation" novalidate>
                        <div class="mb-3">
                            <input type="file" class="form-control" name="archivo" accept=".pdf,application/pdf" data-max-mb="20" required>
                            <div class="invalid-feedback">Seleccione un archivo PDF de máximo 20 MB.</div>
                        </div>
                        <button type="submit" class="btn btn-uts"><i class="bi bi-upload"></i> Enviar documento</button>
                    </form>
                </c:when>
                <c:when test="${p.responsable eq 'FINALIZADO'}">
                    <h5 class="mb-0"><i class="bi bi-award text-uts"></i> Tu proyecto está finalizado. No hay entregas pendientes.</h5>
                </c:when>
                <c:otherwise>
                    <h5 class="mb-1"><i class="bi bi-hourglass-split text-uts"></i> No tienes entregas pendientes</h5>
                    <p class="small text-muted mb-0">Tu proyecto está en revisión. Te avisaremos aquí cuando debas subir un nuevo documento.</p>
                </c:otherwise>
            </c:choose>
        </div>
        <%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
