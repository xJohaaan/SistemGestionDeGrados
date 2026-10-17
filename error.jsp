<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" isErrorPage="true" %>
<%--
    error.jsp: página para errores 404 y 500 (no muestra detalles técnicos al usuario).
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Error | Trabajos de Grado UTS</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="${ctx}/css/estilos.css" rel="stylesheet">
</head>
<body class="publico">
<div class="card tarjeta-login">
    <div class="card-body p-4 p-md-5 text-center">
        <i class="bi bi-exclamation-triangle display-4 text-warning"></i>
        <c:choose>
            <c:when test="${pageContext.errorData.statusCode == 404}">
                <h1 class="h4 fw-semibold mt-2">Página no encontrada</h1>
                <p class="text-muted">La dirección solicitada no existe.</p>
            </c:when>
            <c:otherwise>
                <h1 class="h4 fw-semibold mt-2">Ocurrió un error</h1>
                <p class="text-muted">No fue posible completar la solicitud. Intente nuevamente.</p>
            </c:otherwise>
        </c:choose>
        <a class="btn btn-uts px-4" href="${ctx}/index.jsp"><i class="bi bi-house"></i> Ir al inicio</a>
    </div>
</div>
</body>
</html>
