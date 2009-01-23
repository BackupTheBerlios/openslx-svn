package OpenSLX::DistroUtils::Engine;

use OpenSLX::Basics;

sub new
{
    my $class = shift;
    my $self = {};
    return bless $self, $class;
}


sub loadDistro {
    my $self = shift;
    my $distroName = shift;
    
    my $distro;
    my $loaded = eval {
            $distro = instantiateClass("OpenSLX::DistroUtils::${distroName}");
            return 0 if !$distro;   # module does not exist, try next
            1;
        };
     
    if (!$loaded) {
        $distro = instantiateClass("OpenSLX::DistroUtils::Base");
    }
    return $distro;
}

1;