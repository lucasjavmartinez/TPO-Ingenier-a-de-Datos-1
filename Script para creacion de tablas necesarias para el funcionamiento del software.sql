/* Crea la base de datos si no existe */
IF DB_ID('TorneosEsports') IS NULL
    CREATE DATABASE TorneosEsports;

/* ¡¡¡¡IMPORTANTE!!!! */
/* ¡¡¡¡IMPORTANTE!!!! SOLO CORRER ESTO EN CASO DE SER NECESARIO PORQUE TIRA TODA LA BASE DE DATOS */
IF DB_ID('TorneosEsports') IS NOT NULL
BEGIN
    ALTER DATABASE TorneosEsports SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE TorneosEsports;
END

/* Creacion de la tabla para un juego */
CREATE TABLE Juego (
    id_juego     INT IDENTITY(1,1) CONSTRAINT PK_Juego PRIMARY KEY,
    nombre       VARCHAR(60)  NOT NULL CONSTRAINT UQ_Juego_nombre UNIQUE,
    descripcion  VARCHAR(250) NULL
);


CREATE TABLE Equipo (
    id_equipo   INT IDENTITY(1,1) CONSTRAINT PK_Equipo PRIMARY KEY,
    nombre      VARCHAR(60) NOT NULL CONSTRAINT UQ_Equipo_nombre UNIQUE,
    fecha_alta  DATE        NOT NULL CONSTRAINT DF_Equipo_fecha_alta DEFAULT (CAST(GETDATE() AS DATE))
);

/* datos sensibles */
CREATE TABLE Jugador (  
    id_jugador        INT IDENTITY(1,1) CONSTRAINT PK_Jugador PRIMARY KEY,
    dni               VARCHAR(10)  NOT NULL CONSTRAINT UQ_Jugador_dni  UNIQUE,
    nick              VARCHAR(30)  NOT NULL CONSTRAINT UQ_Jugador_nick UNIQUE,
    nombre            VARCHAR(60)  NOT NULL,
    apellido          VARCHAR(60)  NOT NULL,
    mail              VARCHAR(100) NOT NULL CONSTRAINT UQ_Jugador_mail UNIQUE,
    fecha_nacimiento  DATE         NOT NULL,

    CONSTRAINT CK_Jugador_mail  CHECK (mail LIKE '%_@_%._%'),
    CONSTRAINT CK_Jugador_fnac  CHECK (fecha_nacimiento <= CAST(GETDATE() AS DATE))
);


CREATE TABLE Integrante_Equipo (
    id_integrante  INT IDENTITY(1,1) CONSTRAINT PK_Integrante_Equipo PRIMARY KEY,
    id_equipo      INT  NOT NULL CONSTRAINT FK_Integrante_Equipo_Equipo  FOREIGN KEY REFERENCES Equipo(id_equipo),
    id_jugador     INT  NOT NULL CONSTRAINT FK_Integrante_Equipo_Jugador FOREIGN KEY REFERENCES Jugador(id_jugador),
    fecha_ingreso  DATE NOT NULL CONSTRAINT DF_Integrante_ingreso DEFAULT (CAST(GETDATE() AS DATE)),

    CONSTRAINT UQ_Integrante_Jugador UNIQUE (id_jugador)

);

CREATE TABLE Persona (
    id_persona  INT IDENTITY(1,1) CONSTRAINT PK_Persona PRIMARY KEY,
    dni         VARCHAR(10)  NOT NULL CONSTRAINT UQ_Persona_dni  UNIQUE,
    nombre      VARCHAR(60)  NOT NULL,
    apellido    VARCHAR(60)  NOT NULL,
    mail        VARCHAR(100) NOT NULL CONSTRAINT UQ_Persona_mail UNIQUE,
    CONSTRAINT CK_Persona_mail CHECK (mail LIKE '%_@_%._%')
);
CREATE TABLE Organizador (
    id_persona  INT NOT NULL CONSTRAINT PK_Organizador PRIMARY KEY
    
    CONSTRAINT FK_Organizador_Persona FOREIGN KEY REFERENCES Persona(id_persona)
);

CREATE TABLE Arbitro (
    id_persona  INT NOT NULL CONSTRAINT PK_Arbitro PRIMARY KEY
    
    CONSTRAINT FK_Arbitro_Persona FOREIGN KEY REFERENCES Persona(id_persona)
);


/* crea la tabla para los Torneos */

CREATE TABLE Torneo (
    id_torneo         INT IDENTITY(1,1) CONSTRAINT PK_Torneo PRIMARY KEY,
    id_juego          INT NOT NULL CONSTRAINT FK_Torneo_Juego       FOREIGN KEY REFERENCES Juego(id_juego),
    id_organizador    INT NOT NULL CONSTRAINT FK_Torneo_Organizador FOREIGN KEY REFERENCES Organizador(id_persona),
    nombre            VARCHAR(100) NOT NULL,
    fecha_inicio      DATE NOT NULL,
    fecha_fin         DATE NULL,
    cantidad_equipos  INT  NOT NULL,   
    premio_base       DECIMAL(12,2) NOT NULL, 
    estado            VARCHAR(15) NOT NULL CONSTRAINT DF_Torneo_estado DEFAULT ('Inscripcion'),

    CONSTRAINT UQ_Torneo_nombre_inicio UNIQUE (nombre, fecha_inicio),
    CONSTRAINT CK_Torneo_cantidad CHECK (cantidad_equipos IN (8,16)),
    CONSTRAINT CK_Torneo_premio   CHECK (premio_base > 0 AND premio_base % 50000 = 0),  /* Los premios tendran siempre el siguiente formato = x00.000 o x50.000 */
    CONSTRAINT CK_Torneo_estado   CHECK (estado IN ('Inscripcion','En curso','Finalizado','Cancelado')),
    CONSTRAINT CK_Torneo_fechas   CHECK (fecha_fin IS NULL OR fecha_fin >= fecha_inicio)
);


CREATE TABLE Inscripcion (
    id_inscripcion     INT IDENTITY(1,1) CONSTRAINT PK_Inscripcion PRIMARY KEY,
    id_torneo          INT NOT NULL CONSTRAINT FK_Inscripcion_Torneo FOREIGN KEY REFERENCES Torneo(id_torneo),
    id_equipo          INT NOT NULL CONSTRAINT FK_Inscripcion_Equipo FOREIGN KEY REFERENCES Equipo(id_equipo),
    fecha_inscripcion  DATETIME2 NOT NULL CONSTRAINT DF_Inscripcion_fecha DEFAULT (SYSDATETIME()),
    estado             VARCHAR(15) NOT NULL CONSTRAINT DF_Inscripcion_estado DEFAULT ('Activo'),
    motivo_descalificacion  VARCHAR(250) NULL,
    fecha_descalificacion   DATETIME2 NULL,

    CONSTRAINT UQ_Inscripcion_torneo_equipo UNIQUE (id_torneo, id_equipo),
    CONSTRAINT CK_Inscripcion_estado CHECK (estado IN ('Activo','Eliminado','Descalificado')),
    CONSTRAINT CK_Inscripcion_descalificacion CHECK (
        (estado = 'Descalificado' AND motivo_descalificacion IS NOT NULL AND fecha_descalificacion IS NOT NULL)
        OR (estado <> 'Descalificado' AND motivo_descalificacion IS NULL AND fecha_descalificacion IS NULL))
);


/* Creacion de la tabla de Partidas */

CREATE TABLE Partido (
    id_partido            INT IDENTITY(1,1) CONSTRAINT PK_Partido PRIMARY KEY,
    id_torneo             INT NOT NULL CONSTRAINT FK_Partido_Torneo FOREIGN KEY REFERENCES Torneo(id_torneo),
    nro_fase              INT NOT NULL,   -- 1 = primera fase; la mayor = final
    nro_llave             INT NOT NULL,   -- posición del cruce dentro de la fase
    id_arbitro            INT NULL CONSTRAINT FK_Partido_Arbitro FOREIGN KEY REFERENCES Arbitro(id_persona),
    id_equipo_a           INT NULL CONSTRAINT FK_Partido_EquipoA FOREIGN KEY REFERENCES Equipo(id_equipo),
    id_equipo_b           INT NULL CONSTRAINT FK_Partido_EquipoB FOREIGN KEY REFERENCES Equipo(id_equipo),
    fecha_hora            DATETIME2 NULL,
    estado                VARCHAR(10) NOT NULL CONSTRAINT DF_Partido_estado DEFAULT ('Pendiente'),
    puntaje_a             INT NULL,
    puntaje_b             INT NULL,
    cantidad_espectadores INT NULL,
    id_partido_siguiente  INT NULL CONSTRAINT FK_Partido_Siguiente FOREIGN KEY REFERENCES Partido(id_partido),
    lado_siguiente        CHAR(1) NULL,   -- 'A' o 'B': a que lado del siguiente cruce va el ganador
    id_mvp_jugador        INT NULL CONSTRAINT FK_Partido_MVP FOREIGN KEY REFERENCES Jugador(id_jugador),

    CONSTRAINT CK_Partido_estado CHECK (estado IN ('Pendiente','Jugado','Cancelado')),
    CONSTRAINT UQ_Partido_llave UNIQUE (id_torneo, nro_fase, nro_llave),
    CONSTRAINT CK_Partido_fase  CHECK (nro_fase >= 1 AND nro_llave >= 1),
    CONSTRAINT CK_Partido_equipos_distintos CHECK (id_equipo_a IS NULL OR id_equipo_b IS NULL OR id_equipo_a <> id_equipo_b), -- Ganador = 16, perdedor entre 0 y 15 (el 15-15 se resuelve con ronda de oro: queda 16-15). El ganador NO se guarda: se deduce del puntaje.
    CONSTRAINT CK_Partido_puntaje CHECK (
        (estado = 'Jugado' AND puntaje_a IS NOT NULL AND puntaje_b IS NOT NULL
            AND ((puntaje_a = 16 AND puntaje_b BETWEEN 0 AND 15)
              OR (puntaje_b = 16 AND puntaje_a BETWEEN 0 AND 15)))
        OR (estado IN ('Pendiente','Cancelado') AND puntaje_a IS NULL AND puntaje_b IS NULL)
    ),
    CONSTRAINT CK_Partido_jugado_equipos CHECK (estado <> 'Jugado' OR (id_equipo_a IS NOT NULL AND id_equipo_b IS NOT NULL)),
    CONSTRAINT CK_Partido_espectadores CHECK (cantidad_espectadores IS NULL OR cantidad_espectadores >= 0),
    CONSTRAINT CK_Partido_siguiente CHECK (
        (id_partido_siguiente IS NULL AND lado_siguiente IS NULL)
        OR (id_partido_siguiente IS NOT NULL AND lado_siguiente IN ('A','B'))
    ),
    CONSTRAINT CK_Partido_no_autorreferencia CHECK (id_partido_siguiente IS NULL OR id_partido_siguiente <> id_partido)
);


CREATE TABLE Alineacion_Partido (
    id_partido  INT NOT NULL CONSTRAINT FK_Alineacion_Partido FOREIGN KEY REFERENCES Partido(id_partido),
    id_jugador  INT NOT NULL CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY REFERENCES Jugador(id_jugador),
    puntos_jugador INT NULL,
    id_equipo   INT NOT NULL CONSTRAINT FK_Alineacion_Equipo  FOREIGN KEY REFERENCES Equipo(id_equipo),
    CONSTRAINT PK_Alineacion_Partido PRIMARY KEY (id_partido, id_jugador),
    CONSTRAINT CK_Alineacion_puntos CHECK (puntos_jugador IS NULL OR puntos_jugador >= 0)
);


/* Premios efectivamente pagados (hecho historico como la presencia de Santos en las clases de BBDD) */

CREATE TABLE Pago_Premio (
    id_pago     INT IDENTITY(1,1) CONSTRAINT PK_Pago_Premio PRIMARY KEY,
    id_torneo   INT NOT NULL CONSTRAINT FK_Pago_Torneo  FOREIGN KEY REFERENCES Torneo(id_torneo),
    id_jugador  INT NOT NULL CONSTRAINT FK_Pago_Jugador FOREIGN KEY REFERENCES Jugador(id_jugador),
    tipo        VARCHAR(12) NOT NULL,
    monto       DECIMAL(12,2) NOT NULL,
    fecha_pago  DATETIME2 NOT NULL CONSTRAINT DF_Pago_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Pago UNIQUE (id_torneo, id_jugador, tipo),
    CONSTRAINT CK_Pago_tipo  CHECK (tipo IN ('1er puesto','2do puesto','MVP')),
    CONSTRAINT CK_Pago_monto CHECK (monto > 0)
);