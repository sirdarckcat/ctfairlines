PHONY=server

server: router/nsjail chroots/blackbox chroots/cdls chroots/mcdu
	docker run -P --privileged -it $$(docker build -q .)

router/nsjail:
	cd router/nsjail && git submodule init

chroots/%: players/%
	rm -rf $@
	mkdir -p $@
	docker export $$(docker create $$(docker build -q $<)) | gzip > $@/img.tgz

clean:
	rm -rf chroots/*
