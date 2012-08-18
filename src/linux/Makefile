build: clean
	cmake -H. -Bbuild -DCMAKE_INSTALL_PREFIX=./bundle
	cd build; make

clean:
	rm -rf build src/config.vala

run:
	../../bin/linux/brackets
