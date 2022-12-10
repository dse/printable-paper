package My::Printable::Paper::Util::Installed;
use warnings;
use strict;
use v5.10.0;

use File::Find qw(find);
use File::Spec::Functions qw(canonpath abs2rel);

use Moo;

has rawModuleList => (
    is => 'rw',
);
has rawModuleHash => (
    is => 'rw',
);
sub moduleList {
    my ($self, @args) = @_;
    if (!scalar @args && !$self->rawModuleList) {
        $self->setModuleListAndHash();
    }
    return $self->rawModuleList(@args);
}
sub moduleHash {
    my ($self, @args) = @_;
    if (!scalar @args && !$self->rawModuleHash) {
        $self->setModuleListAndHash();
    }
    return $self->rawModuleHash(@args);
}

sub getListOfRulingModules {
    my ($self) = @_;
    my @modules = grep { m{^My::Printable::Paper::Ruling::} } @{$self->moduleList};
    return @modules;
}

has rawRulingModuleList => (
    is => 'rw',
);
has rawRulingNameList => (
    is => 'rw',
);
sub rulingModuleList {
    my ($self, @args) = @_;
    if (!scalar @args && !$self->rawRulingModuleList) {
        $self->setRulingModuleList();
    }
    return $self->rawRulingModuleList(@args);
}
sub rulingNameList {
    my ($self, @args) = @_;
    if (!scalar @args && !$self->rawRulingNameList) {
        $self->setRulingNameList();
    }
    return $self->rawRulingNameList(@args);
}

sub setRulingModuleList {
    my ($self) = @_;
    my @modules = grep { m{^My::Printable::Paper::Ruling::} } @{$self->moduleList};
    $self->rawRulingModuleList(\@modules);
}
sub setRulingNameList {
    my ($self) = @_;
    my @modules = @{$self->rulingModuleList()};
    my @rulingNameList;
    foreach my $module (@modules) {
        eval "use $module;";
        push(@rulingNameList, $module->rulingName);
    }
    $self->rawRulingNameList(\@rulingNameList);
}

sub setModuleListAndHash {
    my ($self) = @_;
    my @moduleList;
    my %moduleHash;
    foreach my $inc (@INC) {
        my $wanted = sub {
            return unless m{\.pm\z};
            my $canonpath = canonpath($_);
            my $relpath = abs2rel($_, $inc);
            my $module = path_to_module($relpath);
            push(@moduleList, $module);
            $moduleHash{$module} = $canonpath;
        };
        find($wanted, $inc);
    }
    $self->rawModuleList(\@moduleList);
    $self->rawModuleHash(\%moduleHash);
}

sub path_to_module {
    my ($path) = @_;
    $path =~ s{\.pm\z}{};
    $path =~ s{[\/\\]+}{::}g;
    return $path;
}

1;
