PROC IMPORT OUT= WORK.MEDAILLES                                                                                                           
            DATAFILE= "C:\Users\Philippine\Documents\Cours\Maths\M2\Econometrie\SERVEUR ECONOMETRIE 2020-2021\MASTER 2 ING ECO\SERVEUR\ECONOMETRIE DES VARIABLES QUALITATIVES\DATA\MEDAILLES.xls"                        
            DBMS=xls REPLACE;                                                                                                     
     GETNAMES=YES;                                                                                                                      
RUN;

/* Statistiques diverses : base de données brute */


proc contents data=medailles ; /* donne des infos sur la base de données, notamment le nombre d'individu et 
								le nombre de variables ainsi que leur dénomination et leur type (n'affiche pas la base)*/
title 'Informations relatives à la base de données sur les médailles olympiques';
run;

proc print data=medailles (obs=50); /* affiche les  premières entrées de la base */
run;

proc sort data=medailles; /*permet de trier le tableau par ordre chronologique, l'index est bien remis à jour */
by annees;
run;
proc print data=medailles (obs=50); /* affiche les  premières entrées de la base(triées par ordre chrono ici) */
run;
proc univariate data=medailles; /*donne des informations statistiques (moyenne, médiane, quantiles, min, max,...) 
								sur chaque variable considérée en dessous, et ce en fonction de chaque année ici */
								
by annees;
var pop pib;
title 'Statistiques';
run;

/* on regarde les mêmes choses mais cette fois ci par pays et non par année */
proc sort data=medailles;
by pays;
run;
proc print data=medailles (obs=50); /* affiche les  premières entrées de la base (triées par ordre alphabétique du pays ici) */
run;
proc univariate data=medailles; /*donne des informations statistiques (moyenne, médiane, quantiles, min, max,...) 
								sur chaque variable considérée en dessous, et ce en fonction de chaque pays ici 
								on stock ici la population moyenne et le pib moyen de chaque pays (sur toutes les années)
								dans les variables mpop et mpib et on les enregistres dans un nouveau fichier 'moyenne'*/
by pays;
var pop pib;
OUTPUT OUT=moyenne mean=mpop mpib;
title 'Statistiques moyennes';
run;
proc print data=moyenne; /* on obtient un fichier avec 3 variables : pays, mpop et mpib où on a donc plus la notion d'années
							car on a moyenné sur ça, ce fichier sera utile lors de la prédiction de lambda*/
title 'Données moyennées sur les années';
run;

/* Transformation des données en ln (car valeurs grandes et facilite les interprétations) */

data medailles2; /* on créé un nouveau fichier à partir de l'ancien */
set medailles;
lnpop = log(pop); /* définition des nouvelles variables */
lnpib = log(pib);
label lnpop='log(pop)' lnpib='log(pib)';
/* on ne garde que les donnéesde l'année 88 en supprimant les enregistrements ayant des valeurs manquantes */
if annees=88;           * on ne travaille que sur 1988 ;
if totalmedaille ne .;  * 'ne' : pas égal à ;
if pop ne .;
keep totalmedaille lnpop lnpib pop pib pays payshote; /* on garde la variable endogène et les variables exogènes qui nous intéressent */
run;

proc contents data=medailles2 ;
title 'Informations sur la nouvelle base de données créée ';
run;
proc print data=medailles2 (obs=50);
run;
proc univariate data=medailles2;
title 'Informations statistiques sur la nouvelle base de données'; /* infos stats sur les variables gardées */
run;

proc sort data=medailles2;
by pays;
run;
proc univariate data=medailles2; /*Infos stats pays pour 1988, pour les 2 variables gardées ci-dessous */
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
/* Ajout de lignes supplémentaires pour la prédiction de lambda */
data more;
input totalmedaille pop pib payshote;
lnpop = log(pop);
lnpib = log(pib);
keep totalmedaille lnpop lnpib payshote; /* les données que l'on ajoute ensuite doivent aussi être mise sous ln ou non ? */
										/* apparement non */
datalines; 
. 55900000 1.36E12 0
. 57200000 1.01E12 0
;/* données trouvées par UNIVARIATE (données mpop et mpib et la dummy c'est à nous de choisir)*/

data new88;
set medailles2 more;
run;
proc print data=new88;
run;

/* Estimation : Modèle de comptage (Poisson) */

proc countreg data=new88; /* estime les beta et donne le niveau de significaivité des variables associées */
model totalmedaille = lnpop lnpib payshote/ dist=poisson;
output out=out88 pred=lambda_chap ; /*pred = lambda chapeau, pas les probas */
							
title 'Estimation des paramètres bêta_i (interprétable)';
run;

/* prévision de total_medaille (donc estimation de lambda_chap) pour la ligne supplémentaire */
proc print data=out88; * 1 prévision ;
var lambda_chap;
where totalmedaille = .;   
title 'Prévisions modèle de Poisson';
run;

proc sort data=medailles2;
by totalmedaille;
run;
/* comparaison de lambda_chap et du vrai nombre de médaille pour la france en 1988 */
/* est-ce que la somme des probas donne toujours 1 quand on a un petit nombre de modalités ?*/
proc print data=medailles2;
where PAYS='France';
run;

/*possible de le faire pour toutes les modalités quand peu de modalités mais pas quand beaucoup */
data calcul; /* calcul de P(Y=a) */
a=16; /*modalité pour laquelle on veut calculer la proba */
factor = fact(a);
probanew=(30.1793**a*exp(-30.1793))/factor; /* lambda_chap trouvé avant*/
run;
proc print data=calcul;
run;
