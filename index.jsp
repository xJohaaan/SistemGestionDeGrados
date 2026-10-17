<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    index.jsp: página de bienvenida. Si ya hay sesión, envía al panel del rol.
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<c:if test="${not empty sessionScope.rol}">
    <c:redirect url="/${fn:toLowerCase(sessionScope.rol)}/index.jsp"/>
</c:if>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Trabajos de Grado | UTS</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="${ctx}/css/estilos.css" rel="stylesheet">
</head>
<body class="publico">
<div class="card tarjeta-landing">
    <div class="card-body p-4 p-md-5">
        <div class="d-flex flex-wrap align-items-center justify-content-between gap-3 mb-4">
            <div class="d-flex align-items-center gap-3">
                <span class="marca-icono" style="width:56px;height:56px;font-size:1.7rem"><i class="bi bi-mortarboard-fill"></i></span>
                <div>
                    <h1 class="h3 fw-semibold mb-0">SISTEMA - TRABAJOS DE <span class="resalte">GRADO</span></h1>
                    <span class="text-muted small">Universidad Tecnológica de Santander &middot; Ingeniería de Sistemas</span>
                </div>
            </div>
            <a href="${ctx}/login.jsp" class="btn btn-uts px-4"><i class="bi bi-box-arrow-in-right"></i> Ingresar</a>
        </div>
        <p class="text-muted">Bienvenido a la plataforma para la gestión y seguimiento de los trabajos de grado:
            desde la selección de la idea en el banco hasta el cierre y radicado del proyecto.</p>
        <div class="row g-3 mt-2">
            <div class="col-12 col-sm-6 col-lg-3">
                <div class="recurso"><i class="bi bi-lightbulb"></i><h6>Banco de ideas</h6><p>Consulta y propone ideas de proyecto aprobadas por el comité.</p></div>
            </div>
            <div class="col-12 col-sm-6 col-lg-3">
                <div class="recurso"><i class="bi bi-diagram-3"></i><h6>Seguimiento por fases</h6><p>Pago, anteproyecto, evaluación, informe final y cierre.</p></div>
            </div>
            <div class="col-12 col-sm-6 col-lg-3">
                <div class="recurso"><i class="bi bi-people"></i><h6>Director y evaluador</h6><p>Calificaciones y observaciones en un solo lugar.</p></div>
            </div>
            <div class="col-12 col-sm-6 col-lg-3">
                <div class="recurso"><i class="bi bi-cloud-arrow-down"></i><h6>Base documental</h6><p>Calendario académico, formatos y reglamentos.</p></div>
            </div>
        </div>
    </div>
</div>
</body>
</html>
