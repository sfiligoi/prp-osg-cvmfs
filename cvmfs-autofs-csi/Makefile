.PHONY: all cvmfsplugin

NAME=csi-cvmfsplugin

all: cvmfsplugin

cvmfsplugin:
	if [ ! -d ./vendor ]; then dep ensure; fi
	CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' -o  _output/$(NAME) ./cvmfs


clean:
	go clean -r -x
	rm -f deploy/docker/rbdplugin
