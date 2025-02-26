
variable "queue_name" {
    type = string
}


variable "delay_seconds" {
    type = string
    default = 5
}

variable "lambda_function_name" {
  type = string
}