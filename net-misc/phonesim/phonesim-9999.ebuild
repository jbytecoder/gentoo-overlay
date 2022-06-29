# Copyright 2020 Gentoo Authors
# Distributed under the terms of the GNU General Public License v2

EAPI=7

inherit autotools git-r3

DESCRIPTION="Phone Simulator for modem testing (oFono)"
HOMEPAGE="http://ofono.org/"
EGIT_REPO_URI="https://git.kernel.org/pub/scm/network/ofono/${PN}.git"

LICENSE="GPL-2"
SLOT="0"
KEYWORDS="~amd64"
IUSE=""

RDEPEND="
        net-misc/ofono[phonesim]
        dev-qt/qtcore:5
        dev-qt/qtnetwork:5
        dev-qt/qtdeclarative:5
"

DEPEND="
        ${RDEPEND}
        virtual/pkgconfig
"

src_prepare() {
        default
        eautoreconf
}
