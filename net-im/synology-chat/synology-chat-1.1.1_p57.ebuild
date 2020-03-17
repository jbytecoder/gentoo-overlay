EAPI="6"

inherit unpacker

V=${PV/_p/-}

SRC_URI="https://global.download.synology.com/download/Tools/ChatClient/${V}/Ubuntu/x86_64/Chat_${V}_amd64.deb"
DESCRIPTION="Synology chat client"
HOMEPAGE="https://synology.com"

SLOT="0"
KEYWORDS="-* amd64"

S="${WORKDIR}"

RESTRICT="primaryuri strip test"

src_unpack(){
	unpack_deb ${A}
}

src_install() {
	cp -R "$WORKDIR/opt" "${D}" || die "Installation failed!"
	cp -R "$WORKDIR/usr" "${D}" || die "Cannot install desktop files"
}
