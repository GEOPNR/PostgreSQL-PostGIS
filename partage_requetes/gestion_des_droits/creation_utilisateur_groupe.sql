--requete permettant de créer d'abord un groupe, puis un utilisateur avec mot de passe et enfin d'attribuer cet utilisateur à un ou plusieurs groupes

--création d'un groupe
create role NomduGroupe;
--création d'un utilisateur avec mot de passe
create user nomutilisateur with password 'monmotdepasse';
--attribution d'un utilisateur à un groupe
grant NomduGroupe1, NomduGroupe2, NomduGroupe3 to NomUtilisateur;
