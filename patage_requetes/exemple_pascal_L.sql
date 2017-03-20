/* exemple 1 : copier une table postgis vers une autre table postgis, ici des données d’une commune identifiée par son code insee
par Pascal LAMBERT, PNR Oise pays de france */

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
