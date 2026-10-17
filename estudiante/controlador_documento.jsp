<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    estudiante/controlador_documento.jsp: recibe el PDF, lo guarda en /uploads y pasa el proyecto
    al siguiente responsable:
      Fase 1 (pago)          -> COORDINACION valida y asigna director/evaluador
      Fase 2 (anteproyecto)  -> DIRECTOR
      Fase 4 (informe final) -> DIRECTOR
    Validaciones: solo .pdf, máximo 20 MB (también lo limita multipart-config en web.xml).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="ESTUDIANTE"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<c:if test="${pageContext.request.method ne 'POST'}">
    <c:redirect url="/estudiante/entregas.jsp"/>
</c:if>

<%-- Si el archivo supera el límite, Tomcat lanza la excepción al leer la parte --%>
<c:catch var="exParte">
    <c:set var="archivo" value="${pageContext.request.getPart('archivo')}"/>
</c:catch>

<sql:query var="rp" dataSource="${bd}">
    SELECT id_proyecto, codigo, fase, responsable FROM proyecto WHERE id_estudiante = ?
    <sql:param value="${sessionScope.idUsuario}"/>
</sql:query>
<c:set var="p" value="${rp.rows[0]}"/>
<c:choose>
    <c:when test="${p.fase == 1}"><c:set var="tipo" value="PAGO"/><c:set var="carpeta" value="pagos"/><c:set var="siguiente" value="COORDINACION"/></c:when>
    <c:when test="${p.fase == 2}"><c:set var="tipo" value="ANTEPROYECTO"/><c:set var="carpeta" value="anteproyectos"/><c:set var="siguiente" value="DIRECTOR"/></c:when>
    <c:when test="${p.fase == 4}"><c:set var="tipo" value="INFORME_FINAL"/><c:set var="carpeta" value="informes"/><c:set var="siguiente" value="DIRECTOR"/></c:when>
</c:choose>

<c:choose>
    <c:when test="${not empty exParte}">
        <c:set var="msgError" value="El archivo supera el tamaño máximo permitido (20 MB)." scope="session"/>
    </c:when>
    <c:when test="${rp.rowCount == 0 or p.responsable ne 'ESTUDIANTE' or empty tipo}">
        <c:set var="msgError" value="No tienes entregas pendientes en este momento." scope="session"/>
    </c:when>
    <c:when test="${empty archivo or archivo.size == 0}">
        <c:set var="msgError" value="Seleccione un archivo PDF." scope="session"/>
    </c:when>
    <c:when test="${not fn:endsWith(fn:toLowerCase(archivo.submittedFileName), '.pdf')}">
        <c:set var="msgError" value="Solo se permiten archivos en formato PDF." scope="session"/>
    </c:when>
    <c:when test="${archivo.size > 20971520}">
        <c:set var="msgError" value="El archivo supera el tamaño máximo permitido (20 MB)." scope="session"/>
    </c:when>
    <c:otherwise>
        <jsp:useBean id="ahora" class="java.util.Date"/>
        <c:set var="nombreArchivo" value="${p.codigo}-${fn:toLowerCase(tipo)}-${ahora.time}.pdf"/>
        <c:set var="rutaRelativa" value="uploads/${carpeta}/${nombreArchivo}"/>
        <c:set var="rutaAbsoluta" value="${pageContext.servletContext.getRealPath('/uploads')}/${carpeta}/${nombreArchivo}"/>
        <c:catch var="exGuardar">
            ${archivo.write(rutaAbsoluta)}
            <sql:transaction dataSource="${bd}">
                <sql:update var="filas">
                    UPDATE proyecto SET responsable = ?
                    WHERE id_proyecto = ? AND fase = ? AND responsable = 'ESTUDIANTE'
                    <sql:param value="${siguiente}"/>
                    <sql:param value="${p.id_proyecto}"/>
                    <sql:param value="${p.fase}"/>
                </sql:update>
                <c:if test="${filas == 1}">
                    <sql:update>
                        INSERT INTO documento (id_proyecto, tipo, nombre_original, ruta) VALUES (?, ?, ?, ?)
                        <sql:param value="${p.id_proyecto}"/>
                        <sql:param value="${tipo}"/>
                        <sql:param value="${fn:substring(archivo.submittedFileName, 0, 200)}"/>
                        <sql:param value="${rutaRelativa}"/>
                    </sql:update>
                </c:if>
            </sql:transaction>
        </c:catch>
        <c:choose>
            <c:when test="${not empty exGuardar or filas != 1}">
                <c:set var="msgError" value="No fue posible guardar el documento. Intente nuevamente." scope="session"/>
            </c:when>
            <c:otherwise>
                <c:set var="msgExito" value="Documento enviado exitosamente. Tu proyecto quedó en revisión." scope="session"/>
            </c:otherwise>
        </c:choose>
    </c:otherwise>
</c:choose>
<c:redirect url="/estudiante/entregas.jsp"/>
