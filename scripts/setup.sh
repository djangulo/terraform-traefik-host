#!/usr/bin/env bash

##
## Create directory scaffolding.
##

set -euxo pipefail

mkdir -p $(pwd)/traefik
working_dir=$(pwd)/traefik

cd $working_dir

mkdir -p \
    $working_dir/letsencrypt \
    $working_dir/services

cat <<EOF > $working_dir/compose.sh
#/usr/bin/env bash

set -euxo pipefail

##
## Chains together all the docker-compose.yml files in ./services/ in order to load-balance
## them under traefik.

CMD="docker-compose -f docker-compose.yml"
for service in \$(ls -1r ./services); do
    CMD+=" -f ./services/\$service/docker-compose.yml";
done;
CMD+=" \$@"
echo -e "\e[33m\$CMD"
eval "\$CMD"

EOF

chmod +x $working_dir/compose.sh

