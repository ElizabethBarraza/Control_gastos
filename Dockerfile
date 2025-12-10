#  Define la imagen base adecuada
FROM node:18-alpine

# Crea el directorio de trabajo donde estará la aplicación
WORKDIR /usr/src/app

# Copia los archivos de configuración de dependencias 
COPY package*.json ./

# Instala las dependencias necesarias 
RUN npm install

# Copia el código de la aplicación 
COPY . .

# puerto correcto 
EXPOSE 3000

# Configura el comando para iniciar la aplicación 
CMD [ "npm", "start" ]