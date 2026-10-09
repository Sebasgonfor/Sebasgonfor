-- =========================================================
-- FORMATIVA I - CORTE 2
-- LENGUAJE SQL: DML Y CONTROL DE TRANSACCIONES
-- =========================================================

-- Estudiante: Sebastian Gonzalez Fornaris
-- Código: 92510206
-- Fecha: Octubre, 2026.


-- =========================================================
-- TRANSACCIÓN 1
-- Apertura de grupo y proceso de matrícula
-- =========================================================

START TRANSACTION;

-- Crear el nuevo grupo 630 (número 06) de Bases de Datos (asignatura 301),
-- profesor 501, periodo académico 2 (2026-2), con cupo inicial de 25
INSERT INTO grupos (id_grupo, numero_grupo, periodo, cupo, id_asignatura, id_profesor, id_periodo)
VALUES (630, '06', '2026-2', 25, 301, 501, 2);

-- Ampliar el cupo del grupo de 25 a 30 estudiantes
UPDATE grupos
SET cupo = 30
WHERE id_grupo = 630;

-- Establecer punto seguro: el grupo ya está configurado correctamente
SAVEPOINT sp_grupo_configurado;

-- Matricular al estudiante 1005 (matrícula 7300) en el grupo 630
INSERT INTO matriculas (id_matricula, id_estudiante, id_asignatura, periodo, fecha_matricula, estado, id_grupo)
VALUES (7300, 1005, 301, '2026-2', '2026-09-01', 'ACTIVA', 630);

-- Establecer punto seguro: la primera matrícula se registró correctamente
SAVEPOINT sp_primera_matricula;

-- Matricular al estudiante 1006 (matrícula 7301) en el grupo 630
INSERT INTO matriculas (id_matricula, id_estudiante, id_asignatura, periodo, fecha_matricula, estado, id_grupo)
VALUES (7301, 1006, 301, '2026-2', '2026-09-01', 'ACTIVA', 630);

-- Se detecta el error: el estudiante 1006 ya estaba asignado a otro grupo
-- de la misma asignatura y no debía matricularse en el grupo 630.
-- Recuperar el estado correcto: se deshace solo la matrícula 7301
ROLLBACK TO SAVEPOINT sp_primera_matricula;

-- Confirmar definitivamente las operaciones válidas
COMMIT;

-- ESTADO FINAL:
-- Grupo 630                         -> EXISTE (se conserva)
-- Cupo del grupo 630 = 30           -> SE CONSERVA (el UPDATE quedó antes del primer SAVEPOINT)
-- Matrícula 7300 / estudiante 1005  -> EXISTE (se conserva)
-- Matrícula 7301 / estudiante 1006  -> NO EXISTE (revertida con ROLLBACK TO SAVEPOINT,
--                                      sin usar DELETE)


-- =========================================================
-- TRANSACCIÓN 2
-- Gestión de calificaciones y recuperación
-- =========================================================

-- PARTE A

START TRANSACTION;

-- Corregir la nota de la calificación 9100 (matrícula 7300)
UPDATE calificaciones
SET nota = 4.5
WHERE id_calificacion = 9100;

-- Registrar la nueva calificación 9101 para la matrícula 7300
INSERT INTO calificaciones (id_calificacion, nota, fecha_registro, id_matricula)
VALUES (9101, 4.2, '2026-09-25', 7300);

-- Establecer punto seguro: el UPDATE de 9100 y el INSERT de 9101 son correctos
SAVEPOINT sp_calificaciones_correctas;

-- El operador elimina la calificación 9102
DELETE FROM calificaciones
WHERE id_calificacion = 9102;

-- Se detecta el error: la calificación 9102 era válida y no debía eliminarse.
-- Recuperar el estado correcto: se revierte solo el DELETE
ROLLBACK TO SAVEPOINT sp_calificaciones_correctas;

-- Confirmar las operaciones válidas (9100 actualizada, 9101 insertada, 9102 intacta)
COMMIT;


-- PARTE B

START TRANSACTION;

-- UPDATE incorrecto: cambio temporal de la matrícula 7300 a CANCELADA
UPDATE matriculas
SET estado = 'CANCELADA'
WHERE id_matricula = 7300;

-- La coordinación verifica que la matrícula debe seguir ACTIVA:
-- se cancela toda la unidad transaccional (sin COMMIT)
ROLLBACK;

-- ESTADO FINAL:
-- Calificación 9100                 -> nota actualizada a 4.5 (confirmada en la Parte A)
-- Calificación 9101                 -> EXISTE con nota 4.2 y fecha 2026-09-25
-- Calificación 9102                 -> CONTINÚA EXISTIENDO (DELETE revertido con ROLLBACK TO SAVEPOINT)
-- Matrícula 7300                    -> CONTINÚA ACTIVA
-- Cambio temporal a CANCELADA       -> REVERTIDO con ROLLBACK completo (no se ejecutó COMMIT)
