<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    logout.jsp: invalida la sesión en el servidor y vuelve al login (RF-02, RNF-16).
--%>
<%@ taglib prefix="c" uri="http://java.sun.com/jsp/jstl/core" %>
${pageContext.response.setHeader('Cache-Control', 'no-cache, no-store, must-revalidate')}
${pageContext.session.invalidate()}
<c:redirect url="/login.jsp">
    <c:param name="salida" value="1"/>
</c:redirect>
