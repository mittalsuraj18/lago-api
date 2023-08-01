Run the following commands
```shell
export REPO_PATH=""
export VERSION=""
docker build -t $REPO_PATH/api:$VERSION-amd64 --platform linux/amd64 -f Dockerfile . && docker push $REPO_PATH/api:$VERSION-amd64

docker build -t $REPO_PATH/api:$VERSION-arm64 --platform linux/arm64v8 -f Dockerfile.arm64 . && docker push $REPO_PATH/api:$VERSION-arm64

docker manifest create $REPO_PATH/api:$VERSION \
$REPO_PATH/api:$VERSION-arm64 \
$REPO_PATH/api:$VERSION-amd64

docker manifest annotate --arch arm64 $REPO_PATH/api:$VERSION \
$REPO_PATH/api:$VERSION-arm64


docker manifest inspect $REPO_PATH/api:$VERSION

docker manifest push $REPO_PATH/api:$VERSION

```