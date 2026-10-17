<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    ideas/proponer.jsp: formulario para que estudiantes (RF-11) y docentes (RF-12) propongan ideas.
    La idea queda "Pendiente" hasta que Coordinación/Comité la apruebe (RF-13).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${sessionScope.rol ne 'ESTUDIANTE' and sessionScope.rol ne 'DIRECTOR' and sessionScope.rol ne 'EVALUADOR'}">
    <c:redirect url="/acceso.jsp"/>
</c:if>
<c:set var="tituloPagina" value="Proponer"/>
<c:set var="resalte" value="IDEA"/>
<c:set var="menu" value="propuestas"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<p class="text-muted">Tu propuesta será revisada por el Comité de Trabajos de Grado. Cuando sea aprobada aparecerá en el Banco de Ideas.</p>
<form method="POST" action="${ctx}/ideas/controlador_idea.jsp" class="needs-validation" novalidate style="max-width:820px">
    <input type="hidden" name="accion" value="proponer">
    <div class="mb-3">
        <label class="form-label" for="titulo">Título de la idea</label>
        <input type="text" class="form-control" id="titulo" name="titulo" minlength="10" maxlength="150" required>
        <div class="invalid-feedback">Entre 10 y 150 caracteres.</div>
    </div>
    <div class="mb-3">
        <label class="form-label" for="linea">Línea de investigación</label>
        <select class="form-select" id="linea" name="linea" required>
            <option value="">Seleccione…</option>
            <%@ include file="/WEB-INF/jspf/lineas.jspf" %>
        </select>
        <div class="invalid-feedback">Seleccione la línea.</div>
    </div>
    <div class="mb-3">
        <label class="form-label" for="descripcion">Descripción (problema, objetivo y alcance)</label>
        <textarea class="form-control" id="descripcion" name="descripcion" rows="5" minlength="30" maxlength="2000" required></textarea>
        <div class="invalid-feedback">Describa la idea en al menos 30 caracteres.</div>
    </div>
    <div class="d-flex gap-2">
        <button type="submit" class="btn btn-uts"><i class="bi bi-send"></i> Enviar propuesta</button>
        <a class="btn btn-light" href="${ctx}/ideas/mis_propuestas.jsp">Cancelar</a>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
