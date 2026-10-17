<%@ page contentType="text/html; charset=UTF-8" pageEncoding="UTF-8" %>
<%--
    coordinacion/comite.jsp: proyectos que esperan decisión del Comité de Trabajos de Grado.
      Fase 3: aprobación final de la propuesta (RF-25)
      Fase 5: aprobación del informe final y cierre (RF-28, RF-30)
    El comité no es un usuario: Coordinación registra sus decisiones con el número de acta.
--%>
<%@ include file="/WEB-INF/jspf/conexion.jspf" %>
<c:set var="rolRequerido" value="COORDINACION"/>
<%@ include file="/WEB-INF/jspf/seguridad.jspf" %>
<sql:query var="pendientes" dataSource="${bd}">
    SELECT p.id_proyecto, p.codigo, p.fase, p.responsable, i.titulo,
           CONCAT(e.nombres, ' ', e.apellidos) AS estudiante,
           CONCAT(d.nombres, ' ', d.apellidos) AS director,
           CONCAT(v.nombres, ' ', v.apellidos) AS evaluador
    FROM proyecto p
    JOIN idea i ON i.id_idea = p.id_idea
    JOIN usuario e ON e.id_usuario = p.id_estudiante
    JOIN usuario d ON d.id_usuario = p.id_director
    JOIN usuario v ON v.id_usuario = p.id_evaluador
    WHERE p.responsable = 'COMITE'
    ORDER BY p.fase DESC, p.actualizado_en
</sql:query>
<c:set var="tituloPagina" value="Comité de Trabajos de"/>
<c:set var="resalte" value="GRADO"/>
<c:set var="menu" value="comite"/>
<%@ include file="/WEB-INF/jspf/cabecera.jspf" %>

<p class="text-muted">Registre las decisiones del comité con el número de acta. En la Fase 3 se aprueba la propuesta y en la Fase 5 el informe final y el cierre del proyecto.</p>
<div class="table-responsive">
    <table class="table align-middle datatable">
        <thead><tr><th>ID</th><th>Descripción</th><th>Estudiante</th><th>Director / Evaluador</th><th>Estado</th><th class="text-end">Acciones</th></tr></thead>
        <tbody>
        <c:forEach var="p" items="${pendientes.rows}">
            <tr>
                <td class="fw-semibold"><c:out value="${p.codigo}"/></td>
                <td><c:out value="${p.titulo}"/></td>
                <td><c:out value="${p.estudiante}"/></td>
                <td class="small"><c:out value="${p.director}"/><br><span class="text-muted"><c:out value="${p.evaluador}"/></span></td>
                <td class="text-nowrap">
                    <c:set var="faseActual" value="${p.fase}"/><c:set var="resp" value="${p.responsable}"/>
                    <%@ include file="/WEB-INF/jspf/estado_proyecto.jspf" %>
                </td>
                <td class="text-end"><a class="btn btn-sm btn-uts" href="${ctx}/coordinacion/decision_comite.jsp?id=${p.id_proyecto}"><i class="bi bi-hammer"></i> Decidir</a></td>
            </tr>
        </c:forEach>
        </tbody>
    </table>
</div>

<%@ include file="/WEB-INF/jspf/pie.jspf" %>
