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

proc univariate data=projet; /*donne des informations statistiques (moyenne, m�diane, quantiles, min, max,...) 
								sur chaque variable consid�r�e en dessous. On stock ces moyennes dans les variables m_..
								dans un nouveau fichier 'moyenne'*/
var nombre_de_grilles_jou_es;
OUTPUT OUT=moyenne mean= m_nb_grilles;
title 'Statistiques sur les variables quantitatives';
run;

proc print data=moyenne; /* valeur moyenne du nombre de grilles jou�es */
title 'Donn�es moyenn�es';
run;

/* Transformation des donn�es en ln (car valeurs grandes et facilite les interpr�tations) */

data projet2; /* on cr�� un nouveau fichier � partir de l'ancien en �liminant l'ann�e car on va moyenner ln_nb_grille dessus*/
set projet;
ln_nb_grilles = log(nombre_de_grilles_jou_es); /* d�finition des nouvelles variables */
label ln_nb_grilles='ln_nb_grilles';

keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; /* on garde la variable endog�ne et les variables exog�nes qui nous int�ressent */
run;

proc contents data=projet2;
title 'Informations sur la nouvelle base de donn�es cr��e (avec pasage au ln)';
run;
proc print data=projet2 (obs=10); /* on visualise les 10 premi�re observations de cette nouvelle base de donn�es */
run;

proc univariate data=projet2;
var ln_nb_grilles;
OUTPUT OUT=moyenne2 mean= m_ln_nb_grilles;
title 'Statistiques sur les variables quantitatives (pass�es au log)';
run;

proc print data=moyenne2; /* on obtient un fichier avec 3 variables (celles gard�es au dessus) et leur valeur moyenne */
title 'Donn�es moyenn�es';
run;
/* 16.9465  comme valeur moyenne pour la variable quanti pass�e au log */


/* PARTIE PREDICTION */
/* Ajout de lignes suppl�mentaires pour la pr�diction de lambda */
data more;
input Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle;
keep Y ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle; 
										
datalines; 
. 16.9465 1 1 1
. 16.9465 1 1 0
. 16.9465 1 0 0
. 16.9465 0 0 0
. 16.9465 0 0 1
. 16.9465 0 1 1
. 16.9465 0 1 0
. 16.9465 1 0 1

;/* 16.9465 donn�es trouv�es par UNIVARIATE (les dummy c'est � nous de choisir) */

data newprojet2;
set projet2 more;
run;
proc print data=newprojet2; /* pour v�rifier que la nouvelle observation a bien �t� ajout�e */
run;

/* Estimation : Mod�le de comptage (Poisson) */

proc countreg data=newprojet2; /* estime les beta et donne le niveau de significaivit� des variables associ�es */
model Y = ln_nb_grilles boule jour_de_tirage numero_de_tirage_dans_le_cycle / dist=poisson;
output out=outestim pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des param�tres b�ta_i (interpr�tables)';
run;

/* estimation de Y (lambda_chap) pour la ligne suppl�mentaire */

proc print data=outestim; * 1 pr�vision ;
var lambda_chap;
where Y = .;   
title 'Pr�visions mod�le de Poisson';
run;
/* 0.47162 
   0.50749 
   0.43049 
   0.37733 
   0.35066 
   0.41338 
   0.44482 
   0.40006
 lambda_chap pour la configuration des datalines */

data calcul; /* calcul de P(Y=a) */
a=0;
b=1;
c=2;
factora = fact(a);
factorb = fact(b);
factorc = fact(c);
prob0=(0.47162 **a*exp(-0.47162))/factora;
prob1=(0.47162 **b*exp(-0.47162 ))/factorb;
prob2=(0.47162 **c*exp(-0.47162 ))/factorc;

run;
proc print data=calcul;
title 'Probabilit�s';
run;
