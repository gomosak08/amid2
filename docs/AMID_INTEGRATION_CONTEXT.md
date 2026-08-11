# AMID Integration Context

Analisis basado en el codigo actual del repositorio `/home/gomosak/platzi/platzi/amid2`.

Este documento no asume endpoints inexistentes como disponibles. Separa:

- API disponible actualmente: rutas/controladores verificados en el codigo.
- API requerida por la arquitectura objetivo: endpoints que Historial Clinico necesita y que deben diseniarse contract-first.

AMID debe ser fuente de verdad para agenda, doctores, paquetes, disponibilidad, bloqueos, calendarios y citas. Historial Clinico debe ser fuente de verdad para expedientes, triage, consultas, diagnosticos, recetas y documentos clinicos.

## 1. Arquitectura General

AMID es una aplicacion Ruby on Rails 7.2 (`Gemfile`, `config/application.rb`) con SQLite como base de datos (`config/database.yml`). En desarrollo usa `storage/development.sqlite3` y una base separada de Solid Queue en `storage/development_queue.sqlite3`; produccion tambien esta configurada con adaptador SQLite, aunque los nombres parecen de entorno productivo (`amid2_production`, `amid2_production_queue`).

La autenticacion de usuarios usa Devise en `User` con `database_authenticatable`, `registerable`, `recoverable`, `rememberable` y `validatable`. Las rutas Devise estan montadas con `devise_for :users, skip: :registrations`; aunque el modelo incluye `registerable`, las rutas publicas de registro estan omitidas.

Roles actuales:

- `admin`
- `assistant`
- `doctor`

La autorizacion esta implementada directamente en controladores, no mediante Pundit/CanCan. Ejemplos:

- `Admin::AppointmentsController#require_admin_or_assistant_or_doctor`.
- `Admin::DoctorsController#require_admin_or_self_doctor`.
- `Admin::UsersController#require_super_admin`.
- `Admin::PackagesController#require_admin`.

Namespaces principales:

- Publico: `AppointmentsController`, `PackagesController`, `ServicesController`, `SurgeriesController`, `HomeController`, `StaticController`.
- Admin: `Admin::AppointmentsController`, `Admin::DoctorsController`, `Admin::PackagesController`, `Admin::UsersController`, `Admin::PhoneBansController`, `Admin::SpecialtiesController`, `Admin::StatisticsController`.
- Webhooks: `WebhooksController` para WhatsApp.

Servicios relevantes:

- `User::Appointments::Create`
- `Admin::Appointments::Create`
- `User::Appointments::Update`
- `User::Appointments::Cancel`
- `User::Availability::FetchTimes`
- `User::Availability::SlotFree`
- `User::Forms::AppointmentFormContext`
- `Admin::Forms::AppointmentAdminFormContext`
- `User::GoogleCalendar::Client`
- `User::GoogleCalendar::Events::Create`
- `User::GoogleCalendar::Events::Delete`
- `WhatsappNotificationService`
- `User::Security::RecaptchaVerify`

Jobs:

- `SendWhatsappMessageJob`

Frontend:

- Hotwire/Turbo, Stimulus, importmaps/jsbundling y Tailwind.
- FullCalendar esta presente en `vendor/javascript/@fullcalendar--*.js`.
- El calendario medico usa `app/javascript/controllers/doctor_calendar_controller.js`.

Integraciones:

- Google Calendar via `google-api-client`, `googleauth`, `omniauth-google-oauth2` y servicios bajo `app/services/user/google_calendar`.
- WhatsApp Cloud API via `WhatsappNotificationService` y `WebhooksController`.
- reCAPTCHA via gem `recaptcha` y Google Cloud reCAPTCHA Enterprise.
- Active Storage para imagenes de paquetes y adjuntos de resultados en citas.
- Solid Queue para jobs.

Configuracion relevante:

- `config.time_zone = "America/Mexico_City"`.
- `config.active_record.default_timezone = :utc`.
- `APPOINTMENT_BOOKING_ENABLED` controla si se permite agendar.
- `GOOGLE_CALENDAR_ENABLED` habilita creacion/borrado de eventos.
- `GOOGLE_CLIENT_ID`, `GOOGLE_CLIENT_SECRET`, `GOOGLE_REFRESH_TOKEN`.
- `WHATSAPP_ACCESS_TOKEN`, `WHATSAPP_PHONE_NUMBER_ID`, `WHATSAPP_VERIFY_TOKEN`.

## 2. Sedes y Multi-Tenancy

No se encontraron modelos `Clinic`, `Organization`, `Tenant`, `Branch`, `Sucursal` ni equivalentes en `app/models` o `db/schema.rb`.

Estado actual:

- AMID actualmente no tiene multi-tenancy representado en el esquema verificado.
- No existe relacion de usuario, doctor, cita o paquete con sede/sucursal.
- No hay campo `site_id`, `tenant_id`, `organization_id` ni identificadores externos de sede.
- El acceso no se limita entre sedes porque no existe entidad de sede.
- Un doctor puede estar asociado a multiples paquetes, pero no a multiples sedes.
- Un paquete puede estar asociado a multiples doctores, pero no a multiples sedes.

Identificadores externos:

- `ExternalDoctorLink` existe como modelo y migracion `20260722003604_create_external_doctor_links.rb`, con `source_system`, `external_doctor_id`, `external_doctor_name` y `active`.
- `external_doctor_links` no aparece en `db/schema.rb` actual, por lo que el schema no refleja esa migracion al momento de este analisis.

## 3. Usuarios y Doctores

### User

`User` contiene:

- `name`
- `email`
- `role`
- `admin`
- Devise: `encrypted_password`, `reset_password_token`, `reset_password_sent_at`, `remember_created_at`
- `can_upload_results`
- `phone`

Relaciones:

- `has_one :doctor, dependent: :nullify`
- `has_many :created_appointments`
- `has_many :created_phone_bans`

Validaciones:

- `phone` obligatorio.
- Devise valida email/password segun sus reglas.

Rol por defecto:

- `assistant`, asignado en `after_initialize`.

### Doctor

`Doctor` contiene:

- `name`
- `email`
- `available_hours` como texto JSON parseado por getter/setter.
- `unavailable_dates` heredado de migracion anterior, sin uso principal en la logica actual.
- `user_id`
- `specialty_id`

Relaciones:

- `belongs_to :user, optional: true`
- `belongs_to :specialty, optional: true`
- `has_many :appointments`
- `has_many :doctor_packages`
- `has_many :packages, through: :doctor_packages`
- `has_many :doctor_unavailabilities`
- `has_many :doctor_time_blocks`

Permisos del doctor:

- Puede entrar a su propio perfil/calendario desde `Admin::DoctorsController`.
- En `Admin::AppointmentsController#index`, si `current_user.doctor?`, solo ve citas de `current_user.doctor`.
- No puede crear/borrar doctores.

Permisos administrativos:

- `admin` gestiona usuarios, doctores, paquetes, citas y calendarios.
- `assistant` puede acceder a citas administrativas; `can_upload_results` le permite gestionar resultados adjuntos.

El doctor autenticado se identifica por `current_user.doctor`.

## 4. Citas

### Modelo

`Appointment` pertenece a `package`, `doctor` y opcionalmente a `created_by` (`User`). Tiene adjuntos `study_results`.

Campos principales:

- Paciente: `name`, `age`, `email`, `phone`, `sex`, `phone_number_e164`.
- Agenda: `doctor_id`, `package_id`, `start_date`, `end_date`, `duration`.
- Estado: `status`, `canceled_at`.
- Tracking: `unique_code`, `token`, `google_calendar_id`, `scheduled_by`, `created_by_id`.

Enums:

- `scheduled_by`: `patient`, `admin`, `assistant`.
- `status`: `scheduled`, `canceled_by_admin`, `canceled_by_client`, `completed`, `no_show`.

Validaciones:

- `name`, `age`, `phone` obligatorios.
- `token` obligatorio y unico.
- `unique_code` obligatorio y unico.
- `google_calendar_id` unico si existe.
- `doctor_can_deliver_package`.
- `phone_not_banned` al crear.
- `no_double_booking`.
- `doctor_not_unavailable` para bloqueos de dia completo.

Callbacks:

- Antes de validar al crear: `ensure_unique_code`, `ensure_token`, `normalize_phone_number`.
- Despues de crear: `schedule_whatsapp_notifications`.

Prevencion de doble reservacion:

- `Appointment#no_double_booking` evita otra cita `scheduled` con el mismo `doctor_id` y mismo `start_date`.
- `User::Availability::SlotFree` valida slots usando `User::Availability::FetchTimes`.
- La prevencion actual no usa bloqueo de base de datos transaccional ni indice unico compuesto para `doctor_id/start_date/status`.

Zona horaria:

- App configurada en `America/Mexico_City`.
- DB en UTC.
- Disponibilidad usa `Time.use_zone("America/Mexico_City")` por defecto.

### Flujo completo para crear cita publica

1. `GET /appointments/new` carga paquete, doctores y disponibilidad mediante `User::Forms::AppointmentFormContext`.
2. Si el usuario no esta autenticado, `AppointmentsController#create` valida reCAPTCHA.
3. Normaliza telefono con `PhoneNormalizer.to_e164`.
4. Bloquea telefonos con `PhoneBan.active_now`.
5. `User::Appointments::Create.call` resuelve doctor:
   - Si viene `doctor_id`, usa ese doctor.
   - Si no viene, intenta doctor habitual por telefono.
   - Si no hay habitual, elige un doctor al azar entre doctores del paquete.
6. Valida que el doctor atienda el paquete.
7. Parsea `start_date`.
8. Calcula `end_date` con `package.duration`.
9. Revalida baneo por telefono.
10. Verifica disponibilidad con `User::Availability::SlotFree`.
11. Persiste `Appointment` con estado `scheduled`.
12. Crea evento en Google Calendar si `GOOGLE_CALENDAR_ENABLED=1`.
13. Asigna `scheduled_by`.
14. `after_create_commit` agenda WhatsApp de confirmacion, recordatorio de 24h y recordatorio de 2h.

### Creacion administrativa

`Admin::AppointmentsController#create` delega en `Admin::Appointments::Create`, que a su vez delega en `User::Appointments::Create` con `caller_role` y `caller_user`.

### Edicion, cancelacion y finalizacion

- `AppointmentsController#update` esta vacio.
- `AppointmentsController#destroy` cancela por cliente con `User::Appointments::Cancel`.
- `Admin::AppointmentsController#update` solo permite cambiar `status`; `User::Appointments::Update` acepta `completed`, `canceled_by_admin`, `no_show`.
- `Admin::AppointmentsController#cancel` y `#destroy` cancelan por admin con `User::Appointments::Cancel`.
- Cancelar borra evento de Google Calendar si existe, cambia estado y llena `canceled_at`.

Campos que Historial podria enviar para crear una cita:

- `name`, `age`, `email`, `phone`, `sex`, `doctor_id`, `package_id`, `duration`, `start_date`.

Campos que no deben ser modificables externamente sin reglas explicitas:

- `status` salvo endpoints controlados.
- `scheduled_by`.
- `created_by_id`.
- `unique_code`.
- `token`.
- `google_calendar_id`.
- `canceled_at`.
- `end_date` si debe calcularse desde la duracion oficial del paquete.
- `phone_number_e164` si se normaliza internamente.
- Adjuntos `study_results`, porque son resultados/documentos y requieren permisos propios.

## 5. Calendario

Controlador:

- `Admin::DoctorsController#calendar_events`.

Ruta:

- `GET /admin/doctors/:id/calendar_events`.

Vista:

- `app/views/admin/doctors/edit.html.erb`, pestaña "Calendario".

JavaScript:

- `app/javascript/controllers/doctor_calendar_controller.js`.

Libreria:

- FullCalendar con `dayGrid`, `timeGrid` e `interaction`.

Formato JSON actual:

- Arreglo directo de eventos FullCalendar, sin envoltorio `data/meta`.
- Citas:
  - `id`: `appt-:id`
  - `title`: paciente + paquete
  - `start`, `end`, `allDay`, `color`
  - `extendedProps.kind = "cita"`
  - `extendedProps.record_id`, `patient_name`, `package_id`, `package_name`, `scheduled_by`, `scheduled_by_label`, `status`
- Bloqueos por dia:
  - `id`: `unavail-:id`
  - `extendedProps.kind = "bloqueo_dia"`
- Bloqueos por hora:
  - `id`: `unavail-:id` para excepciones especificas con horas.
  - `id`: `tb-:id-:day` para recurrentes.
  - `extendedProps.kind = "bloqueo_horas"`

Filtros:

- `start`
- `end`

Permisos:

- `Admin::DoctorsController` requiere usuario autenticado.
- Admin puede ver/gestionar todos.
- Doctor solo su propio perfil/calendario.
- Otros roles no autorizados.

Zona horaria:

- Fija a `America/Mexico_City`.

Acciones disponibles:

- Ver calendario.
- Crear bloqueo desde modal/form.
- Eliminar bloqueos existentes desde la lista lateral.

Mover/redimensionar citas:

- El JS usa `selectable: false` y no define `eventDrop` ni `eventResize`.
- No hay evidencia de que las citas se puedan mover o redimensionar desde FullCalendar.

## 6. Disponibilidad

Servicio central:

- `User::Availability::FetchTimes.call(doctor:, date:, duration:, timezone: "America/Mexico_City", lead_minutes: 0)`.

Algoritmo:

1. Rechaza si no hay doctor o duracion positiva.
2. Convierte fecha a `Date`.
3. Usa la zona horaria indicada.
4. Busca `DoctorUnavailability` para el doctor y fecha.
5. Si hay indisponibilidad sin `start_time/end_time`, retorna sin slots para todo el dia.
6. Lee `doctor.available_hours`.
7. Normaliza llaves de dias en ingles/espanol.
8. Toma los rangos del dia, por ejemplo `"09:00-17:00"`.
9. Busca citas existentes del doctor en el dia con `status: :scheduled`.
10. Calcula intervalos ocupados por citas existentes usando `start_date/end_date/duration`.
11. Agrega bloqueos recurrentes `DoctorTimeBlock` si `days_of_week` incluye el dia.
12. Agrega bloqueos por hora especificos desde `DoctorUnavailability`.
13. Genera slots avanzando en incrementos iguales a la duracion.
14. Descarta slots pasados por `lead_minutes`.
15. Descarta traslapes con citas y bloqueos.
16. Retorna slots ordenados.

`User::Availability::SlotFree.call` delega en `FetchTimes` y confirma que `start_date` este incluido en los slots.

Endpoint existente:

- No existe endpoint JSON dedicado de disponibilidad bajo `api/internal`.
- Existe flujo HTML/Turbo `GET/POST /appointments/check_availability`.
- Existe `GET /admin/appointments/available_fields`, que responde Turbo Stream y calcula disponibilidad parcial por doctor/fecha/paquete.

Parametros observados en flujos actuales:

- `package_id`
- `doctor_id`
- `appointment_date`
- `time_slot`
- `duration`

Respuesta actual:

- Turbo Stream/HTML, no contrato JSON estable para integracion externa.

## 7. Bloqueos y No Disponibilidad

### DoctorUnavailability

Representa excepciones de fechas especificas:

- Dia completo si `start_time` y `end_time` son `nil`.
- Bloqueo por horas en fecha especifica si tiene `start_time` y `end_time`.

Campos:

- `doctor_id`
- `date`
- `reason`
- `start_time`
- `end_time`

Validaciones:

- `date` obligatoria.
- Unicidad por `doctor_id`, `date`, `start_time`, `end_time`.

Rutas/controlador:

- `POST /admin/doctors/:id/mark_unavailable_day`
- `DELETE /admin/doctors/:id/clear_unavailable_day`
- `POST /admin/doctors/:id/mark_unavailable_range`
- `DELETE /admin/doctors/:id/clear_unavailable_range`
- `POST /admin/doctors/:id/create_unified_block`
- `DELETE /admin/doctors/:id/destroy_unavailability`

### DoctorTimeBlock

Representa bloqueos recurrentes semanales por hora:

- `doctor_id`
- `starts_at`
- `ends_at`
- `days_of_week` como JSON, usando `Date#wday` de Ruby: `0=domingo..6=sabado`.
- `reason`

Validaciones:

- `starts_at`, `ends_at`, `days_of_week` obligatorios.
- `ends_at` debe ser mayor que `starts_at`.

Rutas/controlador:

- `POST /admin/doctors/:id/create_time_block`
- `DELETE /admin/doctors/:id/destroy_time_block`
- Tambien se crea desde `create_unified_block` cuando `is_recurring` es true.

Creacion de varios dias:

- `mark_unavailable_range` y `create_unified_block` iteran `(start_date..end_date)`.
- `end_date` es inclusivo en el codigo.

Conflictos con citas existentes:

- Al crear bloqueos, AMID intenta reasignar citas futuras o dentro del rango a otro doctor que atienda el mismo paquete y tenga exactamente el slot disponible.
- Si no hay doctor disponible, no revierte el bloqueo; acumula `failed_count` y muestra alerta para reagendar manualmente.
- Si reasigna y Google Calendar falla, conserva la reasignacion y muestra alerta.

Como aparecen en calendario:

- `DoctorUnavailability` dia completo: evento rojo `bloqueo_dia`.
- `DoctorUnavailability` por horas: evento naranja `bloqueo_horas`.
- `DoctorTimeBlock`: se expande por dia dentro del rango consultado como evento naranja `bloqueo_horas`.

Recurrencia:

- Solo semanal por dias de semana mediante `DoctorTimeBlock`.
- No hay modelo de regla recurrente avanzada.

Edicion:

- No se encontro accion de edicion directa de bloqueos; se crean y eliminan.

## 8. Paquetes

`Package` contiene:

- `name`
- `description`
- `price`
- `duration`
- `kind`
- `featured`
- imagen por Active Storage.

Enums:

- `kind`: `servicios`, `paquete`, `cirugia`.

Relaciones:

- `has_many :doctor_packages`
- `has_many :doctors, through: :doctor_packages`
- `has_one_attached :image`
- `Appointment belongs_to :package`

Validaciones:

- Imagen obligatoria.

Administracion:

- `Admin::PackagesController` permite CRUD.
- Solo admin.
- Filtros de index: `q`, `sort`, `page`; paginacion manual de 9 por pagina.

API existente:

- No existe API interna JSON de paquetes bajo `api/internal`.
- Existen rutas publicas `GET /packages` y `GET /packages/:id` HTML.

Campos JSON:

- Hay Jbuilder historico en el otro repo AMID, pero en `amid2` no se encontro controlador API ni vistas JSON de paquetes activas bajo API interna.

## 9. API Interna

### API disponible actualmente

No se encontraron rutas bajo `api/internal` en `config/routes.rb` ni controladores `Api::Internal::*` en `app/controllers`.

Por lo tanto, estos endpoints no estan disponibles actualmente en `amid2`:

| Estado | Metodo | Ruta | Proposito |
| --- | --- | --- | --- |
| missing | GET | `/api/internal/appointments` | Listar citas para Historial |
| missing | GET | `/api/internal/appointments/:id` | Consultar cita |
| missing | PATCH | `/api/internal/appointments/:id/clinical_status` | Sincronizar estado clinico |
| missing | GET | `/api/internal/packages` | Listar paquetes |
| missing | GET | `/api/internal/doctors` | Listar doctores |

### Rutas JSON/HTML existentes reutilizables indirectamente

| Metodo | Ruta | Controlador#accion | Autenticacion | Respuesta |
| --- | --- | --- | --- | --- |
| GET | `/admin/doctors/:id/calendar_events` | `Admin::DoctorsController#calendar_events` | Devise + admin o doctor propio | JSON FullCalendar |
| GET/POST | `/appointments/check_availability` | `AppointmentsController#check_availability` | Publico, booking habilitado | No se encontro accion explicita en controlador actual |
| GET | `/admin/appointments/available_fields` | `Admin::AppointmentsController#available_fields` | Devise + rol admin/assistant/doctor | Turbo Stream |

Notas:

- `available_fields` viene de `User::Concerns::AvailableFields`.
- `AppointmentsController` incluye rutas `check_availability`, pero no se encontro metodo `check_availability` definido en el controlador actual.

### API requerida por la arquitectura objetivo

Estos endpoints deben diseniarse cuando sean necesarios, pero no deben suponerse existentes hasta implementarse y verificarse. La diferencia entre esta lista y la API disponible es el plan real de desarrollo.

| Estado | Metodo | Ruta | Proposito | Fuente de verdad | Repositorio |
| --- | --- | --- | --- | --- | --- |
| proposed | GET | `/api/internal/v1/clinical_entitlements/current` | Validar acceso a Historial Clinico | AMID | AMID |
| proposed | GET | `/api/internal/v1/me/doctor` | Obtener doctor autenticado/contextual | AMID | AMID |
| proposed | GET | `/api/internal/v1/doctors` | Listar doctores | AMID | AMID |
| proposed | GET | `/api/internal/v1/doctors/:id` | Consultar doctor | AMID | AMID |
| proposed | GET | `/api/internal/v1/packages` | Listar paquetes | AMID | AMID |
| proposed | GET | `/api/internal/v1/packages/:id` | Consultar paquete | AMID | AMID |
| proposed | GET | `/api/internal/v1/appointments` | Listar citas | AMID | AMID |
| proposed | GET | `/api/internal/v1/appointments/:id` | Consultar cita | AMID | AMID |
| proposed | POST | `/api/internal/v1/appointments` | Crear cita desde Historial | AMID | AMID |
| proposed | PATCH | `/api/internal/v1/appointments/:id` | Actualizar datos operativos de cita | AMID | AMID |
| proposed | POST | `/api/internal/v1/appointments/:id/cancel` | Cancelar cita preservando historial | AMID | AMID |
| proposed | PATCH | `/api/internal/v1/appointments/:id/clinical_status` | Sincronizar estado clinico operacional | AMID conserva agenda; Historial origina estado clinico | AMID + Historial |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/availability` | Consultar slots disponibles | AMID | AMID |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/calendar` | Consultar calendario operativo | AMID | AMID |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/time_blocks` | Consultar bloqueos | AMID | AMID |
| proposed | POST | `/api/internal/v1/doctors/:doctor_id/time_blocks` | Crear bloqueo | AMID | AMID |
| proposed | PATCH | `/api/internal/v1/doctors/:doctor_id/time_blocks/:id` | Editar bloqueo | AMID | AMID |
| proposed | DELETE | `/api/internal/v1/doctors/:doctor_id/time_blocks/:id` | Eliminar bloqueo | AMID | AMID |

## 10. Contrataciones y Pagos

Busqueda realizada sobre nombres relacionados con `Subscription`, `Plan`, `Purchase`, `Payment`, `License`, `FeatureFlag`, `Feature`, `Entitlement`, `Membership`, `ClinicPlan`, `DoctorPlan`, `Clinic`, `Organization`, `Tenant`, `Branch`, `Stripe` y equivalentes.

Resultado:

- No se encontro modelo, tabla ni controlador que represente contrataciones, planes, pagos, licencias, feature flags o entitlements.
- El campo `packages.featured` existe, pero se refiere a paquetes destacados, no a feature flags.
- AMID actualmente no puede representar de forma directa que una sede o doctor compro Historial Clinico.

### Disenio posible 1: suscripcion por sede

Idea:

- Crear `Clinic`.
- Crear `SiteSubscription` o `ClinicalEntitlement` asociado a `site_id`.
- Asociar usuarios, doctores, paquetes y citas a sede.

Ventajas:

- Natural si AMID opera por sedes.
- Permite activar Historial para todo el personal de una sede.
- Simplifica permisos y facturacion.

Riesgos:

- Requiere introducir multi-tenancy real.
- Necesita migrar datos existentes a una sede inicial.
- Debe definir si un doctor puede pertenecer a varias sedes.

Migraciones necesarias:

- `clinics`.
- `clinic_memberships` o `clinic_users`.
- `clinic_doctors` si un doctor puede pertenecer a varias sedes.
- `site_subscriptions`/`clinical_entitlements`.
- `site_id` en citas, paquetes o tablas puente segun el modelo elegido.

### Disenio posible 2: suscripcion por doctor

Idea:

- Crear `DoctorSubscription` o `ClinicalEntitlement` asociado a `doctor_id`.

Ventajas:

- Menor migracion inicial si no hay sedes.
- Compatible con doctores independientes.
- Facilita activar Historial por medico.

Riesgos:

- No modela personal de recepcion/enfermeria por sede.
- Complica paquetes y calendarios compartidos.
- Puede duplicar pagos si varios doctores pertenecen a la misma operacion.

Migraciones necesarias:

- `doctor_subscriptions`/`clinical_entitlements`.
- Campos de estado, plan, vigencia y origen de compra.
- Posible relacion con `User` para usuario comprador/administrador.

### Disenio posible 3: suscripcion hibrida sede + doctor

Idea:

- Crear entidad `ClinicalEntitlement` polimorfica o con columnas `site_id` y `doctor_id`.
- Permitir entitlement de sede y excepciones por doctor.

Ventajas:

- Flexible para sedes y doctores independientes.
- Permite evolucionar sin bloquear un solo modelo comercial.

Riesgos:

- Reglas de precedencia mas complejas.
- Mayor superficie de pruebas.
- Requiere resolver multi-tenancy antes de exponer permisos confiables.

Migraciones necesarias:

- `clinics`.
- `clinical_entitlements` con `owner_type/owner_id` o `site_id/doctor_id`.
- Indices para evitar solapamientos activos.
- Auditoria de cambios de plan/estado.

## 11. Autenticacion Entre AMID e Historial

Opciones analizadas contra el codigo actual:

### Compartir usuarios

Viable parcialmente, pero riesgoso. AMID usa Devise y no hay modelo sede/tenant. Compartir tabla o credenciales entre apps acoplaria despliegues y seguridad.

### SSO

Viable a mediano plazo. AMID ya tiene Devise y una configuracion OmniAuth Google, pero no hay proveedor OAuth propio de AMID ni modelo de sesiones federadas. Requiere trabajo adicional.

### JWT firmado

Compatible como primer paso para enlace entre aplicaciones. Permite que AMID emita un token firmado con `user_id`, `doctor_id`, rol, expiracion y eventual `site_id` cuando exista. Requiere secreto/llave, expiracion corta y revocacion.

### OAuth

Arquitectura mas completa, pero mas costosa. El codigo actual no tiene Doorkeeper u otro provider OAuth.

### Enlace de acceso firmado

Compatible con el estilo actual (`Appointment#token`) y simple para saltar desde AMID a Historial, pero debe ser de vida corta, un solo uso o revocable. No sirve por si solo como API interna durable.

### Cuentas separadas sincronizadas

Compatible con Historial si se sincronizan doctores/usuarios. Requiere endpoint de doctores y reglas para correos faltantes, activacion/desactivacion y revocacion.

Recomendacion:

- Primer paso: cuentas separadas sincronizadas para usuarios/doctores + token interno Bearer scoped para API AMID-Historial.
- Segundo paso: enlace firmado de acceso desde AMID hacia Historial para UX.
- Evolucion: JWT firmado o OAuth cuando exista modelo de sede/tenant y revocacion granular.

Flujo recomendado inicial:

1. AMID conserva usuarios y doctores como fuente de verdad operativa.
2. Historial sincroniza doctores desde AMID.
3. El usuario entra a AMID con Devise.
4. AMID genera enlace firmado corto hacia Historial con identidad de usuario, doctor y rol.
5. Historial valida firma/expiracion y crea sesion local.
6. Historial consume API interna AMID con Bearer token de aplicacion y headers de contexto.

Seguridad requerida:

- Expiracion corta.
- Revocacion por usuario/doctor.
- Auditoria de solicitudes.
- Scopes lectura/escritura.
- Validar que `doctor_id` pertenece al usuario.
- Agregar `site_id` cuando exista multi-tenancy.

## 12. Endpoints Necesarios

No se implementan todavia. Deben documentarse contract-first y luego implementarse en fases.

### API disponible actualmente

| Estado | Metodo | Ruta | Propósito | Consumible por Historial hoy |
| --- | --- | --- | --- | --- |
| existing | GET | `/admin/doctors/:id/calendar_events` | Eventos FullCalendar de un doctor | No directamente; requiere Devise y formato UI |
| missing | GET | `/api/internal/*` | API interna versionada | No |

### API requerida por la arquitectura objetivo

| Estado | Metodo | Ruta | Propósito | Request esperado | Response esperado | Repositorio |
| --- | --- | --- | --- | --- | --- | --- |
| proposed | GET | `/api/internal/v1/clinical_entitlements/current` | Validar si Historial esta habilitado | `site_id`, `doctor_id`, `user_id` cuando existan | `enabled`, `scope`, `plan`, `status`, `features` | AMID |
| proposed | GET | `/api/internal/v1/me/doctor` | Obtener doctor autenticado/contextual | Bearer + usuario contextual | Doctor vinculado al usuario | AMID |
| proposed | GET | `/api/internal/v1/doctors` | Sincronizar doctores | filtros `active`, `specialty`, `updated_since`, paginacion | lista paginada de doctores | AMID |
| proposed | GET | `/api/internal/v1/doctors/:id` | Consultar doctor | `id` | doctor | AMID |
| proposed | GET | `/api/internal/v1/packages` | Sincronizar paquetes | filtros `doctor_id`, `kind`, `active`, `updated_since`, paginacion | lista paginada de paquetes | AMID |
| proposed | GET | `/api/internal/v1/packages/:id` | Consultar paquete | `id` | paquete | AMID |
| proposed | GET | `/api/internal/v1/appointments` | Listar citas | filtros `doctor_id`, `date_from`, `date_to`, `status`, `patient_query`, `package_id`, `updated_since` | lista paginada de citas | AMID |
| proposed | GET | `/api/internal/v1/appointments/:id` | Consultar cita | `id` | cita | AMID |
| proposed | POST | `/api/internal/v1/appointments` | Crear cita desde Historial | `Idempotency-Key` + `appointment` JSON | cita creada | AMID |
| proposed | PATCH | `/api/internal/v1/appointments/:id` | Actualizar cita operativa | campos permitidos: doctor, paquete, fecha/hora, contacto, notas | cita actualizada | AMID |
| proposed | POST | `/api/internal/v1/appointments/:id/cancel` | Cancelar cita | motivo y origen | cita cancelada | AMID |
| proposed | PATCH | `/api/internal/v1/appointments/:id/clinical_status` | Sincronizar estado clinico | estado, `clinical_check_in_id`, `occurred_at` | estado aceptado/idempotente | AMID |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/availability` | Consultar disponibilidad | `package_id`, `date_from`, `date_to`, `timezone` | slots por fecha | AMID |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/calendar` | Consultar calendario operativo | `date_from`, `date_to`, `event_types`, `timezone` | eventos minimizados | AMID |
| proposed | GET | `/api/internal/v1/doctors/:doctor_id/time_blocks` | Consultar bloqueos | rango y tipo | bloqueos | AMID |
| proposed | POST | `/api/internal/v1/doctors/:doctor_id/time_blocks` | Crear bloqueo | `Idempotency-Key` + bloqueo JSON | bloqueo creado | AMID |
| proposed | PATCH | `/api/internal/v1/doctors/:doctor_id/time_blocks/:id` | Editar bloqueo | bloqueo JSON | bloqueo actualizado | AMID |
| proposed | DELETE | `/api/internal/v1/doctors/:doctor_id/time_blocks/:id` | Eliminar bloqueo | `id` | confirmacion | AMID |

Plan real de desarrollo:

1. Crear contrato versionado `/api/internal/v1`.
2. Implementar autenticacion interna Bearer con scopes.
3. Exponer primero endpoints de lectura: doctores, paquetes, citas.
4. Exponer disponibilidad usando `User::Availability::FetchTimes`.
5. Exponer escrituras idempotentes para citas y bloqueos.
6. Agregar `clinical_status` solo despues de mapear estados AMID/Historial.
7. Diseniar entitlements despues de decidir modelo comercial y multi-tenancy.

