
--utilisation de st_intersection
--on créer la table résultat, on sélectionne les colonnes à préserver dans la table résultante,
--on lance l'intersection entre les colonnes géométries (les géom doivent avoir le même EPSG)

create table monSchema.MaTableRésultat as
select matable1.macolonne, matable2.macolonne, st_intersection(matable1.macolonne_geometrie, matable2.macolonne_geometrie) as MaNouvelleColonneGeometrie
from monschema1.matable1 join monschema2.matable2
on st_intersects(matable1.macolonne_geometrie, matable2.macolonne_geometrie)
