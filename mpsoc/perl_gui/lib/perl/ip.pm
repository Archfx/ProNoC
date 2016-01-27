#!/usr/bin/perl -w -I ..
###############################################################################
#
# File:         ip.pm
# 
#
###############################################################################
use warnings;
use strict;
use ip_gen;
use Cwd;


package ip;


sub lib_new {
    my $class = ("ARRAY" eq ref $_[0]) ? "ip" : shift;
    my $self;
    $self = {};
  	my $dir = Cwd::getcwd();
	my @files = glob "$dir/lib/ip/*.IP";
	for my $p (@files){
		
		# Read
		my  $ipgen;
		$ipgen = eval { do $p };
		# Might need "no strict;" before and "use strict;" after "do"
		die "Error reading: $@" if $@;
		
		add_ip($self,$ipgen);
	}
  

    bless($self,$class);

   
    return $self;
} 


sub ip_add_parameter {
	my ($self,$category,$module,$parameter,$deafult,$type,$content,$info,$glob_param,$redefine_param)=@_;
	if (!defined($category) ) {return 0;} 
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}={};
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{deafult}=$deafult;
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{type}=$type;
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{content}=$content;
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{info}=$info;
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{glob_param}=$glob_param;
		$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{redefine_param}=$redefine_param;
	}
}


sub ip_remove_parameter {
	my ($self,$category,$module,$parameter)=@_;
	if (!defined($category) ) {return 0;} 
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		delete $self->{categories}{$category}{names}{$module}{parameters}{$parameter};
		
	}else{ return 0;}
	return 1;
}


sub ip_get_module_parameters{
	my ($self,$category,$module)=@_;
	my @parameters;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (keys %{$self->{categories}{$category}{names}{$module}{parameters}}){
			push(@parameters,$p);
			
		}#for
	}#if	
	return @parameters;
}	


sub ip_get_parameter {
	my ($self,$category,$module,$parameter)=@_;
	my ($deafult,$type,$content,$info,$glob_param,$redefine_param);
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$deafult	=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{deafult};
		$type		=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{type};
		$content	=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{content};
		$info		=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{info};
		$glob_param	=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{glob_param};
		$redefine_param	=$self->{categories}{$category}{names}{$module}{parameters}{$parameter}{redefine_param};
	}
	return ($deafult,$type,$content,$info,$glob_param,$redefine_param); 
}


sub ip_add_socket {
	my ($self,$category,$module,$interface,$type,$value,$connection_num)=@_;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$self->{categories}{$category}{names}{$module}{sockets}{$interface}{type}=$type;
		$self->{categories}{$category}{names}{$module}{sockets}{$interface}{value}=$value;
		if(defined $connection_num){$self->{categories}{$category}{names}{$module}{sockets}{$interface}{connection_num}=$connection_num;}
		
		
	}
}


sub ip_get_socket {
	my ($self,$category,$module,$socket)=@_;
	my ($type,$value,$connection_num);
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$type			=$self->{categories}{$category}{names}{$module}{sockets}{$socket}{type};
		$value			=$self->{categories}{$category}{names}{$module}{sockets}{$socket}{value};
		$connection_num	=$self->{categories}{$category}{names}{$module}{sockets}{$socket}{connection_num};
	}
	return ($type,$value,$connection_num);
}

sub ip_get_module_sockets_list {
	my ($self,$category,$module)=@_;
	my @r;	
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{sockets}}){
			push (@r,$p);
		}
	}
	return @r;
}	



sub ip_add_plug {
	my ($self,$category,$module,$interface,$type,$value,$connection_num)=@_;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$self->{categories}{$category}{names}{$module}{plugs}{$interface}{type}=$type;
		$self->{categories}{$category}{names}{$module}{plugs}{$interface}{value}=$value;
		if(defined $connection_num){ $self->{categories}{$category}{names}{$module}{plugs}{$interface}{connection_num}=$connection_num;}
		
	}
}

sub ip_get_plug {
	my ($self,$category,$module,$plug)=@_;
	my ($type,$value,$connection_num);
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$type			=$self->{categories}{$category}{names}{$module}{plugs}{$plug}{type};
		$value			=$self->{categories}{$category}{names}{$module}{plugs}{$plug}{value};
		$connection_num	=$self->{categories}{$category}{names}{$module}{plugs}{$plug}{connection_num};
	}
	return ($type,$value,$connection_num);
}

sub ip_get_module_plugs_list {
	my ($self,$category,$module)=@_;
	my @r;	
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{plugs}}){
			push (@r,$p);
		}
	}
	return @r;
}	
	
	
	


sub ip_add_port{
	my ($self,$category,$module,$port,$type,$range,$intfc_name,$intfc_port)=@_;
	if (!defined($category) ) {return 0;} 
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		$self->{categories}{$category}{names}{$module}{ports}{$port}={};
		$self->{categories}{$category}{names}{$module}{ports}{$port}{type}=$type;
		$self->{categories}{$category}{names}{$module}{ports}{$port}{range}=$range;
		$self->{categories}{$category}{names}{$module}{ports}{$port}{intfc_name}=$intfc_name;
		$self->{categories}{$category}{names}{$module}{ports}{$port}{intfc_port}=$intfc_port;
	}
}


sub ip_get_port{
	my ($self,$category,$module,$port)=@_;
	my ($type,$range,$intfc_name,$intfc_port);
	if ( exists ($self->{categories}{$category}{names}{$module}{ports}{$port}) ){
		$type		=$self->{categories}{$category}{names}{$module}{ports}{$port}{type};
		$range		=$self->{categories}{$category}{names}{$module}{ports}{$port}{range};
		$intfc_name	=$self->{categories}{$category}{names}{$module}{ports}{$port}{intfc_name};
		$intfc_port	=$self->{categories}{$category}{names}{$module}{ports}{$port}{intfc_port};
	}
	return ($type,$range,$intfc_name,$intfc_port);
}

sub ip_list_ports{
	my ($self,$category,$module)=@_;
	my @ports;
	
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{ports}}){
			push (@ports,$p);
		}
	}
	return @ports;
}



sub ip_get_categories{
	my $self=shift;
	my @r;	
	if  (exists ($self->{categories})){
		foreach my $p (sort keys %{$self->{categories}}){
			push (@r,$p);
		}
	}
	return @r;
}


sub get_modules{
	my ($self,$category)=@_;
	my @r;
	if  (exists ($self->{categories}{$category})){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}}){
			push (@r,$p);
		}
	}
	return @r;
}

sub get_describtion{
	my ($self,$category,$module)=@_;
	my $r;
	if (!defined($module) ) {return $r;} 
		$r=$self->{categories}{$category}{names}{$module}{Describtion};
		
	return $r;

}





sub get_param_default{
	my ($self,$category,$module)=@_;
	my %r;
	if (!defined($module) ) {return %r;} 
	foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{parameters}}){
			$r{$p}=$self->{categories}{$category}{names}{$module}{parameters}{$p}{deafult};
			#print "$p=$r{$p}\n";
		}
	return %r;

}



sub ip_add_socket_names{
	my($self,$ipgen,$category,$module, $socket)=@_;
	my $num=0;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		
		my $name=	$ipgen->ipgen_get_socket_name($socket,$num);
		do{
			$self->{categories}{$category}{names}{$module}{sockets}{$socket}{$num}{name}=$name;
			++$num;
			$name=	$ipgen->ipgen_get_socket_name($socket,$num);
		}while(defined $name);
	
	}
}		

sub ip_get_socket_name{
	my($self,$category,$module, $socket,$num)=@_;
	my $name;
	if ( exists (   $self->{categories}{$category}{names}{$module}{sockets}{$socket}{$num}{name}) ){
		$name=	$self->{categories}{$category}{names}{$module}{sockets}{$socket}{$num}{name};
		
	}
	return $name;
}		



sub ip_add_plug_names{
	my($self,$ipgen,$category,$module, $plug)=@_;
	my $num=0;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		
		my $name=	$ipgen->ipgen_get_plug_name($plug,$num);
		do{
			$self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{name}=$name;
			my ($addr,$width)= $ipgen->ipgen_get_wb_addr($plug,$num);
			if (defined $addr){
					$self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{addr}=$addr;
					$self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{width}=$width;
			}	
			++$num;
			$name=	$ipgen->ipgen_get_plug_name($plug,$num);
				
			
		}while(defined $name);
	
	}	
}

sub ip_get_wb_addr{
	my($self,$category,$module,$plug,$num)=@_;
	my ($addr , $width); 
	if(exists($self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{addr})){
		$addr  = $self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{addr};
		$width = $self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{width};
	}
	return ($addr , $width); 
}	



sub ip_get_plug_name{
	my($self,$category,$module, $plug,$num)=@_;
	my $name;
	if ( exists ($self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{name})){
		$name=$self->{categories}{$category}{names}{$module}{plugs}{$plug}{$num}{name};
	}
	return $name;
}




sub get_module_sokets_value{
	my ($self,$category,$module)=@_;
	if (!defined($category) ) {return 0;} 
	my %r;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{sockets}}){
			$r{$p}=$self->{categories}{$category}{names}{$module}{sockets}{$p}{value};
		}
		
	}
	return %r;	
}	


sub get_module_sokets_type{
	my ($self,$category,$module)=@_;
	if (!defined($category) ) {return 0;} 
	my %r;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{sockets}}){
			$r{$p}=$self->{categories}{$category}{names}{$module}{sockets}{$p}{type};
		}
		
	}
	return %r;	
}	


sub get_module_plugs_value{
	my ($self,$category,$module)=@_;
	if (!defined($category) ) {return 0;} 
	my %r;
	if ( exists ($self->{categories}{$category}{names}{$module}) ){
		foreach my $p (sort keys %{$self->{categories}{$category}{names}{$module}{plugs}}){
			$r{$p}=$self->{categories}{$category}{names}{$module}{plugs}{$p}{value};
		}
		
	}
	return %r;	
}	

sub ip_get_param_order{
	my ($self,$category,$module)=@_;
	my @r;
	if(exists $self->{categories}{$category}{names}{$module}{parameters_order}) {
		@r=@{$self->{categories}{$category}{names}{$module}{parameters_order}};

	}
	return @r;
}


sub ip_get_module_name{
	my ($self, $category,$module)=@_;
	my $module_name;
	if(exists $self->{categories}{$category}{names}{$module}{module_name}){
		$module_name= $self->{categories}{$category}{names}{$module}{module_name};
	}
	return $module_name;
}	


sub ip_get_hdr{
	my ($self, $category,$module)=@_;
	my $hdr;
	if(exists($self->{categories}{$category}{names}{$module}{header})){		
		$hdr=$self->{categories}{$category}{names}{$module}{header};
	}
	return $hdr;
}


sub ip_get_hdl_files{
	my ($self, $category,$module)=@_;
	my @l;
	@l=@{$self->{categories}{$category}{names}{$module}{hdl}} if(defined $self->{categories}{$category}{names}{$module}{hdl});
	return 	 @l;	
}

sub add_ip{

	my ($self,$ipgen) =@_;
	my $module;
	$module	=	$ipgen->ipgen_get_ip_name();
	my $module_name =$ipgen->ipgen_get_module_name();
	if(!defined $module){ $module	=	$module_name}
	my $category=	$ipgen->ipgen_get_category();
	my $Describtion=	$ipgen->ipgen_get_description();
	
	$self->{categories}{$category}{names}{$module}={};
	$self->{categories}{$category}{names}{$module}{Describtion}=$Describtion;
	$self->{categories}{$category}{names}{$module}{module_name}=$module_name;
	my @plugs= $ipgen->ipgen_list_plugs();
	#print "$module:@plugs\n";
	foreach my $plug (@plugs){
		my ($type,$value,$connection_num)= $ipgen->ipgen_get_plug($plug);
		ip_add_plug($self,$category,$module,$plug,$type,$value,$connection_num);
		ip_add_plug_names($self,$ipgen,$category,$module, $plug);
		
	}	
	my @sockets= $ipgen->ipgen_list_sokets();
	#print "$module:@sockets\n";
	foreach my $socket (@sockets){
		my ($type,$value,$connection_num)= $ipgen->ipgen_get_socket($socket);
		ip_add_socket($self,$category,$module, $socket,$type,$value,$connection_num);
		ip_add_socket_names($self,$ipgen,$category,$module, $socket);
	}	
	my @parameters=  $ipgen->ipgen_get_all_parameters_list();
	foreach my $param (@parameters){
		my ($deafult,$type,$content,$info,$glob_param,$redefine_param)=$ipgen->ipgen_get_parameter_detail($param);
		ip_add_parameter($self,$category,$module,$param,$deafult,$type,$content,$info,$glob_param,$redefine_param);
				
	}
	my @params_order= $ipgen->ipgen_get_parameters_order();
	$self->{categories}{$category}{names}{$module}{parameters_order}=\@params_order;
	my @ports= $ipgen->ipgen_list_ports();
	foreach my $port (@ports){
		my($range,$type,$intfc_name,$intfc_port)=$ipgen->ipgen_get_port($port);
		ip_add_port($self,$category,$module,$port,$type,$range,$intfc_name,$intfc_port);
	}
	my $hdr= $ipgen->ipgen_get_hdr();
	$self->{categories}{$category}{names}{$module}{header}=$hdr;	
	
	my @hdl_files= $ipgen->ipgen_get_hdl_files_list();
	$self->{categories}{$category}{names}{$module}{hdl}=\@hdl_files;	
	
}		
	





























1
