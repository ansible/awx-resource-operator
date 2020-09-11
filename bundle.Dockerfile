FROM scratch

LABEL operators.operatorframework.io.bundle.mediatype.v1=registry+v1
LABEL operators.operatorframework.io.bundle.manifests.v1=manifests/
LABEL operators.operatorframework.io.bundle.metadata.v1=metadata/
LABEL operators.operatorframework.io.bundle.package.v1=awx-resource-operator
LABEL operators.operatorframework.io.bundle.channels.v1=release-0.1
LABEL operators.operatorframework.io.bundle.channel.default.v1=release-0.1

COPY deploy/olm-catalog/awx-resource-operator/manifests /manifests/
COPY deploy/olm-catalog/awx-resource-operator/metadata /metadata/
