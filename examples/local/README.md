# Local example

Applies circuit-monitoring to a throwaway Rocky Linux 10 container with systemd, along with circuit-docker and circuit-node-exporter. You need Conn3x and Podman.

Docker runs containers of its own, so the host container runs privileged, which is simplest with rootful Podman. On a Mac, use the Podman machine's root connection. On Linux, use `sudo podman`:

```sh
export CONTAINER_CONNECTION=podman-machine-default-root   # macOS
export PODMAN="sudo podman"                               # Linux
./up.sh
conn3x init
conn3x apply
conn3x plan
```

The second plan says `No changes.` To look at the result:

```sh
ssh -p 2222 -i id_ed25519 -o UserKnownHostsFile=known_hosts root@127.0.0.1 curl -s localhost:9090/api/v1/targets
```

`up.sh` listens on `127.0.0.1:2222`. Set `PORT` to use another port, and pass the same port to Conn3x with `-var port=PORT`. Set `CONTAINERFILE` to test another distro, such as one of the images in Conn3x's `test/images`, which CI uses.

`./down.sh` removes the container, its volumes, the key and the state.

Grafana listens on port 3000 in the container. To open it from your machine, forward the port over SSH and sign in as `admin` with the example's throwaway password, `change-me-locally`:

```sh
ssh -p 2222 -i id_ed25519 -o UserKnownHostsFile=known_hosts -L 3000:localhost:3000 root@127.0.0.1
```
