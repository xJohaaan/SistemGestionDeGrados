<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    admin/controlador_usuario.jsp: procesa el CRUD de usuarios. No genera HTML: escribe en la BD,
    deja un mensaje en sesión y redirige.
    Acciones (param.accion): crear | editar | estado | eliminar
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ADMIN"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/admin/usuarios.jsp"/>
</c:if>

<c:set var="destino" value="/admin/usuarios.jsp"/>
<c:set var="correo" value="${fn:toLowerCase(fn:trim(param.correo))}"/>
<c:set var="rolValido" value="${param.rol eq 'ADMIN' or param.rol eq 'COORDINACION' or param.rol eq 'DIRECTOR' or param.rol eq 'EVALUADOR' or param.rol eq 'ESTUDIANTE'}"/>
<c:set var="datosCompletos" value="${not empty fn:trim(param.codigo) and not empty fn:trim(param.nombres)
                                     and not empty fn:trim(param.apellidos) and fn:contains(correo, '@') and rolValido}"/>

<c:choose>
    <%-- ===================== CREAR ===================== --%>
    <c:when test="${param.accion eq 'crear'}">
        <c:choose>
            <c:when test="${not datosCompletos or fn:length(param.contrasena) lt 6}">
                <c:set var="msgError" value="Complete todos los campos obligatorios. La contraseña debe tener al menos 6 caracteres." scope="session"/>
                <c:set var="destino" value="/admin/form_usuario.jsp"/>
            </c:when>
            <c:otherwise>
                <sql:query var="dup" dataSource="${bd}">
                    SELECT COUNT(*) AS total FROM usuario WHERE correo = ? OR codigo = ?
                    <sql:param value="${correo}"/>
                    <sql:param value="${fn:trim(param.codigo)}"/>
                </sql:query>
                <c:choose>
                    <c:when test="${dup.rows[0].total > 0}">
                        <c:set var="msgError" value="Ya existe un usuario con ese correo o código." scope="session"/>
                        <c:set var="destino" value="/admin/form_usuario.jsp"/>
                    </c:when>
                    <c:otherwise>
                        <c:catch var="ex">
                            <sql:update dataSource="${bd}">
                                INSERT INTO usuario (codigo, nombres, apellidos, correo, telefono, rol, salt, contrasena)
                                SELECT ?, ?, ?, ?, ?, ?, s.salt, SHA2(CONCAT(s.salt, ?), 256)
                                FROM (SELECT HEX(RANDOM_BYTES(16)) AS salt) s
                                <sql:param value="${fn:trim(param.codigo)}"/>
                                <sql:param value="${fn:trim(param.nombres)}"/>
                                <sql:param value="${fn:trim(param.apellidos)}"/>
                                <sql:param value="${correo}"/>
                                <sql:param value="${fn:trim(param.telefono)}"/>
                                <sql:param value="${param.rol}"/>
                                <sql:param value="${param.contrasena}"/>
                            </sql:update>
                        </c:catch>
                        <c:choose>
                            <c:when test="${empty ex}">
                                <c:set var="msgExito" value="Usuario registrado exitosamente." scope="session"/>
                            </c:when>
                            <c:otherwise>
                                <c:set var="msgError" value="No fue posible registrar el usuario." scope="session"/>
                            </c:otherwise>
                        </c:choose>
                    </c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>
    </c:when>

    <%-- ===================== EDITAR ===================== --%>
    <c:when test="${param.accion eq 'editar'}">
        <c:set var="esPropio" value="${idSeguro eq sessionScope.idUsuario}"/>
        <%-- Un usuario con proyectos asociados no puede cambiar de rol (p. ej. Director a Evaluador) --%>
        <sql:query var="actual" dataSource="${bd}">
            SELECT u.rol,
                   (SELECT COUNT(*) FROM proyecto p
                     WHERE p.id_estudiante = u.id_usuario OR p.id_director = u.id_usuario OR p.id_evaluador = u.id_usuario) AS proyectos
            FROM usuario u WHERE u.id_usuario = ?
            <sql:param value="${idSeguro}"/>
        </sql:query>
        <c:set var="cambiaRol" value="${actual.rowCount == 1 and actual.rows[0].rol ne param.rol}"/>
        <c:choose>
            <c:when test="${actual.rowCount == 0}">
                <c:set var="msgError" value="El usuario no existe." scope="session"/>
            </c:when>
            <c:when test="${cambiaRol and actual.rows[0].proyectos > 0}">
                <c:set var="msgError" value="No se puede cambiar el rol: el usuario ya participa en proyectos de grado con su rol actual." scope="session"/>
                <c:set var="destino" value="/admin/form_usuario.jsp?id=${idSeguro}"/>
            </c:when>
            <c:when test="${not datosCompletos or (not empty param.contrasena and fn:length(param.contrasena) lt 6)}">
                <c:set var="msgError" value="Datos incompletos o inválidos. Revise el formulario." scope="session"/>
                <c:set var="destino" value="/admin/form_usuario.jsp?id=${idSeguro}"/>
            </c:when>
            <c:when test="${esPropio and param.rol ne 'ADMIN'}">
                <c:set var="msgError" value="No puede quitarse a sí mismo el rol de administrador." scope="session"/>
                <c:set var="destino" value="/admin/form_usuario.jsp?id=${idSeguro}"/>
            </c:when>
            <c:otherwise>
                <sql:query var="dup" dataSource="${bd}">
                    SELECT COUNT(*) AS total FROM usuario WHERE (correo = ? OR codigo = ?) AND id_usuario <> ?
                    <sql:param value="${correo}"/>
                    <sql:param value="${fn:trim(param.codigo)}"/>
                    <sql:param value="${idSeguro}"/>
                </sql:query>
                <c:choose>
                    <c:when test="${dup.rows[0].total > 0}">
                        <c:set var="msgError" value="Otro usuario ya tiene ese correo o código." scope="session"/>
                        <c:set var="destino" value="/admin/form_usuario.jsp?id=${idSeguro}"/>
                    </c:when>
                    <c:otherwise>
                        <c:catch var="ex">
                            <sql:transaction dataSource="${bd}">
                                <sql:update>
                                    UPDATE usuario SET codigo = ?, nombres = ?, apellidos = ?, correo = ?, telefono = ?, rol = ?
                                    WHERE id_usuario = ?
                                    <sql:param value="${fn:trim(param.codigo)}"/>
                                    <sql:param value="${fn:trim(param.nombres)}"/>
                                    <sql:param value="${fn:trim(param.apellidos)}"/>
                                    <sql:param value="${correo}"/>
                                    <sql:param value="${fn:trim(param.telefono)}"/>
                                    <sql:param value="${param.rol}"/>
                                    <sql:param value="${idSeguro}"/>
                                </sql:update>
                                <c:if test="${not empty param.contrasena}">
                                    <sql:update>
                                        UPDATE usuario u
                                        JOIN (SELECT HEX(RANDOM_BYTES(16)) AS salt_nuevo) s
                                        SET u.salt = s.salt_nuevo, u.contrasena = SHA2(CONCAT(s.salt_nuevo, ?), 256)
                                        WHERE u.id_usuario = ?
                                        <sql:param value="${param.contrasena}"/>
                                        <sql:param value="${idSeguro}"/>
                                    </sql:update>
                                </c:if>
                            </sql:transaction>
                        </c:catch>
                        <c:choose>
                            <c:when test="${empty ex}">
                                <c:set var="msgExito" value="Usuario actualizado exitosamente." scope="session"/>
                                <%-- Si el administrador editó sus propios datos, se refresca la sesión --%>
                                <c:if test="${esPropio}">
                                    <sql:query var="yo" dataSource="${bd}">
                                        SELECT id_usuario, codigo, nombres, apellidos, correo, rol FROM usuario WHERE id_usuario = ?
                                        <sql:param value="${idSeguro}"/>
                                    </sql:query>
                                    <c:set var="usuario" value="${yo.rows[0]}" scope="session"/>
                                </c:if>
                            </c:when>
                            <c:otherwise>
                                <c:set var="msgError" value="No fue posible actualizar el usuario." scope="session"/>
                            </c:otherwise>
                        </c:choose>
                    </c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>
    </c:when>

    <%-- ===================== ACTIVAR / DAR DE BAJA ===================== --%>
    <c:when test="${param.accion eq 'estado'}">
        <sql:update var="filas" dataSource="${bd}">
            UPDATE usuario SET estado = IF(estado = 'Activo', 'Inactivo', 'Activo')
            WHERE id_usuario = ? AND id_usuario <> ?
            <sql:param value="${idSeguro}"/>
            <sql:param value="${sessionScope.idUsuario}"/>
        </sql:update>
        <c:choose>
            <c:when test="${filas == 1}"><c:set var="msgExito" value="Estado del usuario actualizado." scope="session"/></c:when>
            <c:otherwise><c:set var="msgError" value="No se puede cambiar el estado de este usuario." scope="session"/></c:otherwise>
        </c:choose>
    </c:when>

    <%-- ===================== ELIMINAR ===================== --%>
    <c:when test="${param.accion eq 'eliminar'}">
        <c:catch var="ex">
            <sql:update var="filas" dataSource="${bd}">
                DELETE FROM usuario WHERE id_usuario = ? AND id_usuario <> ?
                <sql:param value="${idSeguro}"/>
                <sql:param value="${sessionScope.idUsuario}"/>
            </sql:update>
        </c:catch>
        <c:choose>
            <c:when test="${not empty ex}">
                <c:set var="msgError" value="No se puede eliminar: el usuario tiene ideas, proyectos o evaluaciones asociadas. Use «Dar de baja»." scope="session"/>
            </c:when>
            <c:when test="${filas == 1}"><c:set var="msgExito" value="Usuario eliminado exitosamente." scope="session"/></c:when>
            <c:otherwise><c:set var="msgError" value="No se puede eliminar este usuario." scope="session"/></c:otherwise>
        </c:choose>
    </c:when>

    <c:otherwise>
        <c:set var="msgError" value="Acción no válida." scope="session"/>
    </c:otherwise>
</c:choose>
<c:redirect url="${destino}"/>
