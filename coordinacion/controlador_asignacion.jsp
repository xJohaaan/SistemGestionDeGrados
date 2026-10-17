<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/controlador_asignacion.jsp: asigna director y evaluador y pasa el proyecto
    de la Fase 1 a la Fase 2 (el estudiante debe subir el anteproyecto).
    Los triggers de la BD verifican que el director tenga rol DIRECTOR y el evaluador rol EVALUADOR.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/coordinacion/asignar.jsp"/>
</c:if>

<c:choose>
    <c:when test="${empty param.id or empty param.director or empty param.evaluador}">
        <c:set var="msgError" value="Seleccione el director y el evaluador." scope="session"/>
    </c:when>
    <c:otherwise>
        <c:catch var="ex">
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto SET id_director = ?, id_evaluador = ?, fase = 2, responsable = 'ESTUDIANTE'
                    WHERE id_proyecto = ? AND fase = 1 AND responsable = 'COORDINACION'
                    <sql:param value="${param.director}"/>
                    <sql:param value="${param.evaluador}"/>
                    <sql:param value="${param.id}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion)
                        VALUES (?, 1, 2, ?, 'Pago validado y director/evaluador asignados')
                        <sql:param value="${param.id}"/>
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
                <c:set var="msgError" value="El proyecto ya no está pendiente de asignación." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="/coordinacion/asignar.jsp"/>
