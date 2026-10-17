<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    acceso.jsp: aviso de acceso denegado cuando un usuario entra a un módulo de otro rol (RF-03).
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
<%@ taglib prefix="fn" uri="http://java.sun.com/jsp/jstl/functions" %>
<c:set var="ctx" value="${pageContext.request.contextPath}"/>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Acceso denegado | Trabajos de Grado UTS</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="${ctx}/css/estilos.css" rel="stylesheet">
</head>
<body class="publico">
<div class="card tarjeta-login">
    <div class="card-body p-4 p-md-5 text-center">
        <i class="bi bi-shield-lock display-4 text-danger"></i>
        <h1 class="h4 fw-semibold mt-2">Acceso denegado</h1>
        <p class="text-muted">No tiene permisos para ver esta sección del sistema.</p>
        <c:choose>
            <c:when test="${not empty sessionScope.rol}">
                <a class="btn btn-uts px-4" href="${ctx}/${fn:toLowerCase(sessionScope.rol)}/index.jsp"><i class="bi bi-house"></i> Ir a mi panel</a>
            </c:when>
            <c:otherwise>
                <a class="btn btn-uts px-4" href="${ctx}/login.jsp"><i class="bi bi-box-arrow-in-right"></i> Iniciar sesión</a>
            </c:otherwise>
        </c:choose>
    </div>
</div>
</body>
</html>
