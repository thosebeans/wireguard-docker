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

<table>
  <tr>
    <th>
      ENV-Variable
    <th>
      Example
    <th>
      Default value
    <th>
      Mandatory
    <th>
      Description
  <tr>
    <td>
      I_NAME
    <td>
      wg0
    <td>
    <td>
      X
    <td>
      I_NAME is the name of the wireguard interface.
      <br>
      It has to match the pattern <code>^[0-9a-zA-Z_-]+$</code>.
  <tr>
    <td>
      I_PRIVATEKEY
    <td>
      8NkTeTAM5KUwa4vJ4qOQrhJjBBf4bQX3Yl+srl3O0Ek=
    <td>
    <td>
    <td>
      I_PRIVATEKEY is the private-key of the interface.
      <br>
      It has to be a base64-encoded private-key, like one generated from <code>wg genkey</code>.
  <tr>
    <td>
      I_LISTENPORT
    <td>
      51820
    <td>
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
    <td>
      If set, I_CREATE gives the container the permission to create a new wireguard interface with the name <b>I_NAME</b>.
  <tr>
    <td>
      I_REUSE
    <td>
      1
    <td>
    <td>
    <td>
      If set, I_REUSE give the container the permission, to reuse an already existing wireguard interface, called <b>I_NAME</b>.
</table>

### Peers
`ZZZ` is a placeholder for the peer-id. The peer-id is an alphanumeric identifier, matching `^[0-9a-zA-Z-]+$`, to match related environment variables.


      
#### P_ZZZ_PUBK
P_ZZZ_PUBK is the public-key of the peer. It has to be a bas64-encoded public-key, like the ones created by `wg pubkey`.
P_ZZZ_PUBK has to be present for a peer to be recognized by the container.  
Example: `P_chris_PUBK=stuILATiFXEVewTQBHzdlEqR31RxbNiRmqXSa16qygk=`
