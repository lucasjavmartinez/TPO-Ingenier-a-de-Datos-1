-- Inserts de datos, se usaron datos de equipos, jugadores y demas que juegan lol

USE torneoEsportsBD1;
GO

INSERT INTO Juego (nombre, descripcion) 
VALUES ('League of Legends', 'MOBA 5v5 competitivo desarrollado por Riot Games');
GO

--organizador
EXEC sp_insertPersonal '11111111', 'John', 'Needham', 'jneedham@riotgames.com', '1980-05-10', 'Organizador';
GO

-- managers
EXEC sp_insertPersonal '22222222', 'Jeong-gyun', 'Kim', 'kkoma@t1.gg', '1985-12-23', 'Manager';
EXEC sp_insertPersonal '33333333', 'Dong-bin', 'Go', 'score@geng.gg', '1992-07-08', 'Manager';
EXEC sp_insertPersonal '44444444', 'Romain', 'Bigeard', 'romain@g2esports.com', '1989-11-30', 'Manager';
EXEC sp_insertPersonal '55555550', 'Patrik', 'Sattermon', 'carn@fnatic.com', '1985-04-12', 'Manager';
EXEC sp_insertPersonal '55555555', 'Steve', 'Arhancet', 'steve@teamliquid.com', '1981-04-15', 'Manager';
GO

--arbitro
EXEC sp_insertPersonal '99999999', 'Marc', 'Merrill', 'marc@riotgames.com', '1980-08-22', 'Arbitro';
GO

--jugadores t1
EXEC sp_insertarJugador '66666661', 'Woo-je', 'Choi', 'zeus@t1.gg', '2004-01-31', 'Zeus';
EXEC sp_insertarJugador '66666662', 'Hyeon-joon', 'Moon', 'oner@t1.gg', '2002-12-24', 'Oner';
EXEC sp_insertarJugador '66666663', 'Sang-hyeok', 'Lee', 'faker@t1.gg', '1996-05-07', 'Faker';
EXEC sp_insertarJugador '66666664', 'Min-hyeong', 'Lee', 'gumayusi@t1.gg', '2002-02-06', 'Gumayusi';
EXEC sp_insertarJugador '66666665', 'Min-seok', 'Ryu', 'keria@t1.gg', '2002-10-14', 'Keria';

--jugadores geng
EXEC sp_insertarJugador '77777771', 'Hyeon-joon', 'Choi', 'doran@geng.gg', '2000-07-22', 'Doran';
EXEC sp_insertarJugador '77777772', 'Wang-ho', 'Han', 'peanut@geng.gg', '1998-02-03', 'Peanut';
EXEC sp_insertarJugador '77777773', 'Ji-hoon', 'Jeong', 'chovy@geng.gg', '2001-03-03', 'Chovy';
EXEC sp_insertarJugador '77777774', 'Su-hwan', 'Kim', 'peyz@geng.gg', '2005-12-05', 'Peyz';
EXEC sp_insertarJugador '77777775', 'Hwan-joong', 'Yoo', 'delight@geng.gg', '2002-09-12', 'Delight';

--jugadores g2
EXEC sp_insertarJugador '88888881', 'Sergen', 'Celik', 'brokenblade@g2.com', '2000-01-19', 'BrokenBlade';
EXEC sp_insertarJugador '88888882', 'Martin', 'Sundelin', 'yike@g2.com', '2000-11-11', 'Yike';
EXEC sp_insertarJugador '88888883', 'Rasmus', 'Winther', 'caps@g2.com', '1999-11-17', 'Caps';
EXEC sp_insertarJugador '88888884', 'Steven', 'Liv', 'hanssama@g2.com', '1999-09-02', 'Hans Sama';
EXEC sp_insertarJugador '88888885', 'Mihael', 'Mehle', 'mikyx@g2.com', '1998-11-02', 'Mikyx';

--jugadores fnatic
EXEC sp_insertarJugador '98888881', 'Oscar', 'Munoz', 'oscarinin@fnatic.com', '2003-05-15', 'Oscarinin';
EXEC sp_insertarJugador '98888882', 'Ivan', 'Martin', 'razork@fnatic.com', '2000-10-07', 'Razork';
EXEC sp_insertarJugador '98888883', 'Marek', 'Brazda', 'humanoid@fnatic.com', '2000-03-14', 'Humanoid';
EXEC sp_insertarJugador '98888884', 'Oh', 'Taek', 'noah@fnatic.com', '2001-10-04', 'Noah';
EXEC sp_insertarJugador '98888885', 'Yoon', 'Se-jun', 'jun@fnatic.com', '2000-08-20', 'Jun';
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