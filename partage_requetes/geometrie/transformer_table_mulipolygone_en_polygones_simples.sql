--créer une nouvelle table
create table MonSchema.MaNouvelleTable as
SELECT
--récupère les id d'origine et les place dans une nouvelle colonne id_ori
  id as id_ori,
--éclate les multipolygones en polygone simple avec le système de coordonnées scr 2154 (geom étant la colonne de géométrie)
  (st_dump(geom)).geom::geometry(polygon, 2154),
--récupère les colonnes de l'ancienne table
  colonne1,
  colonne2,
  colonne3,
  colonne4
FROM MonSchema.MonAncienneTable;

--ajoute une colonne de type série >> clé primaire
alter table MonSchema.MaNouvelleTable add column id SERIAL PRIMARY KEY ;
VACUUM ANALYSE MonSchema.MaNouvelleTable; 
