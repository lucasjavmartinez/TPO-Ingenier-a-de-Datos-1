CREATE DATABASE torneoEsportsBD1;
GO

USE torneoEsportsBD1;
GO


CREATE TABLE Juego (
    id_juego     INT IDENTITY(1,1) CONSTRAINT PK_Juego PRIMARY KEY,
    nombre       VARCHAR(60)  NOT NULL CONSTRAINT UQ_Juego_nombre UNIQUE,
    descripcion  VARCHAR(250) NULL
);

CREATE TABLE Persona (
    id_persona  INT IDENTITY(1,1) CONSTRAINT PK_Persona PRIMARY KEY,
    dni         VARCHAR(10)  NOT NULL CONSTRAINT UQ_Persona_dni  UNIQUE,
    nombre      VARCHAR(60)  NOT NULL,
    apellido    VARCHAR(60)  NOT NULL,
    mail        VARCHAR(100) NOT NULL CONSTRAINT UQ_Persona_mail UNIQUE,
    fecha_nacimiento DATE NOT NULL,

    CONSTRAINT CK_Persona_mail CHECK (mail LIKE '%_@_%._%'),
    CONSTRAINT CK_Persona_fnac CHECK (fecha_nacimiento <= CAST(GETDATE() AS DATE))--agregar luego en un trigger o sp un limite minimo de edad para inscribirse
);
CREATE TABLE Organizador (
    id_persona  INT NOT NULL CONSTRAINT PK_Organizador PRIMARY KEY,
    
    CONSTRAINT FK_Organizador_Persona FOREIGN KEY (id_persona) REFERENCES Persona(id_persona)
);

CREATE TABLE Manager (
    id_persona INT NOT NULL CONSTRAINT PK_Manager PRIMARY KEY,

    CONSTRAINT FK_Manager_Persona FOREIGN KEY (id_persona) REFERENCES Persona(id_persona)

);

CREATE TABLE Arbitro (
    id_persona  INT NOT NULL CONSTRAINT PK_Arbitro PRIMARY KEY,
    
    CONSTRAINT FK_Arbitro_Persona FOREIGN KEY (id_persona) REFERENCES Persona(id_persona)
);

--el cambio aca es que hacemos que jugador herede de Persona

CREATE TABLE Jugador (  
    id_persona INT NOT NULL CONSTRAINT PK_Jugador PRIMARY KEY,
    nick              VARCHAR(30)  NOT NULL CONSTRAINT UQ_Jugador_nick UNIQUE,

    CONSTRAINT FK_Jugador_Persona FOREIGN KEY (id_persona) REFERENCES Persona(id_persona)
);

CREATE TABLE Equipo (
    id_equipo   INT IDENTITY(1,1) CONSTRAINT PK_Equipo PRIMARY KEY,
    id_manager INT NOT NULL CONSTRAINT FK_Equipo_Manager FOREIGN KEY REFERENCES Manager(id_persona),
    nombre      VARCHAR(60) NOT NULL CONSTRAINT UQ_Equipo_nombre UNIQUE,
    fecha_alta  DATE        NOT NULL CONSTRAINT DF_Equipo_fecha_alta DEFAULT (CAST(GETDATE() AS DATE))
);


CREATE TABLE Integrante_Equipo (
    id_integrante  INT IDENTITY(1,1) CONSTRAINT PK_Integrante_Equipo PRIMARY KEY,
    id_equipo      INT  NOT NULL CONSTRAINT FK_Integrante_Equipo_Equipo  FOREIGN KEY REFERENCES Equipo(id_equipo),
    id_jugador     INT  NOT NULL CONSTRAINT FK_Integrante_Equipo_Jugador FOREIGN KEY REFERENCES Jugador(id_persona),
    fecha_ingreso  DATE NOT NULL CONSTRAINT DF_Integrante_ingreso DEFAULT (CAST(GETDATE() AS DATE)),
    fecha_egreso   DATE NULL --esto para tener un historial mas detallado

    --CONSTRAINT UQ_Integrante_Jugador UNIQUE (id_jugador)

    --este constraint se elimina ahora pero luego con algun trigger se validara que el jugador no juegue ne dos equipos a la vez

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
    nro_llave             INT NOT NULL,   -- posici�n del cruce dentro de la fase
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
    id_mvp_jugador        INT NULL CONSTRAINT FK_Partido_MVP FOREIGN KEY REFERENCES Jugador(id_persona),

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
    id_jugador  INT NOT NULL CONSTRAINT FK_Alineacion_Jugador FOREIGN KEY REFERENCES Jugador(id_persona),
    -- se implementa kda
    kills INT NOT NULL CONSTRAINT DF_Alineacion_Kills DEFAULT(0),
    deaths INT NOT NULL CONSTRAINT DF_Alineacion_Deaths DEFAULT(0),
    assists INT NOT NULL CONSTRAINT DF_Alineacion_Assists DEFAULT(0),
    id_equipo   INT NOT NULL CONSTRAINT FK_Alineacion_Equipo  FOREIGN KEY REFERENCES Equipo(id_equipo),
    CONSTRAINT PK_Alineacion_Partido PRIMARY KEY (id_partido, id_jugador),
    CONSTRAINT CK_Alineacion_kda CHECK (kills >= 0 AND deaths >= 0 AND assists >= 0)
);


/* Premios efectivamente pagados (hecho historico como la presencia de Santos en las clases de BBDD) */

CREATE TABLE Pago_Premio (
    id_pago     INT IDENTITY(1,1) CONSTRAINT PK_Pago_Premio PRIMARY KEY,
    id_torneo   INT NOT NULL CONSTRAINT FK_Pago_Torneo  FOREIGN KEY REFERENCES Torneo(id_torneo),
    id_jugador  INT NOT NULL CONSTRAINT FK_Pago_Jugador FOREIGN KEY REFERENCES Jugador(id_persona),
    tipo        VARCHAR(12) NOT NULL,
    monto       DECIMAL(12,2) NOT NULL,
    fecha_pago  DATETIME2 NOT NULL CONSTRAINT DF_Pago_fecha DEFAULT (SYSDATETIME()),
    CONSTRAINT UQ_Pago UNIQUE (id_torneo, id_jugador, tipo),
    CONSTRAINT CK_Pago_tipo  CHECK (tipo IN ('1er puesto','2do puesto','MVP')),
    CONSTRAINT CK_Pago_monto CHECK (monto > 0)
);

CREATE TABLE Sancion (
    id_sancion INT IDENTITY(1,1) CONSTRAINT PK_Sancion PRIMARY KEY,
    id_jugador INT NOT NULL CONSTRAINT FK_Sancion_Jugador FOREIGN KEY REFERENCES Jugador(id_persona),
    motivo VARCHAR(250) NOT NULL,
    fecha_inicio DATE NOT NULL,
    fecha_fin DATE NOT NULL,

    CONSTRAINT CK_Fechas_Sancion CHECK (fecha_fin >= fecha_inicio)
);

-- Inserts de datos, se usaron datos de equipos, jugadores y demas que juegan lol

USE torneoEsportsBD1;
GO

INSERT INTO Juego (nombre, descripcion) 
VALUES ('League of Legends', 'MOBA 5v5 competitivo desarrollado por Riot Games');
GO

INSERT INTO Persona (dni, nombre, apellido, mail, fecha_nacimiento) VALUES 
('11111111', 'John', 'Needham', 'jneedham@riotgames.com', '1980-05-10'), 
('22222222', 'Jeong-gyun', 'Kim', 'kkoma@t1.gg', '1985-12-23'),         
('33333333', 'Dong-bin', 'Go', 'score@geng.gg', '1992-07-08'),          
('44444444', 'Romain', 'Bigeard', 'romain@g2esports.com', '1989-11-30'),
('55555550', 'Patrik', 'Sattermon', 'carn@fnatic.com', '1985-04-12'),
('55555555', 'Steve', 'Arhancet', 'steve@teamliquid.com', '1981-04-15'),
('99999999', 'Marc', 'Merrill', 'marc@riotgames.com', '1980-08-22'),
('66666661', 'Woo-je', 'Choi', 'zeus@t1.gg', '2004-01-31'),
('66666662', 'Hyeon-joon', 'Moon', 'oner@t1.gg', '2002-12-24'),
('66666663', 'Sang-hyeok', 'Lee', 'faker@t1.gg', '1996-05-07'),
('66666664', 'Min-hyeong', 'Lee', 'gumayusi@t1.gg', '2002-02-06'),
('66666665', 'Min-seok', 'Ryu', 'keria@t1.gg', '2002-10-14'),
('77777771', 'Hyeon-joon', 'Choi', 'doran@geng.gg', '2000-07-22'),
('77777772', 'Wang-ho', 'Han', 'peanut@geng.gg', '1998-02-03'),
('77777773', 'Ji-hoon', 'Jeong', 'chovy@geng.gg', '2001-03-03'),
('77777774', 'Su-hwan', 'Kim', 'peyz@geng.gg', '2005-12-05'),
('77777775', 'Hwan-joong', 'Yoo', 'delight@geng.gg', '2002-09-12'),
('88888881', 'Sergen', 'Celik', 'brokenblade@g2.com', '2000-01-19'),
('88888882', 'Martin', 'Sundelin', 'yike@g2.com', '2000-11-11'),
('88888883', 'Rasmus', 'Winther', 'caps@g2.com', '1999-11-17'),
('88888884', 'Steven', 'Liv', 'hanssama@g2.com', '1999-09-02'),
('88888885', 'Mihael', 'Mehle', 'mikyx@g2.com', '1998-11-02'),
('98888881', 'Oscar', 'Munoz', 'oscarinin@fnatic.com', '2003-05-15'),
('98888882', 'Ivan', 'Martin', 'razork@fnatic.com', '2000-10-07'),
('98888883', 'Marek', 'Brazda', 'humanoid@fnatic.com', '2000-03-14'),
('98888884', 'Oh', 'Taek', 'noah@fnatic.com', '2001-10-04'),
('98888885', 'Yoon', 'Se-jun', 'jun@fnatic.com', '2000-08-20');
GO

INSERT INTO Organizador (id_persona) VALUES (1);
GO

INSERT INTO Manager (id_persona) VALUES (2), (3), (4), (5), (6);
GO

INSERT INTO Arbitro (id_persona) VALUES (7);
GO

INSERT INTO Jugador (id_persona, nick) VALUES 
(8, 'Zeus'), (9, 'Oner'), (10, 'Faker'), (11, 'Gumayusi'), (12, 'Keria'),
(13, 'Doran'), (14, 'Peanut'), (15, 'Chovy'), (16, 'Peyz'), (17, 'Delight'),
(18, 'BrokenBlade'), (19, 'Yike'), (20, 'Caps'), (21, 'Hans Sama'), (22, 'Mikyx'),
(23, 'Oscarinin'), (24, 'Razork'), (25, 'Humanoid'), (26, 'Noah'), (27, 'Jun');
GO

INSERT INTO Equipo (id_manager, nombre, fecha_alta) VALUES 
(2, 'T1', CAST(GETDATE() AS DATE)),
(3, 'Gen.G', CAST(GETDATE() AS DATE)),
(4, 'G2 Esports', CAST(GETDATE() AS DATE)),
(5, 'Fnatic', CAST(GETDATE() AS DATE)),
(6, 'Team Liquid', DATEADD(DAY, -75, GETDATE())); 
GO

INSERT INTO Integrante_Equipo (id_equipo, id_jugador) VALUES 
(1, 8), (1, 9), (1, 10), (1, 11), (1, 12),
(2, 13), (2, 14), (2, 15), (2, 16), (2, 17),
(3, 18), (3, 19), (3, 20), (3, 21), (3, 22),
(4, 23), (4, 24), (4, 25), (4, 26), (4, 27);
GO

INSERT INTO Torneo (id_juego, id_organizador, nombre, fecha_inicio, cantidad_equipos, premio_base, estado) 
VALUES 
(1, 1, 'Worlds 2023 - Main Event', '2023-10-10', 8, 2000000.00, 'Finalizado'),
(1, 1, 'MSI 2024 - Bracket Stage', '2024-05-01', 8, 500000.00, 'En curso'),
(1, 1, 'Esports World Cup 2024', '2024-07-01', 8, 250000.00, 'Inscripcion');
GO

INSERT INTO Inscripcion (id_torneo, id_equipo, estado) VALUES 
(1, 1, 'Activo'), (1, 2, 'Activo'), (1, 3, 'Activo'), (1, 4, 'Activo'),
(2, 1, 'Activo'), (2, 2, 'Activo'), (2, 4, 'Activo'),
(3, 2, 'Activo'), (3, 3, 'Activo'), (3, 4, 'Activo');
GO

INSERT INTO Partido (id_torneo, nro_fase, nro_llave, id_arbitro, id_equipo_a, id_equipo_b, estado, puntaje_a, puntaje_b, id_mvp_jugador)
VALUES 
(1, 1, 1, 7, 1, 2, 'Jugado', 16, 12, 10), 
(1, 1, 2, 7, 3, 4, 'Jugado', 16, 10, 20), 
(1, 2, 1, 7, 1, 3, 'Jugado', 16, 14, 10), 
(2, 1, 1, 7, 1, 2, 'Jugado', 14, 16, 15),
(2, 1, 2, 7, 4, NULL, 'Pendiente', NULL, NULL, NULL); 
GO

INSERT INTO Alineacion_Partido (id_partido, id_jugador, kills, deaths, assists, id_equipo) VALUES 
(1, 8, 2, 4, 10, 1), (1, 9, 5, 3, 15, 1), (1, 10, 12, 1, 8, 1), (1, 11, 10, 2, 6, 1), (1, 12, 1, 2, 22, 1), 
(1, 13, 2, 6, 4, 2), (1, 14, 3, 5, 8, 2), (1, 15, 9, 3, 5, 2), (1, 16, 4, 7, 3, 2), (1, 17, 0, 9, 12, 2),
(2, 18, 6, 2, 5, 3), (2, 19, 4, 3, 10, 3), (2, 20, 15, 1, 6, 3), (2, 21, 8, 2, 7, 3), (2, 22, 1, 2, 18, 3),
(2, 23, 2, 8, 3, 4), (2, 24, 3, 6, 5, 4), (2, 25, 4, 5, 4, 4), (2, 26, 1, 9, 2, 4), (2, 27, 0, 6, 8, 4),
(3, 8, 4, 3, 8, 1), (3, 9, 6, 4, 12, 1), (3, 10, 14, 2, 9, 1), (3, 11, 8, 3, 7, 1), (3, 12, 2, 1, 18, 1),
(3, 18, 3, 7, 5, 3), (3, 19, 4, 6, 7, 3), (3, 20, 10, 4, 4, 3), (3, 21, 5, 8, 6, 3), (3, 22, 1, 9, 15, 3),
(4, 8, 1, 6, 4, 1), (4, 9, 3, 5, 2, 1), (4, 10, 5, 4, 3, 1), (4, 11, 4, 3, 1, 1), (4, 12, 1, 4, 8, 1),
(4, 13, 5, 2, 7, 2), (4, 14, 4, 1, 12, 2), (4, 15, 11, 2, 6, 2), (4, 16, 7, 1, 5, 2), (4, 17, 0, 2, 16, 2);
GO

INSERT INTO Sancion (id_jugador, motivo, fecha_inicio, fecha_fin)
VALUES (14, 'Comportamiento antideportivo en stage', DATEADD(DAY, -5, GETDATE()), DATEADD(DAY, 10, GETDATE()));
GO





--Consultas SQL

--1. Consultamos el jugador con mas cantidad de kills de un determinado equipo y los ordenamos de mayor a menor
SELECT
    J.nick AS Nickname,
    P.nombre AS Nombre,
    P.apellido AS Apellido,
    E.nombre AS Equipo_actual,
    SUM(AP.kills) AS Total_kills,
    SUM(AP.deaths) AS Total_deaths,
    SUM(AP.assists) AS Total_assits
FROM Persona P
INNER JOIN Jugador J ON P.id_persona = J.id_persona
INNER JOIN Integrante_Equipo IE ON J.id_persona = IE.id_jugador
INNER JOIN Equipo E ON IE.id_equipo = E.id_equipo
INNER JOIN Alineacion_Partido AP ON J.id_persona = AP.id_jugador
WHERE
    E.nombre = 'T1'
    AND IE.fecha_egreso IS NULL
GROUP BY
    J.nick, P.nombre, P.apellido, E.nombre
HAVING
    SUM(AP.kills) > 0
ORDER BY
    Total_kills DESC
GO

--2. Consultamos el mvp del torneo, esto se calcula de la sig manera: el jugador con mayor mvps acumulados en todos los partidos
--es quien ganará el premio mvp del torneo

SELECT TOP 1
    T.nombre AS Torneo,
    J.nick AS Nickname,
    CONCAT(P.nombre,' ', P.apellido) AS Nombre_completo,
    COUNT(Pa.id_partido) AS Cantidad_MVP
FROM Partido Pa
INNER JOIN Torneo T ON Pa.id_torneo = T.id_torneo
INNER JOIN Jugador J ON Pa.id_mvp_jugador = J.id_persona
INNER JOIN Persona P ON J.id_persona = P.id_persona
WHERE
    T.estado = 'Finalizado'
    AND Pa.id_mvp_jugador IS NOT NULL
GROUP BY
    T.nombre, J.nick, P.nombre, P.apellido
ORDER BY
    Cantidad_MVP DESC;
GO


--Consultas con subconsultas

/*1. Consultamos los jugadores inscriptos en el torneo que cuenten con alguna sancion
esto con la finalidad de que el organizador del evento pueda auditar y comprobar que
los equipos que van a disputar la siguiente partida no posea ninguna sancion vigente*/

--la logica para que esto nunca pase se hará en sp o triggers

SELECT
    T.nombre AS Torneo_activo,
    E.nombre AS Equipo_que_infringe,
    J.nick AS Jugador_con_sancion,
    CONCAT(P.nombre, ' ', P.apellido) AS Nombre_Jugador_Con_Sancion
FROM Torneo T
INNER JOIN Inscripcion I ON T.id_torneo = I.id_torneo
Inner Join Equipo E ON I.id_equipo = E.id_equipo
INNER JOIN Integrante_Equipo IE ON E.id_equipo = IE.id_equipo
INNER JOIN Jugador J ON IE.id_jugador = J.id_persona
INNER JOIN Persona P ON J.id_persona = P.id_persona
WHERE
    T.estado IN ('Inscripcion', 'En curso')
    AND IE.fecha_egreso IS NULL
    AND J.id_persona IN(
        --en esta subconsulta buscamos si el jugador tiene alguna sancion al momento
        SELECT id_jugador
        FROM Sancion
        WHERE CAST(GETDATE() AS DATE) BETWEEN fecha_inicio AND fecha_fin
    );
GO

/*2. Consultamos los equipos que llevan al menos 60 dias inactivos con la idea de borrarlos de la bd, 
esto para asegurarnos de que la base de datos no acumule equipos 
El equipo que tenga mas de 60 dias de participar de algun torneo es considerado equipo fantasma y deberia borrarse*/

SELECT
    E.nombre AS Equipo_inactivo,
    E.fecha_alta,
    CONCAT(P.nombre, ' ', P.apellido) AS Nombre_Manager,
    P.mail AS Mail_manager
FROM Equipo E
INNER JOIN Manager M ON E.id_manager = M.id_persona
INNER JOIN Persona P ON M.id_persona = P.id_persona
WHERE
    E.id_equipo NOT IN(
        SELECT DISTINCT id_equipo
        FROM Inscripcion
    )
    AND DATEDIFF(DAY, E.fecha_alta, GETDATE()) > 60;
GO