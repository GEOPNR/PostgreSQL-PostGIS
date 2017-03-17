-- Exemples de commandes SQL pour POSTGIS/POSTGRESQL :
-- voici un document permettant à chacun de proposer des exemples de requêtes SQL pour POSTGIS : merci de documenter les codes pour que ceux-ci soient réutilisables par les autres
-- exemple 1 : copier une table postgis vers une autre table postgis, ici des données d’une commune identifiée par son code insee
-- par Pascal LAMBERT, PNR Oise pays de france

/* REINTRODUCTION des données d’une commune DE LA TABLE GEO_P vers LA TABLE GEO_T */
/* changer le code insee 60589 par le bon code insee*/
/* ****************************************** */

INSERT INTO
        mon_schema.ma_table_t
        (
        idzone,
        libelle,
        libelong,
        typezone,
        destdomi,
        l_observ,
        nomfic,
        urlfic,
        insee,
        datvalid,
        geom
        )
    (
    SELECT
        mon_schema.ma_table_p.idzone,
       mon_schema.ma_table_p.libelle,
        mon_schema.ma_table_p.libelong,
        mon_schema.ma_table_p.typezone,
        mon_schema.ma_table_p.destdomi,
       mon_schema.ma_table_p.l_observ,
        mon_schema.ma_table_p.nomfic,
        mon_schema.ma_table_p.urlfic,
        mon_schema.ma_table_p.insee,
        mon_schema.ma_table_p.datvalid,
        mon_schema.ma_table_p.geom
    FROM
       mon_schema.ma_table_p
    WHERE
       ma_table_p.insee = '60589');

exemple 2 :Importer/Exporter des données SICEN
par Renaud LAIRE, PNR Livradois-Forez. 3 Scripts pour importer ou exporter des données SICEN entre deux bases SICEN différentes. On s’en sert pour échanger des données avec le CEN Auvergne. L’import se déroule en 2 etape (preparation_import.sql puis import.sql). Il faut au préalable créer le shema “export”. Depuis ma collegue à developpé une interface pour faire la même chose à la souris … c est plus fun mais ca fait moins Matrix ...

Script 1 : Export.sql

CREATE OR REPLACE FUNCTION export.export(
    nom_export text,
    repertoire text,
    id_etude integer)
  RETURNS text AS
$BODY$
DECLARE

sql text;

BEGIN
-- Etudes

sql ='COPY(    Select etude.* 
    from md.etude where id_etude = '||id_etude||'
    )TO '||quote_literal(repertoire||nom_export||'_etudes_a_importer.csv')||'  DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

EXECUTE sql;

-- protocoles concernés
sql='COPY(    select distinct(protocole.*)
    from md.protocole
    INNER JOIN saisie.saisie_observation
    ON (protocole.id_protocole = saisie_observation.id_protocole)
    where saisie.saisie_observation.id_etude = '||id_etude||'
)TO '||quote_literal(repertoire||nom_export||'_protocoles_a_importer.csv')||' DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';
EXECUTE sql;
-- personnes concernés par l'étude
sql='COPY(
    select (personne.*)
    from md.personne
    INNER JOIN saisie.saisie_observation
    ON (personne.id_personne ::int in (SELECT regexp_split_to_table(observateur,'||quote_literal('&')||')::integer as id_personne FROM saisie.saisie_observation  ))
    where saisie.saisie_observation.id_etude = 
    '||id_etude||'
GROUP BY personne.id_personne )TO '||quote_literal(repertoire||nom_export||'_observateurs_a_importer.csv')||' DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';
EXECUTE sql;

-- Structures concernées par l'étude
sql ='COPY (    select distinct(structure.*)
    from md.structure
    INNER JOIN saisie.saisie_observation
    ON (structure.id_structure::text = saisie_observation.structure)
    where saisie.saisie_observation.id_etude =  '||id_etude||'
)TO '||quote_literal(repertoire||nom_export||'_structures_a_importer.csv')||' DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';
EXECUTE sql;
-- exporter les observations
sql = 'COPY (    select * 
    from saisie.saisie_observation 
    where id_etude = '||id_etude||'
)TO '||quote_literal(repertoire||nom_export||'_observations_a_importer.csv')||' DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';
EXECUTE sql;

RETURN NULL;
        END;}


-- Script 2 : preparation_import.sql


CREATE OR REPLACE FUNCTION export.preparation_et_import()
  RETURNS text AS
$BODY$
DECLARE
result text := 'test';
searchsql text := '';
sqlajout text;
id_personne_import int;
id_personne_local int;
var_email text;
var_import int;
var_local int;
var_link text;
var_link_protocole text;
sql text;
rec record;
rec0 record;
test_courriel text;
var_role_import text;

BEGIN

-- Import des Etudes --------------------------------------------

searchsql = 'SELECT 
  etudes_a_importer.id_etude as import, 
  etude.id_etude as local,
  etudes_a_importer.nom_etude as link
  FROM 
  export.etudes_a_importer
  LEFT JOIN  md.etude
ON 
  etudes_a_importer.nom_etude = etude.nom_etude';
  
  EXECUTE searchsql;

 FOR rec IN EXECUTE(searchsql) LOOP
    var_import:= rec.import;
    var_local:= rec.local;
    var_link:=rec.link;
    
    IF (var_local IS NULL) THEN
        
            sql = 'INSERT INTO md.etude (nom_etude, cahier_des_charges, date_debut, date_fin, description)
            select nom_etude, cahier_des_charges, date_debut, date_fin, description From export.etudes_a_importer 
            Where etudes_a_importer.id_etude =' || var_import;
            EXECUTE sql;
        
            sql = 'UPDATE export.observations_a_importer
                   SET id_etude = (select id_etude from md.etude WHERE nom_etude = '|| quote_literal(var_link)||')
                   WHERE id_etude = '|| var_import;
            EXECUTE sql;
            
    ELSE IF (var_local IS NOT NULL) AND (var_local <> var_import) THEN
            
            sql = 'UPDATE export.observations_a_importer
                   SET id_etude = (select id_etude from md.etude WHERE nom_etude = '|| quote_literal(var_link)||')
                   WHERE id_etude = '|| var_import;
            EXECUTE sql;
            
        END IF;    
    END IF;
    END LOOP;
-- Fin de l'import des Etudes----------------------------------


-- Import des Protocoles --------------------------------------------

searchsql = 'SELECT 
  protocoles_a_importer.id_protocole as import, 
  protocole.id_protocole as local,
  protocoles_a_importer.libelle as link_protocole
  FROM 
  export.protocoles_a_importer
  LEFT JOIN  md.protocole
ON 
  protocoles_a_importer.libelle = protocole.libelle';
  
  EXECUTE searchsql;

 FOR rec IN EXECUTE(searchsql) LOOP
    var_import:= rec.import;
    var_local:= rec.local;
    var_link_protocole:=rec.link_protocole;
    
    IF (var_local IS NULL) THEN
        
            sql = 'INSERT INTO md.protocole (libelle, resume)
            select libelle, resume From export.protocoles_a_importer 
            Where protocoles_a_importer.id_protocole =' || var_import;
            EXECUTE sql;
        
            sql = 'UPDATE export.observations_a_importer
                   SET id_protocole = (select id_protocole from md.protocole WHERE libelle = '|| quote_literal(var_link_protocole)||')
                   WHERE id_protocole = '|| var_import;
            EXECUTE sql;
            
    ELSE IF (var_local IS NOT NULL) AND (var_local <> var_import) THEN
            
            sql = 'UPDATE export.observations_a_importer
                   SET id_protocole = (select id_protocole from md.protocole WHERE libelle = '|| quote_literal(var_link_protocole)||')
                   WHERE id_protocole = '|| var_import;
            EXECUTE sql;
            
        END IF;    
    END IF;
    END LOOP;
-- Fin de l'import des Protocoles----------------------------------




-- Import des Observateurs --------------------------------------------
-- Desactive le compte admin

searchsql = 'SELECT 
  observateurs_a_importer.id_personne as import, 
  personne.id_personne as local,
  observateurs_a_importer.email as email_link,
  observateurs_a_importer.role as role
FROM 
  export.observateurs_a_importer
  LEFT JOIN  md.personne
ON 
  observateurs_a_importer.email = personne.email';
  
  EXECUTE searchsql;

 FOR rec IN EXECUTE(searchsql) LOOP
    id_personne_import := rec.import;
    id_personne_local:= rec.local;
    var_email = rec.email_link;
    var_role_import = rec.role;
    IF (var_role_import ='admin') THEN
    var_role_import = 'expert';
    END IF;
    
    IF (id_personne_local IS NULL) THEN
        
            sql = 'INSERT INTO md.personne(remarque,fax,portable,tel_pro,tel_perso,pays,ville,code_postal,adresse_1,prenom,nom,email,role,specialite,mot_de_passe,createur,titre,date_maj)
                select remarque,fax,portable,tel_pro,tel_perso,pays,ville,code_postal,adresse_1,prenom,nom,email,'||quote_literal(var_role_import)||',specialite,mot_de_passe,createur,titre,date_maj from export.observateurs_a_importer
            Where observateurs_a_importer.id_personne = '|| id_personne_import;
            EXECUTE sql;
            
            sql = 'UPDATE  export.observations_a_importer 
            set observateur = (Select id_personne::text from md.personne Where email = '||quote_literal(var_email)||') , 
            numerisateur = (Select id_personne::int from md.personne Where email = '||quote_literal(var_email)||')
            WHERE observateur = (Select id_personne::text from export.observateurs_a_importer Where export.observateurs_a_importer.email = '||quote_literal(var_email)||')'; 
            EXECUTE sql;
            
    ELSE IF (id_personne_local IS NOT NULL) AND (id_personne_local <> id_personne_import) THEN
            
            sql = 'UPDATE  export.observations_a_importer 
            set observateur = (Select id_personne::text from md.personne Where email = '||quote_literal(var_email)||') , 
            numerisateur = (Select id_personne::int from md.personne Where email = '||quote_literal(var_email)||')
            WHERE observateur = (Select id_personne::text from export.observateurs_a_importer Where export.observateurs_a_importer.email = '||quote_literal(var_email)||')'; 
            EXECUTE sql;
        END IF;    
    END IF;
    END LOOP;
-- Fin de l'import des observateurs----------------------------------


-- Import des Structures --------------------------------------------

-- Test de le présence complete du champ courriel

test_courriel = 'Select * FROM export.structures_a_importer';

    FOR rec0 IN EXECUTE(test_courriel) LOOP
    IF character_length(rec0.courriel_1) IS NULL THEN
        RAISE unique_violation USING MESSAGE = 'Champ courriel non rempli pour : '||rec0.nom_structure;
        RETURN NULL;
        EXIT;
    ELSE
    

searchsql = 'SELECT 
  structures_a_importer.id_structure as import, 
  structure.id_structure as local,
  structures_a_importer.courriel_1 as link
FROM 
  export.structures_a_importer
  LEFT JOIN  md.structure
ON 
  structures_a_importer.courriel_1 = structure.courriel_1';
  
  EXECUTE searchsql;

 FOR rec IN EXECUTE(searchsql) LOOP
    var_import:= rec.import;
    var_local:= rec.local;
    var_link:=rec.link;
    
    IF (var_local IS NULL) THEN

        sql = 'INSERT INTO md.structure (nom_structure, detail_nom_structure, statut, adresse_1, code_postal, ville, pays, tel, fax, courriel_1, courriel_2, site_web, remarque, createur, diffusable, date_maj)
            select nom_structure, detail_nom_structure, statut, adresse_1, code_postal, ville, pays, tel, fax, courriel_1, courriel_2, site_web, remarque, createur, diffusable, date_maj From export.structures_a_importer 
            Where structures_a_importer.courriel_1 = '||quote_literal(var_link);
        EXECUTE sql;
        
        sql = 'UPDATE export.observations_a_importer
               SET structure = (select id_structure from md.structure WHERE courriel_1 = '|| quote_literal(var_link)||')
               WHERE structure = '|| quote_literal(var_import);
        EXECUTE sql;
            
    ELSE IF (var_local IS NOT NULL) AND (var_local <> var_import) THEN
            
            sql = 'UPDATE export.observations_a_importer
               SET structure = (select id_structure from md.structure WHERE courriel_1 = '|| quote_literal(var_link)||')
               WHERE structure = '|| quote_literal(var_import);
            EXECUTE sql;
            
        END IF;    
    END IF;
END LOOP;
END IF;
END LOOP;

-- Import des données --------------------------------------------

searchsql = 'INSERT into saisie.saisie_observation 
(date_obs, date_debut_obs, date_fin_obs, date_textuelle, regne, nom_vern, nom_complet, cd_nom, effectif_textuel, effectif_min, effectif_max, type_effectif, phenologie, id_waypoint, longitude, latitude, localisation, observateur, numerisateur, validateur, structure, remarque_obs, code_insee, id_lieu_dit, diffusable, "precision", statut_validation, id_etude, id_protocole, effectif, decision_validation, heure_obs, determination, elevation, geometrie)
SELECT 
date_obs, date_debut_obs, date_fin_obs, date_textuelle, regne, nom_vern, nom_complet, cd_nom, effectif_textuel, effectif_min, effectif_max, type_effectif, phenologie, id_waypoint, longitude, latitude, localisation, observateur, numerisateur, validateur, structure, remarque_obs, code_insee, id_lieu_dit, diffusable, "precision", statut_validation, id_etude, id_protocole, effectif, decision_validation, heure_obs, determination, elevation, geometrie
FROM export.observations_a_importer';
  
  EXECUTE searchsql;

 
-- Fin des données----------------------------------

    
RETURN NULL;
        END;

Script 3 : import.sql


CREATE OR REPLACE FUNCTION export.import(
    nom_export text,
    repertoire text)
  RETURNS text AS
$BODY$
DECLARE
sql text;

BEGIN 

-- Import de la table des Etudes
DROP TABLE IF EXISTS export.etudes_a_importer ;
sql =' CREATE TABLE export.etudes_a_importer
    (id_etude integer, nom_etude text, cahier_des_charges text, date_debut date, date_fin date, description text, lien_rapport_final text)
    WITH (OIDS=FALSE);
ALTER TABLE export.etudes_a_importer
    OWNER TO postgres;
COPY export.etudes_a_importer
FROM '||quote_literal(repertoire||nom_export||'_etudes_a_importer.csv')||'  DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

Execute sql;
-------------------------------------------------

-- Import  dans le schéma "export" des Protocoles
DROP TABLE IF EXISTS export.protocoles_a_importer;
sql ='CREATE TABLE export.protocoles_a_importer
    (id_protocole integer, libelle text, resume text)
    WITH (OIDS=FALSE);
ALTER TABLE export.protocoles_a_importer
    OWNER TO postgres;
COPY export.protocoles_a_importer
FROM '||quote_literal(repertoire||nom_export||'_protocoles_a_importer.csv')||' 
DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

Execute sql;

-------------------------------------------------

-- Import  dans le schéma "export" des Observateurs

DROP TABLE IF EXISTS export.observateurs_a_importer;
sql ='CREATE TABLE export.observateurs_a_importer
    (id_personne integer, remarque text, fax text, portable text, tel_pro text, tel_perso text, pays text, ville text, code_postal text, adresse_1 text, prenom text, nom text, email text, role md.enum_role, specialite md.enum_specialite, mot_de_passe text, createur integer, titre md.enum_titre, date_maj date)
    WITH (OIDS=FALSE);
ALTER TABLE export.observateurs_a_importer
    OWNER TO postgres;
COPY export.observateurs_a_importer
FROM '||quote_literal(repertoire||nom_export||'_observateurs_a_importer.csv')||' 
DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

Execute sql;
-------------------------------------------------

-- Import  dans le schéma "export" des Strucutres
DROP TABLE IF EXISTS export.structures_a_importer;
sql ='CREATE TABLE export.structures_a_importer
    (id_structure integer, nom_structure text, detail_nom_structure text, statut text, adresse_1 text, code_postal text, ville text, pays text, tel text, fax text, courriel_1 text, courriel_2 text, site_web text, remarque text, createur integer, diffusable boolean, date_maj date)
    WITH (OIDS=FALSE);
ALTER TABLE export.structures_a_importer
    OWNER TO postgres;
COPY export.structures_a_importer
FROM '||quote_literal(repertoire||nom_export||'_structures_a_importer.csv')||' 
DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

Execute sql;
-------------------------------------------------

-- Import  dans le schéma "export" des Taxref supplémentaires
--DROP TABLE IF EXISTS export.taxref_cd_cen_a_importer;
--sql ='CREATE TABLE export.taxref_cd_cen_a_importer
--    (regne text, phylum text, classe text, ordre text, famille text, cd_nom text, cd_ref text, nom_complet text, nom_valide text, nom_vern text, lb_nom text, cd_taxsup character varying)
--    WITH (OIDS=FALSE);
--ALTER TABLE export.taxref_cd_cen_a_importer
--    OWNER TO postgres;
--COPY export.taxref_cd_cen_a_importer
--FROM '||quote_literal(taxref_file)||'
--DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('LATIN1')||' CSV HEADER;';
--
--Execute sql;

-------------------------------------------------

-- Import dans le schéma "export" des Observations

DROP TABLE IF EXISTS export.observations_a_importer;
sql ='CREATE TABLE export.observations_a_importer
    (id_obs integer, date_obs date, date_debut_obs date, date_fin_obs date, date_textuelle text, regne text, nom_vern text, nom_complet text, cd_nom text, effectif_textuel text, effectif_min bigint, effectif_max bigint, type_effectif text, phenologie text, id_waypoint text, longitude double precision, latitude double precision, localisation text, observateur text, numerisateur integer, validateur integer, structure text, remarque_obs text, code_insee text, id_lieu_dit text, diffusable boolean, "precision" saisie.enum_precision, statut_validation saisie.enum_statut_validation, id_etude integer, id_protocole integer, effectif bigint, url_photo text, commentaire_photo text, decision_validation text, heure_obs time without time zone, determination saisie.enum_determination, elevation bigint, geometrie geometry)
    WITH (OIDS=FALSE);
ALTER TABLE export.observations_a_importer
    OWNER TO postgres;
COPY export.observations_a_importer
FROM '||quote_literal(repertoire||nom_export||'_observations_a_importer.csv')||' 
DELIMITER '||quote_literal(';')||' NULL' ||quote_literal('')||' Encoding '||quote_literal('UTF8')||' CSV HEADER;';

Execute sql;

RETURN NULL;
        END;


----------------------------------------------------------------------------------------------- Fin ! (enfin)
