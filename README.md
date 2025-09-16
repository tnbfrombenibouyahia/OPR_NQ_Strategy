Stratégie de Trading sur l'US100
Stratégie de cassure de l'Open Price Range (OPR)

- - - 

🎯 Objectif du Projet
Ce repository présente une stratégie de trading algorithmique conçue pour l'indice boursier NASDAQ 100 (US100). La logique de cette stratégie, initialement développée en MQL5, repose sur un principe de day trading : la cassure de l'Open Price Range (OPR). Ce document détaille la méthodologie, la logique de trading, ainsi que les résultats du backtesting.

📈 La Stratégie : Logique de l'OPR
La stratégie se fonde sur l'analyse de l'Open Price Range des marchés américains, établi sur la période de 15:30 à 15:45 (heure de Paris). L'OPR est défini par les points hauts (High) et bas (Low) atteints par l'instrument financier durant cette courte fenêtre temporelle.

Règles de Trading
Achat (Long) : Un signal d'achat est généré lorsque le prix de l'US100 casse à la hausse le sommet de l'OPR.

Vente (Short) : Un signal de vente est généré lorsque le prix de l'US100 casse à la baisse le creux de l'OPR.

https://github.com/tnbfrombenibouyahia/OPR_NQ_Strategy/blob/main/Trading%20Setup.png?raw=true

- - - 

Gestion du Risque
Afin de protéger le capital, un stop-loss est systématiquement placé à l'opposé du niveau de cassure (au Low de l'OPR pour un achat, et au High pour une vente). La stratégie intègre également un système de break-even et de clôture partielle des positions pour sécuriser les profits et optimiser le profil de risque-rendement.

Note : Initialement testée sur plusieurs indices (US100, US500, US30, US2000), la stratégie a montré sa plus grande efficacité et une meilleure cohérence des résultats sur l'US100, justifiant ainsi l'exclusivité de ce projet. Les autres paires n'apportait aucun hedging intéressant

📊 Méthodologie de Test et d'Optimisation
Pour valider la robustesse de cette approche, un backtesting rigoureux a été réalisé sur deux périodes distinctes pour éviter le sur-optimisation :

Période d'entraînement (In-Sample) : du 01/01/2018 au 01/01/2023. Cette période a été utilisée pour l'optimisation des paramètres.

Période inconnue (Out-of-Sample) : du 01/01/2023 au 01/03/2023. Cette période a servi de test pour vérifier la robustesse et la capacité de la stratégie à générer des profits sur des données non utilisées lors de l'optimisation.

Les trois meilleures optimisations de la période In-Sample ont été soumises au test sur la période Out-of-Sample. Le modèle final a été sélectionné sur la base des métriques les plus performantes, notamment le Sharpe Ratio, le Drawdown Minimal et le Profit Factor, assurant un équilibre optimal entre rentabilité et gestion du risque.

