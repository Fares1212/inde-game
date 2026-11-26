# Décisions de réalisation

Le moteur Godot 4.5.1 utilise OpenGL Compatibility. La mer repose sur un plan animé qui lit la hauteur du terrain. La même fonction de hauteur place les coques et les pieds du joueur. Le soleil, l’écume et les empreintes fonctionnent dans ce moteur de rendu. Le plan d’eau unique rejoint le large entre deux caps.

Le gros plan d’un outil doit révéler l’attache et l’ouverture. Les douves, cerclages, rivets, poignées et rebords ont leur propre géométrie. Le niveau de liquide monte à l’intérieur du récipient et suit la charge. Le diable s’appuie sur ses roues lorsque la caméra regarde ailleurs.

Le thème commun utilise Bitter et Source Sans 3 sous licence OFL. Le menu s’ouvre sur une capture du rivage. La vignette du carnet a été générée avec Higgsfield. Le monde 3D, les modèles et leurs animations sont construits dans Godot. Les sons et la musique sont synthétisés pour le jeu.

En V1, le lecteur vocal recevait une autre piste entière dès qu’un nouvel événement déclenchait une réplique. Les clips redémarraient tandis que la fermeture du panneau et la fin du texte pouvaient intervenir à des moments différents. En V2, DialogueManager possède la file de répliques et le lecteur vocal. Les syllabes disposent d’une enveloppe d’attaque et de relâchement. Fermer la boîte ou passer la ligne arrête les syllabes.

La sauvegarde v2 utilise des identifiants stables pour les objets. La migration conserve une copie originale du fichier v1 et convertit le remplissage relatif du récipient et de la mer. Les découvertes, l’argent et les outils restent accessibles. Les photos restent locales.
