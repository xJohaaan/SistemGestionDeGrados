<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    admin/index.jsp: panel del administrador con el resumen de usuarios por rol.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ADMIN"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="resumen" dataSource="${bd}">
    SELECT COUNT(*) AS total,
           COALESCE(SUM(rol = 'DIRECTOR'), 0)     AS directores,
           COALESCE(SUM(rol = 'EVALUADOR'), 0)    AS evaluadores,
           COALESCE(SUM(rol = 'ESTUDIANTE'), 0)   AS estudiantes,
           COALESCE(SUM(rol = 'COORDINACION'), 0) AS coordinacion,
           COALESCE(SUM(estado = 'Inactivo'), 0)  AS inactivos
    FROM usuario
</sql:query>
<sql:query var="recientes" dataSource="${bd}">
    SELECT codigo, CONCAT(nombres, ' ', apellidos) AS nombre, correo, rol, estado, creado_en
    FROM usuario ORDER BY creado_en DESC, id_usuario DESC LIMIT 5
</sql:query>
<c:set var="t" value="${resumen.rows[0]}"/>
<c:set var="tituloPagina" value="Panel de"/>
<c:set var="resalte" value="ADMINISTRACIÓN"/>
<c:set var="menu" value="inicio"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-3 mb-4">
    <div class="col-6 col-lg-3">
        <a class="tarjeta-dato d-block text-reset" href="${ctx}/admin/usuarios.jsp">
            <div class="icono"><i class="bi bi-people"></i></div>
            <div class="numero"><c:out value="${t.total}"/></div>
            <div class="etiqueta">Usuarios registrados</div>
        </a>
    </div>
    <div class="col-6 col-lg-3">
        <a class="tarjeta-dato d-block text-reset" href="${ctx}/admin/usuarios.jsp?rol=DIRECTOR">
            <div class="icono"><i class="bi bi-person-workspace"></i></div>
            <div class="numero"><c:out value="${t.directores}"/> / <c:out value="${t.evaluadores}"/></div>
            <div class="etiqueta">Docentes directores / evaluadores</div>
        </a>
    </div>
    <div class="col-6 col-lg-3">
        <a class="tarjeta-dato d-block text-reset" href="${ctx}/admin/usuarios.jsp?rol=ESTUDIANTE">
            <div class="icono"><i class="bi bi-mortarboard"></i></div>
            <div class="numero"><c:out value="${t.estudiantes}"/></div>
            <div class="etiqueta">Estudiantes</div>
        </a>
    </div>
    <div class="col-6 col-lg-3">
        <a class="tarjeta-dato d-block text-reset" href="${ctx}/admin/usuarios.jsp?rol=COORDINACION">
            <div class="icono"><i class="bi bi-building"></i></div>
            <div class="numero"><c:out value="${t.coordinacion}"/></div>
            <div class="etiqueta">Coordinación (<c:out value="${t.inactivos}"/> inactivos en total)</div>
        </a>
    </div>
</div>

<div class="d-flex justify-content-between align-items-center mb-2">
    <h5 class="mb-0">Últimos usuarios registrados</h5>
    <a class="btn btn-uts btn-sm" href="${ctx}/admin/form_usuario.jsp"><i class="bi bi-person-plus"></i> Nuevo usuario</a>
</div>
<div class="table-responsive">
    <table class="table align-middle">
        <thead><tr><th>Código</th><th>Nombre</th><th>Correo</th><th>Rol</th><th>Estado</th></tr></thead>
        <tbody>
        <c:forEach var="u" items="${recientes.rows}">
            <tr>
                <td><c:out value="${u.codigo}"/></td>
                <td><c:out value="${u.nombre}"/></td>
                <td><c:out value="${u.correo}"/></td>
                <td><span class="badge badge-fase"><c:out value="${u.rol}"/></span></td>
                <td><span class="badge ${u.estado eq 'Activo' ? 'badge-fin' : 'text-bg-secondary'}"><c:out value="${u.estado}"/></span></td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
