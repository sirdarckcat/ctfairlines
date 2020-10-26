PHONY=server

server: organizers/nsjail/nsjail Dockerfile chroots/blackbox chroots/cdls chroots/mcdu
	docker build .

organizers/nsjail/nsjail:
	cd organizers/nsjail; git submodule init; make

chroots/%: players/%
	rm -rf $@
	mkdir -p $@
	docker export $(shell docker create $(shell docker build -q $<)) | gzip > $@/img.tgz

clean:
	rm -rf chroots/*
