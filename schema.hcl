table "users" {
  schema = schema.terrateam
  column "id" {
    type = char(36)
    null = false
  }
  column "name" {
    type = varchar(32)
    null = false
  }
  column "is_admin" {
    type = boolean
    null = false
  }
  primary_key {
    columns = [column.id]
  }
}
schema "terrateam" {
}