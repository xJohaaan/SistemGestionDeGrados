<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    perfil.jsp: datos del usuario autenticado y cambio de contraseña (todos los roles).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="r" dataSource="${bd}">
    SELECT codigo, nombres, apellidos, correo, telefono, rol, estado, creado_en
    FROM usuario WHERE id_usuario = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="u" value="${r.rows[0]}"/>
<c:set var="tituloPagina" value="Mi"/>
<c:set var="resalte" value="PERFIL"/>
<c:set var="menu" value="perfil"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-4">
    <div class="col-12 col-lg-6">
        <div class="tarjeta-dato">
            <div class="d-flex align-items-center gap-3 mb-3">
                <span class="avatar" style="width:56px;height:56px;font-size:1.6rem"><i class="bi bi-person-fill"></i></span>
                <div>
                    <h5 class="mb-0"><c:out value="${u.nombres} ${u.apellidos}"/></h5>
                    <span class="badge badge-fase"><c:out value="${u.rol}"/></span>
                </div>
            </div>
            <dl class="row mb-0 small">
                <dt class="col-5">Código / documento</dt><dd class="col-7"><c:out value="${u.codigo}"/></dd>
                <dt class="col-5">Correo</dt><dd class="col-7"><c:out value="${u.correo}"/></dd>
                <dt class="col-5">Teléfono</dt><dd class="col-7"><c:out value="${empty u.telefono ? '—' : u.telefono}"/></dd>
                <dt class="col-5">Estado</dt><dd class="col-7"><c:out value="${u.estado}"/></dd>
                <dt class="col-5">Registrado</dt><dd class="col-7"><fmt:formatDate value="${u.creado_en}" pattern="dd/MM/yyyy"/></dd>
            </dl>
        </div>
    </div>
    <div class="col-12 col-lg-6">
        <div class="tarjeta-dato">
            <h5 class="mb-3"><i class="bi bi-key text-uts"></i> Cambiar contraseña</h5>
            <form method="POST" action="${ctx}/controlador_perfil.jsp" class="needs-validation" novalidate>
                <div class="mb-3">
                    <label class="form-label" for="actual">Contraseña actual</label>
                    <input type="password" class="form-control" id="actual" name="actual" required>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="nueva">Nueva contraseña</label>
                    <input type="password" class="form-control" id="nueva" name="nueva" minlength="6" maxlength="60" required>
                    <div class="invalid-feedback">Mínimo 6 caracteres.</div>
                </div>
                <div class="mb-3">
                    <label class="form-label" for="confirmacion">Confirmar nueva contraseña</label>
                    <input type="password" class="form-control" id="confirmacion" name="confirmacion" minlength="6" maxlength="60" required>
                </div>
                <button type="submit" class="btn btn-uts"><i class="bi bi-save"></i> Actualizar contraseña</button>
            </form>
        </div>
    </div>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
