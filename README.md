# StockFlow

Plataforma B2B de gestión de pedidos e inventario, en desarrollo con Java y Spring Boot; frontend React previsto en la ruta del proyecto.

## Estado de esta guía

Guía de desarrollo local para Windows y PowerShell, revisada el 01/11/2026 contra los archivos actuales.

- PostgreSQL por Docker Compose: configuración, healthcheck y conexión SQL verificados durante B1.
- Backend en Windows: conexión PostgreSQL, arranque JPA/Tomcat y health UP aceptados el 01/11/2026 con logs y resultado entregados por Franco desde IntelliJ. B2.1 aceptada, con ejemplo de variables de Spring inspeccionado y coherente con Compose. La alternativa por wrapper está documentada, todavía sin ejecución comprobada en esta entrega.
- Todavía no hay frontend, migraciones Liquibase ni prueba de integración con base descartable implementados como entregas aceptadas.

## Requisitos

- JDK 21 completo: tanto java como javac deben resolver al JDK elegido.
- Docker Desktop iniciado y usando contenedores Linux, con Docker Compose disponible.
- Acceso a Internet para descargar la imagen o dependencias cuando no estén en la máquina.
- IntelliJ IDEA para la opción de ejecución desde el IDE. La alternativa por terminal usa el wrapper incluido; no requiere Maven global.

En una terminal nueva, comprobar:

    java -version
    javac -version
    docker version
    docker compose version

Java y javac deben informar 21; docker version debe poder comunicarse con el servidor. Para comprobar las rutas de Java en PowerShell:

    Get-Command java,javac | Select-Object Name,Source

Una terminal nueva no conserva las variables que sólo se hayan configurado en una sesión anterior. El JDK de IntelliJ y el de la terminal se seleccionan por separado.

## Preparación inicial: una sola vez por clon

Abrir PowerShell en la raíz del repositorio: la carpeta que contiene compose.yaml y backend/.

Si aún no existe .env, crear la copia local del ejemplo:

    Copy-Item .env.example .env

Editar .env y reemplazar la contraseña de ejemplo por una contraseña local privada. Si ya tenés .env, conservá ese archivo; no lo sobrescribas al retomar.

| Variable para Compose | Uso |
| --- | --- |
| POSTGRES_PASSWORD | Contraseña privada del usuario stockflow |
| POSTGRES_HOST_IP | Dirección de publicación local; usar 127.0.0.1 |
| POSTGRES_HOST_PORT | Puerto publicado en Windows; valor inicial 5433 |

El servicio usa base stockflow, usuario stockflow e imagen postgres:17.11-bookworm. Dentro del contenedor PostgreSQL escucha en 5432; Windows accede por el puerto publicado. El volumen postgres_data está montado en /var/lib/postgresql/data.

.env está ignorado por Git. .env.example documenta nombres y valores de ejemplo, sin credenciales reales. Si ya existe un volumen inicializado, editar POSTGRES_PASSWORD no cambia automáticamente la contraseña guardada en PostgreSQL: seguí usando las credenciales con las que se inicializó ese volumen hasta realizar un cambio explícito de contraseña.

[Interpolación y archivos de entorno de Compose](https://docs.docker.com/compose/how-tos/environment-variables/variable-interpolation/), [imagen oficial de PostgreSQL](https://hub.docker.com/_/postgres/).

## Arranque diario: PostgreSQL

1. Abrir Docker Desktop y esperar a que el motor esté disponible.
2. Abrir PowerShell en la raíz del repositorio.
3. Validar la configuración sin imprimir credenciales y levantar el servicio:

       docker compose config --quiet
       docker compose up -d --wait --wait-timeout 60 postgres
       docker compose ps

El resultado esperado es postgres con estado healthy. El comando up sirve tanto para la primera creación como para retomar un servicio detenido; no hace falta recrear todo manualmente cada día.

Si falla el arranque, revisar:

    docker compose logs --tail 80 postgres

Un timeout o un estado unhealthy requiere diagnóstico antes de iniciar el backend. El healthcheck comprueba disponibilidad de PostgreSQL; no demuestra por sí solo autenticación SQL ni migraciones.

[Comando compose up](https://docs.docker.com/reference/cli/docker/compose/up/).

## Preparar la ejecución del backend

El backend se ejecuta en Windows, fuera del contenedor de PostgreSQL. Necesita estas variables en el proceso que inicia Java:

| Variable de Spring | Valor esperado en el entorno local |
| --- | --- |
| SPRING_DATASOURCE_URL | URL JDBC de PostgreSQL hacia 127.0.0.1, puerto publicado 5433 y base stockflow |
| SPRING_DATASOURCE_USERNAME | stockflow |
| SPRING_DATASOURCE_PASSWORD | La contraseña privada del usuario de PostgreSQL |

Formato de la URL: jdbc:postgresql://host:port/database. Si cambiaste POSTGRES_HOST_PORT, ajustar también el puerto de la URL JDBC.

Compose lee .env para su propia interpolación. Eso no carga automáticamente esas variables en Spring ni convierte POSTGRES_PASSWORD en SPRING_DATASOURCE_PASSWORD. Configurá las variables de Spring en el entorno que realmente ejecute el backend.

[Configuración externa de Spring Boot](https://docs.spring.io/spring-boot/reference/features/external-config.html), [formato de URL JDBC de PostgreSQL](https://jdbc.postgresql.org/documentation/use/).

### Opción A: IntelliJ IDEA

1. Vincular backend/pom.xml como proyecto Maven y sincronizarlo. El POM está dentro de backend/, no en la raíz.
2. Seleccionar JDK 21 para el proyecto y la ejecución.
3. En Run > Edit Configurations, seleccionar la ejecución de StockflowApplication.
4. Si hace falta, habilitar Modify options > Use classpath of module y elegir el módulo importado desde backend/pom.xml. La clase principal es io.github.francolumovich.stockflow.StockflowApplication y debe quedar reconocida sin error rojo.
5. Habilitar Modify options > Environment variables y cargar las tres variables de Spring de la tabla anterior. No van en Active profiles. Mantener la configuración que contiene la contraseña como configuración local del IDE, sin versionarla.
6. Con PostgreSQL healthy, ejecutar la aplicación.

Las variables guardadas en esta configuración no se trasladan automáticamente a una terminal independiente.

[Configuración de ejecución Spring Boot en IntelliJ](https://www.jetbrains.com/help/idea/run-debug-configuration-spring-boot.html).

### Opción B: PowerShell y Maven Wrapper

Desde la raíz, entrar al backend:

    Set-Location backend
    .\mvnw.cmd --version

El wrapper debe informar Java 21. Proveer las tres variables de Spring en esa misma sesión de PowerShell antes de ejecutar Java. Para definir una variable de entorno de sesión se usa el proveedor $env: de PowerShell; consultar la documentación enlazada. No alcanza con que las variables existan en la configuración de IntelliJ.

Luego ejecutar:

    .\mvnw.cmd spring-boot:run

La aplicación queda ejecutándose en esa terminal. Para volver a los comandos de Compose desde allí, regresar a la raíz con Set-Location .. o abrir otra terminal en la raíz.

[Maven y Spring Boot](https://docs.spring.io/spring-boot/maven-plugin/run.html), [variables de entorno en PowerShell](https://learn.microsoft.com/en-us/powershell/module/microsoft.powershell.core/about/about_environment_variables).

## Comprobar que está funcionando

- PostgreSQL: docker compose ps desde la raíz debe mostrar healthy.
- Backend: el log debe mostrar arranque satisfactorio y una conexión PostgreSQL agregada por Hikari. El inicio del pool por sí solo no alcanza si después falla la conexión o el contexto.
- Desde otra terminal consultar:

      Invoke-RestMethod -Uri 'http://localhost:8080/actuator/health'

Se espera HTTP 200 y status UP. Compartir para revisión sólo el resultado y los logs pertinentes, sin contraseñas.

Para comprobar la base de forma independiente, el cliente SQL en Windows debe conectarse a 127.0.0.1, puerto publicado 5433, base stockflow, usuario stockflow y la contraseña local. La consulta de contexto debe confirmar la versión de PostgreSQL, la base y el usuario esperados.

Una compilación exitosa no demuestra conexión a PostgreSQL. Tampoco health UP sustituye las futuras pruebas de migraciones e integración de SF-001.

## Detener al terminar

- Backend: botón Stop de IntelliJ o Ctrl+C en la terminal que ejecuta spring-boot:run.
- PostgreSQL, desde la raíz:

      docker compose stop postgres

Esto permite retomar luego con el comando up y conserva el volumen. Retomar el desarrollo no requiere borrar el volumen ni reinicializar la base.

## Cierre de B2.1 y siguientes entregas

B2.1 aceptada el 01/11/2026: el driver PostgreSQL usa runtime y versión administrada por Spring Boot; application.yaml contiene spring.jpa.hibernate.ddl-auto en validate. Evidencia de cierre:

- .env.example documenta los tres nombres de Spring, con URL local correcta, usuario stockflow y contraseñas de ejemplo sin el secreto privado local.
- La ejecución desde IntelliJ ya tiene evidencia aceptada de conexión, arranque y health UP. Esto no sustituye las futuras pruebas automatizadas de integración.

La implementación y las correcciones las realizó Franco; el mentor inspeccionó archivos y evaluó la evidencia aportada. Liquibase, sus cambios de esquema y la prueba con PostgreSQL descartable corresponden a las entregas posteriores de SF-001; todavía no hay un comando de test de integración aceptado para documentar.
