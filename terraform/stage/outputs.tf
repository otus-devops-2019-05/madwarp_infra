output "reddit_external_ip" {
  value = "${module.app.reddit_external_ip}"
}

output "db_internal_ip" {
  value = "${module.db.mongo_db_internal_ip}"
}
output "db_external_ip" {
  value = "${module.db.mongo_db_external_ip}"
}

