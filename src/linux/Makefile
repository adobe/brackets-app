INSTALL_PREFIX=./bundle

build: clean
	cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	cd build; make

clean:
	rm -rf build src/config.vala bundle

run:
	../../bin/linux/brackets
