PHONY=server

organizers/nsjail/nsjail:
	cd organizers/nsjail; git submodule init; make

chroots/%: players/%
	rm -rf $@
	mkdir -p $@
	docker build -t $< $<
	docker export $(shell docker create $<) | gzip > $@/img.tgz

server: organizers Dockerfile chroots/blackbox chroots/cdls chroots/mcdu
	docker build -t server .

clean:
	rm -rf chroots/*
