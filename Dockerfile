# 1. Define la imagen base adecuada (Nodejs) [cite: 8]
FROM node:18-alpine

# 2. Crea el directorio de trabajo donde estará la aplicación
WORKDIR /usr/src/app

# 3. Copia los archivos de configuración de dependencias (para optimizar el cache)
COPY package*.json ./

# 4. Instala las dependencias necesarias [cite: 10]
RUN npm install

# 5. Copia el código de la aplicación [cite: 9]
COPY . .

# 6. Expone el puerto correcto (ej: 8080) [cite: 11]
EXPOSE 3000

# 7. Configura el comando para iniciar la aplicación [cite: 12]
CMD [ "npm", "start" ]