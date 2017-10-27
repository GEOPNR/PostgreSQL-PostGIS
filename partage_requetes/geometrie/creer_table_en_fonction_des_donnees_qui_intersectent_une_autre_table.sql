--Depuis une table, récupere les données qui intersectent les données d'une autre table
--crée la table TableResultat dans le schéma MonSchema
create table MonSchema.TableResultat as

--récupère toutes les colonnes de table1 et ajoute une colonne d'identifiants uniques (uid) qui seront utilisés comme clé primaire 
--dans la table résultante
select 
row_number() OVER () AS uid,
t1.*

--utilise les tables table1 et table2, et crée un alias pour chacune d'elle (pour créer un alias, 
--il suffit de mettre l'alias juste après le nom de la table, cet alias pourra être repris dans toute la requête)
from MonSchema.table1 t1, MonSchema.table2 t2

--réalise l'intersection géographique des deux tables via la colonne geom (qui est la colonne de géométrie)
where st_intersects(t1.geom, t2.geom);


--deuxième requête permettant de définir la colonne uid comme clé primaire dans la table résultante
ALTER TABLE MonSchema.TableResultat
  ADD CONSTRAINT tableResultat_pkey PRIMARY KEY(uid); 
