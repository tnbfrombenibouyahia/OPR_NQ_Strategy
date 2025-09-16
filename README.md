Stratégie de Trading sur l'US100
Stratégie de cassure de l'Open Price Range (OPR)
🎯 Objectif du Projet
Ce repository présente une stratégie de trading algorithmique conçue pour l'indice boursier NASDAQ 100 (US100). La logique de cette stratégie, initialement développée en MQL5, repose sur un principe de day trading : la cassure de l'Open Price Range (OPR). Ce document détaille la méthodologie de test, la logique de trading, ainsi que les résultats du backtesting.

📈 La Stratégie : Logique de l'OPR
La stratégie se fonde sur l'analyse de l'Open Price Range des marchés américains, établi sur la période de 15:30 à 15:45 (heure de Paris). L'OPR est défini par les points hauts (High) et bas (Low) atteints par l'instrument financier durant cette courte fenêtre temporelle.

Règles de Trading
Achat (Long) : Un signal d'achat est généré lorsque le prix de l'US100 casse à la hausse le sommet de l'OPR.

Vente (Short) : Un signal de vente est généré lorsque le prix de l'US100 casse à la baisse le creux de l'OPR.

<div align="center">
<img src="https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Trading%20Setup.png?raw=true" alt="Exemple de setup de trading OPR"/>
</div>

Ce graphique illustre la logique de la stratégie, avec l'OPR (rectangle gris foncé) et la cassure qui déclenche un signal de trading.

🎰 Gestion du Risque
Afin de protéger le capital, un stop-loss est systématiquement placé à l'opposé du niveau de cassure (au Low de l'OPR pour un achat, et au High pour une vente). La stratégie intègre également un système de break-even et de clôture partielle des positions pour sécuriser les profits et optimiser le profil de risque-rendement.

Note : Initialement testée sur plusieurs indices (US100, US500, US30, US2000), la stratégie a montré une efficacité et une cohérence supérieures sur l'US100. Les autres paires n'apportaient aucune couverture (hedging) intéressante, justifiant ainsi l'exclusivité de ce projet sur cet actif.

📊 Méthodologie de Test et d'Optimisation
Pour valider la robustesse de cette approche et éviter le sur-optimisation, un backtesting rigoureux a été réalisé sur deux périodes distinctes.

🏋️‍♂️ Période d'Entraînement (In-Sample)
Date : du 01/01/2018 au 01/01/2023.

Objectif : Cette période a été utilisée pour l'optimisation des paramètres.

🧙‍♂️ Période de Validation (Out-of-Sample)
Date : du 01/01/2023 au 01/03/2023.

Objectif : Cette période a servi de "terrain inconnu" pour vérifier la robustesse et la capacité de la stratégie à générer des profits sur des données non utilisées lors de l'entraînement.

Les trois meilleures optimisations de la période In-Sample ont été soumises au test sur la période Out-of-Sample. Le modèle final a été sélectionné sur la base de métriques clés telles que le Sharpe Ratio, le Max Drawdown et le Profit Factor, assurant un équilibre optimal entre rentabilité et gestion du risque.

📈 Analyse des Résultats
Après avoir exporté les données de MetaEditor et les avoir importées dans un environnement Python, une analyse plus approfondie a pu être menée.

Courbe de Capital Initiale
Voici la courbe de capital de notre modèle initial, avec ses paramètres prédéfinis sur la période totale. On observe une légère augmentation de 2018 à 2023, ce qui indique que la stratégie performe de manière stable. La poursuite de cette performance sur la période Out-of-Sample (après 2023) confirme que le modèle n'est pas sur-optimisé.

<br>
<br>

🕹️ Optimisation du Stop Mensuel
Une hypothèse a été testée : l'impact d'un stop mensuel automatique. L'objectif était de déterminer si le fait de clôturer et sécuriser les profits une fois un certain seuil de gain mensuel atteint pouvait améliorer la stratégie.

Les résultats visuels montrent que cette approche est prometteuse, même si elle peut générer des mois de pertes. L'analyse des rendements montre une plus grande régularité des gains.

![Rendements mensuels de l'optimisation](https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Testing%20Max%20Earning%20per%20month.png?raw=true)


L'impact sur la courbe de capital est évident : chaque courbe représente une variation de la stratégie avec un stop mensuel différent.

![Courbes de capital par stop mensuel](https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Equity%20Curve%20per%20Monthly%20Max%20Earning.png?raw=true)

Les résultats de l'optimisation ont révélé que le stop mensuel de 3% de gain offre les meilleures métriques de performance, comme le montre le tableau de synthèse ci-dessous.

<div align="center">
<img src="https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Result%20Monthly%20Stop.png?raw=true" alt="Tableau de résultats">
</div>

📟 Évaluation en Environnement Prop Firm
Pour évaluer la faisabilité de cette stratégie dans un contexte de firme de prop trading, une simulation a été menée en tenant compte de leurs règles strictes.

Avec un risque de 1% par position, la simulation montre que la stratégie a un taux de réussite élevé pour passer un challenge. Cependant, le temps nécessaire pour y parvenir est relativement long, souvent de l'ordre d'un an, ce qui la rend peu agressive.

<div align="center">
<img src="https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Distribution%20FTMO%20Challenge.png?raw=true" alt="Distribution de la durée des challenges">
</div>

結論
Cette analyse démontre la validité de la méthodologie utilisée pour tester, backtester et optimiser une stratégie de trading. Bien que la stratégie OPR ne soit pas une solution pour "devenir riche rapidement", elle offre une approche robuste et prudente. Elle permet de générer des rendements stables dans un environnement contrôlé, prouvant ainsi la valeur d'une approche systématique et basée sur les données.
