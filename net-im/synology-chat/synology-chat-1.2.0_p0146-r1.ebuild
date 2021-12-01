EAPI="6"

inherit unpacker

V=${PV/_p/-}

SRC_URI="https://global.download.synology.com/download/Utility/ChatClient/${V}/Ubuntu/x86_64/Synology%20Chat%20Client-${V}.deb"
DESCRIPTION="Synology chat client"
HOMEPAGE="https://synology.com"

SLOT="0"
KEYWORDS="-* amd64"
RDEPEND="
app-arch/bzip2
dev-libs/atk
dev-libs/dbus-glib
dev-libs/expat
dev-libs/fribidi
dev-libs/glib
dev-libs/glib
dev-libs/gmp
dev-libs/libbsd
dev-libs/libffi
dev-libs/libpcre
dev-libs/libtasn1
dev-libs/libunistring
dev-libs/nettle
=dev-libs/nspr-4*
=dev-libs/nss-3*
=gnome-base/gconf-3*
media-gfx/scrot
media-gfx/graphite2
media-libs/alsa-lib 
media-libs/fontconfig
media-libs/freetype
=media-libs/harfbuzz-2.7*
media-libs/libglvnd
=media-libs/libpng-1.6*
net-dns/libidn2
net-libs/gnutls
=net-print/cups-2*
=sys-apps/dbus-1*
sys-apps/util-linux
=sys-libs/zlib-1*
x11-libs/cairo
x11-libs/gdk-pixbuf
=x11-libs/gtk+-3*
x11-libs/libX11
x11-libs/libXau
x11-libs/libxcb
x11-libs/libXcomposite
x11-libs/libXcursor
x11-libs/libXdamage
x11-libs/libXdmcp
x11-libs/libXfixes
=x11-libs/libXi-1.7*
x11-libs/libXrandr
x11-libs/libXrender
x11-libs/libXScrnSaver
x11-libs/libXtst
=x11-libs/pango-1.42*
x11-libs/pixman
"

S="${WORKDIR}"

RESTRICT="primaryuri strip test"

src_unpack(){
	unpack_deb ${A}
}

src_install() {
	cp -R "$WORKDIR/opt" "${D}" || die "Installation failed!"
	cp -R "$WORKDIR/usr" "${D}" || die "Cannot install desktop files"
}
