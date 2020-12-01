PROC IMPORT OUT= WORK.PROJET                                                                                                           
            DATAFILE= "C:\Users\Philippine\Documents\Cours\Maths\M2\Econometrie\Projet_eco\data.xlsx"                        
            DBMS=xlsx REPLACE;                                                                                                     
     GETNAMES=YES;                                                                                                                      
RUN;

/* Statistiques diverses : base de donn�es brute */


proc contents data=projet ; /* donne des infos sur la base de donn�es, notamment le nombre d'observations et 
								le nombre de variables ainsi que leur d�nomination et leur type (n'affiche pas la base)*/
title 'Informations relatives � la base de donn�es Euromillion';
run;

proc print data=projet (obs=10); /* affiche les  premi�res entr�es de la base */
run;


/* Transformation des donn�es en ln (car valeurs grandes et facilite les interpr�tations) et s�paration des ann�es*/

data projet2019; /* on cr�� un nouveau fichier � partir de l'ancien en �liminant l'ann�e 2020 et moyennant ln_nb_grille dessus*/
set projet;
ln_nb_grilles = log(nombre_de_grilles_jou_es); /* d�finition des nouvelles variables */
label ln_nb_grilles='ln_nb_grilles';

if annee = 0; /* on ne travaille que sur 2019 */
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; /* on garde la variable endog�ne et les variables exog�nes qui nous int�ressent */
run;

proc contents data=projet2019;
title 'Informations sur la nouvelle base de donn�es cr��e (avec pasage au ln)';
run;
proc print data=projet2019 (obs=10); /* on visualise les 10 premi�re observations de cette nouvelle base de donn�es */
run;

proc univariate data=projet2019;
var ln_nb_grilles;
OUTPUT OUT=moyenne2019 mean= m_ln_nb_grilles;
title 'Statistiques sur les variables quantitatives (pass�es au log)';
run;

proc print data=moyenne2019; /* on obtient un fichier avec 3 variables (celles gard�es au dessus) et leur valeur moyenne */
title 'Donn�es moyenn�es';
run;
/* 17.0470  comme valeur moyenne pour la variable quanti pass�e au log, pour 2019 */


/* PARTIE PREDICTION */
/* Ajout de lignes suppl�mentaires pour la pr�diction de lambda */
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

;/* 17.0470 donn�es trouv�es par UNIVARIATE (les dummy c'est � nous de choisir) */

data newprojet2019;
set projet2019 more;
run;
proc print data=newprojet2019; /* pour v�rifier que la nouvelle observation a bien �t� ajout�e */
run;

/* Estimation : Mod�le de comptage (Poisson) */

proc countreg data=newprojet2019; /* estime les beta et donne le niveau de significaivit� des variables associ�es */
model Y = ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle / dist=poisson;
output out=outestim2019 pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des param�tres b�ta_i (interpr�tables)';
run;

/* estimation de Y (lambda_chap) pour la ligne suppl�mentaire */

proc print data=outestim2019; * 1 pr�vision ;
var lambda_chap;
where Y = .;   
title 'Pr�visions mod�le de Poisson';
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
title "Probabilit�s pour l'ann�e 2019";
run;
