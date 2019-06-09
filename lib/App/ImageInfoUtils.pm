package App::ImageInfoUtils;

# DATE
# VERSION

use 5.010001;
use strict;
use warnings;
#use Log::Any '$log';

our %SPEC;

our %arg0_files = (
    files => {
        'x.name.is_plural' => 1,
        'x.name.singular' => 'file',
        schema => ['array*' => of => 'filename*', min_len=>1],
        req => 1,
        pos => 0,
        greedy => 1,
    },
);

our %arg0_file = (
    file => {
        schema => ['filename*'],
        req => 1,
        pos => 0,
    },
);

our %argopt_quiet = (
    quiet => {
        summary => "Don't output anything on command-line, ".
            "just return appropriate exit code",
        schema => 'true*',
        cmdline_aliases => {q=>{}, silent=>{}},
    },
);

$SPEC{image_info} = {
    v => 1.1,
    summary => 'Get information about image files',
    args => {
        %arg0_files,
    },
};
sub image_info {
    require Image::Info;

    my %args = @_;

    my @rows;
    for my $file (@{$args{files}}) {
        my $res = Image::Info::image_info($file);
        if ($res->{error}) {
            warn "Can't get image info for '$file': $res->{error}\n";
            next;
        }
        push @rows, { file => $file, %$res };
    }

    return [500, "All failed"] unless @rows;
    if (@{ $args{files} } == 1) {
        return [200, "OK", $rows[0]];
    } else {
        return [200, "OK", \@rows];
    }
}

$SPEC{image_is_portrait} = {
    v => 1.1,
    summary => 'Return exit code 0 if image is portrait',
    description => <<'_',

_
    args => {
        %arg0_file,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Produce smaller version of portrait images',
            src => 'for f in *[0-9].jpg;do [[prog]] -q "$f" && convert "$f" -resize 20% "${f/.jpg/.small.jpg}"; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub image_is_portrait {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    my $orientation = $res->[2]{Orientation} // '';
    my $width  = $res->[2]{width};
    my $height = $res->[2]{height};
    return [412, "Can't determine image orientation"] unless $orientation;
    return [412, "Can't determine image width x height"] unless $width && $height;
    my $is_portrait = ($orientation =~ /\A(left|right)_/ ? 1:0) ^ ($width <= $height ? 1:0) ? 1:0;

    [200, "OK", $is_portrait, {
        'cmdline.exit_code' => $is_portrait ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            'Image is '.
            ($is_portrait ? "portrait" : "NOT portrait (landscape)"),
    }];
}

$SPEC{image_is_landscape} = {
    v => 1.1,
    summary => 'Return exit code 0 if image is landscape',
    description => <<'_',

_
    args => {
        %arg0_file,
        %argopt_quiet,
    },
    examples => [
        {
            summary => 'Move all landscape images to landscape/',
            src => 'for f in *.jpg;do [[prog]] -q "$f" && mv "$f" landscape/; done',
            src_plang => 'bash',
            test => 0,
            'x.doc.show_result' => 0,
        },
    ],
};
sub image_is_landscape {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    my $orientation = $res->[2]{Orientation} // '';
    my $width  = $res->[2]{width};
    my $height = $res->[2]{height};
    return [412, "Can't determine image orientation"] unless $orientation;
    return [412, "Can't determine image width x height"] unless $width && $height;
    my $is_landscape = ($orientation =~ /\A(left|right)_/ ? 1:0) ^ ($width <= $height ? 1:0) ? 0:1;

    [200, "OK", $is_landscape, {
        'cmdline.exit_code' => $is_landscape ? 0:1,
        'cmdline.result' => $args{quiet} ? '' :
            'Image is '.
            ($is_landscape ? "landscape" : "NOT landscape (portrait)"),
    }];
}

$SPEC{image_orientation} = {
    v => 1.1,
    summary => "Return orientation of image",
    args => {
        %arg0_file,
    },
};
sub image_orientation {
    my %args = @_;

    my $res = image_info(files => [$args{file}]);
    return $res unless $res->[0] == 200;

    [200, "OK", $res->[2]{Orientation}];
}

1;
# ABSTRACT:
