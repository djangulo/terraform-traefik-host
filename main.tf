module "docker_compose_host" {
  source  = "djangulo/docker-compose-host/digitalocean"
  version = "0.2.4"

  do_token     = var.do_token
  droplet_name = "Projects"
  tags         = ["test", "staging"]
  image        = "ubuntu-18-04-x64"
  region       = "nyc3"
  size         = "s-1vcpu-1gb"

  ssh_keys        = var.ssh_keys
  ssh_private_key = var.ssh_private_key
  init_script     = "./scripts/setup.sh"
  domain          = var.domain
  user            = var.user
  records         = var.records
}

resource "null_resource" "traefik_up" {

  connection {
    type = "ssh"
    user = var.user
    host = module.docker_compose_host.ipv4_address
  }

  provisioner "file" {
    content = templatefile("${path.module}/docker-compose.yml", {
      letsencrypt_admin_email = var.letsencrypt_admin_email,
    })
    destination = "/home/${var.user}/traefik/docker-compose.yml"
  }

  provisioner "remote-exec" {
    inline = [
      "cd /home/${var.user}/traefik",
      "docker-compose down",
      "docker-compose up -d",
    ]
  }
}
