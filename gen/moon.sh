#!/bin/sh

# Default ZeroTier moon port
moon_port=9993

# Parse arguments
while getopts "4:6:p:" arg; do
    case $arg in
        4)
            ipv4_address="$OPTARG"
            echo "IPv4 address: $ipv4_address"
            ;;
        6)
            ipv6_address="$OPTARG"
            echo "IPv6 address: $ipv6_address"
            ;;
        p)
            moon_port="$OPTARG"
            echo "Moon port: $moon_port"
            ;;
        ?)
            echo "Unknown argument"
            exit 1
            ;;
    esac
done

# Construct the stableEndpoints field for moon.json
stableEndpointsForSed=""
if [ -z "${ipv4_address+x}" ]; then
    if [ -z "${ipv6_address+x}" ]; then
        echo "Please set IPv4 address or IPv6 address."
        exit 1
    else
        stableEndpointsForSed="\"$ipv6_address\/$moon_port\""
    fi
else
    if [ -z "${ipv6_address+x}" ]; then
        stableEndpointsForSed="\"$ipv4_address\/$moon_port\""
    else
        stableEndpointsForSed="\"$ipv4_address\/$moon_port\",\"$ipv6_address\/$moon_port\""
    fi
fi

# Generate moon.json using zerotier-idtool initmoon
/usr/sbin/zerotier-idtool initmoon /var/lib/zerotier-one/identity.public > /var/lib/zerotier-one/moon.json

# Update moon.json with stableEndpoints
sed -i 's/"stableEndpoints": \[\]/"stableEndpoints": ['$stableEndpointsForSed']/g' /var/lib/zerotier-one/moon.json

# Generate the .moon file
/usr/sbin/zerotier-idtool genmoon /var/lib/zerotier-one/moon.json > /dev/null

# Create moons.d directory if it doesn't exist
mkdir -p /var/lib/zerotier-one/moons.d

# Move the generated .moon file to moons.d
mv *.moon /var/lib/zerotier-one/moons.d/

# Output the Moon ID
moon_id=$(grep \"id\" /var/lib/zerotier-one/moon.json | cut -d '"' -f4)
echo -e "Your ZeroTier moon ID is \033[0;31m$moon_id\033[0m"
