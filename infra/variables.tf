# Variables de configuración (contraseñas, nombres)
# infra/variables.tf

variable "app_image_url" {
  description = "URL de la imagen de Docker Hub para el servicio de apps"
  default     = "elibarraza/gastos-app:1.0" 
}

variable "db_password" {
  description = "Contraseña segura para la Base de Datos RDS"
  type        = string
  sensitive   = true 
  default     = "Password123"
}