/* Comportamiento común de los paneles: tablas, menú lateral y validaciones en el cliente. */
(function () {
    'use strict';

    // Tablas con paginación, selector de registros y búsqueda (RF-36, RF-37)
    if (window.jQuery && jQuery.fn.DataTable) {
        jQuery('table.datatable').DataTable({
            pageLength: 5,
            lengthMenu: [5, 10, 25, 50],
            order: [],
            language: {
                lengthMenu: 'Mostrar _MENU_ registros por página',
                zeroRecords: 'No se encontraron registros',
                info: 'Mostrando la página _PAGE_ de _PAGES_',
                infoEmpty: 'Sin registros',
                infoFiltered: '(filtrado de _MAX_ registros)',
                search: 'Buscar:',
                searchPlaceholder: 'Ingrese una clave',
                paginate: { first: '«', last: '»', next: '›', previous: '‹' }
            }
        });
    }

    // Abrir / cerrar el menú lateral en pantallas pequeñas
    var sidebar = document.getElementById('sidebar');
    document.querySelectorAll('[data-toggle-sidebar]').forEach(function (el) {
        el.addEventListener('click', function () { if (sidebar) sidebar.classList.toggle('abierto'); });
    });

    // Confirmación antes de acciones irreversibles: <form data-confirmar="¿Seguro?">
    document.querySelectorAll('form[data-confirmar]').forEach(function (form) {
        form.addEventListener('submit', function (e) {
            if (!confirm(form.getAttribute('data-confirmar'))) e.preventDefault();
        });
    });

    // Validación HTML5 con estilos de Bootstrap: <form class="needs-validation" novalidate>
    document.querySelectorAll('form.needs-validation').forEach(function (form) {
        form.addEventListener('submit', function (e) {
            if (!form.checkValidity()) { e.preventDefault(); e.stopPropagation(); }
            form.classList.add('was-validated');
        });
    });

    // Archivos: solo PDF y tamaño máximo (RNF-23, RNF-25): <input type="file" data-max-mb="20">
    document.querySelectorAll('input[type=file][data-max-mb]').forEach(function (input) {
        input.addEventListener('change', function () {
            var archivo = input.files[0];
            var maxMb = parseFloat(input.getAttribute('data-max-mb'));
            input.setCustomValidity('');
            if (!archivo) return;
            if (!/\.pdf$/i.test(archivo.name)) {
                input.setCustomValidity('Solo se permiten archivos PDF.');
            } else if (archivo.size > maxMb * 1024 * 1024) {
                input.setCustomValidity('El archivo supera el máximo de ' + maxMb + ' MB.');
            }
            input.reportValidity();
        });
    });
})();
