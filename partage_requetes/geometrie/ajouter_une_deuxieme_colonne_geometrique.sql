--ajouter une colonne de géométrie en spécifiant le type de géom (multipolygon, polygon, linestring, ...) et le SRID attendu
alter table matable add column MaNouvelleColonneDeGeometrie geometry(TypeDeGeometrie, MonSRIDcible);
update matable set MaNouvelleColonneDeGeometrie = st_transform(MaColonneDeGeometrieActuelle, MonSRIDactuel);
-- eventuellement un index sur cette colonne si elle est utilisée dans une clause where, ou dans qgis:
create index matable_MaNouvelleColonneDeGeometrie_gist on matable USING GIST (MaNouvelleColonneDeGeometrie);
VACUUM ANALYZE matable;
