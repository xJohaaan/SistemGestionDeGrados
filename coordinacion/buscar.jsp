<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/buscar.jsp: búsqueda del historial y estado del proyecto de un estudiante
    por código estudiantil (RF-38) o por nombre completo (RF-39).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:set var="criterio" value="${param.criterio eq 'nombre' ? 'nombre' : 'codigo'}"/>
<c:set var="q" value="${fn:trim(param.q)}"/>
<c:set var="buscando" value="${fn:length(q) ge 3}"/>
<c:if test="${buscando}">
    <sql:query var="res" dataSource="${bd}">
        SELECT e.codigo AS codigo_estudiante, CONCAT(e.nombres, ' ', e.apellidos) AS estudiante, e.correo, e.estado AS estado_cuenta,
               p.id_proyecto, p.codigo, p.fase, p.responsable, p.radicado, i.titulo,
               CONCAT(d.nombres, ' ', d.apellidos) AS director,
               CONCAT(v.nombres, ' ', v.apellidos) AS evaluador,
               (SELECT MAX(h.fecha) FROM historial_fase h WHERE h.id_proyecto = p.id_proyecto) AS ultimo_movimiento
        FROM usuario e
        LEFT JOIN proyecto p ON p.id_estudiante = e.id_usuario
        LEFT JOIN idea i ON i.id_idea = p.id_idea
        LEFT JOIN usuario d ON d.id_usuario = p.id_director
        LEFT JOIN usuario v ON v.id_usuario = p.id_evaluador
        WHERE e.rol = 'ESTUDIANTE'
          AND ( (? = 'codigo' AND e.codigo LIKE CONCAT(?, '%'))
             OR (? = 'nombre' AND CONCAT(e.nombres, ' ', e.apellidos) LIKE CONCAT('%', ?, '%')) )
        ORDER BY e.apellidos, e.nombres
        LIMIT 50
        <sql:param value="${criterio}"/>
        <sql:param value="${q}"/>
        <sql:param value="${criterio}"/>
        <sql:param value="${q}"/>
    </sql:query>
</c:if>
<c:set var="tituloPagina" value="Buscar"/>
<c:set var="resalte" value="ESTUDIANTE"/>
<c:set var="menu" value="buscar"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<form method="GET" action="${ctx}/coordinacion/buscar.jsp" class="row g-2 align-items-end mb-4" style="max-width:820px">
    <div class="col-12 col-md-4">
        <label class="form-label" for="criterio">Buscar por</label>
        <select class="form-select" id="criterio" name="criterio">
            <option value="codigo" ${criterio eq 'codigo' ? 'selected' : ''}>Código estudiantil</option>
            <option value="nombre" ${criterio eq 'nombre' ? 'selected' : ''}>Nombre completo</option>
        </select>
    </div>
    <div class="col-12 col-md-5">
        <label class="form-label" for="q">Texto</label>
        <input type="search" class="form-control" id="q" name="q" minlength="3" maxlength="80" value="${fn:escapeXml(q)}"
               placeholder="Ej: 1095000009 o Santiago Díaz" required>
    </div>
    <div class="col-12 col-md-3">
        <button class="btn btn-uts w-100" type="submit"><i class="bi bi-search"></i> Buscar</button>
    </div>
</form>

<c:choose>
    <c:when test="${not empty param.q and not buscando}">
        <div class="alert alert-warning">Escriba al menos 3 caracteres.</div>
    </c:when>
    <c:when test="${buscando and res.rowCount == 0}">
        <div class="tarjeta-dato text-center text-muted py-4"><i class="bi bi-person-x fs-3 d-block"></i> No se encontraron estudiantes con ese <c:out value="${criterio eq 'codigo' ? 'código' : 'nombre'}"/>.</div>
    </c:when>
    <c:when test="${buscando}">
        <p class="small text-muted"><c:out value="${res.rowCount}"/> resultado(s)</p>
        <div class="row g-3">
            <c:forEach var="r" items="${res.rows}">
                <div class="col-12 col-xl-6">
                    <div class="tarjeta-dato">
                        <div class="d-flex justify-content-between flex-wrap gap-2">
                            <div>
                                <div class="fw-semibold"><c:out value="${r.estudiante}"/></div>
                                <small class="text-muted"><c:out value="${r.codigo_estudiante}"/> &middot; <c:out value="${r.correo}"/>
                                    <c:if test="${r.estado_cuenta ne 'Activo'}"> &middot; <span class="text-danger">Cuenta inactiva</span></c:if></small>
                            </div>
                            <c:if test="${not empty r.id_proyecto}">
                                <span class="text-nowrap">
                                    <c:set var="faseActual" value="${r.fase}"/><c:set var="resp" value="${r.responsable}"/>
                                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                                </span>
                            </c:if>
                        </div>
                        <hr class="my-2">
                        <c:choose>
                            <c:when test="${empty r.id_proyecto}">
                                <p class="small text-muted mb-0">Sin proyecto de grado. Aún no ha seleccionado una idea del banco.</p>
                            </c:when>
                            <c:otherwise>
                                <p class="mb-1"><span class="fw-semibold"><c:out value="${r.codigo}"/></span> &middot; <c:out value="${r.titulo}"/></p>
                                <p class="small mb-1"><span class="text-muted">Director:</span> <c:out value="${empty r.director ? 'Sin asignar' : r.director}"/>
                                    &middot; <span class="text-muted">Evaluador:</span> <c:out value="${empty r.evaluador ? 'Sin asignar' : r.evaluador}"/></p>
                                <p class="small mb-2"><span class="text-muted">Último movimiento:</span> <fmt:formatDate value="${r.ultimo_movimiento}" pattern="dd/MM/yyyy HH:mm"/>
                                    <c:if test="${not empty r.radicado}"> &middot; <span class="badge badge-fin">Radicado <c:out value="${r.radicado}"/></span></c:if></p>
                                <a class="btn btn-sm btn-outline-uts" href="${ctx}/coordinacion/proyecto.jsp?id=${r.id_proyecto}"><i class="bi bi-clock-history"></i> Ver historial completo</a>
                            </c:otherwise>
                        </c:choose>
                    </div>
                </div>
            </c:forEach>
        </div>
    </c:when>
</c:choose>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
