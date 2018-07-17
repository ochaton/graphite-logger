%{!?lua_version: %global lua_version %{lua: print(string.sub(_VERSION, 5))}}
%{!?lua_libdir: %global lua_libdir %{_libdir}/lua/%{lua_version}}
%{!?lua_pkgdir: %global lua_pkgdir %{_datadir}/lua/%{lua_version}}

%define __repo graphite-logger
%define lua_version 5.1

Name:           lua-%{__repo}
Version:        0.1
Release:        0
License:        BSD
Group:          Development/Libraries
Url:            https://github.com/orchaton/graphite-logger
Summary:		FFI-library
BuildArch:		noarch
Requires:       luajit
BuildRoot:      %{_tmppath}/%{name}

%description
Connector to graphite/ethine

%prep

%if %{?SRC_DIR:1}%{!?SRC_DIR:0}
	rm -rf %{__repo}
	mkdir -p %{__repo}
    cp -rai %{SRC_DIR}/* %{__repo}
    cd %{__repo}
%else
%setup -q -n %{__repo}
%endif

%build

%install
cd %{__repo}
luarocks --tree=%{buildroot}%{_prefix} make graphite-scm-1.rockspec

%clean
rm -rf %{buildroot}
rm -rf %{__repo}

%files
%defattr(-,root,root)
%{_datadir}/lua/%{lua_version}/*
%{_prefix}/lib/luarocks/*

%changelog

