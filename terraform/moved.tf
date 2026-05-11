moved {
  from = aws_instance.production
  to   = aws_instance.env["production"]
}

moved {
  from = aws_db_instance.main
  to   = aws_db_instance.env["production"]
}
