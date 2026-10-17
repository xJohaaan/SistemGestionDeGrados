<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/decision_comite.jsp: ficha del proyecto y formulario de decisión del comité.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="chk" dataSource="${bd}">
    SELECT id_proyecto, fase FROM proyecto WHERE id_proyecto = ? AND responsable = 'COMITE'
    <sql:param value="${param.id}"/>
</sql:query>
<c:if test="${chk.rowCount == 0}">
    <c:set var="msgAviso" value="El proyecto no está pendiente de decisión del comité." scope="session"/>
    <c:redirect url="/coordinacion/comite.jsp"/>
</c:if>
<c:set var="idProy" value="${chk.rows[0].id_proyecto}"/>
<c:set var="faseComite" value="${chk.rows[0].fase}"/>
<c:set var="tituloPagina" value="Decisión del"/>
<c:set var="resalte" value="COMITÉ"/>
<c:set var="menu" value="comite"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<%@ include file="/WEB-INF/jspf/detalle_proyecto.jspf" %>

<form class="tarjeta-dato needs-validation" method="POST" action="${ctx}/coordinacion/controlador_comite.jsp" novalidate style="max-width:820px">
    <input type="hidden" name="id" value="${idProy}">
    <h5 class="mb-3"><i class="bi bi-hammer text-uts"></i>
        <c:choose>
            <c:when test="${faseComite == 3}">Aprobación final de la propuesta (Fase 3)</c:when>
            <c:otherwise>Aprobación del informe final y cierre del proyecto (Fase 5)</c:otherwise>
        </c:choose>
    </h5>
    <div class="row g-3">
        <div class="col-12 col-md-4">
            <label class="form-label" for="acta">Número de acta</label>
            <input type="text" class="form-control" id="acta" name="acta" maxlength="20" pattern="[0-9A-Za-z\-]{1,20}" required>
            <div class="invalid-feedback">Ingrese el número de acta.</div>
        </div>
        <div class="col-12 col-md-8">
            <label class="form-label d-block">Decisión</label>
            <div class="form-check form-check-inline">
                <input class="form-check-input" type="radio" name="decision" id="dAprob" value="APROBADO" required>
                <label class="form-check-label" for="dAprob">
                    <c:out value="${faseComite == 3 ? 'Aprobar (pasa a Fase 4)' : 'Aprobar y cerrar (genera radicado)'}"/>
                </label>
            </div>
            <div class="form-check form-check-inline">
                <input class="form-check-input" type="radio" name="decision" id="dRech" value="RECHAZADO" required>
                <label class="form-check-label" for="dRech">
                    <c:out value="${faseComite == 3 ? 'Rechazar (vuelve a Fase 2)' : 'Rechazar (vuelve a Fase 4)'}"/>
                </label>
            </div>
        </div>
        <div class="col-12">
            <label class="form-label" for="observaciones">Observaciones del comité</label>
            <textarea class="form-control" id="observaciones" name="observaciones" rows="3" maxlength="1500" required></textarea>
            <div class="invalid-feedback">Escriba las observaciones.</div>
        </div>
    </div>
    <div class="mt-3 d-flex gap-2">
        <button type="submit" class="btn btn-uts"><i class="bi bi-save"></i> Registrar decisión</button>
        <a class="btn btn-light" href="${ctx}/coordinacion/comite.jsp">Cancelar</a>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
