PHONY=server

server: organizers/nsjail chroots/blackbox chroots/cdls chroots/mcdu
	docker run --privileged -it $$(docker build -q .)

organizers/nsjail:
	cd organizers/nsjail && git submodule init

chroots/%: players/%
	rm -rf $@
	mkdir -p $@
	docker export $$(docker create $$(docker build -q $<)) | gzip > $@/img.tgz

clean:
	rm -rf chroots/*