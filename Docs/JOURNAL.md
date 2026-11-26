# Vérifications de la deuxième édition

| Phase | Fichiers principaux | Vérification reproductible |
|---|---|---|
| 1. Direction artistique | Docs/AUDIT-V2.md | Comparer les observations de la première édition aux captures de la deuxième. |
| 2. Données et reprise | Game/resources, scripts/item_inventory.gd, scripts/voyage.gd | Le parcours QA convertit une partie V1 et recharge la sauvegarde de secours après une écriture corrompue. |
| 3. Équilibrage | Game/qa/balance.gd et Game/resources/mer.tres | Lancer la commande de simulation du README pour obtenir les temps, les revenus cumulés et les soldes aux quatre jalons. |
| 4. Interface | Game/resources/coast_theme.tres, Game/art/ui, scripts/ui.gd, scripts/menu.gd et scripts/game.gd | Tester les deux onglets du carnet et de la boutique, le focus clavier, la pause et les réglages. |
| 5. Voix | Game/scripts/dialogue.gd et Game/scripts/sound.gd | Ouvrir le comptoir. Passer une réplique avec Tab et fermer pendant la suivante. Vérifier les réglages de voix, de vitesse et de sous-titres. |
| 6. Côte | Game/shaders, Game/scripts/shore.gd, coast.gd et shorecraft.gd | Aller de la boutique au bord de l’eau, suivre la mousse et regarder les bateaux depuis deux niveaux de mer. |
| 7. Manipulations | Game/models, Game/scripts/vessels.gd et player.gd | Observer les six outils vides et pleins, courir avec une charge, verser au déversoir et inspecter les traces sur le sable. |
| 8. Fins | Game/scripts/game.gd, voyage.gd, Game/audio/generated | Tester les trois choix, les dix-huit pages ramassées sur le terrain, la remise de la clé, la promenade et le retour au treuil. |
| 9. Livraison | Game/qa/probe.gd, Tools/verify_result.py, Packaging, .github/workflows/release.yml | Exécuter le parcours OpenGL, les exports et les installateurs dans GitHub Actions. Les captures du parcours restent disponibles dans les artefacts de la construction. |

Le rendu automatisé local utilise Mesa llvmpipe. Une mesure de cadence sur le PC du joueur reste distincte de ce parcours logiciel.
