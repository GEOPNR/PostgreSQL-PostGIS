-- création d'une Vue matérialisée (VM) "RNF_SITES_GEOM" dans le schéma serena
-- cette vue contient un champ géométrie (geom) calculé d'après le champs "SITE_CAR" de la table "RNF_SITE"
-- les noms des champs sont entre guillemets car stockés en majuscules dans la base ACCESS de SERENA

CREATE MATERIALIZED VIEW serena.RNF_SITES_GEOM AS 
SELECT	"SITE_ID",
	"SITE_NOM",
	"RNF_CHOI"."CHOI_NOM",
	"SITE_CAR",
	split_part("SITE_CAR", ' ', 1) || ' - ' || split_part("SITE_CAR", ' ', 4) AS DATUM,
	CASE 
		WHEN split_part("SITE_CAR", ' ', 1)='L93F' THEN 2154
		WHEN split_part("SITE_CAR", ' ', 1)='LIIEF' THEN 27582
		ELSE 0
	END AS SRID,
	CAST(split_part("SITE_CAR", ' ', 2) as decimal)*1000 AS X,
	CAST(split_part("SITE_CAR", ' ', 3) as decimal)*1000 AS Y,
	ST_Transform(ST_GeomFromText('POINT(' || CAST(split_part("SITE_CAR", ' ', 2) as decimal)*1000 || ' ' || CAST(split_part("SITE_CAR", ' ', 3) as decimal)*1000 || ')', CASE 
		WHEN split_part("SITE_CAR", ' ', 1)='L93F' THEN 2154
		WHEN split_part("SITE_CAR", ' ', 1)='LIIEF' THEN 27582
		ELSE 0
	END),2154) AS GEOM
  FROM "RNF_SITE", "RNF_CHOI"
  WHERE "RNF_SITE"."SITE_CATEG_CHOI_ID" = "RNF_CHOI"."CHOI_ID"
  ORDER BY "SITE_ID";
