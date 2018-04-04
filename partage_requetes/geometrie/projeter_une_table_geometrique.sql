--je modifie la projection de ma table ET je transforme les géométries dans le nouveau système de coordonnées
--le SRID doit être connu dans les propriétés de la table
alter table monschema.matable
alter column MacolonneGeométrique type geometry (MonTypeDeGeom,MonSRIDCible)
using ST_transform (MonTypeDeGeom,MonSRIDCible);
--MonTypeDeGeom = Multipolygon, polygon, multipolygonz, linestring, ...
--MonSRIDCible = 2154, 3945, 4326, ...

--il semble nécessaire de lancer la requête suivante
select Populate_Geometry_Columns ();
