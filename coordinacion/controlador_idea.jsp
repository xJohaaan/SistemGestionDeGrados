<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/controlador_idea.jsp: CRUD y aprobación del Banco de Ideas (RF-13, RF-15).
      crear | editar | aprobar | rechazar | eliminar
    Una idea "Tomada" (con proyecto) no se puede editar ni eliminar.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<%@ include file="/WEB-INF/jspf/id_seguro.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/coordinacion/ideas.jsp"/>
</c:if>
<c:set var="destino" value="/coordinacion/ideas.jsp"/>
<c:set var="datosValidos" value="${fn:length(fn:trim(param.titulo)) ge 10 and fn:length(fn:trim(param.descripcion)) ge 30 and not empty param.linea}"/>

<c:choose>
    <c:when test="${param.accion eq 'crear'}">
        <c:choose>
            <c:when test="${not datosValidos}">
                <c:set var="msgError" value="Complete el título (mín. 10), la línea y la descripción (mín. 30 caracteres)." scope="session"/>
                <c:set var="destino" value="/coordinacion/form_idea.jsp"/>
            </c:when>
            <c:otherwise>
                <sql:update dataSource="${bd}">
                    INSERT INTO idea (titulo, descripcion, linea, id_autor, estado) VALUES (?, ?, ?, ?, 'Aprobada')
                    <sql:param value="${fn:substring(fn:trim(param.titulo), 0, 150)}"/>
                    <sql:param value="${fn:substring(fn:trim(param.descripcion), 0, 2000)}"/>
                    <sql:param value="${fn:substring(param.linea, 0, 80)}"/>
                    <sql:param value="${sessionScope.idUsuario}"/>
                </sql:update>
                <c:set var="msgExito" value="Idea creada y publicada en el banco." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${param.accion eq 'editar'}">
        <c:choose>
            <c:when test="${not datosValidos or (param.estado ne 'Pendiente' and param.estado ne 'Aprobada' and param.estado ne 'Rechazada')}">
                <c:set var="msgError" value="Datos incompletos o inválidos." scope="session"/>
                <c:set var="destino" value="/coordinacion/form_idea.jsp?id=${idSeguro}"/>
            </c:when>
            <c:otherwise>
                <sql:update var="filas" dataSource="${bd}">
                    UPDATE idea SET titulo = ?, descripcion = ?, linea = ?, estado = ?, observacion = NULLIF(?, '')
                    WHERE id_idea = ? AND estado <> 'Tomada'
                    <sql:param value="${fn:substring(fn:trim(param.titulo), 0, 150)}"/>
                    <sql:param value="${fn:substring(fn:trim(param.descripcion), 0, 2000)}"/>
                    <sql:param value="${fn:substring(param.linea, 0, 80)}"/>
                    <sql:param value="${param.estado}"/>
                    <sql:param value="${fn:substring(fn:trim(param.observacion), 0, 300)}"/>
                    <sql:param value="${idSeguro}"/>
                </sql:update>
                <c:choose>
                    <c:when test="${filas == 1}"><c:set var="msgExito" value="Idea actualizada exitosamente." scope="session"/></c:when>
                    <c:otherwise><c:set var="msgError" value="La idea no existe o ya fue tomada por un estudiante." scope="session"/></c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${param.accion eq 'aprobar'}">
        <sql:update var="filas" dataSource="${bd}">
            UPDATE idea SET estado = 'Aprobada', observacion = NULL WHERE id_idea = ? AND estado = 'Pendiente'
            <sql:param value="${idSeguro}"/>
        </sql:update>
        <c:choose>
            <c:when test="${filas == 1}"><c:set var="msgExito" value="Idea aprobada. Ya es visible en el Banco de Ideas." scope="session"/></c:when>
            <c:otherwise><c:set var="msgError" value="La idea ya no está pendiente." scope="session"/></c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${param.accion eq 'rechazar'}">
        <c:choose>
            <c:when test="${empty fn:trim(param.observacion)}">
                <c:set var="msgError" value="Escriba el motivo del rechazo." scope="session"/>
            </c:when>
            <c:otherwise>
                <sql:update var="filas" dataSource="${bd}">
                    UPDATE idea SET estado = 'Rechazada', observacion = ? WHERE id_idea = ? AND estado = 'Pendiente'
                    <sql:param value="${fn:substring(fn:trim(param.observacion), 0, 300)}"/>
                    <sql:param value="${idSeguro}"/>
                </sql:update>
                <c:choose>
                    <c:when test="${filas == 1}"><c:set var="msgExito" value="Idea rechazada. El autor verá el motivo en sus propuestas." scope="session"/></c:when>
                    <c:otherwise><c:set var="msgError" value="La idea ya no está pendiente." scope="session"/></c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>
    </c:when>

    <c:when test="${param.accion eq 'eliminar'}">
        <c:catch var="ex">
            <sql:update var="filas" dataSource="${bd}">
                DELETE FROM idea WHERE id_idea = ? AND estado <> 'Tomada'
                <sql:param value="${idSeguro}"/>
            </sql:update>
        </c:catch>
        <c:choose>
            <c:when test="${empty ex and filas == 1}"><c:set var="msgExito" value="Idea eliminada del banco." scope="session"/></c:when>
            <c:otherwise><c:set var="msgError" value="No se puede eliminar: la idea ya tiene un proyecto asociado." scope="session"/></c:otherwise>
        </c:choose>
    </c:when>

    <c:otherwise>
        <c:set var="msgError" value="Acción no válida." scope="session"/>
    </c:otherwise>
</c:choose>
<c:redirect url="${destino}"/>
