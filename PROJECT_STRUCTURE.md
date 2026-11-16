# Estructura del proyecto

## Sugerencias para ampliar este documento

Además del árbol de archivos, conviene documentar:

1. **Flujo de datos:** cómo se pasa de los archivos GTFS a la base SQLite y de
   ahí a las páginas de rutas y horarios.
2. **Puesta en marcha y operaciones:** requisitos, comandos de instalación,
   arranque, pruebas, actualización del feed y configuración de producción.
3. **Modelo de datos y decisiones:** entidades, relaciones y convenciones del
   feed que afectan al parser (por ejemplo, identificadores numéricos y horas
   posteriores a medianoche).
4. **Límites del inventario:** distinguir fuentes versionadas de dependencias,
   compilados y otros artefactos locales para que el árbol no atribuya código
   generado en cada máquina al proyecto.

Esta versión incluye un resumen del flujo, comandos esenciales y límites del
inventario. El [README.md](README.md) ya contiene información operativa y del
modelo de datos, por lo que este documento la resume y enlaza sin duplicarla
por completo.

## Cómo interpretar las etiquetas

La comparación se hizo contra el commit inicial `0fe8ab3` (`base phoenix
structure`) y el historial disponible en este repositorio:

- **[Phoenix]**: archivo incluido en el esqueleto inicial y sin cambios
  posteriores relevantes para la aplicación.
- **[Phoenix modificado]**: partía del esqueleto inicial, pero el historial
  muestra cambios para integrar o adaptar esta aplicación.
- **[Proyecto]**: añadido después del esqueleto inicial para los datos,
  funcionalidades o pruebas de BusInfoGtfs.
- **[Instrucciones]**: documentación de trabajo del repositorio; no es parte
  funcional que Phoenix genere para la aplicación.

Estas etiquetas describen la historia del archivo, no demuestran quién lo
escribió personalmente. En particular, los archivos de datos pueden proceder
de un feed externo aunque estén versionados aquí.

## Árbol de directorios y archivos

El árbol enumera los archivos versionados. Cada archivo incluye su procedencia
y una descripción funcional; también incluye este documento, recién añadido.

```text
bus_info_gtfs/
├── .formatter.exs                         [Phoenix] Configuración del formateador de Elixir.
├── .gitignore                             [Phoenix] Excluye compilados, dependencias, bases y archivos temporales.
├── AGENTS.md                              [Instrucciones] Reglas de trabajo para cambios en este repositorio.
├── PROJECT_STRUCTURE.md                   [Proyecto] Inventario, procedencia de archivos y guía rápida de arquitectura.
├── README.md                              [Phoenix modificado] Presenta la aplicación, su instalación, datos GTFS, pruebas y despliegue.
├── mix.exs                                [Phoenix modificado] Configura la aplicación Mix, dependencias, compiladores y alias.
├── mix.lock                               [Phoenix modificado] Fija las versiones resueltas de las dependencias.
├── assets/
│   ├── tsconfig.json                      [Phoenix] Configura IntelliSense de JavaScript/LiveView para el editor.
│   ├── css/
│   │   └── app.css                        [Phoenix] Entrada CSS de Tailwind, plugins y estilos del frontend.
│   ├── js/
│   │   └── app.js                         [Phoenix] Inicializa Phoenix HTML, LiveView, hooks y barra de navegación.
│   └── vendor/
│       ├── heroicons.js                   [Phoenix] Plugin Tailwind para generar clases de iconos Heroicons.
│       └── topbar.js                      [Phoenix] Código cliente de la barra de progreso de navegación.
├── config/
│   ├── config.exs                         [Phoenix modificado] Configuración común, Repo, endpoint, assets y directorio GTFS.
│   ├── dev.exs                            [Phoenix modificado] Configuración de desarrollo, SQLite, recarga y dashboard.
│   ├── prod.exs                           [Phoenix] Valores y ajustes propios del entorno de producción.
│   ├── runtime.exs                        [Phoenix] Configuración de despliegue leída al iniciar, incluidas variables de entorno.
│   └── test.exs                           [Phoenix modificado] Configura SQLite sandbox y fixtures GTFS para pruebas.
├── GTFS/
│   ├── routes.txt                         [Proyecto] Feed de rutas incluido como fuente de datos.
│   ├── shapes.txt                         [Proyecto] Feed de puntos geográficos de las formas de ruta.
│   ├── stop_times.txt                     [Proyecto] Feed de horarios y secuencia de paradas por viaje.
│   ├── stops.txt                          [Proyecto] Feed de paradas y sus coordenadas.
│   └── trips.txt                          [Proyecto] Feed de viajes, rutas, formas y direcciones.
├── lib/
│   ├── bus_info_gtfs.ex                   [Phoenix] Módulo raíz del dominio de la aplicación.
│   ├── bus_info_gtfs_web.ex                [Phoenix] Macros y funciones compartidas para módulos web Phoenix.
│   ├── bus_info_gtfs/
│   │   ├── application.ex                 [Phoenix modificado] Árbol de supervisión OTP, Repo, migraciones, bootstrap y endpoint.
│   │   ├── bootstrap.ex                   [Proyecto] Ingesta opcional del feed al arrancar si la base no tiene rutas.
│   │   ├── catalog.ex                     [Proyecto] API de lectura que conecta la capa web con los casos de uso.
│   │   ├── ingest.ex                      [Proyecto] Coordina el parseo GTFS y la sustitución del conjunto de datos.
│   │   ├── mailer.ex                      [Phoenix] Módulo de correo Swoosh del proyecto.
│   │   ├── parser.ex                      [Proyecto] Lee archivos GTFS, valida/castea filas y construye modelos.
│   │   ├── repo.ex                        [Phoenix] Repo de Ecto asociado a SQLite.
│   │   ├── gtfs/
│   │   │   ├── route.ex                   [Proyecto] Esquema Ecto y modelo de una ruta GTFS.
│   │   │   ├── shape.ex                   [Proyecto] Esquema de una forma y asociación con sus puntos.
│   │   │   ├── shape_point.ex             [Proyecto] Esquema de un punto geográfico ordenado de una forma.
│   │   │   ├── stop.ex                    [Proyecto] Esquema Ecto de una parada y sus coordenadas.
│   │   │   ├── stop_schedule.ex           [Proyecto] Modelo de lectura que agrupa horarios por parada.
│   │   │   ├── stop_time.ex               [Proyecto] Esquema de visita/horario; almacena la hora en segundos.
│   │   │   ├── stop_visit.ex              [Proyecto] Modelo de lectura que une una parada con una visita concreta.
│   │   │   └── trip.ex                    [Proyecto] Esquema Ecto de un viaje, su ruta, forma y frecuencia.
│   │   ├── services/
│   │   │   └── explore_route.ex           [Proyecto] Casos de uso para rutas, viajes y horarios agrupados por día/dirección.
│   │   └── storage/
│   │       └── ecto.ex                    [Proyecto] Implementación SQLite/Ecto del contrato de persistencia.
│   ├── bus_info_gtfs_web/
│   │   ├── endpoint.ex                    [Phoenix] Endpoint HTTP, sockets LiveView y cadena de plugs.
│   │   ├── gettext.ex                     [Phoenix] Configuración de traducciones Gettext.
│   │   ├── router.ex                      [Phoenix modificado] Rutas web: inicio, detalle LiveView y herramientas de desarrollo.
│   │   ├── telemetry.ex                   [Phoenix] Supervisor y métricas de Phoenix, VM y Repo.
│   │   ├── components/
│   │   │   ├── core_components.ex         [Phoenix] Componentes HTML comunes, formularios, iconos y mensajes flash.
│   │   │   ├── layouts.ex                 [Phoenix modificado] Layout, mensajes flash y cabecera de la aplicación.
│   │   │   └── layouts/
│   │   │       └── root.html.heex         [Phoenix modificado] Documento HTML raíz y carga de estilos/scripts.
│   │   ├── controllers/
│   │   │   ├── error_html.ex              [Phoenix] Respuestas predeterminadas para errores HTML.
│   │   │   ├── error_json.ex              [Phoenix] Respuestas predeterminadas para errores JSON.
│   │   │   ├── page_controller.ex         [Phoenix modificado] Controlador de la página principal y listado de rutas.
│   │   │   ├── page_html.ex               [Phoenix] Módulo que incorpora las plantillas HTML de página.
│   │   │   └── page_html/
│   │   │       └── home.html.heex         [Phoenix modificado] Interfaz de inicio con enlaces a las rutas disponibles.
│   │   └── live/
│   │       └── route_live.ex              [Proyecto] Pantalla LiveView con paradas, días y horarios de una ruta.
│   └── mix/
│       └── tasks/
│           └── gtfs.ingest.ex             [Proyecto] Tarea `mix gtfs.ingest` para importar o reemplazar un feed.
├── priv/
│   ├── gettext/
│   │   ├── errors.pot                     [Phoenix] Plantilla de mensajes traducibles extraídos.
│   │   └── en/
│   │       └── LC_MESSAGES/
│   │           └── errors.po              [Phoenix] Catálogo inglés de mensajes de errores.
│   ├── repo/
│   │   ├── seeds.exs                      [Phoenix modificado] Carga inicial del feed configurado en la base.
│   │   └── migrations/
│   │       ├── .formatter.exs             [Phoenix] Formato específico para migraciones.
│   │       └── 20261116084948_create_gtfs_tables.exs [Proyecto] Crea tablas, claves, restricciones e índices GTFS.
│   └── static/
│       ├── favicon.ico                    [Phoenix] Icono del sitio.
│       ├── robots.txt                     [Phoenix] Directivas para rastreadores web.
│       └── images/
│           └── logo.svg                   [Phoenix] Imagen SVG estática del sitio.
└── test/
    ├── test_helper.exs                    [Phoenix] Arranca ExUnit y configura el SQL Sandbox manual.
    ├── bus_info_gtfs/
    │   ├── ingest_test.exs                [Proyecto] Comprueba la coordinación de parseo e ingesta.
    │   ├── parser_test.exs                [Proyecto] Comprueba formatos, casting, filas inválidas y horarios GTFS.
    │   ├── services/
    │   │   └── explore_route_test.exs     [Proyecto] Comprueba selección y orden de paradas y horarios.
    │   └── storage/
    │       └── ecto_test.exs              [Proyecto] Comprueba persistencia, reemplazo y consultas SQLite.
    ├── bus_info_gtfs_web/
    │   ├── controllers/
    │   │   ├── error_html_test.exs        [Phoenix] Comprueba respuestas de error HTML.
    │   │   ├── error_json_test.exs        [Phoenix] Comprueba respuestas de error JSON.
    │   │   └── page_controller_test.exs   [Phoenix modificado] Comprueba la página principal y las rutas mostradas.
    │   └── live/
    │       └── route_live_test.exs        [Proyecto] Comprueba la pantalla de ruta y sus horarios interactivos.
    ├── fixtures/
    │   ├── gtfs/
    │   │   ├── notes.txt                 [Proyecto] Notas sobre las fixtures del parser.
    │   │   ├── routes.txt                [Proyecto] Fixture de rutas para pruebas del parser.
    │   │   ├── shapes.txt                [Proyecto] Fixture de formas para pruebas del parser.
    │   │   ├── stop_times.txt            [Proyecto] Fixture de horarios, incluidas horas posteriores a 24:00.
    │   │   ├── stops.txt                 [Proyecto] Fixture de paradas para pruebas del parser.
    │   │   └── trips.txt                 [Proyecto] Fixture de viajes para pruebas del parser.
    │   ├── gtfs_domain/
    │   │   ├── routes.txt                [Proyecto] Rutas de prueba para casos de uso del dominio.
    │   │   ├── shapes.txt                [Proyecto] Formas de prueba para casos de uso del dominio.
    │   │   ├── stop_times.txt            [Proyecto] Horarios de prueba para casos de uso del dominio.
    │   │   ├── stops.txt                 [Proyecto] Paradas de prueba para casos de uso del dominio.
    │   │   └── trips.txt                 [Proyecto] Viajes de prueba para casos de uso del dominio.
    │   └── gtfs_web/
    │       ├── routes.txt                [Proyecto] Rutas para pruebas de la interfaz web.
    │       ├── shapes.txt                [Proyecto] Formas para pruebas de la interfaz web.
    │       ├── stop_times.txt            [Proyecto] Horarios para pruebas de la interfaz web.
    │       ├── stops.txt                 [Proyecto] Paradas para pruebas de la interfaz web.
    │       └── trips.txt                 [Proyecto] Viajes para pruebas de la interfaz web.
    └── support/
        ├── conn_case.ex                   [Phoenix] Configuración común de pruebas que usan conexiones HTTP.
        ├── data_case.ex                   [Phoenix] Configuración común de pruebas Ecto y sandbox.
        ├── fake_storage.ex                [Proyecto] Almacenamiento en memoria usado por las pruebas del dominio.
        └── test_support.ex                [Proyecto] Ayudantes para cargar fixtures y consultar la base en pruebas.
```

## Flujo funcional

1. `GTFS/` aporta las tablas de rutas, viajes, formas, paradas y horarios.
2. `BusInfoGtfs.Parser` (`lib/bus_info_gtfs/parser.ex`) valida las columnas y
   convierte las filas a modelos GTFS; `BusInfoGtfs.Ingest` coordina esa
   conversión con el almacenamiento.
3. `BusInfoGtfs.Storage.Ecto` reemplaza los datos en SQLite dentro de una
   transacción. La importación se puede lanzar con `mix gtfs.ingest`, durante
   `mix setup`, o mediante el bootstrap opcional.
4. `BusInfoGtfs.Catalog` y `BusInfoGtfs.Services.ExploreRoute` consultan los
   datos a través del contrato `BusInfoGtfs.Storage`.
5. El controlador muestra las rutas en `/`; `BusInfoGtfsWeb.RouteLive` presenta
   las paradas y los horarios por día en `/routes/:route_id`.

## Comandos principales

```sh
mix setup
mix phx.server
mix gtfs.ingest
mix test
mix precommit
```

Para más detalle sobre requisitos, configuración de producción, carga de otro
feed y decisiones del modelo, consultar [README.md](README.md).

## Archivos no incluidos en el árbol

El árbol describe lo versionado, no todo lo que puede aparecer en una copia de
trabajo. Se omiten dependencias descargadas (`deps/`), compilados (`_build/`),
bases SQLite y archivos auxiliares locales (ignorados por Git), y recursos
compilados bajo `priv/static/assets/`. Estos últimos se producen a partir de
`assets/` durante la compilación de frontend.
