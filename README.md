# grafana

[Graphana](https://grafana.com) - Dashboard anything. Observe everything.  Query, visualize, alert on, and understand your data no matter where it’s stored. With Grafana you can create, explore and share all of your data through beautiful, flexible dashboards

## Container

### Versions

- [September 2, 2021](https://grafana.com/grafana/download?pg=graf-deployment-options&plcmt=deploy-box-1) - Active version is 8.1.2 as tag [REL_13_4](https://github.com/grafana/grafana/tags)

### Manual Build

```
docker build --build-arg ALPINE_TAG=3.14.1 --build-arg BRANCH=v8.1.2 --tag graphana:dev -f Containerfile . 
docker run -i -p 3000:3000 -t --name grafana --rm grafana:dev
```

## Configuration

### Anonymous Auth

The default for this container is to not have authentication. The `/etc/grafana/config.ini` file provides this default configuration which overrides the `default.ini` file.

```
#################################### Anonymous Auth ######################
[auth.anonymous]
# enable anonymous access
enabled = true

# specify organization name that should be used for unauthenticated users
org_name = Main Org.

# specify role for unauthenticated users
org_role = Admin

# mask the Grafana version number for unauthenticated users
hide_version = false
```

### Paths

- Configuration file `/tec/grafana/config.ini`
- This container runs under the `graphana` user and the primary location for grafana is `/home/grafana`. 
- The location for the instance data is `/opt/grafana-data` which is linked to `'/home/grafana/lib`.
- The plugin directory is `/home/grafana/lib/plugins`
- logs are sent to `/dev/stdout`


## Usage



