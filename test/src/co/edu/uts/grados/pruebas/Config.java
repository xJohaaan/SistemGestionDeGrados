package co.edu.uts.grados.pruebas;

import java.nio.charset.StandardCharsets;
import java.nio.file.Files;
import java.nio.file.Path;
import java.nio.file.Paths;
import java.sql.Connection;
import java.sql.DriverManager;
import java.sql.SQLException;
import java.util.regex.Matcher;
import java.util.regex.Pattern;

/**
 * Configuración compartida por las pruebas: URL del sistema y conexión a MySQL.
 * <p>
 * Las credenciales se leen de {@code META-INF/context.xml}, el mismo archivo que usa Tomcat,
 * para no repetirlas en el código de pruebas.
 * </p>
 */
final class Config {

    /** URL base de la aplicación desplegada en el Tomcat de XAMPP. */
    static final String URL_APP = System.getProperty("app.url", "http://localhost:8080/SistemGestionDeGrados");

    /** URL JDBC de la base de datos del sistema (la misma de web.xml). */
    static final String URL_BD = "jdbc:mysql://localhost:3306/gestion_grados?useSSL=false&allowPublicKeyRetrieval=true"
            + "&serverTimezone=America/Bogota&useUnicode=true&characterEncoding=UTF-8&useOldAliasMetadataBehavior=true";

    private Config() {
    }

    /**
     * Abre una conexión a MySQL con las credenciales de {@code META-INF/context.xml}.
     *
     * @return conexión nueva
     * @throws Exception si no se puede leer el archivo o conectar
     */
    static Connection conexion() throws Exception {
        Path ctx = Paths.get(System.getProperty("app.raiz", "."), "META-INF", "context.xml");
        String xml = new String(Files.readAllBytes(ctx), StandardCharsets.UTF_8);
        return DriverManager.getConnection(URL_BD, parametro(xml, "dbUser"), parametro(xml, "dbPass"));
    }

    private static String parametro(String xml, String nombre) throws SQLException {
        Matcher m = Pattern.compile("name=\"" + nombre + "\"\\s+value=\"([^\"]*)\"").matcher(xml);
        if (!m.find()) {
            throw new SQLException("No se encontró " + nombre + " en META-INF/context.xml");
        }
        return m.group(1);
    }
}
