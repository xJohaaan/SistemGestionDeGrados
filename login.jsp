<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    login.jsp: inicio de sesión (RF-01). Se procesa a sí misma por POST.
    La contraseña se compara en MySQL con SHA-256(salt + clave).
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:if test="${not empty sessionScope.rol}">
    <c:redirect url="/${fn:toLowerCase(sessionScope.rol)}/index.jsp"/>
</c:if>

<c:if test="${pageContext.request.method eq 'POST'}">
    <c:catch var="errorBD">
        <sql:query var="r" dataSource="${bd}">
            SELECT id_usuario, codigo, nombres, apellidos, correo, rol
            FROM usuario
            WHERE correo = ? AND estado = 'Activo' AND contrasena = SHA2(CONCAT(salt, ?), 256)
            <sql:param value="${fn:toLowerCase(fn:trim(param.correo))}"/>
            <sql:param value="${param.contrasena}"/>
        </sql:query>
    </c:catch>
    <c:choose>
        <c:when test="${not empty errorBD}">
            <c:set var="error" value="No fue posible conectar con la base de datos. Revise la configuración en web.xml."/>
        </c:when>
        <c:when test="${r.rowCount == 1}">
            <%-- Nuevo identificador de sesión para evitar fijación de sesión --%>
            <c:set var="idNuevo" value="${pageContext.request.changeSessionId()}"/>
            <c:set var="usuario" value="${r.rows[0]}" scope="session"/>
            <c:set var="idUsuario" value="${r.rows[0].id_usuario}" scope="session"/>
            <c:set var="rol" value="${r.rows[0].rol}" scope="session"/>
            <c:redirect url="/${fn:toLowerCase(r.rows[0].rol)}/index.jsp"/>
        </c:when>
        <c:otherwise>
            <c:set var="error" value="Correo o contraseña incorrectos, o la cuenta está inactiva."/>
        </c:otherwise>
    </c:choose>
</c:if>
<!DOCTYPE html>
<html lang="es">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Iniciar sesión | Trabajos de Grado UTS</title>
    <link href="https://fonts.googleapis.com/css2?family=Poppins:wght@400;500;600;700&display=swap" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap@5.3.3/dist/css/bootstrap.min.css" rel="stylesheet">
    <link href="https://cdn.jsdelivr.net/npm/bootstrap-icons@1.11.3/font/bootstrap-icons.min.css" rel="stylesheet">
    <link href="${ctx}/css/estilos.css" rel="stylesheet">
</head>
<body class="publico">
<div class="card tarjeta-login">
    <div class="card-body p-4 p-md-5">
        <div class="text-center mb-4">
            <span class="marca-icono mx-auto mb-2" style="width:64px;height:64px;font-size:2rem"><i class="bi bi-mortarboard-fill"></i></span>
            <h1 class="h4 fw-semibold mb-1">Trabajos de <span class="resalte">GRADO</span></h1>
            <p class="text-muted small mb-0">Ingeniería de Sistemas &middot; UTS</p>
        </div>

        <c:if test="${param.salida eq '1'}">
            <div class="alert alert-success py-2 small"><i class="bi bi-check-circle"></i> Sesión cerrada correctamente.</div>
        </c:if>
        <c:if test="${not empty error}">
            <div class="alert alert-danger py-2 small"><i class="bi bi-exclamation-octagon"></i> <c:out value="${error}"/></div>
        </c:if>

        <form method="POST" action="${ctx}/login.jsp" class="needs-validation" novalidate>
            <div class="mb-3">
                <label for="correo" class="form-label">Correo institucional</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-envelope"></i></span>
                    <input type="email" class="form-control" id="correo" name="correo" maxlength="120"
                           value="${fn:escapeXml(param.correo)}" required autofocus>
                    <div class="invalid-feedback">Ingrese un correo válido.</div>
                </div>
            </div>
            <div class="mb-4">
                <label for="contrasena" class="form-label">Contraseña</label>
                <div class="input-group">
                    <span class="input-group-text"><i class="bi bi-lock"></i></span>
                    <input type="password" class="form-control" id="contrasena" name="contrasena" required>
                    <div class="invalid-feedback">Ingrese su contraseña.</div>
                </div>
            </div>
            <button type="submit" class="btn btn-uts w-100 py-2"><i class="bi bi-box-arrow-in-right"></i> Ingresar</button>
        </form>
        <p class="text-center mt-3 mb-0 small"><a class="text-uts" href="${ctx}/index.jsp">Volver al inicio</a></p>
    </div>
</div>
<script src="${ctx}/js/app.js"></script>
</body>
</html>
