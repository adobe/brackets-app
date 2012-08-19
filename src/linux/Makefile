INSTALL_PREFIX=./bundle

build: clean
	cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=${INSTALL_PREFIX}
	cd build; make

clean:
	rm -rf build src/config.vala src/config_install.vala bundle

run:
	../../bin/linux/brackets

install:
	cd build; make install
