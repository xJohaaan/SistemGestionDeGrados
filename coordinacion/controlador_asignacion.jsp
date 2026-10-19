<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/controlador_asignacion.jsp: asigna director y evaluador y pasa el proyecto
    de la Fase 1 a la Fase 2 (el estudiante debe subir el anteproyecto).
    Los triggers de la BD verifican que el director tenga rol DIRECTOR y el evaluador rol EVALUADOR.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/coordinacion/asignar.jsp"/>
</c:if>

<c:choose>
    <c:when test="${idSeguro le 0 or empty param.director or empty param.evaluador}">
        <c:set var="msgError" value="Seleccione el director y el evaluador." scope="session"/>
    </c:when>
    <c:otherwise>
        <c:catch var="ex">
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto SET id_director = ?, id_evaluador = ?, fase = 2, responsable = 'ESTUDIANTE'
                    WHERE id_proyecto = ? AND fase = 1 AND responsable = 'COORDINACION'
                      AND EXISTS (SELECT 1 FROM usuario WHERE id_usuario = ? AND rol = 'DIRECTOR'  AND estado = 'Activo')
                      AND EXISTS (SELECT 1 FROM usuario WHERE id_usuario = ? AND rol = 'EVALUADOR' AND estado = 'Activo')
                    <sql:param value="${param.director}"/>
                    <sql:param value="${param.evaluador}"/>
                    <sql:param value="${idSeguro}"/>
                    <sql:param value="${param.director}"/>
                    <sql:param value="${param.evaluador}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion)
                        VALUES (?, 1, 2, ?, 'Pago validado y director/evaluador asignados')
                        <sql:param value="${idSeguro}"/>
                        <sql:param value="${sessionScope.idUsuario}"/>
                    </sql:update>
                </c:if>
            </sql:transaction>
        </c:catch>
        <c:choose>
            <c:when test="${not empty ex}">
                <c:set var="msgError" value="No fue posible asignar: verifique que el director tenga rol Docente Director y el evaluador rol Docente Evaluador." scope="session"/>
            </c:when>
            <c:when test="${filas == 1}">
                <c:set var="msgExito" value="Docentes asignados exitosamente. El proyecto pasó a la Fase 2 (anteproyecto)." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgError" value="No se asignó: el proyecto ya no está pendiente o alguno de los docentes no está activo con el rol correcto." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="/coordinacion/asignar.jsp"/>
