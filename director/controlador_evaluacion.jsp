<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    director/controlador_evaluacion.jsp: registra la calificación del director.
      Fase 2 aprobado  -> Fase 3, responsable EVALUADOR (RF-21)
      Fase 4 aprobado  -> Fase 5, responsable EVALUADOR (RF-27)
      Rechazado        -> misma fase, responsable ESTUDIANTE (debe corregir y volver a subir)
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="DIRECTOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/director/index.jsp"/>
</c:if>

<c:catch var="exNota">
    <c:set var="notaValida" value="${not empty param.nota and param.nota + 0 ge 0 and param.nota + 0 le 5}"/>
</c:catch>
<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto, fase FROM proyecto
    WHERE id_proyecto = ? AND id_director = ? AND responsable = 'DIRECTOR' AND fase IN (2, 4)
    <sql:param value="${idSeguro}"/>
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="destino" value="/director/calificar.jsp?id=${idSeguro}"/>
<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <c:set var="msgError" value="Este proyecto no tiene revisiones pendientes de su parte." scope="session"/>
        <c:set var="destino" value="/director/index.jsp"/>
    </c:when>
    <c:when test="${not empty exNota or not notaValida or empty fn:trim(param.observaciones)
                    or (param.decision ne 'APROBADO' and param.decision ne 'RECHAZADO')}">
        <c:set var="msgError" value="Ingrese una nota entre 0.0 y 5.0, la decisión y las observaciones." scope="session"/>
    </c:when>
    <c:otherwise>
        <c:set var="faseActual" value="${rp.rows[0].fase}"/>
        <c:set var="documento" value="${faseActual == 2 ? 'Anteproyecto' : 'Informe final'}"/>
        <c:choose>
            <c:when test="${param.decision eq 'APROBADO'}">
                <c:set var="faseNueva" value="${faseActual + 1}"/><c:set var="respNuevo" value="EVALUADOR"/>
                <c:set var="desc" value="${documento} aprobado por el director"/>
                <c:set var="mensaje" value="${documento} aprobado. El proyecto pasó a la Fase ${faseActual + 1} (evaluador)."/>
            </c:when>
            <c:otherwise>
                <c:set var="faseNueva" value="${faseActual}"/><c:set var="respNuevo" value="ESTUDIANTE"/>
                <c:set var="desc" value="${documento} devuelto al estudiante por el director"/>
                <c:set var="mensaje" value="${documento} devuelto al estudiante con observaciones."/>
            </c:otherwise>
        </c:choose>
        <c:catch var="ex">
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto SET fase = ?, responsable = ?
                    WHERE id_proyecto = ? AND id_director = ? AND responsable = 'DIRECTOR' AND fase = ?
                    <sql:param value="${faseNueva}"/>
                    <sql:param value="${respNuevo}"/>
                    <sql:param value="${idSeguro}"/>
                    <sql:param value="${sessionScope.idUsuario}"/>
                    <sql:param value="${faseActual}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO evaluacion (id_proyecto, id_usuario, rol_evaluador, fase, nota, observaciones, decision)
                        VALUES (?, ?, 'DIRECTOR', ?, ?, ?, ?)
                        <sql:param value="${idSeguro}"/>
                        <sql:param value="${sessionScope.idUsuario}"/>
                        <sql:param value="${faseActual}"/>
                        <sql:param value="${param.nota}"/>
                        <sql:param value="${fn:trim(param.observaciones)}"/>
                        <sql:param value="${param.decision}"/>
                    </sql:update>
                    <sql:update>
                        INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion)
                        VALUES (?, ?, ?, ?, ?)
                        <sql:param value="${idSeguro}"/>
                        <sql:param value="${faseActual}"/>
                        <sql:param value="${faseNueva}"/>
                        <sql:param value="${sessionScope.idUsuario}"/>
                        <sql:param value="${desc}"/>
                    </sql:update>
                </c:if>
            </sql:transaction>
        </c:catch>
        <c:choose>
            <c:when test="${not empty ex or filas != 1}">
                <c:set var="msgError" value="No fue posible registrar la calificación." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgExito" value="${mensaje}" scope="session"/>
                <c:set var="destino" value="/director/index.jsp"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="${destino}"/>
