Name:           libsatsolver0-0
Version:        0.0.1
Release:        1
License:        BSD
Url:            http://svn.opensuse.org/svn/zypp/trunk/sat-solver
Source:         satsolver-%{version}.tar.bz2
BuildRoot:      %{_tmppath}/%{name}-%{version}-build
Group:          System/Libraries
BuildRequires:  libexpat-devel db43-devel
Requires:       expat db43
Summary:        A new approach to package dependency solving


%description
-

%package devel
Summary:        A new approach to package dependency solving
Group:          Development/Libraries

%description devel
-

%prep
%setup -n satsolver-%{version}

%build
%configure --prefix=/usr --libdir=%{_libdir} --sysconfdir=/etc --disable-static
make

%install
make DESTDIR=%{buildroot} install
rm -f %{buildroot}%{_libdir}/libsatsolver0.la

%post -p /sbin/ldconfig
%postun -p /sbin/ldconfig

%clean
rm -rf "$RPM_BUILD_ROOT"

%files
%defattr(-,root,root)
%{_libdir}/libsatsolver0.so.*

%files devel
%defattr(-,root,root)
%{_libdir}/libsatsolver0.so
%doc doc/README*
%doc doc/THEORY
%doc doc/PLANNING
%dir /usr/include/satsolver
/usr/include/satsolver/*

%changelog
