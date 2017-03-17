--1-- création d'un groupe
create role nomdugroupe;
--2-- création d'un utilisateur avec mot de passe
create user nomutilisateur with password 'monmotdepasse';
--3-- attribution d'un utilisateur à un groupe
grant groupe1, groupe2, groupe3 to utilisateur;

--4-- exemple de TRIGGER :

CREATE OR REPLACE FUNCTION maj_itineraire_v1()
  RETURNS trigger AS
$$
DECLARE
BEGIN
  IF TG_OP = 'UPDATE'  THEN
    --si je change la géométrie, maj_g devient true
    IF NOT st_equals(OLD.geom, NEW.geom) THEN
      NEW.maj_g = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;
   
    -- si un itinéraire rentre dans le cartoguide (la colonne cartoguide passe de non à oui), maj_c devient true
    IF NEW.cartoguide = 'oui' and OLD.cartoguide = 'non' THEN
      NEW.maj_c = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;
   
    --si je change le nom, maj_s devient true et date_maj prend la date du jour
    raise notice 'update called';
    IF NEW.nom IS DISTINCT FROM OLD.nom THEN
      NEW.maj_s = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;
   
    --si je change typeroute, maj_s devient true et date_maj prend la date du jour
    raise notice 'update called';
    IF NEW.typeroute IS DISTINCT FROM OLD.typeroute THEN
      NEW.maj_s = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;

    --si je change numroute, maj_s devient true et date_maj prend la date du jour
    raise notice 'update called';
    IF NEW.numroute IS DISTINCT FROM OLD.numroute THEN
      NEW.maj_s = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;
   
    --si je change le revetement, maj_s devient true et date_maj prend la date du jour
    raise notice 'update called';
    IF NEW.revet IS DISTINCT FROM OLD.revet THEN
      NEW.maj_s = true;
      NEW.date_maj = now();
      NEW.user_modif = session_user;
    END IF;
   
  --Si je crée un objet
  ELSEIF TG_OP = 'INSERT' THEN
    NEW.maj_c = true;
    NEW.maj_g = false;
    NEW.maj_s = false;
    NEW.date_maj = now();
    NEW.id_externe = NEW.id;
    NEW.valide = true;
    NEW.structure = true;
    NEW.visible = true;
    NEW.user_modif = session_user;
  


  ELSEIF TG_OP = 'DELETE' THEN
    insert into accueil_rando.del_itineraire (id_supp, date_supp)
      values (OLD.id, now());
  END IF;

  RETURN new;

END;


$$ LANGUAGE plpgsql;


-- definition du trigger sur la vue
drop TRIGGER IF EXISTS maj_itineraire_v1 on accueil_rando.itineraire;
create TRIGGER maj_itineraire_v1
-- la fonction sera executée avant chacune de ces actions sur la table cible :
  AFTER UPDATE or insert or delete
  ON accueil_rando.itineraire
 
-- pour chaque ligne :
  FOR EACH ROW
  EXECUTE PROCEDURE maj_itineraire_v1();
