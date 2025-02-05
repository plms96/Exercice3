# Descriptif

Fichier pour l'exercice 3

###################################################################
#                 STAGE 1 : BUILD DU FRONT (REACT + VITE)         #
###################################################################
# On choisit l'image officielle Node (version 18 ou 19 si besoin).
# "slim" est un compromis entre "full" (buster, bullseye) et "alpine".
FROM node:18-slim AS build-front

# On définit le dossier de travail pour ce stage.
WORKDIR /app/front

# On copie d'abord les fichiers package.json et package-lock.json
# (ou yarn.lock) pour permettre le caching de npm install.
COPY front/package*.json ./

# On installe les dépendances du front.
RUN npm install

# On copie le reste du code source du front.
COPY front/ .

# On lance la commande de build Vite pour React.
RUN npm run build
# Résultat : le build final se trouve dans /app/front/dist

###################################################################
#     STAGE 2 : BACK-END + COPIE DES FICHIERS STATIQUES FRONT     #
###################################################################
FROM node:18-slim

# Création d'un utilisateur non-root pour des raisons de sécurité.
# - addgroup / adduser peuvent varier selon l'OS de base. Sur Debian/Ubuntu,
#   tu peux utiliser groupadd / useradd. Sur Alpine, c’est addgroup / adduser.
RUN addgroup --system appgroup && \
    adduser --system --ingroup appgroup appuser

# On définit le dossier de travail pour le conteneur final.
WORKDIR /app

# On copie uniquement ce qui est nécessaire pour installer les dépendances
# du back (caching Docker sur l'étape d'installation).
COPY back/package*.json ./
RUN npm install

# On crée un dossier "public" (ou tout autre nom) où on va déposer
# les fichiers statiques du front.
RUN mkdir public

# On copie les fichiers du front compilé (dist) depuis le STAGE 1
# (build-front) dans notre dossier public.
COPY --from=build-front /app/front/dist ./public

# On copie maintenant le reste du code back.
COPY back/ .

# (Optionnel) On définit quelques variables d'environnement, par exemple :
ENV PORT=8080

# On documente le port exposé (ce n'est pas obligatoire pour Docker,
# mais c'est pratique pour la compréhension).
EXPOSE 8080

# Ajout d’un HEALTHCHECK qui ping l’endpoint /health toutes les 30 secondes.
# Si la requête échoue, Docker considérera le conteneur comme unhealthy.
HEALTHCHECK --interval=30s --timeout=5s --retries=3 \
  CMD wget -qO- http://localhost:8080/health || exit 1

# On passe en utilisateur non-root.
USER appuser

# Enfin, on lance l'application Node via la commande start définie
# dans back/package.json.
CMD ["npm", "start"]
 
