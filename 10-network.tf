resource "yandex_vpc_network" "dimploma" {
  name = "dimploma-${terraform.workspace}"
}

resource "yandex_vpc_subnet" "public" {
  name           = "public-${terraform.workspace}"
  v4_cidr_blocks = ["10.0.0.0/24"]
  # zone = "ru-central1-a"
  network_id = yandex_vpc_network.dimploma.id
}

resource "yandex_vpc_subnet" "private" {
  name           = "private-${terraform.workspace}"
  v4_cidr_blocks = ["10.0.2.0/24"]
  # zone = "ru-central1-a"
  network_id = yandex_vpc_network.dimploma.id
  # route_table_id = yandex_vpc_route_table.private_to_public.id
}
