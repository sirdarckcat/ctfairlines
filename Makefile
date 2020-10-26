PHONY=server

organizers/nsjail/nsjail:
	cd organizers/nsjail; git submodule init; make

chroots/%: players/%
	rm -rf $@
	mkdir -p $@
	docker export $(shell docker create $(shell docker build -q $<)) | gzip > $@/img.tgz

server: organizers Dockerfile chroots/blackbox chroots/cdls chroots/mcdu
	docker build -q .

clean:
	rm -rf chroots/*
