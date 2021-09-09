# wireguard-docker

This container makes it easy to deploy a wireguard-interface, using docker.

## Features

- configuration with env-variables
- persistent wireguard-interface across container restart
- minimal connection loss 
- loading secret-keys from local storage

## Build

```sh
git clone https://github.com/thosebeans/wireguard-docker.git
wireguard-docker/build.sh
```

## Configuration

wireguard-docker is configured entirely through environment variables.

### Interface

<table>
  <tr>
    <th>
      ENV-Variable
    <th>
      Example
    <th>
      Default value
    <th>
      Description
  <tr>
    <td>
      I_NAME
    <td>
      wg0
    <td>
    <td>
      I_NAME is the name of the wireguard interface.
      <br>
      It has to match the pattern <code>^[0-9a-zA-Z_-]+$</code>.
      <br>
      I_NAME has to be set.
  <tr>
    <td>
      I_PRIVATEKEY
    <td>
      8NkTeTAM5KUwa4vJ4qOQrhJjBBf4bQX3Yl+srl3O0Ek=
      <hr>
      /run/secrets/wg0_priv
    <td>
    <td>
      I_PRIVATEKEY is the private-key of the interface.
      <br>
      It has to be a base64-encoded private-key, like one generated from <code>wg genkey</code>
      or the path to a file, storing such a key.
  <tr>
    <td>
      I_LISTENPORT
    <td>
      51820
    <td>
    <td>
      I_LISTENPORT is the port on which the interface should listen for its peers.
      <br>
      Its an integer between <b>0</b> and <b>65535</b>.
  <tr>
    <td>
      I_FWMARK
    <td>
      644
    <td>
    <td>
      I_FWMARK is a firewall-marking for outgoing packets.
      <br>
      Its an integer between <b>0</b> and <b>4294967295</b> or <b>off</b>(same as 0).
  <tr>
    <td>
      I_CREATE
    <td>
      1
    <td>
      1
    <td>
      If set, I_CREATE gives the container the permission to create a new wireguard interface with the name <b>I_NAME</b>.
  <tr>
    <td>
      I_REUSE
    <td>
      1
    <td>
    <td>
      If set, I_REUSE give the container the permission, to reuse an already existing wireguard interface, called <b>I_NAME</b>.
  <tr>
    <td>
      I_NODESTROY
    <td>
      1
    <td>
    <td>
      If set, I_NODESTROY skips the destruction of the wireguard interface, after the container gets shut down.
</table>

### Peers
`ZZZ` is a placeholder for the peer-id. The peer-id is an alphanumeric identifier, matching `^[0-9a-zA-Z-]+$`, to match related environment variables.  
Example: `P_chris_PUBK=pea3swDlkV7Db1OIF9LK2bDSR0HhR+g7TS3Es4c1pWE=`

<table>
  <tr>
    <th>
      ENV-Variable
    <th>
      Example
    <th>
      Description
  <tr>
    <td>
      P_ZZZ_PUBK
    <td>
      pea3swDlkV7Db1OIF9LK2bDSR0HhR+g7TS3Es4c1pWE=
    <td>
      P_ZZZ_PUBK is the public-key of the peer.
      <br>
      It has to be a bas64-encoded public-key, like the ones created by <code>wg pubkey</code>.
      <br>
      P_ZZZ_PUBK has to be present for a peer to be recognized by the container.
  <tr>
    <td>
      P_ZZZ_PSK
    <td>
      t8QXS7CsF4YPq27GmfEHTURyY6IgCaYzdziRN+WF32g=
      <hr>
       /run/secrets/wg0_psk
    <td>
      P_ZZZ_PSK is the preshared-key of the peer.
      <br>
      It has to be a base64-encoded preshared-key, like one generated from <code>wg genpsk</code>
      or the path to a file, storing such a key.
  <tr>
    <td>
      P_ZZZ_IPS
    <td>
      10.0.0.1/8,fd9e:21a7:a92c:2323::1/64
    <td>
      P_ZZZ_IPS are the allowed ips of the peer (the routes to the peer).
      <br>
      P_ZZZ_IPS has to be a comma seperated list of IPv4 or IPv6 addresses.
  <tr>
    <td>
      P_ZZZ_END
    <td>
      192.168.178.22:51820
    <td>
      P_ZZZ_END is the endpoint of the peer.
  <tr>
    <td>
      P_ZZZ_PKA
    <td>
      5
    <td>
      P_ZZZ_PKA is the persistent keep-alive of the peer.
      <br>
      P_ZZZ_PKA has to be an integer value between <b>0</b> and <b>65535</b>.
</table>

## Troubleshooting

### RTNETLINK answers: Operation not permitted

#### Problem
      
The container doesn't have the capabilities to do any network-manipulation.

#### Solution

Add the capability `CAP_NET_ADMIN`.
      
### RTNETLINK answers: Not supported
      
#### Problem
      
The wireguard kernel-module isn't loaded.
      
#### Solution 1

Load the `wireguard` module before starting the container.
      
#### Solution 2
      
Bind `/lib/modules` to `/lib/modules` into the container and run the container in __priviliged mode__.
The container will try to load the module on startup.
