FROM x11vnc/desktop as builder


RUN apt-get update && apt-get install -y \
	git \
	build-essential \
	build-essential  \
	libpango1.0-dev \
	clang \
	lib32z1 \
	libgd-graph-perl \
	libgd-gd2-perl \
	libglib-perl \
	cpanminus \
	libusb-1.0 \
	graphviz \
	libcanberra-gtk-module \
	unzip \
	xterm \
	verilator \
	wget \
	python \
	python-pip \
	curl \
	libgtk-3-dev \
	libglib3.0-cil-dev \
	libgtk3-perl \
	libgtksourceview-3.0-dev

RUN cpanm ExtUtils::Depends ExtUtils::PkgConfig Glib Pango String::Similarity  IO::CaptureOutput Proc::Background List::MoreUtils File::Find::Rule  Verilog::EditFiles IPC::Run File::Which Class::Accessor String::Scanf File::Copy::Recursive  GD::Graph::bars3d GD::Graph::linespoints GD::Graph::Data constant::boolean Event::MakeMaker Glib::Event Chart::Gnuplot Gtk3 Gtk3::SourceView

RUN curl https://bootstrap.pypa.io/pip/2.7/get-pip.py --output get-pip.py
RUN python2 get-pip.py 
RUN pip install trueskill numpy "networkx<2.0"


# RUN chown -R $user ProNoC/mpsoc/perl_gui/ProNoC 


