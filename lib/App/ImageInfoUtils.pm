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

$SPEC{image_info} = {
    v => 1.1,
    summary => 'Get information about image files',
    args => {
        %arg0_files,
    },
};
sub image_info {
    require Media::Info;

    my %args = @_;

    my @rows;
    for my $file (@{$args{files}}) {
        my $res = image_info($file);
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

Portrait is defined as having 'rotate' metadata of 90 or 270 when the width >
height. Otherwise, media is assumed to be 'landscape'.

_
    args => {
        %arg0_file,
    },
};
sub image_is_portrait {
    my %args = @_;

    my $res = image_info(file => [$args{file}]);
    return $res unless $res->[0] == 200;

    my $rotate = $res->[2]{rotate} // 0;
    my $width  = $res->[2]{video_width}  // $res->[2]{width};
    my $height = $res->[2]{video_height} // $res->[2]{height};
    return [412, "Can't determine video width x height"] unless $width && $height;
    my $is_portrait = ($rotate == 90 || $rotate == 270 ? 1:0) ^ ($width <= $height ? 1:0) ? 1:0;

    [200, "OK", $is_portrait, {'cmdline.exit_code' => $is_portrait ? 0:1, 'cmdline.result' => ''}];
}

$SPEC{image_is_landscape} = {
    v => 1.1,
    summary => 'Return exit code 0 if media is landscape',
    description => <<'_',

Portrait is defined as having 'rotate' metadata of 90 or 270. Otherwise, media
is assumed to be 'landscape'.

_
    args => {
        %arg0_file,
    },
};
sub image_is_landscape {
    my %args = @_;

    my $res = media_info(media => [$args{media}], backend=>$args{backend});
    return $res unless $res->[0] == 200;

    my $rotate = $res->[2]{rotate} // 0;
    my $width  = $res->[2]{video_width}  // $res->[2]{width};
    my $height = $res->[2]{video_height} // $res->[2]{height};
    return [412, "Can't determine video width x height"] unless $width && $height;
    my $is_landscape = ($rotate == 90 || $rotate == 270 ? 1:0) ^ ($width <= $height ? 1:0) ? 0:1;

    [200, "OK", $is_landscape, {'cmdline.exit_code' => $is_landscape ? 0:1, 'cmdline.result' => ''}];
}

$SPEC{image_orientation} = {
    v => 1.1,
    summary => "Return orientation of image ('portrait' or 'landscape')",
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
