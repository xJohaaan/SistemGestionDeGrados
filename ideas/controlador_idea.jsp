<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    ideas/controlador_idea.jsp: acciones de estudiantes y docentes sobre el Banco de Ideas.
      proponer    -> crea una idea "Pendiente" (RF-11, RF-12)
      retirar     -> elimina una propuesta propia que sigue "Pendiente"
      seleccionar -> el estudiante toma una idea "Aprobada": la idea pasa a "Tomada" y se crea
                     su proyecto GRA-NNNNN en Fase 1 (RF-14). Todo en una transacción.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/ideas/banco.jsp"/>
</c:if>
<c:set var="esProponente" value="${sessionScope.rol eq 'ESTUDIANTE' or sessionScope.rol eq 'DIRECTOR' or sessionScope.rol eq 'EVALUADOR'}"/>
<c:set var="destino" value="/ideas/banco.jsp"/>

<c:choose>
    <%-- ===================== PROPONER ===================== --%>
    <c:when test="${param.accion eq 'proponer' and esProponente}">
        <c:set var="destino" value="/ideas/mis_propuestas.jsp"/>
        <c:choose>
            <c:when test="${fn:length(fn:trim(param.titulo)) lt 10 or fn:length(fn:trim(param.descripcion)) lt 30 or empty param.linea}">
                <c:set var="msgError" value="Complete el título (mín. 10 caracteres), la línea y la descripción (mín. 30 caracteres)." scope="session"/>
                <c:set var="destino" value="/ideas/proponer.jsp"/>
            </c:when>
            <c:otherwise>
                <sql:update dataSource="${bd}">
                    INSERT INTO idea (titulo, descripcion, linea, id_autor, estado) VALUES (?, ?, ?, ?, 'Pendiente')
                    <sql:param value="${fn:substring(fn:trim(param.titulo), 0, 150)}"/>
                    <sql:param value="${fn:substring(fn:trim(param.descripcion), 0, 2000)}"/>
                    <sql:param value="${fn:substring(param.linea, 0, 80)}"/>
                    <sql:param value="${sessionScope.idUsuario}"/>
                </sql:update>
                <c:set var="msgExito" value="Propuesta enviada exitosamente. Quedó pendiente de aprobación del comité." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:when>

    <%-- ===================== RETIRAR ===================== --%>
    <c:when test="${param.accion eq 'retirar' and esProponente}">
        <c:set var="destino" value="/ideas/mis_propuestas.jsp"/>
        <sql:update var="filas" dataSource="${bd}">
            DELETE FROM idea WHERE id_idea = ? AND id_autor = ? AND estado = 'Pendiente'
            <sql:param value="${param.id}"/>
            <sql:param value="${sessionScope.idUsuario}"/>
        </sql:update>
        <c:choose>
            <c:when test="${filas == 1}"><c:set var="msgExito" value="Propuesta retirada." scope="session"/></c:when>
            <c:otherwise><c:set var="msgError" value="Solo puede retirar sus propuestas pendientes." scope="session"/></c:otherwise>
        </c:choose>
    </c:when>

    <%-- ===================== SELECCIONAR (crea el proyecto) ===================== --%>
    <c:when test="${param.accion eq 'seleccionar' and sessionScope.rol eq 'ESTUDIANTE'}">
        <sql:query var="yaTiene" dataSource="${bd}">
            SELECT codigo FROM proyecto WHERE id_estudiante = ?
            <sql:param value="${sessionScope.idUsuario}"/>
        </sql:query>
        <c:choose>
            <c:when test="${yaTiene.rowCount > 0}">
                <c:set var="msgError" value="Ya tienes un proyecto de grado en curso (${yaTiene.rows[0].codigo})." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:catch var="ex">
                    <sql:transaction dataSource="${bd}">
                        <sql:update var="tomada">
                            UPDATE idea SET estado = 'Tomada' WHERE id_idea = ? AND estado = 'Aprobada'
                            <sql:param value="${param.id}"/>
                        </sql:update>
                        <c:if test="${tomada == 1}">
                            <sql:update>
                                INSERT INTO proyecto (id_idea, id_estudiante, fase, responsable) VALUES (?, ?, 1, 'ESTUDIANTE')
                                <sql:param value="${param.id}"/>
                                <sql:param value="${sessionScope.idUsuario}"/>
                            </sql:update>
                            <sql:update>
                                UPDATE proyecto SET codigo = CONCAT('GRA-', LPAD(id_proyecto, 5, '0')) WHERE id_estudiante = ?
                                <sql:param value="${sessionScope.idUsuario}"/>
                            </sql:update>
                            <sql:update>
                                INSERT INTO historial_fase (id_proyecto, fase_anterior, fase_nueva, id_usuario, descripcion)
                                SELECT id_proyecto, 0, 1, id_estudiante, 'Selección de idea del banco' FROM proyecto WHERE id_estudiante = ?
                                <sql:param value="${sessionScope.idUsuario}"/>
                            </sql:update>
                        </c:if>
                    </sql:transaction>
                </c:catch>
                <c:choose>
                    <c:when test="${not empty ex}">
                        <c:set var="msgError" value="No fue posible seleccionar la idea. Intente nuevamente." scope="session"/>
                    </c:when>
                    <c:when test="${tomada != 1}">
                        <c:set var="msgError" value="La idea ya no está disponible: otro estudiante la seleccionó." scope="session"/>
                    </c:when>
                    <c:otherwise>
                        <c:set var="msgExito" value="¡Idea seleccionada! Se creó tu proyecto de grado. Ahora sube el recibo de pago (Fase 1)." scope="session"/>
                        <c:set var="destino" value="/estudiante/entregas.jsp"/>
                    </c:otherwise>
                </c:choose>
            </c:otherwise>
        </c:choose>
    </c:when>

    <c:otherwise>
        <c:set var="msgError" value="Acción no permitida." scope="session"/>
    </c:otherwise>
</c:choose>
<c:redirect url="${destino}"/>
