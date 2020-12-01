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

data projet2020; /* on créé un nouveau fichier à partir de l'ancien en éliminant l'année 2019 et moyennant ln_nb_grille dessus*/
set projet;
ln_nb_grilles = log(nombre_de_grilles_jou_es); /* définition des nouvelles variables */
label ln_nb_grilles='ln_nb_grilles';

if annee = 1; /* on ne travaille que sur 2020 */
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; /* on garde la variable endogène et les variables exogènes qui nous intéressent */
run;

proc contents data=projet2020;
title 'Informations sur la nouvelle base de données créée (avec pasage au ln)';
run;
proc print data=projet2020 (obs=10); /* on visualise les 10 première observations de cette nouvelle base de données */
run;

proc univariate data=projet2020;
var ln_nb_grilles;
OUTPUT OUT=moyenne2020 mean= m_ln_nb_grilles;
title 'Statistiques sur les variables quantitatives (passées au log)';
run;

proc print data=moyenne2020;
title 'Données moyennées';
run;
/* 16.8448  comme valeur moyenne pour la variable quanti passée au log, pour 2020 */


/* PARTIE PREDICTION */
/* Ajout de lignes supplémentaires pour la prédiction de lambda */
data more2;
input Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle;
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; 
										
datalines; 
. 16.8448 1 1 1
. 16.8448 1 1 0
. 16.8448 1 0 0
. 16.8448 0 0 0
. 16.8448 0 0 1
. 16.8448 0 1 1
. 16.8448 0 1 0
. 16.8448 1 0 1

;/* 16.8448 données trouvées par UNIVARIATE (les dummy c'est à nous de choisir) */

data newprojet2020;
set projet2020 more2;
run;
proc print data=newprojet2020; /* pour vérifier que la nouvelle observation a bien été ajoutée */
run;

/* Estimation : Modèle de comptage (Poisson) */

proc countreg data=newprojet2020; /* estime les beta et donne le niveau de significaivité des variables associées */
model Y = ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle / dist=poisson;
output out=outestim2020 pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des paramètres bêta_i (interprétables)';
run;

/* estimation de Y (lambda_chap) pour la ligne supplémentaire */

proc print data=outestim2020; * 1 prévision ;
var lambda_chap;
where Y = .;   
title 'Prévisions modèle de Poisson';
run;
/* 0.70137 
   0.52038 
   0.29104 
   0.28391 
   0.38266 
   0.68419 
   0.50763 
   0.39227 
 lambda_chap pour la configuration des datalines pour 2019*/

data calcul2020; /* calcul de P(Y=a) */
a=0;
b=1;
c=2;
factora = fact(a);
factorb = fact(b);
factorc = fact(c);
prob0=(0.70137**a*exp(-0.70137))/factora;
prob1=(0.70137**b*exp(-0.70137))/factorb;
prob2=(0.70137**c*exp(-0.70137))/factorc;

run;
proc print data=calcul2020;
title "Probabilités pour l'année 2020";
run;
