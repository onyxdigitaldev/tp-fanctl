srpm:
	dnf install -y git rpm-build
	mkdir -p rpmbuild/{SOURCES,SPECS}
	git archive --format=tar.gz --prefix=tp-fanctl-1.0.0/ HEAD > rpmbuild/SOURCES/tp-fanctl-1.0.0.tar.gz
	cp tp-fanctl.spec rpmbuild/SPECS/
	rpmbuild -bs rpmbuild/SPECS/tp-fanctl.spec --define "_topdir $(shell pwd)/rpmbuild"
	cp rpmbuild/SRPMS/*.src.rpm $(outdir)
