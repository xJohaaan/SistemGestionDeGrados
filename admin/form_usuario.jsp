<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    admin/form_usuario.jsp: formulario para crear (RF-04, RF-05, RF-06) o editar (RF-07) usuarios.
    Sin parámetro "id" crea; con ?id=N edita.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ADMIN"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="editando" value="${not empty param.id}"/>
<c:if test="${editando}">
    <sql:query var="r" dataSource="${bd}">
        SELECT id_usuario, codigo, nombres, apellidos, correo, telefono, rol, estado
        FROM usuario WHERE id_usuario = ?
        <sql:param value="${param.id}"/>
    </sql:query>
    <c:if test="${r.rowCount == 0}">
        <c:set var="msgError" value="El usuario solicitado no existe." scope="session"/>
        <c:redirect url="/admin/usuarios.jsp"/>
    </c:if>
    <c:set var="u" value="${r.rows[0]}"/>
</c:if>
<c:set var="esPropio" value="${editando and u.id_usuario eq sessionScope.idUsuario}"/>
<c:set var="rolSel" value="${editando ? u.rol : (empty param.rol ? 'ESTUDIANTE' : param.rol)}"/>
<c:set var="tituloPagina" value="${editando ? 'Editar' : 'Nuevo'}"/>
<c:set var="resalte" value="USUARIO"/>
<c:set var="menu" value="usuarios"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<form method="POST" action="${ctx}/admin/controlador_usuario.jsp" class="needs-validation" novalidate style="max-width:820px">
    <input type="hidden" name="accion" value="${editando ? 'editar' : 'crear'}">
    <c:if test="${editando}"><input type="hidden" name="id" value="${u.id_usuario}"></c:if>

    <div class="row g-3">
        <div class="col-12 col-md-6">
            <label class="form-label" for="rol">Rol</label>
            <select class="form-select" id="rol" name="rol" required ${esPropio ? 'disabled' : ''}>
                <option value="ESTUDIANTE"   ${rolSel eq 'ESTUDIANTE' ? 'selected' : ''}>Estudiante</option>
                <option value="DIRECTOR"     ${rolSel eq 'DIRECTOR' ? 'selected' : ''}>Docente Director</option>
                <option value="EVALUADOR"    ${rolSel eq 'EVALUADOR' ? 'selected' : ''}>Docente Evaluador</option>
                <option value="COORDINACION" ${rolSel eq 'COORDINACION' ? 'selected' : ''}>Coordinación (incluye comité)</option>
                <option value="ADMIN"        ${rolSel eq 'ADMIN' ? 'selected' : ''}>Administrador</option>
            </select>
            <c:if test="${esPropio}">
                <input type="hidden" name="rol" value="ADMIN">
                <div class="form-text">No puede cambiar su propio rol.</div>
            </c:if>
            <div class="form-text">Cada usuario tiene un solo rol. Un docente es Director o Evaluador, no ambos.</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="codigo">Código estudiantil / documento</label>
            <input type="text" class="form-control" id="codigo" name="codigo" maxlength="20" pattern="[0-9A-Za-z\-]{4,20}"
                   value="${fn:escapeXml(u.codigo)}" required>
            <div class="invalid-feedback">Entre 4 y 20 caracteres (letras, números o guion).</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="nombres">Nombres</label>
            <input type="text" class="form-control" id="nombres" name="nombres" maxlength="80"
                   value="${fn:escapeXml(u.nombres)}" required>
            <div class="invalid-feedback">Ingrese los nombres.</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="apellidos">Apellidos</label>
            <input type="text" class="form-control" id="apellidos" name="apellidos" maxlength="80"
                   value="${fn:escapeXml(u.apellidos)}" required>
            <div class="invalid-feedback">Ingrese los apellidos.</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="correo">Correo institucional</label>
            <input type="email" class="form-control" id="correo" name="correo" maxlength="120"
                   value="${fn:escapeXml(u.correo)}" required>
            <div class="invalid-feedback">Ingrese un correo válido.</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="telefono">Teléfono</label>
            <input type="tel" class="form-control" id="telefono" name="telefono" maxlength="20" pattern="[0-9 +\-]{7,20}"
                   value="${fn:escapeXml(u.telefono)}">
            <div class="invalid-feedback">Solo números (7 a 20 dígitos).</div>
        </div>
        <div class="col-12 col-md-6">
            <label class="form-label" for="contrasena">Contraseña <c:if test="${editando}"><small class="text-muted">(dejar vacía para no cambiarla)</small></c:if></label>
            <input type="password" class="form-control" id="contrasena" name="contrasena" minlength="6" maxlength="60"
                   ${editando ? '' : 'required'}>
            <div class="invalid-feedback">Mínimo 6 caracteres.</div>
        </div>
    </div>

    <div class="mt-4 d-flex gap-2">
        <button type="submit" class="btn btn-uts"><i class="bi bi-save"></i> Guardar</button>
        <a href="${ctx}/admin/usuarios.jsp" class="btn btn-light">Cancelar</a>
    </div>
</form>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
