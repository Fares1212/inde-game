# La crique des objets perdus

Une seule mer de 500 000 litres. Le fond descend du lagon jusqu’à la fosse en passant par le récif, la forêt de varech, les épaves et la plaine abyssale. Grâce au siphon installé par Bernard, une petite quantité d’eau entraîne un volume supérieur. Le nombre de litres dans la main et la baisse globale gardent chacun leur jauge et leur unité.

| Récipient | Capacité | Geste |
|---|---:|---|
| Cuillère à café | 5 mL | Plonger la petite cuillère et rapporter le premier « plic » |
| Louche de cuisine | 650 mL | Puiser avec le bol profond |
| Seau à douves | 8,5 L | Remplir le seau suspendu par son anse |
| Arrosoir de cuivre | 14 L | Immerger le corps et diriger le bec vers la goulotte |
| Baquet à cordes | 22 L | Transporter à deux poignées pendant que le moulin travaille |
| Tonneau sur diable | 38 L | Pousser le fût sur ses deux roues et le basculer au déversoir |

Les vitesses, capacités, pertes, revenus et prix se règlent dans les six ressources de récipient référencées par `Game/resources/mer.tres`. La marée montante réduit le progrès net. Une digue protège la quantité déjà retirée lors de son achat. Courir accélère le trajet et fait perdre une partie de la cargaison. Des déversoirs successifs se découvrent le long de la conduite. Les repères de pêche de Bernard pointent vers une trouvaille encore inconnue.

## Courbe simulée

Le simulateur parcourt la pente du terrain pour estimer le trajet entre l’eau et le déversoir. Il applique les temps de remplissage, le ralentissement dû au poids, les revenus, les courants et les seuils d’achat du jeu. Le profil exploration ajoute des pauses et des détours. Les deux modèles achètent les récipients dès que possible et ignorent les achats facultatifs.

| Jalon | Trajet optimisé | Exploration |
|---|---:|---:|
| Siphon amorcé | 55 s | 1 min 37 s |
| Louche achetée | 6 min 45 s | 11 min 27 s |
| 1 % | 7 min 37 s | 12 min 52 s |
| 10 % | 24 min 14 s | 48 min 21 s |
| 50 % | 1 h 06 min 35 s | 2 h 39 min 45 s |
| Choix final | 2 h 01 min 46 s | 4 h 57 min 36 s |

Ces durées proviennent de la simulation. La chasse libre, les trajets à la nage, les objets vendus et les achats facultatifs changent la durée d’une partie humaine.

## Les trois fins

La Marée ramène l’eau sur la rive. Le Grand Vide laisse le treuil tourner jusqu’au silence. La Maison demande les dix-huit pages du carnet et la restitution à Bernard de la clé du logis. Un point de reprise lié à la partie conserve l’état avant le choix et les fins déjà découvertes. La promenade libre reprend ensuite sur la même côte.
