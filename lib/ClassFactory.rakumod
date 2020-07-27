unit module ClassFactory;

use Text::Utils :strip-comment, :normalize-string;
use JSON::Class;
use JSON::Hjson;
use File::Find;

our $coll-name is export = 0;
our %data      is export = [];
our %classes   is export = [];

sub show-files(:$dir, :$debug) is export {
    if $dir and $dir.IO.d {
        my @f = find :$dir, :exclude(/'.' [precomp|git] /);
        for @f -> $f is copy {
            say "  $f";
        }
        return;
    }

    # Default is to list files in the lib and data directories.
    my @f1 = find :dir<lib>, :exclude(/'.' [precomp|git] /);
    my @f2 = find :dir<data>, :exclude(/'.' [precomp|git] /);
    for (|@f1, |@f2).sort -> $f is copy {
        #$f ~~ s/$cwd//;
        say "  $f";
    }

}

sub initialize($cwd, :$factory-name!, :$force, :$debug) {
    # Given a directory and a factory name, create
    # all the necessary files and directories.
    # Do not overwrite existing files unless the force
    # opion is true.
    my $fn = $factory-name;
    # the tree
    constant $tree = q:to/HERE/;
        data/
    HERE

    my $dn = 'data'
}

sub instantiate($cwd, :$type = 'cf-data', :$debug) is export {
    die "FATAL: Data type '$type' not available." if $type ne 'cf-data';
}

sub collect-class-instances($dir, :$debug) {
    # We first try to search the .json directory if
    # it exists.

} # end sub

sub collect-class-definitions($dir, :$debug) {
} # end sub

sub read-class-instances($f, :$debug) {
} # end sub

sub read-class-definitions($f, :$debug) {
    # Reads a file and extracts the class definitions
    # into separate strings which are inserted
    # into the class hash.
    my $cname;
    my %attrs = %();
    LINE: for $f.IO.lines -> $line is copy {
        $line = strip-comment $line;
        next if $line !~~ /\S/;

        if $line ~~ /^ \h* 'class:' (\N+) $/ {
            my $new-class = normalize-string ~$0;
            # start a new class, so finish any existing class
            if $cname {
                my $err = 0;
                # an error if no attrs
                if not %attrs.elems  {
                    note "ERROR: Class '$cname' has no attributes...ignoring it.";
                    ++$err;
                }
                if %classes{$cname}:exists {
                    note "ERROR: Class '$cname' already exists...ignoring it.";
                    ++$err;
                }
                if $err {
                    $cname = 0;
                }
                else {
                    %classes{$cname} = make-body-str $cname, %attrs;
                }
            }
            # start the new class
            $cname = $new-class;
            %attrs = %();
            next LINE;
        }

        # must be an attr line to add to the current class
        my @w = $line.words;
        my $attr = @w.shift;
        my $type = @w.shift // 'Str';
        # check we have a valid type
        if $type !~~ /Int|UInt|Num|Str/ {
            note "ERROR: Class '$cname', attr '$attr' has unknown type '$type'";
        }
        else {
            %attrs{$attr} = $type;
        }
    } # end of LINE block

    # any data remaining?
    if $cname {
        die "FATAL: Class '$cname' has no attrs" if not %attrs.elems;
        %classes{$cname} = make-body-str $cname, %attrs;
        $cname = 0;
        %attrs = %();
    }
} # sub end

sub make-body-str($cname, %attrs, :$debug) {
    # Given a class name and a hash of attribute names and
    # types, make a string of the class definition.
    my ($max, $max2) = 0, 0;
    for %attrs.kv -> $k,  $v {
        my $n  = $k.elems;
        my $n2 = $v.elems;
        $max   = $n  if $max  < $n;
        $max2  = $n2 if $max2 < $n2;
    }
    my $s = "class $cname does JSON::Class is export \{\n";
    for %attrs.kv -> $k,  $v {
        $s ~= sprintf '    has %*.*s !.%*.*s', $max, $max, $k, $max2, $max2, $v;
    }
    $s ~= "}\n\n";
    %classes{$cname} = $s;
} # sub end
