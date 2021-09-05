# wireguard-docker

This container makes it easy to deploy a wireguard-interface, using docker.

## Features
- configuration with env-variables
- persistent wireguard-interface across container restart
- minimal connection loss 
- loading secret-keys from local storage

## Configuration
wireguard-docker is configured entirely through environment variables.

### Interface

#### I_NAME
I_NAME is the name of the interface. It has to match the pattern `^[0-9a-zA-Z_-]+$`  
Example: `I_NAME=wg0`

#### I_PRIVATEKEY
I_PRIVATEKEY is the private-key of the interface. It has to be a base64-encoded private-key,
like one generated from `wg genkey`.  
Example: `I_PRIVATEKEY=8NkTeTAM5KUwa4vJ4qOQrhJjBBf4bQX3Yl+srl3O0Ek=`

#### I_LISTENPORT
I_LISTENPORT is the port on which the interface should listen for its peers. Its an integer between `0` and `65535`.  
Example: `I_LISTENPORT=51820`

#### I_FWMARK
I_FWMARK is a firewall-marking for outgoing packets. Its an integer between `0` and `4294967295` or `off`(same as 0).
I_FWMARK can be in deciamal or hexadecimal.  
Example: `I_FWMARK=off`

### Peers
`ZZZ` is a placeholder for the peer-id. The peer-id is an alphanumeric identifier, matching `^[0-9a-zA-Z-]+$`, to match related environment variables.

#### P_ZZZ_PUBK
P_ZZZ_PUBK is the public-key of the peer. It has to be a bas64-encoded public-key, like the ones created by `wg pubkey`.
P_ZZZ_PUBK has to be present for a peer to be recognized by the container.  
Example: `P_chris_PUBK=stuILATiFXEVewTQBHzdlEqR31RxbNiRmqXSa16qygk=`

