#
# Build mock and local RPM versions of tools
#

# Assure that sorting is case sensitive
LANG=C

#MOCKS+=epel-7-i386
MOCKS+=epel-6-i386
#MOCKS+=epel-5-i386
#MOCKS+=epel-4-i386

#MOCKS+=epel-7-x86_64
#MOCKS+=epel-6-x86_64
#MOCKS+=epel-5-x86_64
#MOCKS+=epel-4-x86_64

SPEC := lua-opt32.spec

all:: verifyspec $(MOCKS)


tarball::
	rm -f *.tar.gz
	VERSION=`grep ^Version: $(SPEC) | awk '{print $$NF}'`; \
	    wget http://www.lua.org/ftp/lua-$${VERSION}.tar.gz

# Oddness to get deduced .spec file verified
verifyspec:: FORCE
	@if [ ! -e $(SPEC) ]; then \
	    echo Error: SPEC file $(SPEC) not found, exiting; \
	    exit 1; \
	fi

srpm:: verifyspec FORCE
	@echo "Building SRPM with $(SPEC)"
	rm -rf rpmbuild
	rpmbuild --define '_topdir $(PWD)/rpmbuild' \
		 --define '_sourcedir $(PWD)' \
		 -bs $(SPEC) --nodeps

build:: srpm FORCE
	rpmbuild --define '_topdir $(PWD)/rpmbuild' \
		 --rebuild $(PWD)/rpmbuild/SRPMS/*.src.rpm

$(MOCKS):: verifyspec FORCE
	@if [ -e $@ -a -n "`find $@ -name \*.rpm`" ]; then \
		echo "Skipping RPM populated $@"; \
	else \
		echo "Building $@ RPMS with $(SPEC)"; \
		rm -rf $@; \
		/usr/bin/mock -q -r $@ --sources=$(PWD) \
		    --resultdir=$(PWD)/$@ \
		    --buildsrpm --spec=$(SPEC); \
		echo "Storing $@/*.src.rpm in $@.rpm"; \
		/bin/mv $@/*.src.rpm $@.src.rpm; \
		echo "Actally building RPMS in $@"; \
		rm -rf $@; \
		/usr/bin/mock -q -r $@ \
		     --resultdir=$(PWD)/$@ \
		     $@.src.rpm; \
	fi
	rm -f $@.src.rpm

mock:: $(MOCKS)

clean::
	rm -rf $(MOCKS)
	rm -rf rpmbuild

realclean distclean:: clean
	rm -f *.src.rpm

FORCE:
