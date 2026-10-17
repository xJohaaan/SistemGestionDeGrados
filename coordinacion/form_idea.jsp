<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/form_idea.jsp: crear o editar una idea del banco institucional (RF-15).
    Las ideas creadas por Coordinación quedan aprobadas. Una idea "Tomada" no se edita.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="editando" value="${not empty param.id}"/>
<c:if test="${editando}">
    <sql:query var="r" dataSource="${bd}">
        SELECT id_idea, titulo, descripcion, linea, estado, observacion FROM idea WHERE id_idea = ? AND estado <> 'Tomada'
        <sql:param value="${param.id}"/>
    </sql:query>
    <c:if test="${r.rowCount == 0}">
        <c:set var="msgError" value="La idea no existe o ya fue tomada por un estudiante." scope="session"/>
        <c:redirect url="/coordinacion/ideas.jsp"/>
    </c:if>
    <c:set var="idea" value="${r.rows[0]}"/>
</c:if>
<c:set var="lineaSel" value="${idea.linea}"/>
<c:set var="tituloPagina" value="${editando ? 'Editar' : 'Nueva'}"/>
<c:set var="resalte" value="IDEA"/>
<c:set var="menu" value="ideas"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<form method="POST" action="${ctx}/coordinacion/controlador_idea.jsp" class="needs-validation" novalidate style="max-width:820px">
    <input type="hidden" name="accion" value="${editando ? 'editar' : 'crear'}">
    <c:if test="${editando}"><input type="hidden" name="id" value="${idea.id_idea}"></c:if>
    <div class="mb-3">
        <label class="form-label" for="titulo">Título</label>
        <input type="text" class="form-control" id="titulo" name="titulo" minlength="10" maxlength="150" value="${fn:escapeXml(idea.titulo)}" required>
        <div class="invalid-feedback">Entre 10 y 150 caracteres.</div>
    </div>
    <div class="row g-3 mb-3">
        <div class="col-12 col-md-6">
            <label class="form-label" for="linea">Línea de investigación</label>
            <select class="form-select" id="linea" name="linea" required>
                <option value="">Seleccione…</option>
                <%@ include file="/WEB-INF/jspf/lineas.jspf" %>
            </select>
        </div>
        <c:if test="${editando}">
            <div class="col-12 col-md-6">
                <label class="form-label" for="estado">Estado</label>
                <select class="form-select" id="estado" name="estado">
                    <option value="Pendiente" ${idea.estado eq 'Pendiente' ? 'selected' : ''}>Pendiente</option>
                    <option value="Aprobada"  ${idea.estado eq 'Aprobada' ? 'selected' : ''}>Aprobada (visible en el banco)</option>
                    <option value="Rechazada" ${idea.estado eq 'Rechazada' ? 'selected' : ''}>Rechazada</option>
                </select>
            </div>
        </c:if>
    </div>
    <div class="mb-3">
        <label class="form-label" for="descripcion">Descripción</label>
        <textarea class="form-control" id="descripcion" name="descripcion" rows="5" minlength="30" maxlength="2000" required><c:out value="${idea.descripcion}"/></textarea>
        <div class="invalid-feedback">Mínimo 30 caracteres.</div>
    </div>
    <c:if test="${editando}">
        <div class="mb-3">
            <label class="form-label" for="observacion">Observación del comité (opcional)</label>
            <input type="text" class="form-control" id="observacion" name="observacion" maxlength="300" value="${fn:escapeXml(idea.observacion)}">
        </div>
    </c:if>
    <div class="d-flex gap-2">
        <button type="submit" class="btn btn-uts"><i class="bi bi-save"></i> Guardar</button>
        <a class="btn btn-light" href="${ctx}/coordinacion/ideas.jsp">Cancelar</a>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
