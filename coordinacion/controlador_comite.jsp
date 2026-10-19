<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/controlador_comite.jsp: registra la decisión del comité.
      Fase 3 aprobado  -> Fase 4, responsable ESTUDIANTE (sube informe final)
      Fase 3 rechazado -> Fase 2, responsable ESTUDIANTE (corrige anteproyecto)
      Fase 5 aprobado  -> Fase 6 (cierre), FINALIZADO y radicado RAD-AAAA-NNNNN (RF-30, RF-31)
      Fase 5 rechazado -> Fase 4, responsable ESTUDIANTE (corrige informe)
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/coordinacion/comite.jsp"/>
</c:if>

<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto, fase FROM proyecto WHERE id_proyecto = ? AND responsable = 'COMITE'
    <sql:param value="${idSeguro}"/>
</sql:query>
<c:set var="aprobado" value="${param.decision eq 'APROBADO'}"/>
<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <c:set var="msgError" value="El proyecto no está pendiente de decisión del comité." scope="session"/>
    </c:when>
    <c:when test="${empty fn:trim(param.acta) or empty fn:trim(param.observaciones)
                    or (param.decision ne 'APROBADO' and param.decision ne 'RECHAZADO')}">
        <c:set var="msgError" value="Complete el número de acta, la decisión y las observaciones." scope="session"/>
    </c:when>
    <c:otherwise>
        <c:set var="faseActual" value="${rp.rows[0].fase}"/>
        <c:choose>
            <c:when test="${faseActual == 3 and aprobado}">
                <c:set var="faseNueva" value="4"/><c:set var="respNuevo" value="ESTUDIANTE"/>
                <c:set var="desc" value="Propuesta aprobada por el comité (acta ${fn:trim(param.acta)})"/>
            </c:when>
            <c:when test="${faseActual == 3}">
                <c:set var="faseNueva" value="2"/><c:set var="respNuevo" value="ESTUDIANTE"/>
                <c:set var="desc" value="Propuesta rechazada por el comité (acta ${fn:trim(param.acta)})"/>
            </c:when>
            <c:when test="${aprobado}">
                <c:set var="faseNueva" value="6"/><c:set var="respNuevo" value="FINALIZADO"/>
                <c:set var="desc" value="Informe final aprobado por el comité y cierre del proyecto (acta ${fn:trim(param.acta)})"/>
            </c:when>
            <c:otherwise>
                <c:set var="faseNueva" value="4"/><c:set var="respNuevo" value="ESTUDIANTE"/>
                <c:set var="desc" value="Informe final rechazado por el comité (acta ${fn:trim(param.acta)})"/>
            </c:otherwise>
        </c:choose>
        <c:catch var="ex">
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto
                    SET fase = ?, responsable = ?,
                        radicado = IF(? = 6, CONCAT('RAD-', YEAR(CURRENT_DATE), '-', LPAD(id_proyecto, 5, '0')), radicado)
                    WHERE id_proyecto = ? AND fase = ? AND responsable = 'COMITE'
                    <sql:param value="${faseNueva}"/>
                    <sql:param value="${respNuevo}"/>
                    <sql:param value="${faseNueva}"/>
                    <sql:param value="${idSeguro}"/>
                    <sql:param value="${faseActual}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO evaluacion (id_proyecto, id_usuario, rol_evaluador, fase, nota, observaciones, decision)
                        VALUES (?, ?, 'COMITE', ?, NULL, ?, ?)
                        <sql:param value="${idSeguro}"/>
                        <sql:param value="${sessionScope.idUsuario}"/>
                        <sql:param value="${faseActual}"/>
                        <sql:param value="Acta de comité No. ${fn:trim(param.acta)}: ${fn:trim(param.observaciones)}"/>
                        <sql:param value="${param.decision}"/>
                    </sql:update>
                    <sql:update>
                        INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion)
                        VALUES (?, ?, ?, ?, ?)
                        <sql:param value="${idSeguro}"/>
                        <sql:param value="${faseActual}"/>
                        <sql:param value="${faseNueva}"/>
                        <sql:param value="${sessionScope.idUsuario}"/>
                        <sql:param value="${fn:substring(desc, 0, 200)}"/>
                    </sql:update>
                </c:if>
            </sql:transaction>
        </c:catch>
        <c:choose>
            <c:when test="${not empty ex or filas != 1}">
                <c:set var="msgError" value="No fue posible registrar la decisión del comité." scope="session"/>
            </c:when>
            <c:when test="${faseNueva == 6}">
                <c:set var="msgExito" value="Proyecto cerrado exitosamente. Se generó el radicado de grado." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgExito" value="Decisión del comité registrada exitosamente." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="/coordinacion/comite.jsp"/>
