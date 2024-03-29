# Copyright 1999-2019 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

MY_P=${PN/f/F}-$(ver_rs 4 '-')
inherit autotools flag-o-matic user

DESCRIPTION="Relational database offering many ANSI SQL:2003 and some SQL:2008 features"
HOMEPAGE="https://www.firebirdsql.org/"
docroot=https://firebirdsql.org/file/documentation/pdf/en
SRC_URI="
	https://github.com/FirebirdSQL/firebird/releases/download/v$(ver_cut 1-3)/${MY_P}.tar.xz
	doc? ( ${docroot}/refdocs/fblangref40/firebird-40-language-reference.pdf
	       ${docroot}/firebirddocs/qsg3/firebird-3-quickstartguide.pdf
	       ${docroot}/refdocs/fbdevgd30/firebird-30-developers-guide.pdf
	       ${docroot}/firebirddocs/isql/firebird-isql.pdf
	       ${docroot}/firebirddocs/gsec/firebird-gsec.pdf
	       ${docroot}/firebirddocs/gbak/firebird-gbak.pdf
	       ${docroot}/firebirddocs/nbackup/firebird-nbackup.pdf
	       ${docroot}/firebirddocs/gstat/firebird-gstat.pdf
	       ${docroot}/firebirddocs/gfix/firebird-gfix.pdf
	       ${docroot}/firebirddocs/fbmgr/firebird-fbmgr.pdf
	       ${docroot}/firebirddocs/gsplit/firebird-gsplit.pdf
	       ${docroot}/firebirddocs/generatorguide/firebird-generator-guide.pdf
	       ${docroot}/firebirddocs/nullguide/firebird-null-guide.pdf
	       ${docroot}/firebirddocs/fbmetasecur/firebird-metadata-security.pdf
	       ${docroot}/firebirddocs/ufb/using-firebird.pdf
	     )"

LICENSE="IDPL Interbase-1.0"
SLOT="0"
KEYWORDS="amd64 ~x86"
IUSE="doc examples +server xinetd"

# FIXME: cloop?
DEPEND="
	dev-libs/icu:=
	dev-libs/libedit
	dev-libs/libtommath
"
RDEPEND="${DEPEND}
	xinetd? ( virtual/inetd )
	!sys-cluster/ganglia
"

S="${WORKDIR}/${MY_P}"

PATCHES=(
	"${FILESDIR}/extauth.patch"
#	firebird's patches to btyacc are now necessary
#	"${FILESDIR}"/${PN}-3.0.2.32703.0-unbundle.patch
)

pkg_pretend() {
	if [[ -e /var/run/${PN}/${PN}.pid ]] ; then
		ewarn
		ewarn "The presence of server connections may prevent isql or gsec"
		ewarn "from establishing an embedded connection. Accordingly,"
		ewarn "creating employee.fdb or security4.fdb could fail."
		ewarn "It is more secure to stop the firebird daemon before running emerge."
		ewarn
	fi
}

pkg_setup() {
	enewgroup firebird 450
	enewuser firebird 450 /bin/sh /usr/$(get_libdir)/firebird firebird
}

check_sed() {
	MSG="sed of $3, required $2 line(s) modified $1"
	einfo "${MSG}"
	[[ $1 -ge $2 ]] || die "${MSG}"
}

src_prepare() {
	default

	# Rename references to isql to fbsql
	# sed vs patch for portability and addtional location changes
	check_sed "$(sed -i -e 's:"isql :"fbsql :w /dev/stdout' \
		src/isql/isql.epp | wc -l)" "1" "src/isql/isql.epp" # 1 line
	check_sed "$(sed -i -e 's:isql :fbsql :w /dev/stdout' \
		src/msgs/history2.sql | wc -l)" "4" "src/msgs/history2.sql" # 4 lines
	check_sed "$(sed -i -e 's:--- ISQL:--- FBSQL:w /dev/stdout' \
		-e 's:isql :fbsql :w /dev/stdout' \
		-e 's:ISQL :FBSQL :w /dev/stdout' \
		src/msgs/messages2.sql | wc -l)" "6" "src/msgs/messages2.sql" # 6 lines

	find . -name \*.sh -exec chmod +x {} + || die
	# firebird's patches to btyacc are now necessary
	# firebird needs components of icu not on system
	rm -r extern/editline || die

	eautoreconf
}

src_configure() {
	filter-flags -fprefetch-loop-arrays
	filter-mfpmath sse

	# otherwise this doesnt build with gcc-6
	# http://tracker.firebirdsql.org/browse/CORE-5099
	append-cflags -fno-sized-deallocation -fno-delete-null-pointer-checks
	append-cxxflags -fno-sized-deallocation -fno-delete-null-pointer-checks -std=c++11

	local myeconfargs=(
		--prefix=/usr/$(get_libdir)/firebird
		--with-editline
		--with-system-editline
		--with-fbbin=/usr/bin
		--with-fbsbin=/usr/sbin
		--with-fbconf=/etc/${PN}
		--with-fblib=/usr/$(get_libdir)
		--with-fbinclude=/usr/include
		--with-fbdoc=/usr/share/doc/${PF}
		--with-fbsample=/usr/share/${PN}/examples
		--with-fbsample-db=/usr/share/${PN}/examples/empbuild
		--with-fbhelp=/usr/share/${PN}/help
		--with-fbintl=/usr/$(get_libdir)/${PN}/intl
		--with-fbmisc=/usr/share/${PN}
		--with-fbsecure-db=/etc/${PN}
		--with-fbmsg=/usr/share/${PN}/msg
		--with-fblog=/var/log/${PN}/
		--with-fbglock=/var/run/${PN}
		--with-fbplugins=/usr/$(get_libdir)/${PN}/plugins
		--with-gnu-ld
	)
	econf "${myeconfargs[@]}"
}

# from linux underground, merging into this here
src_install() {
	if use doc; then
		dodoc -r doc
		for x in ${A}; do
			case "$x" in *.pdf) dodoc "$DISTDIR"/"$x";; esac
		done
	fi

	cd "${S}/gen/Release/${PN}" || die

	doheader -r include/*
	dolib.so lib/*.so*

	# links for backwards compatibility
	insinto /usr/$(get_libdir)
	dosym libfbclient.so /usr/$(get_libdir)/libgds.so
	dosym libfbclient.so /usr/$(get_libdir)/libgds.so.0
	dosym libfbclient.so /usr/$(get_libdir)/libfbclient.so.1

	insinto /usr/share/${PN}/msg
	doins *.msg

	use server || return

	einfo "Renaming isql -> fbsql"
	mv bin/isql bin/fbsql || die "failed to rename isql -> fbsql"

	dobin bin/{fb_config,fbsql,fbsvcmgr,fbtracemgr,gbak,gfix,gpre,gsec,gsplit,gstat,nbackup,qli}
	dosbin bin/{firebird,fbguard,fb_lock_print}

	insinto /usr/share/${PN}/help
	# why???
	insopts -m0660 -o firebird -g firebird
	doins help/help.fdb

	exeinto /usr/$(get_libdir)/${PN}/intl
	doexe intl/libfbintl.so
	dosym libfbintl.so /usr/$(get_libdir)/${PN}/intl/fbintl.so

	insinto /usr/$(get_libdir)/${PN}/intl
	insopts -m0644 -o root -g root
	doins intl/fbintl.conf

	# plugins
	exeinto /usr/$(get_libdir)/${PN}/plugins
	doexe plugins/*.so
	exeinto /usr/$(get_libdir)/${PN}/plugins/udr
	doexe plugins/udr/*.so

	# logging (do we really need the perms?)
	diropts -m 755 -o firebird -g firebird
	dodir /var/log/${PN}
	keepdir /var/log/${PN}

	# logrotate
	insinto /etc/logrotate.d
	newins "${FILESDIR}/${PN}.logrotate" ${PN}

	# configuration files
	insinto /etc/${PN}/plugins
	doins plugins/udr_engine.conf
	insinto /etc/${PN}
	doins {databases,fbtrace,firebird,plugins}.conf

	# install secutity4.fdb
	insopts -m0660 -o firebird -g firebird
	doins security4.fdb

	if use xinetd; then
		insinto /etc/xinetd.d
		newins "${FILESDIR}/${PN}.xinetd.3.0" ${PN}
	else
		newinitd "${FILESDIR}/${PN}.init.d.3.0" ${PN}
	fi

	if use examples; then
		cd examples || die
		insinto /usr/share/${PN}/examples
		insopts -m0644 -o root -g root
		doins -r api
		doins -r dbcrypt
		doins -r include
		doins -r interfaces
		doins -r package
		doins -r stat
		doins -r udf
		doins -r udr
		doins CMakeLists.txt
		doins functions.c
		doins README
		insinto /usr/share/${PN}/examples/empbuild
		insopts -m0660 -o firebird -g firebird
		doins empbuild/employee.fdb
	fi

	elog "Starting with version 3, server mode is set in firebird.conf"
	elog "The default setting is superserver."
	elog
	elog "Firebird 4 strongly deprecates use of UDFs.  They are disabled by default."
	elog "Only enable if you really need them, and know what you're doing."
}
