drop table rezervare;
drop table angajat;
drop table sesiune;
drop table client;
drop table defectiuni;
drop table periferice;
drop table statie;
drop table sala;

create table angajat
(
CNP varchar2(13) not null 
    constraint cnp13 check(length(cnp)=13)
    constraint CNP1 check(substr(cnp, 1, 1) in ('1', '2', '5', '6'))
    constraint pk_angajat primary key,
data_angajare date not null,
nume varchar2(20) not null,
prenume varchar2(50),
email varchar2(35) unique not null,
numar_telefon varchar2(20)
    constraint vf_mobil_angajat
    check(numar_telefon like '07%' and length(numar_telefon) = 10),
salariu number(8, 2) not null
    constraint vf_salariu
    check(salariu>0),
schimb_munca varchar2(6) default 'zi' not null
    constraint vf_schimb_munca
    check(schimb_munca in ('zi', 'noapte'))
);

create table sesiune
(
id_sesiune number(10, 0) not null
    constraint pk_sesiune primary key,
pret_ora number(3, 0) not null
    constraint vf_pret
    check(pret_ora>0),
data_si_ora date not null,
durata number(2, 0) not null,
id_statie number(4, 0) not null,
    constraint fk_sesiune_statie 
    foreign key (id_statie)
    references statie(id_statie)
    on delete cascade,
cod_client number(10, 0) not null,
    constraint fk_sesiune_client
    foreign key (cod_client)
    references client(cod_client)
    on delete cascade
);

create table statie
(
id_statie number(4, 0) not null
    constraint vf_id_statie
    check(id_statie>0)
    constraint pk_statie primary key,
nume_statie varchar2(20),
sistem_operare varchar2(15) default 'windows11' not null
    constraint vf_sistem_operare
    check (sistem_operare in ('windows10', 'windows11', 'linux', 'FreeBSD', 'Xbox OS')),
grad_performanta number(1)
    constraint vf_grad_performanta
    check (grad_performanta in (1, 2, 3, 4, 5)),
nr_sala number(2, 0) not null,
    constraint fk_statie_sala
    foreign key (nr_sala)
    references sala(nr_sala)
    on delete cascade
);

create table client
(
cod_client number(10, 0) not null
    constraint vf_cod_client
    check(cod_client>0)
    constraint pk_client primary key,
numar_telefon varchar2(20)
    constraint vf_mobil_client
    check(numar_telefon like '07%'),
nume varchar2(20) not null,
prenume varchar2(50)
);

create table defectiuni
(
id_defectiune number(3, 0) not null
    constraint vf_id_defectiune
    check(id_defectiune>0)
    constraint pk_defectiuni primary key,
data_constatare date not null,
data_rezolvare date,
status number(1, 0) not null
    constraint vf_status_defectiuni
    check (status in (0, 1, 2)),
prioritate number(1, 0) not null
    constraint vf_prioritate
    check (prioritate in (0, 1)),
id_statie number(4, 0) not null,
    constraint fk_defectiune_statie
    foreign key (id_statie)
    references statie(id_statie)
    on delete cascade,
constraint vf_data_rezolvare
    check (data_rezolvare is null or data_rezolvare >= data_constatare)
);

create table periferice
(
id_periferice number(3, 0) not null 
    constraint vf_id_periferice
    check(id_periferice>0)
    constraint pk_periferice primary key,
tip_periferic varchar2(20) not null,
data_achizitie date,
id_statie number(4, 0) not null,
    constraint fk_periferice_statie
    foreign key (id_statie)
    references statie(id_statie)
    on delete cascade
);

create table sala
(
nr_sala number(2, 0) not null
    constraint vf_nr_sala
    check (nr_sala>0)
    constraint pk_sala primary key,
nume_sala varchar2(30),
status number(1) not null
    constraint vf_status_sala
    check(status in (0, 1)),
tip_scaune varchar2(20),
tip_decor_ambiant varchar2(50)
);

create table rezervare
(
CNP varchar2(13) not null, 
    constraint fk_rezervare_angajat
    foreign key (CNP)
    references angajat(CNP)
    on delete cascade,
id_sesiune number(10, 0) not null,
    constraint fk_rezervare_sesiune
    foreign key (id_sesiune)
    references sesiune(id_sesiune)
    on delete cascade,
primary key (CNP, id_sesiune),
tip_plata char(4) not null
    constraint vf_tip_plata
    check(tip_plata in ('cash', 'card')),
status number(1, 0) not null
);

create or replace view vizualizare_compusa as
select p.id_periferice, p.tip_periferic, p.id_statie, st.sistem_operare, st.nume_statie, st.nr_sala
from periferice p
left join statie st on p.id_statie = st.id_statie;

create or replace view vizualizare_complexa as
select cod_client, avg(pret_ora * durata) Cheltuieli_medii
from sesiune
group by cod_client;

create or replace trigger trg_check_suprapuneri_sesiuni
before insert on sesiune
for each row
declare
    v_count number;
begin
    select count(*)
    into v_count
    from sesiune
    where id_statie = :new.id_statie
      and (
          (:new.data_si_ora < data_si_ora + interval '1' hour * durata)
          and (data_si_ora < :new.data_si_ora + interval '1' hour * :new.durata)
      );

    if v_count > 0 then
        raise_application_error(-20000, 'Intervalul de sesiune se suprapune cu o sesiune existenta la statia specificata');
    end if;
end;

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (1, 'inferno', 1, 'fotoliu', 'cs2');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (2, 'summoners_rift', 1, 'ergonomic', 'lol');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (3, 'haven', 1, 'curse', 'valorant');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (4, 'verdansk', 0, 'gaming', 'cod');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (5, 'tilted_towers', 1, 'clasic', 'fortnite');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (6, 'ascent', 1, 'fotoliu', 'valorant');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (7, 'end_city', 0, 'pivotant', 'minecraft');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (8, 'jungle', 1, 'directorial', 'lol');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (9, 'paradise', 1, 'ergonomic', 'fortnite');

insert into sala (nr_sala, nume_sala, status, tip_scaune, tip_decor_ambiant)
values (10, 'nuketown', 1, 'minimalist', 'cod');

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (1, 'Statie_1', 'windows11', 5, 1);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (2, 'Statie_2', 'linux', 4, 1);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (3, 'Statie_3', 'windows10', 3, 1);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (4, 'Statie_4', 'linux', 2, 2);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (5, 'Statie_5', 'windows11', 1, 2);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (6, 'Statie_6', 'linux', 5, 2);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (7, 'Statie_7', 'Xbox OS', 4, 3);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (8, 'Statie_8', 'FreeBSD', 3, 3);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (9, 'Statie_9', 'windows10', 2, 3);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (10, 'Statie_10', 'windows11', 1, 4);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (11, 'Statie_11', 'linux', 5, 4);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (12, 'Statie_12', 'windows11', 4, 4);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (13, 'Statie_13', 'FreeBSD', 3, 5);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (14, 'Statie_14', 'Xbox OS', 2, 5);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (15, 'Statie_15', 'linux', 1, 5);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (16, 'Statie_16', 'windows10', 5, 6);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (17, 'Statie_17', 'windows11', 4, 6);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (18, 'Statie_18', 'FreeBSD', 3, 6);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (19, 'Statie_19', 'Xbox OS', 2, 7);

insert into statie (id_statie, nume_statie, sistem_operare, grad_performanta, nr_sala)
values (20, 'Statie_20', 'linux', 1, 7);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (1, 'Tastatura', to_date('2023-01-15', 'yyyy-mm-dd'), 1);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (2, 'Mouse', to_date('2023-02-10', 'yyyy-mm-dd'), 2);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (3, 'Monitor', to_date('2022-11-20', 'yyyy-mm-dd'), 3);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (4, 'Casti', to_date('2021-12-05', 'yyyy-mm-dd'), 4);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (5, 'Tastatura', to_date('2022-10-01', 'yyyy-mm-dd'), 5);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (6, 'Mouse', to_date('2023-03-25', 'yyyy-mm-dd'), 6);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (7, 'Monitor', to_date('2022-09-15', 'yyyy-mm-dd'), 7);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (8, 'Casti', to_date('2021-11-30', 'yyyy-mm-dd'), 8);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (9, 'Tastatura', to_date('2023-04-10', 'yyyy-mm-dd'), 9);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (10, 'Mouse', to_date('2022-08-20', 'yyyy-mm-dd'), 10);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (11, 'Monitor', to_date('2023-05-15', 'yyyy-mm-dd'), 11);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (12, 'Casti', to_date('2022-07-05', 'yyyy-mm-dd'), 12);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (13, 'Tastatura', to_date('2021-10-01', 'yyyy-mm-dd'), 13);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (14, 'Mouse', to_date('2022-06-15', 'yyyy-mm-dd'), 14);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (15, 'Monitor', to_date('2021-09-25', 'yyyy-mm-dd'), 15);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (16, 'Casti', to_date('2023-07-20', 'yyyy-mm-dd'), 16);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (17, 'Tastatura', to_date('2022-05-10', 'yyyy-mm-dd'), 17);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (18, 'Mouse', to_date('2021-08-01', 'yyyy-mm-dd'), 18);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (19, 'Monitor', to_date('2023-09-15', 'yyyy-mm-dd'), 19);

insert into periferice (id_periferice, tip_periferic, data_achizitie, id_statie)
values (20, 'Casti', to_date('2022-04-25', 'yyyy-mm-dd'), 20);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (1, to_date('2025-01-01', 'YYYY-MM-DD'), to_date('2025-01-05', 'YYYY-MM-DD'), 1, 0, 1);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (2, to_date('2025-01-02', 'YYYY-MM-DD'), 1, 1, 2);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (3, to_date('2025-01-03', 'YYYY-MM-DD'), 0, 0, 3);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (4, to_date('2025-01-04', 'YYYY-MM-DD'), to_date('2025-01-08', 'YYYY-MM-DD'), 2, 0, 4);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (5, to_date('2025-01-05', 'YYYY-MM-DD'), to_date('2025-01-09', 'YYYY-MM-DD'), 1, 1, 5);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (6, to_date('2025-01-06', 'YYYY-MM-DD'), 2, 1, 6);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie)
values (7, to_date('2025-01-07', 'YYYY-MM-DD'), 1, 0, 7);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (8, to_date('2025-01-08', 'YYYY-MM-DD'), to_date('2025-01-12', 'YYYY-MM-DD'), 1, 1, 8);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (9, to_date('2025-01-09', 'YYYY-MM-DD'), 0, 0, 9);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (10, to_date('2025-01-10', 'YYYY-MM-DD'), to_date('2025-01-14', 'YYYY-MM-DD'), 2, 0, 10);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (11, to_date('2025-01-11', 'YYYY-MM-DD'), 1, 0, 11);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (12, to_date('2025-01-12', 'YYYY-MM-DD'), to_date('2025-01-16', 'YYYY-MM-DD'), 1, 1, 12);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (13, to_date('2025-01-13', 'YYYY-MM-DD'), 0, 0, 13);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (14, to_date('2025-01-14', 'YYYY-MM-DD'), to_date('2025-01-18', 'YYYY-MM-DD'), 2, 0, 14);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (15, to_date('2025-01-15', 'YYYY-MM-DD'), 1, 1, 15);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (16, to_date('2025-01-16', 'YYYY-MM-DD'), 2, 1, 16);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (17, to_date('2025-01-17', 'YYYY-MM-DD'), to_date('2025-01-21', 'YYYY-MM-DD'), 1, 0, 17);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (18, to_date('2025-01-18', 'YYYY-MM-DD'), to_date('2025-01-22', 'YYYY-MM-DD'), 1, 1, 18);

insert into defectiuni (id_defectiune, data_constatare, status, prioritate, id_statie) 
values (19, to_date('2025-01-19', 'YYYY-MM-DD'), 0, 0, 19);

insert into defectiuni (id_defectiune, data_constatare, data_rezolvare, status, prioritate, id_statie) 
values (20, to_date('2025-01-20', 'YYYY-MM-DD'), to_date('2025-01-24', 'YYYY-MM-DD'), 2, 0, 20);

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1970101234567', to_date('2020-01-01', 'YYYY-MM-DD'), 'Popescu', 'Ion', 'ion.popescu@example.com', '0712345678', 3000.50, 'zi');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('2960702345678', to_date('2021-03-15', 'YYYY-MM-DD'), 'Ionescu', 'Maria', 'maria.ionescu@example.com', '0723456789', 2500.00, 'noapte');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1970803456789', to_date('2022-06-20', 'YYYY-MM-DD'), 'Georgescu', 'Vasile', 'vasile.georgescu@example.com', '0734567890', 3500.75, 'zi');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1760904567890', to_date('2019-10-10', 'YYYY-MM-DD'), 'Marinescu', 'Anca', 'anca.marinescu@example.com', '0745678901', 2800.60, 'noapte');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('2960305678901', to_date('2020-07-01', 'YYYY-MM-DD'), 'Constantinescu', 'Paul', 'paul.constantinescu@example.com', '0756789012', 3100.40, 'zi');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1970102345678', to_date('2018-02-01', 'YYYY-MM-DD'), 'Dumitrescu', 'Elena', 'elena.dumitrescu@example.com', '0767890123', 3200.80, 'zi');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('2960506789012', to_date('2021-08-25', 'YYYY-MM-DD'), 'Petrescu', 'Andrei', 'andrei.petrescu@example.com', '0778901234', 2900.90, 'noapte');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1970803456781', to_date('2022-05-30', 'YYYY-MM-DD'), 'Popa', 'Larisa', 'larisa.popa@example.com', '0789012345', 3300.00, 'zi');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('2960407890123', to_date('2023-01-15', 'YYYY-MM-DD'), 'Nistor', 'Lucian', 'lucian.nistor@example.com', '0790123456', 2750.50, 'noapte');

insert into angajat (CNP, data_angajare, nume, prenume, email, numar_telefon, salariu, schimb_munca) 
values ('1760608901234', to_date('2021-11-12', 'YYYY-MM-DD'), 'Stanciu', 'Roxana', 'roxana.stanciu@example.com', '0701234567', 3000.00, 'zi');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (1, '0712345678', 'Popescu', 'Ion');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (2, '0723456789', 'Ionescu', 'Maria');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (3, '0734567890', 'Georgescu', 'Vasile');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (4, '0745678901', 'Marinescu', 'Anca');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (5, '0756789012', 'Constantinescu', 'Paul');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (6, '0767890123', 'Dumitrescu', 'Elena');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (7, '0778901234', 'Petrescu', 'Andrei');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (8, '0789012345', 'Popa', 'Larisa');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (9, '0790123456', 'Nistor', 'Lucian');

insert into client (cod_client, numar_telefon, nume, prenume) 
values (10, '0701234567', 'Stanciu', 'Roxana');

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (1, 15, to_date('2025-01-02 10:00', 'YYYY-MM-DD HH24:MI'), 2, 1, 1);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (2, 20, to_date('2025-01-02 12:00', 'YYYY-MM-DD HH24:MI'), 3, 2, 2);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (3, 25, to_date('2025-01-02 14:00', 'YYYY-MM-DD HH24:MI'), 1, 3, 3);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (4, 18, to_date('2025-01-02 16:00', 'YYYY-MM-DD HH24:MI'), 2, 4, 4);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (5, 22, to_date('2025-01-02 18:00', 'YYYY-MM-DD HH24:MI'), 2, 5, 5);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (6, 30, to_date('2025-01-03 08:00', 'YYYY-MM-DD HH24:MI'), 4, 6, 6);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (7, 35, to_date('2025-01-03 12:00', 'YYYY-MM-DD HH24:MI'), 1, 7, 7);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (8, 28, to_date('2025-01-03 13:00', 'YYYY-MM-DD HH24:MI'), 3, 8, 8);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (9, 16, to_date('2025-01-03 16:00', 'YYYY-MM-DD HH24:MI'), 2, 9, 9);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (10, 19, to_date('2025-01-03 18:00', 'YYYY-MM-DD HH24:MI'), 4, 10, 10);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (11, 24, to_date('2025-01-04 08:00', 'YYYY-MM-DD HH24:MI'), 2, 11, 1);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (12, 21, to_date('2025-01-04 10:00', 'YYYY-MM-DD HH24:MI'), 3, 12, 2);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (13, 17, to_date('2025-01-04 13:00', 'YYYY-MM-DD HH24:MI'), 1, 13, 3);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (14, 29, to_date('2025-01-04 14:00', 'YYYY-MM-DD HH24:MI'), 4, 14, 4);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (15, 23, to_date('2025-01-04 18:00', 'YYYY-MM-DD HH24:MI'), 2, 15, 5);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (16, 31, to_date('2025-01-05 08:00', 'YYYY-MM-DD HH24:MI'), 3, 16, 6);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (17, 26, to_date('2025-01-05 11:00', 'YYYY-MM-DD HH24:MI'), 2, 17, 7);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (18, 20, to_date('2025-01-05 13:00', 'YYYY-MM-DD HH24:MI'), 1, 18, 8);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (19, 22, to_date('2025-01-05 15:00', 'YYYY-MM-DD HH24:MI'), 4, 19, 9);

insert into sesiune (id_sesiune, pret_ora, data_si_ora, durata, id_statie, cod_client) 
values (20, 18, to_date('2025-01-05 17:00', 'YYYY-MM-DD HH24:MI'), 2, 20, 10);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970101234567', 1, 'cash', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960702345678', 2, 'card', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970803456789', 3, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1760904567890', 4, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960305678901', 5, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970102345678', 6, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960506789012', 7, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970803456781', 8, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960407890123', 9, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1760608901234', 10, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970101234567', 11, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960702345678', 12, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970803456789', 13, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1760904567890', 14, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960305678901', 15, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970102345678', 16, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960506789012', 17, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1970803456781', 18, 'card', 0);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('2960407890123', 19, 'cash', 1);

insert into rezervare (CNP, id_sesiune, tip_plata, status) 
values ('1760608901234', 20, 'card', 0);

commit;
