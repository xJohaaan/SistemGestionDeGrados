<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    estudiante/index.jsp: seguimiento del proyecto con tarjetas por fase (RF-35),
    datos del director y evaluador (RF-32, RF-33) y última observación recibida.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="rp" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, p.fase, p.responsable, p.radicado, i.titulo, i.descripcion,
           CONCAT(d.nombres, ' ', d.apellidos) AS director, d.correo AS correo_director,
           CONCAT(v.nombres, ' ', v.apellidos) AS evaluador, v.correo AS correo_evaluador
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    LEFT JOIN usuario d ON d.id_usuario = p.id_director
    LEFT JOIN usuario v ON v.id_usuario = p.id_evaluador
    WHERE p.id_estudiante = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="tituloPagina" value="Seguimiento del"/>
<c:set var="resalte" value="PROYECTO"/>
<c:set var="menu" value="inicio"/>

<c:if test="${rp.rowCount == 1}">
    <c:set var="p" value="${rp.rows[0]}"/>
    <sql:query var="fases" dataSource="${bd}">
        SELECT id_fase, nombre, descripcion, icono FROM fase ORDER BY id_fase
    </sql:query>
    <sql:query var="ultima" dataSource="${bd}">
        SELECT e.rol_evaluador, e.fase, e.nota, e.observaciones, e.decision, e.fecha
        FROM evaluacion e WHERE e.id_proyecto = ? ORDER BY e.fecha DESC, e.id_evaluacion DESC LIMIT 1
        <sql:param value="${p.id_proyecto}"/>
    </sql:query>
</c:if>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<c:choose>
    <c:when test="${rp.rowCount == 0}">
        <div class="text-center py-5">
            <i class="bi bi-lightbulb display-4 text-uts"></i>
            <h5 class="mt-3">Aún no tienes un proyecto de grado</h5>
            <p class="text-muted">Consulta el banco de ideas y selecciona una idea aprobada para iniciar tu proceso.</p>
        </div>
    </c:when>
    <c:otherwise>
        <p class="text-muted mb-1">Aquí podrás llevar el seguimiento del proyecto de grado en curso.</p>
        <p class="mb-4"><span class="fw-semibold"><c:out value="${p.codigo}"/></span> &middot; <c:out value="${p.titulo}"/>
            <c:if test="${not empty p.radicado}"> &middot; <span class="badge badge-fin">Radicado <c:out value="${p.radicado}"/></span></c:if>
        </p>

        <div class="row g-3 mb-4">
            <c:forEach var="f" items="${fases.rows}">
                <c:choose>
                    <c:when test="${f.id_fase lt p.fase or p.responsable eq 'FINALIZADO'}"><c:set var="claseFase" value="completada"/></c:when>
                    <c:when test="${f.id_fase == p.fase}"><c:set var="claseFase" value="actual"/></c:when>
                    <c:otherwise><c:set var="claseFase" value="pendiente"/></c:otherwise>
                </c:choose>
                <div class="col-6 col-md-4 col-xl-2">
                    <div class="fase-card ${claseFase}">
                        <div class="fase-icono">
                            <c:choose>
                                <c:when test="${claseFase eq 'completada'}"><i class="bi bi-check-circle"></i></c:when>
                                <c:when test="${claseFase eq 'actual'}"><i class="bi bi-hourglass-split"></i></c:when>
                                <c:otherwise><i class="bi ${f.icono}"></i></c:otherwise>
                            </c:choose>
                        </div>
                        <h6>Fase <c:out value="${f.id_fase}"/>: <c:out value="${f.nombre}"/></h6>
                        <p><c:out value="${f.descripcion}"/></p>
                    </div>
                </div>
            </c:forEach>
        </div>

        <div class="row g-3">
            <div class="col-12 col-md-4">
                <div class="tarjeta-dato">
                    <div class="etiqueta mb-1">Estado actual</div>
                    <c:set var="faseActual" value="${p.fase}"/><c:set var="resp" value="${p.responsable}"/>
                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                    <p class="small text-muted mt-2 mb-0">
                        <c:choose>
                            <c:when test="${p.responsable eq 'ESTUDIANTE'}">Tienes una entrega pendiente. <a class="text-uts" href="${ctx}/estudiante/entregas.jsp">Ir a entregas</a></c:when>
                            <c:when test="${p.responsable eq 'FINALIZADO'}">Tu proyecto fue cerrado. ¡Felicitaciones!</c:when>
                            <c:otherwise>Tu proyecto está en revisión.</c:otherwise>
                        </c:choose>
                    </p>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="tarjeta-dato">
                    <div class="etiqueta mb-1"><i class="bi bi-person-workspace"></i> Docente director</div>
                    <c:choose>
                        <c:when test="${empty p.director}"><span class="text-muted">Pendiente de asignación</span></c:when>
                        <c:otherwise><div class="fw-semibold"><c:out value="${p.director}"/></div><small class="text-muted"><c:out value="${p.correo_director}"/></small></c:otherwise>
                    </c:choose>
                </div>
            </div>
            <div class="col-12 col-md-4">
                <div class="tarjeta-dato">
                    <div class="etiqueta mb-1"><i class="bi bi-clipboard-check"></i> Docente evaluador</div>
                    <c:choose>
                        <c:when test="${empty p.evaluador}"><span class="text-muted">Pendiente de asignación</span></c:when>
                        <c:otherwise><div class="fw-semibold"><c:out value="${p.evaluador}"/></div><small class="text-muted"><c:out value="${p.correo_evaluador}"/></small></c:otherwise>
                    </c:choose>
                </div>
            </div>
            <c:if test="${ultima.rowCount == 1}">
                <c:set var="ev" value="${ultima.rows[0]}"/>
                <div class="col-12">
                    <div class="tarjeta-dato">
                        <div class="etiqueta mb-1">Última observación
                            (<c:out value="${fn:toLowerCase(ev.rol_evaluador)}"/>, fase <c:out value="${ev.fase}"/>,
                            <fmt:formatDate value="${ev.fecha}" pattern="dd/MM/yyyy HH:mm"/>)</div>
                        <span class="badge ${ev.decision eq 'APROBADO' ? 'badge-fin' : 'text-bg-danger'}"><c:out value="${ev.decision}"/></span>
                        <c:if test="${not empty ev.nota}"><span class="badge badge-fase">Nota <c:out value="${ev.nota}"/></span></c:if>
                        <p class="mt-2 mb-0"><c:out value="${ev.observaciones}"/></p>
                    </div>
                </div>
            </c:if>
        </div>
    </c:otherwise>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
