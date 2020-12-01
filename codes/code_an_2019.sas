PROC IMPORT OUT= WORK.PROJET                                                                                                           
            DATAFILE= "C:\Users\Philippine\Documents\Cours\Maths\M2\Econometrie\Projet_eco\data.xlsx"                        
            DBMS=xlsx REPLACE;                                                                                                     
     GETNAMES=YES;                                                                                                                      
RUN;

/* Statistiques diverses : base de données brute */


proc contents data=projet ; /* donne des infos sur la base de données, notamment le nombre d'observations et 
								le nombre de variables ainsi que leur dénomination et leur type (n'affiche pas la base)*/
title 'Informations relatives à la base de données Euromillion';
run;

proc print data=projet (obs=10); /* affiche les  premières entrées de la base */
run;


/* Transformation des données en ln (car valeurs grandes et facilite les interprétations) et séparation des années*/

data projet2019; /* on créé un nouveau fichier à partir de l'ancien en éliminant l'année 2020 et moyennant ln_nb_grille dessus*/
set projet;
ln_nb_grilles = log(nombre_de_grilles_jou_es); /* définition des nouvelles variables */
label ln_nb_grilles='ln_nb_grilles';

if annee = 0; /* on ne travaille que sur 2019 */
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; /* on garde la variable endogène et les variables exogènes qui nous intéressent */
run;

proc contents data=projet2019;
title 'Informations sur la nouvelle base de données créée (avec pasage au ln)';
run;
proc print data=projet2019 (obs=10); /* on visualise les 10 première observations de cette nouvelle base de données */
run;

proc univariate data=projet2019;
var ln_nb_grilles;
OUTPUT OUT=moyenne2019 mean= m_ln_nb_grilles;
title 'Statistiques sur les variables quantitatives (passées au log)';
run;

proc print data=moyenne2019; /* on obtient un fichier avec 3 variables (celles gardées au dessus) et leur valeur moyenne */
title 'Données moyennées';
run;
/* 17.0470  comme valeur moyenne pour la variable quanti passée au log, pour 2019 */


/* PARTIE PREDICTION */
/* Ajout de lignes supplémentaires pour la prédiction de lambda */
data more;
input Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle;
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; 
										
datalines; 
. 17.0470 1 1 1
. 17.0470 1 1 0
. 17.0470 1 0 0
. 17.0470 0 0 0
. 17.0470 0 0 1
. 17.0470 0 1 1
. 17.0470 0 1 0
. 17.0470 1 0 1

;/* 17.0470 données trouvées par UNIVARIATE (les dummy c'est à nous de choisir) */

data newprojet2019;
set projet2019 more;
run;
proc print data=newprojet2019; /* pour vérifier que la nouvelle observation a bien été ajoutée */
run;

/* Estimation : Modèle de comptage (Poisson) */

proc countreg data=newprojet2019; /* estime les beta et donne le niveau de significaivité des variables associées */
model Y = ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle / dist=poisson;
output out=outestim2019 pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des paramètres bêta_i (interprétables)';
run;

/* estimation de Y (lambda_chap) pour la ligne supplémentaire */

proc print data=outestim2019; * 1 prévision ;
var lambda_chap;
where Y = .;   
title 'Prévisions modèle de Poisson';
run;
/* 0.33644 
   0.50534 
   0.61816 
   0.46257 
   0.30797 
   0.25176 
   0.37814 
   0.41155 

 lambda_chap pour la configuration des datalines pour 2019*/

data calcul2019; /* calcul de P(Y=a) */
a=0;
b=1;
c=2;
factora = fact(a);
factorb = fact(b);
factorc = fact(c);
prob0=(0.33644 **a*exp(-0.33644))/factora;
prob1=(0.33644 **b*exp(-0.33644))/factorb;
prob2=(0.33644 **c*exp(-0.33644))/factorc;

run;
proc print data=calcul2019;
title "Probabilités pour l'année 2019";
run;
