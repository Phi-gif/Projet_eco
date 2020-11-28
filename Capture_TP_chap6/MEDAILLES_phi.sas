PROC IMPORT OUT= WORK.MEDAILLES                                                                                                           
            DATAFILE= "C:\Users\Philippine\Documents\Cours\Maths\M2\Econometrie\SERVEUR ECONOMETRIE 2020-2021\MASTER 2 ING ECO\SERVEUR\ECONOMETRIE DES VARIABLES QUALITATIVES\DATA\MEDAILLES.xls"                        
            DBMS=xls REPLACE;                                                                                                     
     GETNAMES=YES;                                                                                                                      
RUN;

/* Statistiques diverses : base de donn�es brute */


proc contents data=medailles ; /* donne des infos sur la base de donn�es, notamment le nombre d'individu et 
								le nombre de variables ainsi que leur d�nomination et leur type (n'affiche pas la base)*/
title 'Informations relatives � la base de donn�es sur les m�dailles olympiques';
run;

proc print data=medailles (obs=50); /* affiche les  premi�res entr�es de la base */
run;

proc sort data=medailles; /*permet de trier le tableau par ordre chronologique, l'index est bien remis � jour */
by annees;
run;
proc print data=medailles (obs=50); /* affiche les  premi�res entr�es de la base(tri�es par ordre chrono ici) */
run;
proc univariate data=medailles; /*donne des informations statistiques (moyenne, m�diane, quantiles, min, max,...) 
								sur chaque variable consid�r�e en dessous, et ce en fonction de chaque ann�e ici */
								
by annees;
var pop pib;
title 'Statistiques';
run;

/* on regarde les m�mes choses mais cette fois ci par pays et non par ann�e */
proc sort data=medailles;
by pays;
run;
proc print data=medailles (obs=50); /* affiche les  premi�res entr�es de la base (tri�es par ordre alphab�tique du pays ici) */
run;
proc univariate data=medailles; /*donne des informations statistiques (moyenne, m�diane, quantiles, min, max,...) 
								sur chaque variable consid�r�e en dessous, et ce en fonction de chaque pays ici 
								on stock ici la population moyenne et le pib moyen de chaque pays (sur toutes les ann�es)
								dans les variables mpop et mpib et on les enregistres dans un nouveau fichier 'moyenne'*/
by pays;
var pop pib;
OUTPUT OUT=moyenne mean=mpop mpib;
title 'Statistiques moyennes';
run;
proc print data=moyenne; /* on obtient un fichier avec 3 variables : pays, mpop et mpib o� on a donc plus la notion d'ann�es
							car on a moyenn� sur �a, ce fichier sera utile lors de la pr�diction de lambda*/
title 'Donn�es moyenn�es sur les ann�es';
run;

/* Transformation des donn�es en ln (car valeurs grandes et facilite les interpr�tations) */

data medailles2; /* on cr�� un nouveau fichier � partir de l'ancien */
set medailles;
lnpop = log(pop); /* d�finition des nouvelles variables */
lnpib = log(pib);
label lnpop='log(pop)' lnpib='log(pib)';
/* on ne garde que les donn�esde l'ann�e 88 en supprimant les enregistrements ayant des valeurs manquantes */
if annees=88;           * on ne travaille que sur 1988 ;
if totalmedaille ne .;  * 'ne' : pas �gal � ;
if pop ne .;
keep totalmedaille lnpop lnpib pop pib pays payshote; /* on garde la variable endog�ne et les variables exog�nes qui nous int�ressent */
run;

proc contents data=medailles2 ;
title 'Informations sur la nouvelle base de donn�es cr��e ';
run;
proc print data=medailles2 (obs=50);
run;
proc univariate data=medailles2;
title 'Informations statistiques sur la nouvelle base de donn�es'; /* infos stats sur les variables gard�es */
run;

proc sort data=medailles2;
by pays;
run;
proc univariate data=medailles2; /*Infos stats pays pour 1988, pour les 2 variables gard�es ci-dessous */
by pays;
var pop pib;
OUTPUT OUT=moyenne mean=mpop mpib;
run;
proc print data=moyenne;
run;

proc print data=moyenne;
where PAYS='France';
run;

/* PARTIE PREDICTION */
/* Ajout de lignes suppl�mentaires pour la pr�diction de lambda */
data more;
input totalmedaille pop pib payshote;
lnpop = log(pop);
lnpib = log(pib);
keep totalmedaille lnpop lnpib payshote; /* les donn�es que l'on ajoute ensuite doivent aussi �tre mise sous ln ou non ? */
										/* apparement non */
datalines; 
. 55900000 1.36E12 0
. 57200000 1.01E12 0
;/* donn�es trouv�es par UNIVARIATE (donn�es mpop et mpib et la dummy c'est � nous de choisir)*/

data new88;
set medailles2 more;
run;
proc print data=new88;
run;

/* Estimation : Mod�le de comptage (Poisson) */

proc countreg data=new88; /* estime les beta et donne le niveau de significaivit� des variables associ�es */
model totalmedaille = lnpop lnpib payshote/ dist=poisson;
output out=out88 pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des param�tres b�ta_i (interpr�table)';
run;

/* pr�vision de total_medaille (donc estimation de lambda_chap) pour la ligne suppl�mentaire */
proc print data=out88; * 1 pr�vision ;
var lambda_chap;
where totalmedaille = .;   
title 'Pr�visions mod�le de Poisson';
run;

proc sort data=medailles2;
by totalmedaille;
run;
/* comparaison de lambda_chap et du vrai nombre de m�daille pour la france en 1988 */
/* est-ce que la somme des probas donne toujours 1 quand on a un petit nombre de modalit�s ?*/
proc print data=medailles2;
where PAYS='France';
run;

/*possible de le faire pour toutes les modalit�s quand peu de modalit�s mais pas quand beaucoup */
data calcul; /* calcul de P(Y=a) */
a=16; /*modalit� pour laquelle on veut calculer la proba */
factor = fact(a);
probanew=(30.1793**a*exp(-30.1793))/factor; /* lambda_chap trouv� avant*/
run;
proc print data=calcul;
run;
