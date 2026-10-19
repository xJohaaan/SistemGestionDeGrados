<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    evaluador/controlador_evaluacion.jsp: registra la evaluación del evaluador.
      Fase 3 aprobado  -> sigue en Fase 3, responsable COMITE (aprobación final de la propuesta)
      Fase 3 rechazado -> Fase 2, responsable ESTUDIANTE
      Fase 5 aprobado  -> sigue en Fase 5, responsable COMITE (aprobación del informe y cierre)
      Fase 5 rechazado -> Fase 4, responsable ESTUDIANTE (RF-29)
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="EVALUADOR"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/evaluador/index.jsp"/>
</c:if>

<c:catch var="exNota">
    <c:set var="notaValida" value="${not empty param.nota and param.nota + 0 ge 0 and param.nota + 0 le 5}"/>
</c:catch>
<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto, fase FROM proyecto
    WHERE id_proyecto = ? AND id_evaluador = ? AND responsable = 'EVALUADOR' AND fase IN (3, 5)
    <sql:param value="${idSeguro}"/>
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="destino" value="/evaluador/calificar.jsp?id=${idSeguro}"/>
<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <c:set var="msgError" value="Este proyecto no tiene evaluaciones pendientes de su parte." scope="session"/>
        <c:set var="destino" value="/evaluador/index.jsp"/>
    </c:when>
    <c:when test="${not empty exNota or not notaValida or empty fn:trim(param.observaciones)
                    or (param.decision ne 'APROBADO' and param.decision ne 'RECHAZADO')}">
        <c:set var="msgError" value="Ingrese una nota entre 0.0 y 5.0, la decisión y las observaciones." scope="session"/>
    </c:when>
    <c:otherwise>
        <c:set var="faseActual" value="${rp.rows[0].fase}"/>
        <c:set var="documento" value="${faseActual == 3 ? 'Propuesta' : 'Informe final'}"/>
        <c:set var="aprob" value="${faseActual == 3 ? 'aprobada' : 'aprobado'}"/>
        <c:set var="rech" value="${faseActual == 3 ? 'rechazada' : 'rechazado'}"/>
        <c:choose>
            <c:when test="${param.decision eq 'APROBADO'}">
                <c:set var="faseNueva" value="${faseActual}"/><c:set var="respNuevo" value="COMITE"/>
                <c:set var="desc" value="${documento} ${aprob} por el evaluador; pasa al comité"/>
                <c:set var="mensaje" value="${documento} ${aprob}. El proyecto pasó al comité de trabajos de grado."/>
            </c:when>
            <c:otherwise>
                <c:set var="faseNueva" value="${faseActual - 1}"/><c:set var="respNuevo" value="ESTUDIANTE"/>
                <c:set var="desc" value="${documento} ${rech} por el evaluador; vuelve a Fase ${faseActual - 1}"/>
                <c:set var="mensaje" value="${documento} ${rech}. El proyecto volvió a la Fase ${faseActual - 1} para correcciones."/>
            </c:otherwise>
        </c:choose>
        <c:catch var="ex">
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto SET fase = ?, responsable = ?
                    WHERE id_proyecto = ? AND id_evaluador = ? AND responsable = 'EVALUADOR' AND fase = ?
                    <sql:param value="${faseNueva}"/>
                    <sql:param value="${respNuevo}"/>
                    <sql:param value="${idSeguro}"/>
                    <sql:param value="${sessionScope.idUsuario}"/>
                    <sql:param value="${faseActual}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO evaluacion (id_proyecto, id_usuario, rol_evaluador, fase, nota, observaciones, decision)
                        VALUES (?, ?, 'EVALUADOR', ?, ?, ?, ?)
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
                <c:set var="msgError" value="No fue posible registrar la evaluación." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgExito" value="${mensaje}" scope="session"/>
                <c:set var="destino" value="/evaluador/index.jsp"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="${destino}"/>
