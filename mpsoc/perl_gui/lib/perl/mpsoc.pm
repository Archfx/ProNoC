#! /usr/bin/perl -w
use strict;


package mpsoc;

use ip_gen;


#use Clone 'clone';



sub mpsoc_new {
    # be backwards compatible with non-OO call
    my $class = ("ARRAY" eq ref $_[0]) ? "mpsoc" : shift;
    my $self;

   
    $self = {};
    $self->{file_name}        = (); # information on each file
    $self->{noc_param}=   {};
    $self->{noc_indept_param}={};
    $self->{parameters_order}=[];
    $self->{setting}={};
   	$self->{socs}={};
   	mpsoc_initial_setting($self);
	

    bless($self,$class);

   
    return $self;
} 

sub mpsoc_initial_setting{
	my $self=shift;
	$self->{setting}{show_noc_setting}=1;
	$self->{setting}{show_adv_setting}=0;
	$self->{setting}{show_tile_setting}=1;	
	$self->{setting}{soc_path}="lib/soc";
}

sub mpsoc_set_setting{
	my ($self,$name,$value)=@_;
	$self->{setting}{$name}=$value;
	
}

sub mpsoc_get_setting{
	my ($self,$name)=@_;
	return $self->{setting}{$name};
	
}


sub mpsoc_set_mpsoc_name{
	my ($self,$name)=@_;
	if(defined $name){$self->{mpsoc_name}=$name;}	
}	

sub mpsoc_get_mpsoc_name{
	my ($self)=@_;
	my $name;
	if(exists  $self->{mpsoc_name}){ $name=$self->{mpsoc_name};}	
	return $name;
}	

sub mpsoc_get_indept_params{
	my $self=shift;
	return  $self->{noc_indept_param};
}


sub mpsoc_add_param{
	my ($self,$param,$value)=@_;
	$self->{noc_param}{$param}=$value;

}

sub mpsoc_get_param{
	my ($self,$param)=@_;
	return $self->{noc_param}{$param};

}
sub mpsoc_add_param_order{
	my ($self,@param)=@_;
	foreach my $p (@param){
		push (@{$self->{parameters_order}},$p);

	}
}
sub mpsoc_get_param_order{
	my $self=shift;
	return @{$self->{parameters_order}};
}




sub mpsoc_get_instance_info{
	my ($self,$ip_num)=@_;
	return $self->{ips}{$ip_num}{name}
}

sub mpsoc_set_ip_inst_name{
	my ($self,$ip_num,$new_instance)=@_;
	$self->{ips}{$ip_num}{name}=$new_instance;

}

sub mpsoc_get_soc_list{
	my $self=shift;
	my @list;
	foreach my $p (sort keys %{$self->{socs}}){
		push(@list,$p);
	}
	return @list;
}





sub mpsoc_add_soc{
	my ($self,$name,$soc)=@_;
	$self->{socs}{$name}{top}=$soc;	
	
}




sub mpsoc_get_soc{
	my ($self,$name)=@_;
	return $self->{socs}{$name}{top};	
	
}


sub mpsoc_remove_soc{
	my ($self,$name)=@_;
	delete $self->{socs}{$name};		
}

sub mpsoc_remove_all_soc{
	my ($self)=@_;
	delete $self->{socs};		
}



sub mpsoc_add_soc_tiles_num{
	my ($self,$name,$nums) =@_;
	if(defined $nums){
		my @f=sort { $a <=> $b } @{$nums};
		if( exists $self->{socs}{$name}){
			$self->{socs}{$name}{tile_nums}=\@f;
		
		}
	}else {
		$self->{socs}{$name}{tile_nums}=undef;
		
	}		
}

sub mpsoc_get_soc_tiles_num{
	my ($self,$name) =@_;
	my @nums;
	if( defined $self->{socs}{$name}{tile_nums}){
		@nums = @{$self->{socs}{$name}{tile_nums}};
		
	}
	return @ nums;		
}

sub mpsoc_get_scolar_pos{
	my ($item,@list)=@_;
	my $pos;
	my $i=0;
	foreach my $c (@list)
	{
		if(  $c eq $item) {$pos=$i}
		$i++;
	}	
	return $pos;	
}	

sub mpsoc_get_tile_soc_name{
	my ($self,$tile)=@_;
	my @all_socs=mpsoc_get_soc_list($self); 
	my $soc_num=0;
	my $p;
	foreach $p( @all_socs){
		my @tiles=mpsoc_get_soc_tiles_num ($self,$p);
		if ( grep( /^$tile$/, @tiles ) ){
			    my $num =mpsoc_get_scolar_pos($tile,@tiles);
			
				return ($p,$soc_num,$num);
		}
		$soc_num++;
		
	}
	return ($p,$soc_num,undef);
	
}

sub mpsoc_remove_scolar_from_array{
	my ($array_ref,$item)=@_;
	my @array=@{$array_ref};
	my @new;
	foreach my $p (@array){
		if($p ne $item ){
			push(@new,$p);
		}		
	}
	return @new;	
}

sub mpsoc_set_tile_free{
	my ($self,$tile)=@_;
	#
	mpsoc_set_tile_param_setting($self, $tile, 'Default');
	my @all_socs=mpsoc_get_soc_list($self); 
	my $soc_num=0;
	my $p;
	foreach $p( @all_socs){
		my @tiles=mpsoc_get_soc_tiles_num ($self,$p);
		my @n=mpsoc_remove_scolar_from_array(\@tiles,$tile);
		mpsoc_add_soc_tiles_num($self,$p,\@n);
		
	}
	
}
	
sub mpsoc_set_tile_soc_name{
	my ($self,$tile,$new_soc)=@_;
	mpsoc_set_tile_free($self,$tile);
	my @tiles=mpsoc_get_soc_tiles_num ($self,$new_soc);
	push(@tiles,$tile);
	mpsoc_add_soc_tiles_num($self,$new_soc,\@tiles);
	
	
}

sub mpsoc_set_tile_param_setting{
	my ($self,$tile,$setting)=@_;
	$self->{tile}{$tile}{param_setting}=$setting;

}	

sub mpsoc_get_tile_param_setting{
	my ($self,$tile)=@_;
	my $setting='Default';
	if(exists $self->{tile}{$tile}{param_setting}){
		$setting=$self->{tile}{$tile}{param_setting};
		
	}
	return $setting;
}	


1

