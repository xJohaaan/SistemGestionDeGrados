<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    admin/usuarios.jsp: lista paginada de usuarios con su rol (RF-07, RF-08, RF-09).
    Filtro opcional por rol: ?rol=DIRECTOR
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ADMIN"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="filtroRol" value="${empty param.rol ? '' : param.rol}"/>
<sql:query var="usuarios" dataSource="${bd}">
    SELECT id_usuario, codigo, nombres, apellidos, correo, telefono, rol, estado
    FROM usuario
    WHERE (? = '' OR rol = ?)
    ORDER BY rol, apellidos, nombres
    <sql:param value="${filtroRol}"/>
    <sql:param value="${filtroRol}"/>
</sql:query>
<c:set var="tituloPagina" value="Gestión de"/>
<c:set var="resalte" value="USUARIOS"/>
<c:set var="menu" value="usuarios"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="d-flex flex-wrap gap-2 justify-content-between align-items-center mb-3">
    <div class="btn-group flex-wrap" role="group" aria-label="Filtrar por rol">
        <a class="btn btn-sm ${filtroRol eq '' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp">Todos</a>
        <a class="btn btn-sm ${filtroRol eq 'ADMIN' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp?rol=ADMIN">Administradores</a>
        <a class="btn btn-sm ${filtroRol eq 'COORDINACION' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp?rol=COORDINACION">Coordinación</a>
        <a class="btn btn-sm ${filtroRol eq 'DIRECTOR' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp?rol=DIRECTOR">Directores</a>
        <a class="btn btn-sm ${filtroRol eq 'EVALUADOR' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp?rol=EVALUADOR">Evaluadores</a>
        <a class="btn btn-sm ${filtroRol eq 'ESTUDIANTE' ? 'btn-uts' : 'btn-outline-uts'}" href="${ctx}/admin/usuarios.jsp?rol=ESTUDIANTE">Estudiantes</a>
    </div>
    <a class="btn btn-uts" href="${ctx}/admin/form_usuario.jsp"><i class="bi bi-person-plus"></i> Nuevo usuario</a>
</div>

<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead>
        <tr><th>Código</th><th>Nombre</th><th>Correo</th><th>Rol</th><th>Estado</th><th class="text-end">Acciones</th></tr>
        </thead>
        <tbody>
        <c:forEach var="u" items="${usuarios.rows}">
            <tr>
                <td><c:out value="${u.codigo}"/></td>
                <td><c:out value="${u.nombres} ${u.apellidos}"/></td>
                <td><c:out value="${u.correo}"/></td>
                <td><span class="badge badge-fase"><c:out value="${u.rol}"/></span></td>
                <td><span class="badge ${u.estado eq 'Activo' ? 'badge-fin' : 'text-bg-secondary'}"><c:out value="${u.estado}"/></span></td>
                <td class="text-end text-nowrap">
                    <a class="btn btn-sm btn-light btn-accion" title="Editar" href="${ctx}/admin/form_usuario.jsp?id=${u.id_usuario}"><i class="bi bi-pencil"></i></a>
                    <c:if test="${u.id_usuario ne sessionScope.idUsuario}">
                        <form class="d-inline" method="POST" action="${ctx}/admin/controlador_usuario.jsp"
                              data-confirmar="¿Cambiar el estado de este usuario?">
                            <input type="hidden" name="accion" value="estado">
                            <input type="hidden" name="id" value="${u.id_usuario}">
                            <button class="btn btn-sm btn-light btn-accion" type="submit"
                                    title="${u.estado eq 'Activo' ? 'Dar de baja' : 'Reactivar'}">
                                <i class="bi ${u.estado eq 'Activo' ? 'bi-person-dash' : 'bi-person-check'}"></i>
                            </button>
                        </form>
                        <form class="d-inline" method="POST" action="${ctx}/admin/controlador_usuario.jsp"
                              data-confirmar="¿Eliminar definitivamente este usuario? Esta acción no se puede deshacer.">
                            <input type="hidden" name="accion" value="eliminar">
                            <input type="hidden" name="id" value="${u.id_usuario}">
                            <button class="btn btn-sm btn-light btn-accion text-danger" type="submit" title="Eliminar"><i class="bi bi-trash"></i></button>
                        </form>
                    </c:if>
                </td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
