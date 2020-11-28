########################################################################

library(readxl)
library(questionr)
library(dplyr)
library(tidyr)
library(tidyselect)
library(factoextra)
library(openxlsx)

########################################################################

setwd('C:/Users/Bertrand Carlos/Documents/_M2_DS/Econom�trie/')

########################################################################

df = read_excel("EUROMILLION2019-2020.xlsx")

########################################################################
jour_de_tirage = c(1:nrow(df))
for (i in 1:nrow(df)) {
  if (df[i,2] == "VENDREDI") {
    jour_de_tirage[i] = 0
  } else if(df[i,2] == "MARDI") {
    jour_de_tirage[i] = 1
  }
}
df = select(df, -jour_de_tirage)
df = cbind(df, jour_de_tirage)

########################################################################

Y = c(1:nrow(df))
for (i in 1:nrow(df)) {
  if (df[i,10] <=9 & df[i,11]<=9) {
    Y[i] = 0
  } else if((df[i,10] <=9 & df[i,11]>=10) | (df[i,10] >=10 & df[i,11]<=9)) {
    Y[i] = 1
  } else if(df[i,10] >=10 & df[i,11]>=10) {
    Y[i] = 2
  }
}
filtre = c("E1", "E2")
df = select(df, -all_of(filtre))
df = cbind(df, Y)

########################################################################

df$date_de_tirage = as.Date(df$date_de_tirage)
df = df %>%
  separate(date_de_tirage, into = c("annee","mois", "jour"), sep = "-") %>%
  mutate(annee = as.numeric(annee),
         mois = as.numeric(mois),
         jour = as.numeric(jour))
filtre2 = c("mois", "jour")
df = select(df, -all_of(filtre2))

annee = c(1:nrow(df))

for (i in 1:nrow(df)) {
  if (df[i,3] == 2019) {
    annee[i] = 0
  } else if(df[i,3] ==2020) {
    annee[i] = 1
  }
}
df = select(df, -annee)
df = cbind(df, annee)

########################################################################

filtre3 = c("boules_gagnantes_en_ordre_croissant",
            "etoiles_gagnantes_en_ordre_croissant")
df = select(df, -all_of(filtre3))

########################################################################

num�ro_de_tirage_dans_le_cycle = c(1:nrow(df))
for (i in 1:nrow(df)) {
  if ((df[i,3] == "1") | (df[i,3] == "2") | (df[i,3] == "3") | (df[i,3] == "4") | (df[i,3] == "5")) {
    num�ro_de_tirage_dans_le_cycle[i] = 0
  } else {
    num�ro_de_tirage_dans_le_cycle[i] = 1
  }
}
df = select(df, -num�ro_de_tirage_dans_le_cycle)
df = cbind(df, num�ro_de_tirage_dans_le_cycle)

########################################################################

boule = c(1:nrow(df))
for (i in 1:nrow(df)) {
  boule[i] = sum(df[i,3], df[i,4], df[i,5], df[i,6], df[i,7])
  if (boule[i]%%2 == 0) {
    boule[i] = 0
  } else {
    boule[i] = 1
  }
}
filtre4 = c("B1", "B2", "B3", "B4", "B5")
df = select(df, -all_of(filtre4))
df = cbind(df, boule)

########################################################################

res = PCA(df, quali.sup = c(1,42:46))
plot.PCA(res,
         choix='var',
                  habillage = 'contrib',
                  cex=0.5,cex.main=0.5,
                  cex.axis=0.5,
                  title="Graphe des variables de l'ACP",col.quanti.sup='#0000FF')
fviz_contrib(res, choice = 'var', top = 5, axes = 2)

########################################################################

variables = c("nombre_de_gagnant_au_rang9_Euro_Millions_en_europe",
              "nombre_de_gagnant_au_rang9_Euro_Millions_en_france",
              "boule",
              "num�ro_de_tirage_dans_le_cycle",
              "annee",
              "Y",
              "jour_de_tirage")

df_final = select(df, all_of(variables))
write.csv(x = df_final, file = "data.csv")
write.xlsx(df_final, file = "data.xlsx")

########################################################################
