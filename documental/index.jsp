<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    documental/index.jsp: base documental para todos los roles (RF-43, RF-44, RF-45).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="recursos" dataSource="${bd}">
    SELECT titulo, descripcion, url, icono FROM recurso_documental ORDER BY orden, titulo
</sql:query>
<c:set var="tituloPagina" value="Base"/>
<c:set var="resalte" value="DOCUMENTAL"/>
<c:set var="menu" value="documental"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<div class="row g-3">
    <c:forEach var="rec" items="${recursos.rows}">
        <div class="col-12 col-sm-6 col-lg-4">
            <a class="recurso" href="${fn:escapeXml(rec.url)}" target="_blank" rel="noopener">
                <i class="bi ${fn:escapeXml(rec.icono)}"></i>
                <h6><c:out value="${rec.titulo}"/></h6>
                <p><c:out value="${rec.descripcion}"/></p>
            </a>
        </div>
    </c:forEach>
    <c:if test="${recursos.rowCount == 0}">
        <p class="text-muted">Aún no hay recursos registrados.</p>
    </c:if>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
