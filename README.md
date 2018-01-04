# Luzifer / reg-clean

Cleanup S3 based Docker registry v2:

- Delete all non-tagged manifests
- Garbage-collection can remove the blobs

## Usage

```bash
## Build container (optional)
$ docker build -t luzifer/reg-clean .

## Define AWS credentials
$ cat env
AWS_ACCESS_KEY_ID=myaccesskey
AWS_SECRET_ACCESS_KEY=mysecretaccesskey
AWS_DEFAULT_REGION=eu-west-1

AUTH=registryuser:pass
BUCKET=io.luzifer.docker-registry
REGISTRY=https://registry.luzifer.io

## Execute script
$ docker run --rm -ti --env-file=env luzifer/reg-clean
```
