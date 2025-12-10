
output "alb_url_http" {
  description = "La URL del Balanceador de Cargas (ALB) para la aplicación. Úsala para el entregable."
  value       = "http://${aws_lb.gastos_alb.dns_name}"
}

output "alb_url_https" {
  description = "La URL del Balanceador de Cargas (ALB) con HTTPS (una vez validado el certificado)."
  value       = "https://${aws_lb.gastos_alb.dns_name}"
}