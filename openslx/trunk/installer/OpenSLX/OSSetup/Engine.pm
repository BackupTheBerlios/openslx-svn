# Copyright (c) 2006..2009 - OpenSLX GmbH
#
# This program is free software distributed under the GPL version 2.
# See http://openslx.org/COPYING
#
# If you have any feedback please consult http://openslx.org/feedback and
# send your suggestions, praise, or complaints to feedback@openslx.org
#
# General information about OpenSLX can be found at http://openslx.org/
# -----------------------------------------------------------------------------
# Engine.pm
#    - provides driver engine for the OSSetup API.
# -----------------------------------------------------------------------------
package OpenSLX::OSSetup::Engine;

use strict;
use warnings;

our (@ISA, @EXPORT, $VERSION);
$VERSION = 1.01;    # API-version . implementation-version

use Exporter;
@ISA = qw(Exporter);

@EXPORT = qw(
    %supportedDistros
);

use Config::General;
use File::Basename;
use URI;

use OpenSLX::Basics;
use OpenSLX::ScopedResource;
use OpenSLX::Syscall;
use OpenSLX::Utils;

use vars qw(%supportedDistros);

%supportedDistros = (
    'debian-3.1'        => 'clone,install,update,shell',
    'debian-4.0'        => 'clone,install,update,shell',
    'debian-4.0_amd64'  => 'clone,install,update,shell',
    'debian-5.0'        => 'clone,update,shell',
    'fedora-6'          => 'clone,install,update,shell',
    'fedora-6_x86_64'   => 'clone,install,update,shell',
    'gentoo-2007.X'     => 'clone',
    'suse-10.1'         => 'clone,install,update,shell',
    'suse-10.1_x86_64'  => 'clone,install,update,shell',
    'suse-10.2'         => 'clone,install,update,shell',
    'suse-10.2_x86_64'  => 'clone,install,update,shell',
    'suse-10.3'         => 'clone,install,update,shell',
    'suse-10.3_x86_64'  => 'clone,update,shell',
    'suse-11.0'         => 'clone,install,update,shell',
    'suse-11.0_x86_64'  => 'clone,update,shell',
    'suse-11.1'         => 'clone,install,update,shell',
    'suse-11.1_x86_64'  => 'clone,update,shell',
    'scilin-4.7'        => 'clone,update,shell',
    'scilin-5.1'        => 'clone,update,shell',
    'ubuntu-8.04'       => 'clone,install,update,shell',
    'ubuntu-8.04_amd64' => 'clone,update,shell',
    'ubuntu-8.10'       => 'clone,install,update,shell',
    'ubuntu-8.10_amd64' => 'clone,update,shell',
    'ubuntu-9.04'       => 'clone,install,update,shell',
    'ubuntu-9.04_amd64' => 'clone,update,shell',
    'ubuntu-9.10'       => 'clone,update,shell',
    'ubuntu-9.10_amd64' => 'clone,update,shell',
);

my %localHttpServers;

################################################################################
### interface methods
################################################################################
sub new
{
    my $class = shift;

    my $self = {};

    return bless $self, $class;
}

sub initialize
{
    my $self         = shift;
    my $vendorOSName = shift;
    my $actionType   = shift;

    if ($vendorOSName eq '<<<default>>>') {
        die _tr("you can't do that with the default vendor-OS!\n");
    }
    if ($vendorOSName !~ m[^([^\-]+\-[^\-]+)(?:\-(.+))?]) {
        die _tr(    
            "Given vendor-OS has unknown format, expected '<name>-<release>[-<selection>]'\n"
        );
    }
    my $distroName = lc($1);
    my $selectionName = $2 || 'default';
    $self->{'vendor-os-name'} = $vendorOSName;
    $self->{'action-type'}    = $actionType;
    $self->{'distro-name'}    = $distroName;
    $self->{'selection-name'} = $selectionName;
    $self->{'clone-source'}   = '';
    if (!exists $supportedDistros{$distroName}) {
        print _tr("Sorry, distro '%s' is unsupported.\n", $distroName);
        print _tr("List of supported distros:\n\t");
        print join("\n\t", sort keys %supportedDistros) . "\n";
        exit 1;
    }
    my $support = $supportedDistros{$distroName};
    if ($actionType eq 'install' && $support !~ m[install]i) {
        print _tr(
            "Sorry, distro '%s' can not be installed, only cloned!\n", 
            $distroName
        );
        exit 1;
    }
    elsif ($actionType eq 'update' && $support !~ m[(update)]i) {
        print _tr(
            "Sorry, update support for vendor-OS '%s' has not been implemented!\n", 
            $distroName
        );
        exit 1;
    }
    elsif ($actionType eq 'shell' && $support !~ m[(shell)]i) {
        print _tr(
            "Sorry, vendor-OS '%s' has no support for chrooted shells available!\n",
            $distroName
        );
        exit 1;
    }

    # load module for the requested distro:
    my $distro = loadDistroModule({
        distroName   => $distroName,
        distroScope  => 'OpenSLX::OSSetup::Distro',
        fallbackName => 'Any_Clone',
    });
    if (!$distro) {
        die _tr(
            'unable to load any OSSetup::Distro module for vendor-OS %s!', 
            $vendorOSName
        );
    }

    $distro->initialize($self);
    $self->{distro} = $distro;

    # protect against parallel executions of writing OpenSLX scripts
    $self->{'vendor-os-lock'} = grabLock($vendorOSName);

    if ($actionType =~ m{^(install|update|shell|plugin)}) {
        # setup path to distribution-specific info:
        my $sharedDistroInfoDir 
            = "$openslxConfig{'base-path'}/share/distro-info/$self->{'distro-name'}";
        if (!-d $sharedDistroInfoDir) {
            die _tr(
                "unable to find shared distro-info in '%s'\n",
                $sharedDistroInfoDir
            );
        }
        $self->{'shared-distro-info-dir'} = $sharedDistroInfoDir;
        my $configDistroInfoDir =
            "$openslxConfig{'config-path'}/distro-info/$self->{'distro-name'}";
        if (!-d $configDistroInfoDir) {
            die _tr(
                "unable to find configurable distro-info in '%s'\n",
                $configDistroInfoDir
            );
        }
        $self->{'config-distro-info-dir'} = $configDistroInfoDir;
   
        my $setupMirrorsIfNecessary = $actionType eq 'install';
        $self->_readDistroInfo($setupMirrorsIfNecessary);
    }

    if ($self->{'action-type'} eq 'install'
        && !exists $self->{'distro-info'}->{'selection'}->{$selectionName})
    {
        die(
            _tr(
                "selection '%s' is unknown to distro '%s'\n",
                $selectionName, $self->{'distro-name'}
            )
            . _tr("These selections are available:\n\t")
            . join("\n\t", sort keys %{$self->{'distro-info'}->{'selection'}})
            . "\n"
        );
    }

    $self->{'vendor-os-path'} 
        = "$openslxConfig{'private-path'}/stage1/$self->{'vendor-os-name'}";
    vlog(1, "vendor-OS path is '$self->{'vendor-os-path'}'");

    if ($actionType =~ m{^(install|update|shell|plugin)}) {
        $self->_createPackager();
        $self->_createMetaPackager();
    }

    return;
}

sub installVendorOS
{
    my $self = shift;
    my $vendorOSSettings = shift;

    my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
    if (-e $installInfoFile) {
        die _tr("vendor-OS '%s' already exists, giving up!\n",
            $self->{'vendor-os-path'});
    }
    $self->_createVendorOSPath();

    my $httpServers = OpenSLX::ScopedResource->new({
        name    => 'local-http-servers',
        acquire => sub { $self->_startLocalURLServersAsNeeded(); 1 },
        release => sub { $self->_stopLocalURLServers(); 1 },
    });

    my $baseSystemFile = "$self->{'vendor-os-path'}/.openslx-base-system";
    if (-e $baseSystemFile) {
        vlog(0, _tr("found existing base system, continuing...\n"));
    }
    else {
        # basic setup, stage1a-c:
        $self->_setupStage1A();
        callInSubprocess(
            sub {
                # some tasks that involve a chrooted environment:
                $self->_changePersonalityIfNeeded();
                $self->_setupStage1B();
                $self->_setupStage1C();
            }
        );
        $self->_stage1C_cleanupBasicVendorOS();
        # just touch the file, in order to indicate a basic system:
        slxsystem("touch $baseSystemFile");
    }
    callInSubprocess(
        sub {
            # another task that involves a chrooted environment:
            $self->_changePersonalityIfNeeded();
            $self->_setupStage1D();
        }
    );

    # create the install-info file, in order to indicate a proper installation:
    spitFile(
        $installInfoFile,
        "SLX_META_PACKAGER=$self->{distro}->{'meta-packager-type'}\n"
    );

    # base system info file is no longer needed, we have a full system now
    slxsystem("rm $baseSystemFile");

    $self->_applyVendorOSSettings($vendorOSSettings) unless !$vendorOSSettings;

    vlog(
        0,
        _tr(
            "Vendor-OS '%s' installed succesfully.\n",
            $self->{'vendor-os-name'}
        )
    );

    # add the uclibs and tools to the stage1 and add them to library search
    # path
    $self->_copyUclibcRootfs();
    callInSubprocess(
        sub {
            $self->_callChrootedFunction({
            chrootDir    => $self->{'vendor-os-path'},
            function     => sub {
                $self->{'distro'}->addUclibLdconfig();
        },
        updateConfig => 1,
        });
    });
    $self->_touchVendorOS();
    $self->addInstalledVendorOSToConfigDB();
    return;
}

sub cloneVendorOS
{
    my $self   = shift;
    my $source = shift;

    if (substr($source, -1, 1) ne '/') {
        # make sure source path ends with a slash, as otherwise, the
        # last folder would be copied (but we only want its contents).
        $source .= '/';
    }

    $self->{'clone-source'} = $source;
    my $lastCloneSource = '';
    my $cloneInfoFile = "$self->{'vendor-os-path'}/.openslx-clone-info";
    my $isReClone;
    if (-e $self->{'vendor-os-path'}) {
        my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
        if (-e $installInfoFile) {
            # oops, given vendor-os has been installed, not cloned, we complain:
            croak(
                _tr(
                    "The vendor-OS '%s' exists but it is no clone, refusing to clobber!\nPlease delete the folder manually, if that's really what you want...\n",
                    $self->{'vendor-os-path'}
                )
            );
        }
        elsif (-e $cloneInfoFile) {
            # check if last and current source match:
            my $cloneInfo = slurpFile($cloneInfoFile);
            if ($cloneInfo =~ m[^source\s*=\s*(.+?)\s*$]ims) {
                $lastCloneSource = $1;
            }
            if ($source ne $lastCloneSource) {
                # protect user from confusing sources (still allowed, though):
                my $yes = _tr('yes');
                my $no  = _tr('no');
                print _tr(
                    "Last time this vendor-OS was cloned, it has been cloned from '%s', now you specified a different source: '%s'\nWould you still like to proceed (%s/%s)? ",
                    $lastCloneSource, $source, $yes, $no
                );
                my $answer = <STDIN>;
                exit 5 unless $answer =~ m[^\s*$yes]i;
            }
            $isReClone = 1;
        }
        else {
            # Neither the install-info nor the clone-info file exists. This
            # probably means that the folder has been created by an older
            # version of the tools. There's not much we can do, we simply
            # trust our user and assume that he knows what he's doing.
        }
    }

    $self->_createVendorOSPath();

    $self->_clone_fetchSource($source);
    if ($source ne $lastCloneSource) {
        spitFile($cloneInfoFile, "source=$source\n");
    }
    if ($isReClone) {
        vlog(
            0,
            _tr(
                "Vendor-OS '%s' has been re-cloned succesfully.\n",
                $self->{'vendor-os-name'}
            )
        );
    }
    else {
        vlog(
            0,
            _tr(
                "Vendor-OS '%s' has been cloned succesfully.\n",
                $self->{'vendor-os-name'}
            )
        );
    }
    # add the uclibs and tools to the stage1 and add them to library search
    # path
    $self->_copyUclibcRootfs();
    callInSubprocess(
        sub {
            $self->_callChrootedFunction({
            chrootDir    => $self->{'vendor-os-path'},
            function     => sub {
                $self->{'distro'}->addUclibLdconfig();
        },
        updateConfig => 1,
        });
    });
    $self->_touchVendorOS();
    $self->addInstalledVendorOSToConfigDB();
    return;
}

sub updateVendorOS
{
    my $self = shift;

    if (!-e $self->{'vendor-os-path'}) {
        die _tr("can't update vendor-OS '%s', since it doesn't exist!\n",
            $self->{'vendor-os-path'});
    }

    my $httpServers = OpenSLX::ScopedResource->new({
        name    => 'local-http-servers',
        acquire => sub { $self->_startLocalURLServersAsNeeded(); 1 },
        release => sub { $self->_stopLocalURLServers(); 1 },
    });

    callInSubprocess(
        sub {
            $self->_changePersonalityIfNeeded();
            $self->_updateStage1D();
        }
    );

    $self->_copyUclibcRootfs();
    $self->_touchVendorOS();
    vlog(
        0,
        _tr("Vendor-OS '%s' updated succesfully.\n", $self->{'vendor-os-name'})
    );

    $self->_installPlugins();

    return;
}

sub startChrootedShellForVendorOS
{
    my $self = shift;

    if (!-e $self->{'vendor-os-path'}) {
        die _tr(
            "can't start chrooted shell for vendor-OS '%s', since it doesn't exist!\n",
            $self->{'vendor-os-path'}
        );
    }

    my $httpServers = OpenSLX::ScopedResource->new({
        name    => 'local-http-servers',
        acquire => sub { $self->_startLocalURLServersAsNeeded(); 1 },
        release => sub { $self->_stopLocalURLServers(); 1 },
    });

    callInSubprocess(
        sub {
            $self->_changePersonalityIfNeeded();
            $self->_startChrootedShellInStage1D();
        }
    );

    vlog(
        0,
        _tr(
            "Chrooted shell for vendor-OS '%s' has been closed.\n",
            $self->{'vendor-os-name'}
        )
    );
    $self->_touchVendorOS();

    return;
}

sub callChrootedFunctionForVendorOS
{
    my $self         = shift;
    my $function     = shift;
    my $updateConfig = shift || 0;

    if (!-e $self->{'vendor-os-path'}) {
        die _tr(
            "can't call chrooted function for vendor-OS '%s', since it doesn't exist!\n",
            $self->{'vendor-os-path'}
        );
    }

    # avoid trying to chroot into a 64-bit vendor-OS if the host is only 32-bit:
    if (!$self->_hostIs64Bit() && -e "$self->{'vendor-os-path'}/lib64") {
        die _tr("you can't use a 64-bit vendor-OS on a 32-bit host, sorry!\n");
    }

    my $httpServers = OpenSLX::ScopedResource->new({
        name    => 'local-http-servers',
        acquire => sub { $self->_startLocalURLServersAsNeeded(); 1 },
        release => sub { $self->_stopLocalURLServers(); 1 },
    });

    callInSubprocess(
        sub {
            $self->_changePersonalityIfNeeded();
            $self->_callChrootedFunction({
                chrootDir    => $self->{'vendor-os-path'}, 
                function     => $function,
                updateConfig => $updateConfig,
            });
        }
    );

    vlog(
        1,
        _tr(
            "Chrooted function for vendor-OS '%s' has finished.\n",
            $self->{'vendor-os-name'}
        )
    );
    $self->_touchVendorOS();

    return 1;
}

sub removeVendorOS
{
    my $self = shift;

    vlog(
        0,
        _tr("removing vendor-OS folder '%s'...", $self->{'vendor-os-path'})
    );
    if (system(
        "find $self->{'vendor-os-path'} -xdev -depth -print0 | xargs -0 rm -r"
    )) {
        vlog(
            0,
            _tr("* unable to remove vendor-OS '%s'!", $self->{'vendor-os-path'})
        );
    }
    else {
        vlog(
            0,
            _tr(
                "Vendor-OS '%s' removed succesfully.\n",
                $self->{'vendor-os-name'}
            )
        );
    }
    $self->removeVendorOSFromConfigDB();
    return;
}

sub addInstalledVendorOSToConfigDB
{
    my $self = shift;

    if (!-e $self->{'vendor-os-path'}) {
        die _tr(
            "can't import vendor-OS '%s', since it doesn't exist!\n",
            $self->{'vendor-os-path'}
        );
    }
    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();

    my @plugins;

    # insert new vendor-os if it doesn't already exist in DB:
    my $vendorOSName = $self->{'vendor-os-name'};
    my $vendorOS = $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
    if (defined $vendorOS) {
        if ($vendorOS->{'clone_source'}
        && $self->{'clone-source'} ne $vendorOS->{'clone_source'}) {
            $openslxDB->changeVendorOS(
                $vendorOS->{id},
                { 'clone_source' => $self->{'clone-source'} }
            );
            vlog(
                0,
                _tr(
                    "Vendor-OS '%s' has been updated in OpenSLX-database.\n",
                    $vendorOSName
                )
            );
        }
        else {
            vlog(
                0,
                _tr(
                    "No need to change vendor-OS '%s' in OpenSLX-database.\n",
                    $vendorOSName
                )
            );
        }
        # fetch installed plugins of this vendor-OS in order to reinstall them
        @plugins = $openslxDB->fetchInstalledPlugins($vendorOS->{id});
    }
    else {
        my $data = { 'name' => $vendorOSName };
        if (length($self->{'clone-source'})) {
            $data->{'clone_source'} = $self->{'clone-source'};
        }
        my $id = $openslxDB->addVendorOS($data);

        vlog(
            0,
            _tr(
                "Vendor-OS '%s' has been added to DB (ID=%s).\n",
                $vendorOSName, $id
            )
        );
        # fetch plugins from default vendor-OS in order to install those into
        # this new one
        @plugins = $openslxDB->fetchInstalledPlugins(0);
    }

    $openslxDB->disconnect();
    
    # now that we have the list of plugins, we (re-)install all of them:
    $self->_installPlugins(\@plugins, defined $vendorOS);
    
    return;
}

sub removeVendorOSFromConfigDB
{
    my $self = shift;

    my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
    $openslxDB->connect();

    my $vendorOSName = $self->{'vendor-os-name'};
    my $vendorOS = $openslxDB->fetchVendorOSByFilter({'name' => $vendorOSName});
    if (!defined $vendorOS) {
        vlog(
            0,
            _tr(
                "Vendor-OS '%s' didn't exist in OpenSLX-database.\n",
                $vendorOSName
            )
        );
    }
    else {
        # remove all exports (and systems) using this vendor-OS and then
        # remove the vendor-OS itself:
        my @exports = $openslxDB->fetchExportByFilter(
            {'vendor_os_id' => $vendorOS->{id}});
        foreach my $export (@exports) {
            my $osExportEngine = instantiateClass("OpenSLX::OSExport::Engine");
            $osExportEngine->initializeFromExisting($export->{name});
            vlog(
                0,
                _tr(
                    "purging export '%s', since it belongs to the vendor-OS being deleted...",
                    $export->{name}
                )
            );
            $osExportEngine->purgeExport();
        }

        $openslxDB->removeVendorOS($vendorOS->{id});
        vlog(
            0,
            _tr("Vendor-OS '%s' has been removed from DB!\n", $vendorOSName)
        );
    }

    $openslxDB->disconnect();
    return;
}

sub pickKernelFile
{
    my $self = shift;

    return $self->{distro}->pickKernelFile(@_);
}

sub distroName
{
    my $self = shift;

    return $self->{'distro-name'};
}

sub metaPackager
{
    my $self = shift;

    return $self->{'meta-packager'};
}

sub packager
{
    my $self = shift;

    return $self->{'packager'};
}

sub getInstallablePackagesForSelection
{
    my $self   = shift;
    my $selKey = shift;

    return if !$selKey;

    my $selection = $self->{'distro-info'}->{selection}->{$selKey};
    return if !$selection;
    
    my @pkgs = split m{\s+}, $selection->{packages};
    my %installedPkgs;
    @installedPkgs{ $self->{'packager'}->getInstalledPackages() } = ();
    @pkgs = grep { !exists $installedPkgs{$_} } @pkgs;

    return join ' ', @pkgs;
}

sub busyboxBinary
{
    my $self = shift;
    
    my $uclibdir = "$openslxConfig{'base-path'}/share/uclib-rootfs";

    return sprintf(
        "LD_LIBRARY_PATH=%s/lib %s/bin/busybox",
        $uclibdir,
        $uclibdir
    );
}

################################################################################
### implementation methods
################################################################################
sub _readDistroInfo
{
    my $self                    = shift;
    my $setupMirrorsIfNecessary = shift || 0;

    vlog(1, "reading configuration info for $self->{'vendor-os-name'}...");

    $self->{'distro-info'} = {
        'package-subdir'     => '',
        'prereq-packages'    => '',
        'bootstrap-packages' => '',
        'metapackager'       => {},
        'repository'         => {},
        'selection'          => {},
        'excludes'           => {},
    };

    # merge user-provided configuration with distro defaults
    foreach my $file (
        "$self->{'shared-distro-info-dir'}/settings.default",
        "$self->{'config-distro-info-dir'}/settings"
    ) {
        if (-e $file) {
            vlog(2, "reading configuration file $file...");
            my $configObject = Config::General->new(
                -AllowMultiOptions => 0,
                -AutoTrue          => 1,
                -ConfigFile        => $file,
                -LowerCaseNames    => 1,
                -SplitPolicy       => 'equalsign',
            );
            my %config = $configObject->getall();
            mergeHash($self->{'distro-info'}, \%config);
        }
    }
    
    # fetch mirrors for all repositories (if requested):
    foreach my $repoKey (keys %{$self->{'distro-info'}->{repository}}) {
        my $repo = $self->{'distro-info'}->{repository}->{$repoKey};
        $repo->{key} = $repoKey;
        # if there is local URL, only that is used, otherwise we fetch the
        # configured mirrors:
        if (!$repo->{'local-url'}) {
            $repo->{urls} = $self->_fetchConfiguredMirrorsForRepository(
                $repo, $setupMirrorsIfNecessary
            );
        }
    }

    # expand all selections:
    my $seen = {};
    foreach my $selKey (keys %{$self->{'distro-info'}->{selection}}) {
        $self->_expandSelection($selKey, $seen);
    }

    # dump distro-info, if asked for:
    if ($openslxConfig{'log-level'} >= 2) {
        my $repository = $self->{'distro-info'}->{repository};
        foreach my $r (sort keys %$repository) {
            vlog(2, "repository '$r':");
            foreach my $k (sort keys %{$repository->{$r}}) {
                vlog(3, "\t$k = '$repository->{$r}->{$k}'");
            }
        }
        my $selection = $self->{'distro-info'}->{selection};
        foreach my $s (sort keys %$selection) {
            vlog(2, "selection '$s':");
            foreach my $k (sort keys %{$selection->{$s}}) {
                vlog(3, "\t$k = '$selection->{$s}->{$k}'");
            }
        }
        my $excludes = $self->{'distro-info'}->{excludes};
        foreach my $e (sort keys %$excludes) {
            vlog(2, "excludes for '$e':");
            foreach my $k (sort keys %{$excludes->{$e}}) {
                vlog(3, "\t$k = '$excludes->{$e}->{$k}'");
            }
        }
    }
    return;
}

sub _fetchConfiguredMirrorsForRepository
{
    my $self                    = shift;
    my $repoInfo                = shift;
    my $setupMirrorsIfNecessary = shift;

    my $configuredMirrorsFile
        = "$self->{'config-distro-info-dir'}/mirrors/$repoInfo->{key}";
    if (!-e $configuredMirrorsFile) {
        return '' if !$setupMirrorsIfNecessary;
        vlog(0, 
            _tr(
                "repo '%s' has no configured mirrors, let's pick some ...",
                $repoInfo->{name}
            )
        );
        $self->_configureBestMirrorsForRepository($repoInfo);
    }
    vlog(2, "reading configured mirrors file '$configuredMirrorsFile'.");
    my $configObject = Config::General->new(
        -AllowMultiOptions => 0,
        -AutoTrue          => 1,
        -ConfigFile        => $configuredMirrorsFile,
        -LowerCaseNames    => 1,
        -SplitPolicy       => 'equalsign',
    );
    my %config = $configObject->getall();
    
    return $config{urls};
}

sub _configureBestMirrorsForRepository
{
    my $self     = shift;
    my $repoInfo = shift;

    my $configuredMirrorsFile
        = "$self->{'config-distro-info-dir'}/mirrors/$repoInfo->{key}";

    if (!-e "$self->{'config-distro-info-dir'}/mirrors") {
        mkdir "$self->{'config-distro-info-dir'}/mirrors";
    }

    my $allMirrorsFile
        = "$self->{'shared-distro-info-dir'}/mirrors/$repoInfo->{key}";
    my @allMirrors = string2Array(scalar slurpFile($allMirrorsFile));

    my $mirrorsToTryCount = $openslxConfig{'mirrors-to-try-count'} || 20;
    my $mirrorsToUseCount = $openslxConfig{'mirrors-to-use-count'} || 5;
    vlog(1, 
        _tr(
            "selecting the '%s' best mirrors (from a set of '%s') for repo '%s' ...", 
            $mirrorsToUseCount, $mirrorsToTryCount, $repoInfo->{key}
        )
    );

    # determine own top-level domain:
    my $topLevelDomain;
    if (defined $openslxConfig{'mirrors-preferred-top-level-domain'}) {
        $topLevelDomain 
            = lc($openslxConfig{'mirrors-preferred-top-level-domain'});
    }
    else {
        my $FQDN = getFQDN();
        $FQDN =~ m{\.(\w+)$};
        $topLevelDomain = lc($1);
    }

    # select up to $mirrorsToTryCount "close" mirrors from the array ...
    my @tryMirrors
        =     grep {
                my $uri = URI->new($_);
                my $host = $uri->host();
                $host =~ m{\.(\w+)$} && lc($1) eq $topLevelDomain;
            }
            @allMirrors;

    my $tryList = join("\n\t", @tryMirrors);
    vlog(1, 
        _tr(
            "mirrors matching the preferred top level domain ('%s'):\n\t%s\n",
            $topLevelDomain, $tryList
        )
    );

    if (@tryMirrors > $mirrorsToTryCount) {
        # shrink array to $mirrorsToTryCount elements
        vlog(1, _tr("shrinking list to %s mirrors\n", $mirrorsToTryCount));
        $#tryMirrors = $mirrorsToTryCount;
    }
    elsif (@tryMirrors < $mirrorsToTryCount) {
        # we need more mirrors, try adding some others randomly:
        vlog(1, 
            _tr(
                "filling list with %s more random mirrors:\n", 
                $mirrorsToTryCount - @tryMirrors
            )
        );

        # fill @untriedMirrors with the mirrors not already contained 
        # in @tryMirrors ...
        my @untriedMirrors 
            =    grep {
                    my $mirror = $_;
                    !grep { $mirror eq $_ } @tryMirrors;
                } @allMirrors;

        # ... and pick randomly until we have reached the limit or there are 
        # no more unused mirrors left
        foreach my $count (@tryMirrors..$mirrorsToTryCount-1) {
            last if !@untriedMirrors;
            my $index = int(rand(scalar @untriedMirrors));
            my $randomMirror = splice(@untriedMirrors, $index, 1);
            push @tryMirrors, $randomMirror;
            vlog(1, "\t$randomMirror\n");
        }
    }
    
    # just make sure we are not going to try/use more mirros than we have
    # available
    if ($mirrorsToTryCount > @tryMirrors) {
        $mirrorsToTryCount = @tryMirrors;
    }
    if ($mirrorsToUseCount > $mirrorsToTryCount) {
        $mirrorsToUseCount = $mirrorsToTryCount;
    }

    # ... fetch a file from all of these mirrors and measure the time taken ...
    vlog(0, 
        _tr(
            "testing %s mirrors to determine the fastest %s ...\n", 
            $mirrorsToTryCount, $mirrorsToUseCount
        )
    );
    my %mirrorSpeed;
    my $veryGoodSpeedCount = 0;
    foreach my $mirror (@tryMirrors) {
        if ($veryGoodSpeedCount >= $mirrorsToUseCount) {
            # we already have enough mirrors with very good speed,
            # it makes no sense to test any others. We simply set the
            # time of the remaining mirrors to some large value, so they
            # won't get picked:
            $mirrorSpeed{$mirror} = 10000;
            next;
        }

        # test the current mirror and record the result
        my $time = $self->_speedTestMirror(
            $mirror, $repoInfo->{'file-for-speedtest'}
        );
        $mirrorSpeed{$mirror} = $time;
        if ($time <= 1) {
            $veryGoodSpeedCount++;
        }
    }

    # ... now select the best (fastest) $mirrorsToUseCount mirrors ... 
    my @bestMirrors 
        =    (
                sort {
                    $mirrorSpeed{$a} <=> $mirrorSpeed{$b};
                }
                @tryMirrors
            )[0..$mirrorsToUseCount-1];
    
    vlog(0, 
        _tr(
            "picked these '%s' mirrors for repo '%s':\n\t%s\n",
            $mirrorsToUseCount, $repoInfo->{name}, join("\n\t", @bestMirrors)
        )
    );

    # ... and write them into the configuration file:
    my $configObject = Config::General->new(
        -AllowMultiOptions => 0,
        -AutoTrue          => 1,
        -LowerCaseNames    => 1,
        -SplitPolicy       => 'equalsign',
    );
    $configObject->save_file($configuredMirrorsFile, {
        'urls' => join("\n", @bestMirrors),
    });
    return;
}

sub _speedTestMirror
{
    my $self   = shift;
    my $mirror = shift;
    my $file   = shift;

    vlog(0, _tr("\ttesting mirror '%s' ...\n", $mirror));
    
    # do an explicit DNS-lookup as we do not want to include the time that takes
    # in the speedtest
    my $uri = URI->new($mirror);
    my $hostName = $uri->host();
    if (!gethostbyname($hostName)) {
        # unable to resolve host, we pretend it took really long
        return 10000;
    }

    # now measure the time it takes to download the file
    my $wgetCmd  = $self->busyboxBinary();
       $wgetCmd .= " wget -q -O - $mirror/$file >/dev/null";
    my $start = time();
    if (slxsystem($wgetCmd)) {
        # just return any large number that is unlikely to be selected
        return 10000;
    }
    my $time = time() - $start;
    vlog(0, "\tfetched '$file' in $time seconds\n");
    return $time;
}
        
sub _expandSelection
{
    my $self   = shift;
    my $selKey = shift;
    my $seen =   shift;

    return if $seen->{$selKey};
    $seen->{$selKey} = 1;

    return if !exists $self->{'distro-info'}->{selection}->{$selKey};
    my $selection = $self->{'distro-info'}->{selection}->{$selKey};

    if ($selection->{base}) {
        # add all packages from base selection(s) to the current one:
        my $basePackages = '';
        for my $base (split ',', $selection->{base}) {
            my $baseSelection = $self->{'distro-info'}->{selection}->{$base}
                or die _tr(
                    'base-selection "%s" is unknown (referenced in "%s")!', 
                    $base, $selKey
                );
            $self->_expandSelection($base, $seen);
            $basePackages .= $baseSelection->{packages} || '';
        }
        my $packages = $selection->{packages} || '';
        $selection->{packages} = $basePackages . "\n" . $packages;
    }
    return;
}

sub _applyVendorOSSettings
{
    my $self = shift;
    my $vendorOSSettings = shift;

    if (exists $vendorOSSettings->{'root-password'}) {
        # hashes password according to requirements of current distro and 
        # writes it to /etc/shadow
        $self->{distro}->setPasswordForUser(
            'root', $vendorOSSettings->{'root-password'}
        );
    }

    return;
}

sub _createVendorOSPath
{
    my $self = shift;

    if (slxsystem("mkdir -p $self->{'vendor-os-path'}")) {
        die _tr("unable to create directory '%s', giving up! (%s)\n",
            $self->{'vendor-os-path'}, $!);
    }
    return;
}

sub _touchVendorOS
{
    my $self = shift;

    # touch root folder, as we are using this folder to determine the
    # 'age' of the vendor-OS when trying to determine whether or not we
    # need to re-export this vendor-OS:
    slxsystem("touch $self->{'vendor-os-path'}");
    return;
}

sub _copyUclibcRootfs
{
    my $self = shift;
    my $targetRoot = shift || $self->{'vendor-os-path'};
    my $distro = $self->{distro};

    vlog(0, _tr("copying uclibc-rootfs into vendor-OS ...\n"));

    my $target     = "$targetRoot/opt/openslx/uclib-rootfs";

    if (system("mkdir -p $target")) {
        die _tr("unable to create directory '%s', giving up! (%s)\n",
                $target, $!);
    }

    my $uclibcRootfs = "$openslxConfig{'base-path'}/share/uclib-rootfs";
    my @excludes = qw(
        dialog
        kexec
        libcurses.so*
        libncurses.so*
        mconf
        strace
    );
    my $exclOpts = join ' ', map { "--exclude $_" } @excludes;
    vlog(3, _tr("using exclude-filter:\n%s\n", $exclOpts));
    my $rsyncFH;
    my $rsyncCmd
        = "rsync -aq --delete-excluded --exclude-from=- $uclibcRootfs/ $target";
    vlog(2, "executing: $rsyncCmd\n");
    # if we're doing a fresh install we need to create /lib, /bin first
    mkdir "$targetRoot/lib";
    mkdir "$targetRoot/bin";
    # link uClibc from the uclib-rootfs to /lib to make tools working
    my $uClibCmd = "ln -sf /opt/openslx/uclib-rootfs/lib/ld-uClibc.so.0";
    $uClibCmd .= " $targetRoot/lib/ld-uClibc.so.0";
    system($uClibCmd);

    open($rsyncFH, '|-', $rsyncCmd)
        or die _tr("unable to start rsync for source '%s', giving up! (%s)",
                   $uclibcRootfs, $!);
    print $rsyncFH $exclOpts;
    close($rsyncFH)
        or die _tr("unable to copy to target '%s', giving up! (%s)",
                   $target, $!);

    # write version of uclibc-rootfs original into a file in order to be
    # able to check the up-to-date state later (in the config-demuxer)
    slxsystem("slxversion >${target}.version");

    return;
}

sub _createPackager
{
    my $self = shift;

    my $packagerClass 
        = "OpenSLX::OSSetup::Packager::$self->{distro}->{'packager-type'}";
    my $packager = instantiateClass($packagerClass);
    $packager->initialize($self);
    $self->{'packager'} = $packager;
    return;
}

sub _createMetaPackager
{
    my $self = shift;

    my $metaPackagerType = $self->{distro}->{'meta-packager-type'};

    my $installInfoFile = "$self->{'vendor-os-path'}/.openslx-install-info";
    if (-e $installInfoFile) {
        # activate the meta-packager that was used when installing the os:
        my $installInfo = slurpFile($installInfoFile);
        if ($installInfo =~ m[SLX_META_PACKAGER=(\w+)]) {
            $metaPackagerType = $1;
        }
    }

    my $metaPackagerClass = "OpenSLX::OSSetup::MetaPackager::$metaPackagerType";
    my $metaPackager      = instantiateClass($metaPackagerClass);
    $metaPackager->initialize($self);
    $self->{'meta-packager'} = $metaPackager;
    return;
}

sub _sortRepositoryURLs
{
    my $self     = shift;
    my $repoInfo = shift;

    my @URLs 
        = defined $repoInfo->{'local-url'}
            ? $repoInfo->{'local-url'}
            : string2Array($repoInfo->{urls});
    if (!@URLs) {
        die(
            _tr(
                "repository '%s' has no URLs defined, unable to fetch anything!",
                $repoInfo->{name},
            )
        );
    }

    return \@URLs;
}

sub _downloadBaseFiles
{
    my $self  = shift;
    my $files = shift;

    my $pkgSubdir   = $self->{'distro-info'}->{'package-subdir'};
    my @URLs        = @{$self->{'baseURLs'}};
    my $maxTryCount = $openslxConfig{'ossetup-max-try-count'};

    my @foundFiles;
    foreach my $fileVariantStr (@$files) {
        my $tryCount = 0;
        next unless $fileVariantStr =~ m[\S];
        my $foundFile;
try_next_url:
        my $url = $URLs[$self->{'baseURL-index'}];
        $url .= "/$pkgSubdir" if length($pkgSubdir);

        foreach my $file (split '\s+', $fileVariantStr) {
            my $basefile = basename($file);
            vlog(2, "fetching <$file>...");
            if (slxsystem("wget", "-c", "-O", "$basefile", "$url/$file") == 0) {
                $foundFile = $basefile;
                last;
            }
            elsif (-e $basefile) {
                vlog(0, "removing left-over '$basefile' and trying again...");
                unlink $basefile;
                redo;
            }
        }
        if (!defined $foundFile) {
            if ($tryCount < $maxTryCount) {
                $tryCount++;
                $self->{'baseURL-index'} 
                    = ($self->{'baseURL-index'} + 1) % scalar(@URLs);
                vlog(
                    0,
                    _tr(
                        "switching to mirror '%s'.",
                        $URLs[$self->{'baseURL-index'}]
                    )
                );
                goto try_next_url;
            }
            die _tr("unable to fetch '%s' from any source!\n", $fileVariantStr);
        }
        push @foundFiles, $foundFile;
    }
    return @foundFiles;
}

sub _startLocalURLServersAsNeeded
{
    my $self = shift;

    my $port = 5080;
    my %portForURL;
    foreach my $repoInfo (values %{$self->{'distro-info'}->{repository}}) {
        my $localURL = $repoInfo->{'local-url'} || '';
        next if !$localURL;
        next if $localURL =~ m[^\w+:];    # anything with a protcol-spec is non-local
        if (!exists $localHttpServers{$localURL}) {
            my $pid 
                = executeInSubprocess(
                    $self->busyboxBinary(), "httpd", '-p', $port, '-h', '/', '-f'
                );
            vlog(1, 
                _tr(
                    "started local HTTP-server for URL '%s' on port '%s'.", 
                    $localURL, $port
                )
            );
            $repoInfo->{'local-url'} = "http://localhost:$port$localURL";
            $localHttpServers{$localURL}->{pid} = $pid;
            $localHttpServers{$localURL}->{url} = $repoInfo->{'local-url'};
            $port++;
        }
        else {
            $repoInfo->{'local-url'} = $localHttpServers{$localURL}->{url};
        }
    }
    return;
}

sub _stopLocalURLServers
{
    my $self = shift;

    while (my ($localURL, $serverInfo) = each %localHttpServers) {
        vlog(1, _tr("stopping local HTTP-server for URL '%s'.", $localURL));
        kill TERM => $serverInfo->{pid};
    }
}

sub _setupStage1A
{
    my $self = shift;

    vlog(1, "setting up stage1a for $self->{'vendor-os-name'}...");

    # specify individual paths for the respective substages:
    $self->{stage1aDir}    = "$self->{'vendor-os-path'}/stage1a";
    $self->{stage1bSubdir} = 'slxbootstrap';
    $self->{stage1cSubdir} = 'slxfinal';

    # we create *all* of the above folders by creating stage1cDir:
    my $stage1cDir 
        = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
    if (slxsystem("mkdir -p $stage1cDir")) {
        die _tr("unable to create directory '%s', giving up! (%s)\n",
            $stage1cDir, $!);
    }

    $self->_stage1A_setupUclibcEnvironment();
    $self->_stage1A_copyPrerequiredFiles();
    $self->_stage1A_copyTrustedPackageKeys();
    $self->_stage1A_createRequiredFiles();
    return;
}

sub _stage1A_setupUclibcEnvironment
{
    my $self = shift;
    $self->_copyUclibcRootfs("$self->{stage1aDir}/$self->{stage1bSubdir}");
    my $source = "$self->{stage1bSubdir}/opt/openslx/uclib-rootfs";
    my $target = "$self->{stage1aDir}";
    slxsystem("ln -sf $source/bin $target/bin");
    slxsystem("ln -sf $source/lib $target/lib");
    slxsystem("ln -sf $source/usr $target/usr");
    $self->_stage1A_setupResolver();
    
    return;
}


sub _stage1A_setupResolver
{
    my $self       = shift;
    my $libcFolder = shift;

    #if (!defined $libcFolder) {
    #    warn _tr("unable to determine libc-target-folder, will use /lib!");
    #    $libcFolder = '/lib';
    #}

    copyFile('/etc/resolv.conf', "$self->{stage1aDir}/etc");
    copyFile('/etc/nsswitch.conf', "$self->{stage1aDir}/etc");
    spitFile("$self->{stage1aDir}/etc/hosts", "127.0.0.1 localhost\n");
    #copyFile("$libcFolder/libresolv*",    "$self->{stage1aDir}$libcFolder");
    #copyFile("$libcFolder/libnss_dns*",   "$self->{stage1aDir}$libcFolder");
    #copyFile("$libcFolder/libnss_files*", "$self->{stage1aDir}$libcFolder");

    my $stage1cDir 
        = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
    copyFile('/etc/resolv.conf', "$stage1cDir/etc");
    return;
}

sub _stage1A_copyPrerequiredFiles
{
    my $self = shift;

    return unless -d "$self->{'shared-distro-info-dir'}/prereqfiles";

    vlog(2, "copying folder with pre-required files...");
    my $stage1cDir 
        = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
    my $cmd = qq[
        tar -cp -C $self->{'shared-distro-info-dir'}/prereqfiles . \\
        | tar -xp -C $stage1cDir
    ];
    if (slxsystem($cmd)) {
        die _tr(
            "unable to copy folder with pre-required files to folder '%s' (%s)\n",
            $stage1cDir, $!
        );
    }
    vlog(2, "fix pre-required files...");
    $self->{distro}->fixPrerequiredFiles($stage1cDir);
    return;
}

sub _stage1A_copyTrustedPackageKeys
{
    my $self = shift;

    vlog(2, "copying folder with trusted package keys...");
    my $stage1bDir = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
    foreach my $folder (
        $self->{'shared-distro-info-dir'}, $self->{'config-distro-info-dir'}
    ) {
        next unless -d "$folder/trusted-package-keys";
        my $cmd = qq[
            tar -cp -C $folder trusted-package-keys \\
        | tar -xp -C $stage1bDir
        ];
        if (slxsystem($cmd)) {
            die _tr(
                "unable to copy folder with trusted package keys to folder '%s' (%s)\n",
                "$stage1bDir/trusted-package-keys", $!
            );
        }
        slxsystem("chmod 444 $stage1bDir/trusted-package-keys/*");

        # install ultimately trusted keys (from distributor):
        my $stage1cDir = "$stage1bDir/$self->{'stage1cSubdir'}";
        my $keyDir = "$self->{'shared-distro-info-dir'}/trusted-package-keys";
        if (-e "$keyDir/pubring.gpg") {
            copyFile("$keyDir/pubring.gpg", "$stage1cDir/usr/lib/rpm/gnupg");
        }
    }
    return;
}

sub _stage1A_createRequiredFiles
{
    my $self = shift;

    vlog(2, "creating required files...");

    # fake all files required by stage1b (by creating them empty):
    my $stage1bDir = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}";
    foreach my $fake (@{$self->{distro}->{'stage1b-faked-files'}}) {
        fakeFile("$stage1bDir/$fake");
    }

    # fake all files required by stage1c (by creating them empty):
    my $stage1cDir = "$stage1bDir/$self->{'stage1cSubdir'}";
    foreach my $fake (@{$self->{distro}->{'stage1c-faked-files'}}) {
        fakeFile("$stage1cDir/$fake");
    }

    mkdir "$stage1cDir/dev";
    if (!-e "$stage1cDir/dev/null"
        && slxsystem("mknod $stage1cDir/dev/null c 1 3"))
    {
        die _tr(
            "unable to create node '%s' (%s)\n", "$stage1cDir/dev/null", $!
        );
    }
    return;
}

sub _setupStage1B
{
    my $self = shift;

    vlog(1, "setting up stage1b for $self->{'vendor-os-name'}...");
    $self->_stage1B_chrootAndBootstrap();
    return;
}

sub _stage1B_chrootAndBootstrap
{
    my $self = shift;

    # give packager a chance to copy required files into stage1a-folder:
    $self->{packager}->prepareBootstrap($self->{stage1aDir});
    
    $self->_callChrootedFunction({
        chrootDir => $self->{stage1aDir},
        function  => sub {
            # chdir into slxbootstrap, as we want to drop packages into there:
            chdir "/$self->{stage1bSubdir}"
                or die _tr(
                    "unable to chdir into '%s' (%s)\n", 
                    "/$self->{stage1bSubdir}", $!
                );

            # fetch prerequired packages and use them to bootstrap the packager:
            $self->{'baseURLs'} = $self->_sortRepositoryURLs(
                $self->{'distro-info'}->{repository}->{base}
            );
            $self->{'baseURL-index'} = 0;
            my @pkgs = string2Array($self->{'distro-info'}->{'prereq-packages'});
            vlog(
                2, 
                "downloading these prereq packages:\n\t" . join("\n\t", @pkgs)
            );
            my @prereqPkgs = $self->_downloadBaseFiles(\@pkgs);
            $self->{'prereq-packages'} = \@prereqPkgs;
            $self->{packager}->bootstrap(\@prereqPkgs);
        
            @pkgs = string2Array($self->{'distro-info'}->{'bootstrap-packages'});
            push(
                @pkgs,
                string2Array(
                    $self->{'distro-info'}->{'metapackager'}
                        ->{$self->{distro}->{'meta-packager-type'}}->{packages}
                )
            );
            vlog(
                2, 
                "downloading bootstrap packages:\n\t" . join("\n\t", @pkgs)
            );
            my @bootstrapPkgs = $self->_downloadBaseFiles(\@pkgs);
            $self->{'bootstrap-packages'} = \@bootstrapPkgs;
        },
    });
    return;
}

sub _setupStage1C
{
    my $self = shift;

    vlog(1, "setting up stage1c for $self->{'vendor-os-name'}...");
    $self->_stage1C_chrootAndInstallBasicVendorOS();
    return;
}

sub _stage1C_chrootAndInstallBasicVendorOS
{
    my $self = shift;

    my $stage1bDir = "/$self->{stage1bSubdir}";
    chrootInto($stage1bDir);

    my $stage1cDir = "/$self->{stage1cSubdir}";

    # import any additional trusted package keys to rpm-DB:
    my $keyDir = "/trusted-package-keys";
    my $keyDirDH;
    if (opendir($keyDirDH, $keyDir)) {
        my @keyFiles 
            = map { "$keyDir/$_" }
              grep { $_ !~ m[^(\.\.?|pubring.gpg)$] } 
              readdir($keyDirDH);
        closedir($keyDirDH);
        $self->{packager}->importTrustedPackageKeys(\@keyFiles, $stage1cDir);
    }

    # install bootstrap packages
    $self->{packager}->installPackages(
        $self->{'bootstrap-packages'}, $stage1cDir
    );
    return;
}

sub _stage1C_cleanupBasicVendorOS
{
    my $self = shift;

    my $stage1cDir 
        = "$self->{'stage1aDir'}/$self->{'stage1bSubdir'}/$self->{'stage1cSubdir'}";
    if (slxsystem("mv $stage1cDir/* $self->{'vendor-os-path'}/")) {
        die _tr(
            "unable to move final setup to '%s' (%s)\n",
            $self->{'vendor-os-path'}, $!
        );
    }
    if (slxsystem("rm -rf $self->{stage1aDir}")) {
        die _tr(
            "unable to remove temporary folder '%s' (%s)\n",
            $self->{stage1aDir}, $!
        );
    }
    return;
}

sub _setupStage1D
{
    my $self = shift;

    vlog(1, "setting up stage1d for $self->{'vendor-os-name'}...");

    $self->_callChrootedFunction({
        chrootDir    => $self->{'vendor-os-path'},
        function     => sub {
            $self->_stage1D_setupPackageSources();
            $self->_stage1D_updateBasicVendorOS();
            $self->{distro}->preSystemInstallationHook();
            my $ok = eval {
                $self->_stage1D_installPackageSelection();
                1;
            };
            my $err = $ok ? undef : $@;
            $self->{distro}->postSystemInstallationHook();
            die $err if defined $err;
        },
        updateConfig => 1,
    });
    return;
}

sub _updateStage1D
{
    my $self = shift;

    vlog(1, "updating $self->{'vendor-os-name'}...");

    $self->_callChrootedFunction({
        chrootDir    => $self->{'vendor-os-path'},
        function     => sub {
            $self->_stage1D_updateBasicVendorOS();
        },
        updateConfig => 1,
    });
    return;
}

sub _startChrootedShellInStage1D
{
    my $self = shift;

    vlog(0, "starting chrooted shell for $self->{'vendor-os-name'}");
    vlog(0, "---------------------------------------");
    vlog(0, "- please type 'exit' if you are done! -");
    vlog(0, "---------------------------------------");

    $self->_callChrootedFunction({
        chrootDir    => $self->{'vendor-os-path'},
        function     => sub {
            # will hang until user exits manually:
            slxsystem($openslxConfig{'default-shell'});
        },
        updateConfig => 1,
    });
    return;
}

sub _callChrootedFunction
{
    my $self   = shift;
    my $params = shift;
    
    checkParams($params, {
        'chrootDir'    => '!',
        'function'     => '!',
        'updateConfig' => '?',
    });

    my $distro = $self->{distro};
    my $distroSession = OpenSLX::ScopedResource->new({
        name    => 'ossetup::distro::session',
        acquire => sub { $distro->startSession($params->{chrootDir}); 1 },
        release => sub { $distro->finishSession(); 1 },
    });

    die $@ if ! eval {
        # invoke given function:
        $params->{function}->();
        $distro->updateDistroConfig() if $params->{updateConfig};
        1;
    };

    return;
}

sub _stage1D_setupPackageSources
{
    my $self = shift;

    vlog(1, "setting up package sources for meta packager...");
    my $selectionName = $self->{'selection-name'};
    my $pkgExcludes
        = $self->{'distro-info'}->{excludes}->{$selectionName}->{packages};
    my $excludeList = join ' ', string2Array($pkgExcludes);
    $self->{'meta-packager'}->initPackageSources();
    my ($rk, $repo);
    while (($rk, $repo) = each %{$self->{'distro-info'}->{repository}}) {
        vlog(2, "setting up package source $rk...");
        $self->{'meta-packager'}->setupPackageSource(
            $rk, $repo, $excludeList, $self->_sortRepositoryURLs($repo)
        );
    }
    return;
}

sub _stage1D_updateBasicVendorOS
{
    my $self = shift;

    vlog(1, "updating basic vendor-os...");
    $self->{'meta-packager'}->updateBasicVendorOS();
    return;
}

sub _stage1D_installPackageSelection
{
    my $self = shift;

    my $selectionName = $self->{'selection-name'};

    vlog(1, "installing package selection <$selectionName>...");
    my $selection     = $self->{'distro-info'}->{selection}->{$selectionName};
    my @pkgs          = string2Array($selection->{packages});
    my @installedPkgs = $self->{'packager'}->getInstalledPackages();
    @pkgs = grep {
        my $pkg = $_;
        if (grep { $_ eq $pkg; } @installedPkgs) {
            vlog(1, "package '$pkg' filtered, it is already installed.");
            0;
        }
        else {
            1;
        }
    } @pkgs;
    if (!@pkgs) {
        vlog(
            0,
            _tr(
                "No packages listed for selection '%s', nothing to do.",
                $selectionName
            )
        );
    }
    else {
        vlog(1, "installing these packages:\n" . join("\n\t", @pkgs));
        $self->{'meta-packager'}->installPackages(join(' ', @pkgs), 1);
    }
    return;
}

sub _clone_fetchSource
{
    my $self   = shift;
    my $source = shift;

    vlog(
        0,
        _tr(
            "Cloning vendor-OS from '%s' to '%s'...\n", $source,
            $self->{'vendor-os-path'}
        )
    );
    my $excludeIncludeList = $self->_clone_determineIncludeExcludeList();
    vlog(1, "using exclude-include-filter:\n$excludeIncludeList\n");
    my $additionalRsyncOptions = $ENV{SLX_RSYNC_OPTIONS} || '';
    my $rsyncCmd 
        = "rsync -av --delete --exclude-from=- $additionalRsyncOptions"
            . " $source $self->{'vendor-os-path'}";
    vlog(2, "executing: $rsyncCmd\n");
    my $rsyncFH;
    open($rsyncFH, '|-', $rsyncCmd)
        or croak(
            _tr(
                "unable to start rsync for source '%s', giving up! (%s)\n",
                $source, $!
            )
        );
    print $rsyncFH $excludeIncludeList;
    if (!close($rsyncFH)) {
        print "rsync-result=", 0+$!, "\n";
        croak _tr(
            "unable to clone from source '%s', giving up! (%s)\n", $source, $!
        );
    }
    return;
}

sub _clone_determineIncludeExcludeList
{
    my $self = shift;

    my $localFilterFile 
        = "$openslxConfig{'config-path'}/distro-info/clone-filter";
    my $includeExcludeList 
        = slurpFile($localFilterFile, { failIfMissing => 0 });
    $includeExcludeList .= $self->{distro}->{'clone-filter'};
    $includeExcludeList =~ s[^\s+][]igms;

    # remove any leading whitespace, as rsync doesn't like it
    return $includeExcludeList;
}

sub _installPlugins
{
    my $self        = shift;
    my $plugins     = shift;
    my $isReInstall = shift;

    if (!$plugins) {
        $plugins = [];
        my $openslxDB = instantiateClass("OpenSLX::ConfigDB");
        $openslxDB->connect();
        # fetch plugins from existing vendor-OS
        my $vendorOS = $openslxDB->fetchVendorOSByFilter({
            'name' => $self->{'vendor-os-name'}
        });
        if ($vendorOS) {
            push @$plugins, $openslxDB->fetchInstalledPlugins($vendorOS->{id});
            $isReInstall = 1;
        }
        $openslxDB->disconnect();
    }

    return if ! @$plugins;
    
    require OpenSLX::OSPlugin::Engine;
    vlog(
        0, 
        $isReInstall
            ? _tr("reinstalling plugins...\n")
            : _tr("installing default plugins...\n")
    );
    for my $pluginInfo (
        sort { 
            $self->_sortPluginsByDependency($a->{plugin_name}, $b->{plugin_name}); 
        } @$plugins
    ) {
        my $pluginName = $pluginInfo->{plugin_name};
        my $pluginEngine = OpenSLX::OSPlugin::Engine->new();
        vlog(0, _tr("\t%s\n", $pluginName));
        $pluginEngine->initialize(
            $pluginName, $self->{'vendor-os-name'}, $pluginInfo->{attrs}
        );
        $pluginEngine->installPlugin();
    }
    vlog(0, _tr("done with plugins.\n"));

    return;
}
    
sub _sortPluginsByDependency
{
    my $self        = shift;
    my $pluginNameA = shift;
    my $pluginNameB = shift;
    
    my $pluginA = OpenSLX::OSPlugin::Roster->getPlugin($pluginNameA);
    if ($pluginA->dependsOnPlugin($pluginNameB)) {
        return 1;
    }
    my $pluginB = OpenSLX::OSPlugin::Roster->getPlugin($pluginNameB);
    if ($pluginB->dependsOnPlugin($pluginNameA)) {
        return -1;
    }
    return 0;
}

################################################################################
### utility methods
################################################################################
sub _changePersonalityIfNeeded
{
    my $self = shift;

    my $distroName = $self->{'distro-name'};
    if ($self->_hostIs64Bit() && $distroName !~ m[_64]) {
        vlog(2, 'entering 32-bit personality');
        OpenSLX::Syscall->enter32BitPersonality();
    }
    return;
}

sub _hostIs64Bit
{
    my $self = shift;

    $self->{arch} = `uname -m` unless defined $self->{arch};
    return ($self->{arch} =~ m[64]);
}

1;

=pod

=head1 NAME

OpenSLX::OSSetup::Engine - driver engine for OSSetup API

=head1 SYNOPSIS

...

=cut

