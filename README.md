# RAU4: Proyecto de Control de Gastos en la Nube 

Este repositorio contiene la aplicación de Control de Gastos, su contenedor Docker y la infraestructura como código (IaC) para ser desplegada en un dominio gratuito

## Enlaces Importantes

* [cite_start]**URL Pública Funcional:** [Añadir enlace HTTPS aquí cuando esté desplegado] 
* [cite_start]**Imagen Docker Hub:** `elibarraza/gastos-app:1.0` 

## Instrucciones de Ejecución Local (Docker)

Para ejecutar la aplicación en un ambiente local, sigue estos pasos:

1.  **Clonar el repositorio:** `git clone https://github.com/ElizabethBarraza/Control_gastos.git`
2.  **Construir la imagen:** `docker build -t gastos-app .`
3.  **Ejecutar el contenedor:** `docker run -p 8000:3000 gastos-app`
4.  **Acceso:** Abrir `http://localhost:8000` en el navegador.