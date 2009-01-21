#
# spec file for OpenSLX (Version 4.0.0)
#

Name:           openslx
Version:        4.0.0
Release:        0
License:        GNU General Public License (GPL)
Group:          Productivity/Networking/System
Url:            http://openslx.org/
Autoreqprov:    on
Requires:       perl-DBD-CSV perl-DBD-SQLite perl-DBD-mysql
#PreReq:
Source:         %{name}-%{version}.tar.bz2
Summary:        Open StateLess Extensions
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
BuildRequires:  perl-DBD-CSV perl-DBD-SQLite perl-DBD-mysql

%description
OpenSLX aims on the Linux desktop as a middleware solution to provide easy
administration of large bunchs of computers. The project might be of interest
in a wide field of utilization: schools , education, universities, grid
clusters, corporations with a lot of office workplaces, ...

An OpenSLX client is just a Linux workstation as you would expect, if you have
installed just any distribution onto the local disk. The average user will not
see any difference


Authors:
--------
    Dirk von Suchodoletz, <dvs@OpenSLX.com>, 2002 - 2007
	 Michael Janczyk, 2003 - 2007
	 Nico Dietrich, 2005 - 2006
	 Felix Endres, 2005 - 2007
	 Tobias Maier, 2005 - 2006
	 Bastian Wissler, 2006 - 2007
	 Lars Mueller, <lm@OpenSLX.com>, 2006 - 2007
	 Oliver Tappe, <ot@OpenSLX.com>, 2006 - 2007

%prep
%setup

%build

%install
[ "${RPM_BUILD_ROOT}" != "/" -a -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}
make install \
	DESTDIR="${RPM_BUILD_ROOT}"

%clean
[ "${RPM_BUILD_ROOT}" != "/" -a -d ${RPM_BUILD_ROOT} ] && rm -rf ${RPM_BUILD_ROOT}

%files -f packaging/rpm/openslx-filelist
%defattr(-,root,root)
