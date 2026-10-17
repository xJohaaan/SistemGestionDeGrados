<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    controlador_perfil.jsp: cambia la contraseña del usuario autenticado.
    Verifica la contraseña actual y genera un salt nuevo.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/perfil.jsp"/>
</c:if>

<c:choose>
    <c:when test="${fn:length(param.nueva) lt 6}">
        <c:set var="msgError" value="La nueva contraseña debe tener al menos 6 caracteres." scope="session"/>
    </c:when>
    <c:when test="${param.nueva ne param.confirmacion}">
        <c:set var="msgError" value="La confirmación no coincide con la nueva contraseña." scope="session"/>
    </c:when>
    <c:otherwise>
        <sql:update var="filas" dataSource="${bd}">
            UPDATE usuario u
            JOIN (SELECT HEX(RANDOM_BYTES(16)) AS salt_nuevo) s
            SET u.salt = s.salt_nuevo,
                u.contrasena = SHA2(CONCAT(s.salt_nuevo, ?), 256)
            WHERE u.id_usuario = ? AND u.contrasena = SHA2(CONCAT(u.salt, ?), 256)
            <sql:param value="${param.nueva}"/>
            <sql:param value="${sessionScope.idUsuario}"/>
            <sql:param value="${param.actual}"/>
        </sql:update>
        <c:choose>
            <c:when test="${filas == 1}">
                <c:set var="msgExito" value="Contraseña actualizada exitosamente." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgError" value="La contraseña actual no es correcta." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="/perfil.jsp"/>
