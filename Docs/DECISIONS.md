# Décisions de réalisation

Le projet utilise Godot 4.5.1 et GDScript. Le moteur, les modèles d’export et le compilateur de l’installateur permettent de livrer le jeu sans compte de création supplémentaire. Les vérifications d’intégrité du moteur figurent dans le script de construction.

Le rivage est un maillage de terrasses déterministes, accompagné d’une carte de hauteur. Le shader lit cette carte pour tracer la mousse et la profondeur du lagon. L’eau et le sol partagent les mêmes altitudes. Les empreintes de pas suivent la pente et disparaissent à la marée montante. Une flotte de 2 080 silhouettes instanciées anime le tourbillon final.

L’affiche et le ciel panoramique ont été créés avec ChatGPT. Le crabe, sa tasse, les outils, les voiliers, les huttes et les trouvailles sont composés de maillages dans le projet. La musique et les effets sont synthétisés à partir d’une partition et de générateurs originaux. Bernard parle avec une voix française synthétique précalculée par eSpeak NG.

Chaque livraison, achat, découverte et changement de bassin est enregistré localement. Le jeu écrit un fichier temporaire et conserve une copie de secours. Les cartes postales automatiques ne sont jamais transmises par le jeu.
