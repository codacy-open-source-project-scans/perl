package IO::Compress::Deflate ;

require 5.006 ;

use strict ;
use warnings;
use bytes;

require Exporter ;

use IO::Compress::RawDeflate 2.207 ();
use IO::Compress::Adapter::Deflate 2.207 ;

use IO::Compress::Zlib::Constants 2.207 ;
use IO::Compress::Base::Common  2.207 qw();


our ($VERSION, @ISA, @EXPORT_OK, %EXPORT_TAGS, %DEFLATE_CONSTANTS, $DeflateError);

$VERSION = '2.207';
$DeflateError = '';

@ISA    = qw(IO::Compress::RawDeflate Exporter);
@EXPORT_OK = qw( $DeflateError deflate ) ;
%EXPORT_TAGS = %IO::Compress::RawDeflate::DEFLATE_CONSTANTS ;

push @{ $EXPORT_TAGS{all} }, @EXPORT_OK ;
Exporter::export_ok_tags('all');


sub new
{
    my $class = shift ;

    my $obj = IO::Compress::Base::Common::createSelfTiedObject($class, \$DeflateError);
    return $obj->_create(undef, @_);
}

sub deflate
{
    my $obj = IO::Compress::Base::Common::createSelfTiedObject(undef, \$DeflateError);
    return $obj->_def(@_);
}

sub mkComp
{
    my $self = shift ;
    my $got = shift ;

    my ($obj, $errstr, $errno) = IO::Compress::Adapter::Deflate::mkCompObject1(
                                                 $got->getValue('crc32'),
                                                 $got->getValue('adler32'),
                                                 $got->getValue('level'),
                                                 $got->getValue('strategy')
                                                 );

   return $self->saveErrorString(undef, $errstr, $errno)
       if ! defined $obj;

   return $obj;
}


sub mkHeader
{
    my $self = shift ;
    return '';
}

sub mkTrailer
{
    my $self = shift ;
    return '';
}

sub mkFinalTrailer
{
    return '';
}

sub getExtraParams
{
    my $self = shift ;
    return $self->getZlibParams(),
}

sub getInverseClass
{
    no warnings 'once';
    return ('IO::Uncompress::Inflate',
                \$IO::Uncompress::Inflate::InflateError);
}

sub getFileInfo
{
    my $self = shift ;
    my $params = shift;
    my $file = shift ;

}



1;

__END__

=head1 NAME

IO::Compress::Deflate - Write RFC 1950 files/buffers

=head1 SYNOPSIS

    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    my $status = deflate $input => $output [,OPTS]
        or die "deflate failed: $DeflateError\n";

    my $z = IO::Compress::Deflate->new( $output [,OPTS] )
        or die "deflate failed: $DeflateError\n";

    $z->print($string);
    $z->printf($format, $string);
    $z->write($string);
    $z->syswrite($string [, $length, $offset]);
    $z->flush();
    $z->tell();
    $z->eof();
    $z->seek($position, $whence);
    $z->binmode();
    $z->fileno();
    $z->opened();
    $z->autoflush();
    $z->input_line_number();
    $z->newStream( [OPTS] );

    $z->deflateParams();

    $z->close() ;

    $DeflateError ;

    # IO::File mode

    print $z $string;
    printf $z $format, $string;
    tell $z
    eof $z
    seek $z, $position, $whence
    binmode $z
    fileno $z
    close $z ;

=head1 DESCRIPTION

This module provides a Perl interface that allows writing compressed
data to files or buffer as defined in RFC 1950.

For reading RFC 1950 files/buffers, see the companion module
L<IO::Uncompress::Inflate|IO::Uncompress::Inflate>.

=head1 Functional Interface

A top-level function, C<deflate>, is provided to carry out
"one-shot" compression between buffers and/or files. For finer
control over the compression process, see the L</"OO Interface">
section.

    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    deflate $input_filename_or_reference => $output_filename_or_reference [,OPTS]
        or die "deflate failed: $DeflateError\n";

The functional interface needs Perl5.005 or better.

=head2 deflate $input_filename_or_reference => $output_filename_or_reference [, OPTS]

C<deflate> expects at least two parameters,
C<$input_filename_or_reference> and C<$output_filename_or_reference>
and zero or more optional parameters (see L</Optional Parameters>)

=head3 The C<$input_filename_or_reference> parameter

The parameter, C<$input_filename_or_reference>, is used to define the
source of the uncompressed data.

It can take one of the following forms:

=over 5

=item A filename

If the C<$input_filename_or_reference> parameter is a simple scalar, it is
assumed to be a filename. This file will be opened for reading and the
input data will be read from it.

=item A filehandle

If the C<$input_filename_or_reference> parameter is a filehandle, the input
data will be read from it.  The string '-' can be used as an alias for
standard input.

=item A scalar reference

If C<$input_filename_or_reference> is a scalar reference, the input data
will be read from C<$$input_filename_or_reference>.

=item An array reference

If C<$input_filename_or_reference> is an array reference, each element in
the array must be a filename.

The input data will be read from each file in turn.

The complete array will be walked to ensure that it only
contains valid filenames before any data is compressed.

=item An Input FileGlob string

If C<$input_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<deflate> will assume that it is an
I<input fileglob string>. The input is the list of files that match the
fileglob.

See L<File::GlobMapper|File::GlobMapper> for more details.

=back

If the C<$input_filename_or_reference> parameter is any other type,
C<undef> will be returned.

=head3 The C<$output_filename_or_reference> parameter

The parameter C<$output_filename_or_reference> is used to control the
destination of the compressed data. This parameter can take one of
these forms.

=over 5

=item A filename

If the C<$output_filename_or_reference> parameter is a simple scalar, it is
assumed to be a filename.  This file will be opened for writing and the
compressed data will be written to it.

=item A filehandle

If the C<$output_filename_or_reference> parameter is a filehandle, the
compressed data will be written to it.  The string '-' can be used as
an alias for standard output.

=item A scalar reference

If C<$output_filename_or_reference> is a scalar reference, the
compressed data will be stored in C<$$output_filename_or_reference>.

=item An Array Reference

If C<$output_filename_or_reference> is an array reference,
the compressed data will be pushed onto the array.

=item An Output FileGlob

If C<$output_filename_or_reference> is a string that is delimited by the
characters "<" and ">" C<deflate> will assume that it is an
I<output fileglob string>. The output is the list of files that match the
fileglob.

When C<$output_filename_or_reference> is an fileglob string,
C<$input_filename_or_reference> must also be a fileglob string. Anything
else is an error.

See L<File::GlobMapper|File::GlobMapper> for more details.

=back

If the C<$output_filename_or_reference> parameter is any other type,
C<undef> will be returned.

=head2 Notes

When C<$input_filename_or_reference> maps to multiple files/buffers and
C<$output_filename_or_reference> is a single
file/buffer the input files/buffers will be stored
in C<$output_filename_or_reference> as a concatenated series of compressed data streams.

=head2 Optional Parameters

The optional parameters for the one-shot function C<deflate>
are (for the most part) identical to those used with the OO interface defined in the
L</"Constructor Options"> section. The exceptions are listed below

=over 5

=item C<< AutoClose => 0|1 >>

This option applies to any input or output data streams to
C<deflate> that are filehandles.

If C<AutoClose> is specified, and the value is true, it will result in all
input and/or output filehandles being closed once C<deflate> has
completed.

This parameter defaults to 0.

=item C<< BinModeIn => 0|1 >>

This option is now a no-op. All files will be read in binmode.

=item C<< Append => 0|1 >>

The behaviour of this option is dependent on the type of output data
stream.

=over 5

=item * A Buffer

If C<Append> is enabled, all compressed data will be append to the end of
the output buffer. Otherwise the output buffer will be cleared before any
compressed data is written to it.

=item * A Filename

If C<Append> is enabled, the file will be opened in append mode. Otherwise
the contents of the file, if any, will be truncated before any compressed
data is written to it.

=item * A Filehandle

If C<Append> is enabled, the filehandle will be positioned to the end of
the file via a call to C<seek> before any compressed data is
written to it.  Otherwise the file pointer will not be moved.

=back

When C<Append> is specified, and set to true, it will I<append> all compressed
data to the output data stream.

So when the output is a filehandle it will carry out a seek to the eof
before writing any compressed data. If the output is a filename, it will be opened for
appending. If the output is a buffer, all compressed data will be
appended to the existing buffer.

Conversely when C<Append> is not specified, or it is present and is set to
false, it will operate as follows.

When the output is a filename, it will truncate the contents of the file
before writing any compressed data. If the output is a filehandle
its position will not be changed. If the output is a buffer, it will be
wiped before any compressed data is output.

Defaults to 0.

=back

=head2 Oneshot Examples

Here are a few example that show the capabilities of the module.

=head3 Streaming

This very simple command line example demonstrates the streaming capabilities of the module.
The code reads data from STDIN, compresses it, and writes the compressed data to STDOUT.

    $ echo hello world | perl -MIO::Compress::Deflate=deflate -e 'deflate \*STDIN => \*STDOUT' >output.1950

The special filename "-" can be used as a standin for both C<\*STDIN> and C<\*STDOUT>,
so the above can be rewritten as

    $ echo hello world | perl -MIO::Compress::Deflate=deflate -e 'deflate "-" => "-"' >output.1950

=head3 Compressing a file from the filesystem

To read the contents of the file C<file1.txt> and write the compressed
data to the file C<file1.txt.1950>.

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    my $input = "file1.txt";
    deflate $input => "$input.1950"
        or die "deflate failed: $DeflateError\n";

=head3 Reading from a Filehandle and writing to an in-memory buffer

To read from an existing Perl filehandle, C<$input>, and write the
compressed data to a buffer, C<$buffer>.

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;
    use IO::File ;

    my $input = IO::File->new( "<file1.txt" )
        or die "Cannot open 'file1.txt': $!\n" ;
    my $buffer ;
    deflate $input => \$buffer
        or die "deflate failed: $DeflateError\n";

=head3 Compressing multiple files

To compress all files in the directory "/my/home" that match "*.txt"
and store the compressed data in the same directory

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    deflate '</my/home/*.txt>' => '<*.1950>'
        or die "deflate failed: $DeflateError\n";

and if you want to compress each file one at a time, this will do the trick

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    for my $input ( glob "/my/home/*.txt" )
    {
        my $output = "$input.1950" ;
        deflate $input => $output
            or die "Error compressing '$input': $DeflateError\n";
    }

=head1 OO Interface

=head2 Constructor

The format of the constructor for C<IO::Compress::Deflate> is shown below

    my $z = IO::Compress::Deflate->new( $output [,OPTS] )
        or die "IO::Compress::Deflate failed: $DeflateError\n";

The constructor takes one mandatory parameter, C<$output>, defined below and
zero or more C<OPTS>, defined in L<Constructor Options>.

It returns an C<IO::Compress::Deflate> object on success and C<undef> on failure.
The variable C<$DeflateError> will contain an error message on failure.

If you are running Perl 5.005 or better the object, C<$z>, returned from
IO::Compress::Deflate can be used exactly like an L<IO::File|IO::File> filehandle.
This means that all normal output file operations can be carried out
with C<$z>.
For example, to write to a compressed file/buffer you can use either of
these forms

    $z->print("hello world\n");
    print $z "hello world\n";

Below is a simple exaple of using the OO interface to create an output file
C<myfile.1950> and write some data to it.

    my $filename = "myfile.1950";
    my $z = IO::Compress::Deflate->new($filename)
        or die "IO::Compress::Deflate failed: $DeflateError\n";

    $z->print("abcde");
    $z->close();

See the L</Examples> for more.

The mandatory parameter C<$output> is used to control the destination
of the compressed data. This parameter can take one of these forms.

=over 5

=item A filename

If the C<$output> parameter is a simple scalar, it is assumed to be a
filename. This file will be opened for writing and the compressed data
will be written to it.

=item A filehandle

If the C<$output> parameter is a filehandle, the compressed data will be
written to it.
The string '-' can be used as an alias for standard output.

=item A scalar reference

If C<$output> is a scalar reference, the compressed data will be stored
in C<$$output>.

=back

If the C<$output> parameter is any other type, C<IO::Compress::Deflate>::new will
return undef.

=head2 Constructor Options

C<OPTS> is any combination of zero or more the following options:

=over 5

=item C<< AutoClose => 0|1 >>

This option is only valid when the C<$output> parameter is a filehandle. If
specified, and the value is true, it will result in the C<$output> being
closed once either the C<close> method is called or the C<IO::Compress::Deflate>
object is destroyed.

This parameter defaults to 0.

=item C<< Append => 0|1 >>

Opens C<$output> in append mode.

The behaviour of this option is dependent on the type of C<$output>.

=over 5

=item * A Buffer

If C<$output> is a buffer and C<Append> is enabled, all compressed data
will be append to the end of C<$output>. Otherwise C<$output> will be
cleared before any data is written to it.

=item * A Filename

If C<$output> is a filename and C<Append> is enabled, the file will be
opened in append mode. Otherwise the contents of the file, if any, will be
truncated before any compressed data is written to it.

=item * A Filehandle

If C<$output> is a filehandle, the file pointer will be positioned to the
end of the file via a call to C<seek> before any compressed data is written
to it.  Otherwise the file pointer will not be moved.

=back

This parameter defaults to 0.

=item C<< Merge => 0|1 >>

This option is used to compress input data and append it to an existing
compressed data stream in C<$output>. The end result is a single compressed
data stream stored in C<$output>.

It is a fatal error to attempt to use this option when C<$output> is not an
RFC 1950 data stream.

There are a number of other limitations with the C<Merge> option:

=over 5

=item 1

This module needs to have been built with zlib 1.2.1 or better to work. A
fatal error will be thrown if C<Merge> is used with an older version of
zlib.

=item 2

If C<$output> is a file or a filehandle, it must be seekable.

=back

This parameter defaults to 0.

=item -Level

Defines the compression level used by zlib. The value should either be
a number between 0 and 9 (0 means no compression and 9 is maximum
compression), or one of the symbolic constants defined below.

   Z_NO_COMPRESSION
   Z_BEST_SPEED
   Z_BEST_COMPRESSION
   Z_DEFAULT_COMPRESSION

The default is Z_DEFAULT_COMPRESSION.

Note, these constants are not imported by C<IO::Compress::Deflate> by default.

    use IO::Compress::Deflate qw(:strategy);
    use IO::Compress::Deflate qw(:constants);
    use IO::Compress::Deflate qw(:all);

=item -Strategy

Defines the strategy used to tune the compression. Use one of the symbolic
constants defined below.

   Z_FILTERED
   Z_HUFFMAN_ONLY
   Z_RLE
   Z_FIXED
   Z_DEFAULT_STRATEGY

The default is Z_DEFAULT_STRATEGY.

=item C<< Strict => 0|1 >>

This is a placeholder option.

=back

=head2 Examples

=head3 Streaming

This very simple command line example demonstrates the streaming capabilities
of the module. The code reads data from STDIN or all the files given on the
commandline, compresses it, and writes the compressed data to STDOUT.

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    my $z = IO::Compress::Deflate->new("-", Stream => 1)
        or die "IO::Compress::Deflate failed: $DeflateError\n";

    while (<>) {
        $z->print("abcde");
    }
    $z->close();

Note the use of C<"-"> to means C<STDOUT>. Alternatively you can use C<\*STDOUT>.

=head3 Compressing a file from the filesystem

To read the contents of the file C<file1.txt> and write the compressed
data to the file C<file1.txt.1950> there are a few options

Start by creating the compression object and opening the input file

    use strict ;
    use warnings ;
    use IO::Compress::Deflate qw(deflate $DeflateError) ;

    my $input = "file1.txt";
    my $z = IO::Compress::Deflate->new("file1.txt.1950")
        or die "IO::Compress::Deflate failed: $DeflateError\n";

    # open the input file
    open my $fh, "<", "file1.txt"
        or die "Cannot open file1.txt: $!\n";

    # loop through the input file & write to the compressed file
    while (<$fh>) {
        $z->print($_);
    }

    # not forgetting to close the compressed file
    $z->close();

=head1 Methods

=head2 print

Usage is

    $z->print($data)
    print $z $data

Compresses and outputs the contents of the C<$data> parameter. This
has the same behaviour as the C<print> built-in.

Returns true if successful.

=head2 printf

Usage is

    $z->printf($format, $data)
    printf $z $format, $data

Compresses and outputs the contents of the C<$data> parameter.

Returns true if successful.

=head2 syswrite

Usage is

    $z->syswrite $data
    $z->syswrite $data, $length
    $z->syswrite $data, $length, $offset

Compresses and outputs the contents of the C<$data> parameter.

Returns the number of uncompressed bytes written, or C<undef> if
unsuccessful.

=head2 write

Usage is

    $z->write $data
    $z->write $data, $length
    $z->write $data, $length, $offset

Compresses and outputs the contents of the C<$data> parameter.

Returns the number of uncompressed bytes written, or C<undef> if
unsuccessful.

=head2 flush

Usage is

    $z->flush;
    $z->flush($flush_type);

Flushes any pending compressed data to the output file/buffer.

This method takes an optional parameter, C<$flush_type>, that controls
how the flushing will be carried out. By default the C<$flush_type>
used is C<Z_FINISH>. Other valid values for C<$flush_type> are
C<Z_NO_FLUSH>, C<Z_SYNC_FLUSH>, C<Z_FULL_FLUSH> and C<Z_BLOCK>. It is
strongly recommended that you only set the C<flush_type> parameter if
you fully understand the implications of what it does - overuse of C<flush>
can seriously degrade the level of compression achieved. See the C<zlib>
documentation for details.

Returns true on success.

=head2 tell

Usage is

    $z->tell()
    tell $z

Returns the uncompressed file offset.

=head2 eof

Usage is

    $z->eof();
    eof($z);

Returns true if the C<close> method has been called.

=head2 seek

    $z->seek($position, $whence);
    seek($z, $position, $whence);

Provides a sub-set of the C<seek> functionality, with the restriction
that it is only legal to seek forward in the output file/buffer.
It is a fatal error to attempt to seek backward.

Empty parts of the file/buffer will have NULL (0x00) bytes written to them.

The C<$whence> parameter takes one the usual values, namely SEEK_SET,
SEEK_CUR or SEEK_END.

Returns 1 on success, 0 on failure.

=head2 binmode

Usage is

    $z->binmode
    binmode $z ;

This is a noop provided for completeness.

=head2 opened

    $z->opened()

Returns true if the object currently refers to a opened file/buffer.

=head2 autoflush

    my $prev = $z->autoflush()
    my $prev = $z->autoflush(EXPR)

If the C<$z> object is associated with a file or a filehandle, this method
returns the current autoflush setting for the underlying filehandle. If
C<EXPR> is present, and is non-zero, it will enable flushing after every
write/print operation.

If C<$z> is associated with a buffer, this method has no effect and always
returns C<undef>.

B<Note> that the special variable C<$|> B<cannot> be used to set or
retrieve the autoflush setting.

=head2 input_line_number

    $z->input_line_number()
    $z->input_line_number(EXPR)

This method always returns C<undef> when compressing.

=head2 fileno

    $z->fileno()
    fileno($z)

If the C<$z> object is associated with a file or a filehandle, C<fileno>
will return the underlying file descriptor. Once the C<close> method is
called C<fileno> will return C<undef>.

If the C<$z> object is associated with a buffer, this method will return
C<undef>.

=head2 close

    $z->close() ;
    close $z ;

Flushes any pending compressed data and then closes the output file/buffer.

For most versions of Perl this method will be automatically invoked if
the IO::Compress::Deflate object is destroyed (either explicitly or by the
variable with the reference to the object going out of scope). The
exceptions are Perl versions 5.005 through 5.00504 and 5.8.0. In
these cases, the C<close> method will be called automatically, but
not until global destruction of all live objects when the program is
terminating.

Therefore, if you want your scripts to be able to run on all versions
of Perl, you should call C<close> explicitly and not rely on automatic
closing.

Returns true on success, otherwise 0.

If the C<AutoClose> option has been enabled when the IO::Compress::Deflate
object was created, and the object is associated with a file, the
underlying file will also be closed.

=head2 newStream([OPTS])

Usage is

    $z->newStream( [OPTS] )

Closes the current compressed data stream and starts a new one.

OPTS consists of any of the options that are available when creating
the C<$z> object.

See the L</"Constructor Options"> section for more details.

=head2 deflateParams

Usage is

    $z->deflateParams

TODO

=head1 Importing

A number of symbolic constants are required by some methods in
C<IO::Compress::Deflate>. None are imported by default.

=over 5

=item :all

Imports C<deflate>, C<$DeflateError> and all symbolic
constants that can be used by C<IO::Compress::Deflate>. Same as doing this

    use IO::Compress::Deflate qw(deflate $DeflateError :constants) ;

=item :constants

Import all symbolic constants. Same as doing this

    use IO::Compress::Deflate qw(:flush :level :strategy) ;

=item :flush

These symbolic constants are used by the C<flush> method.

    Z_NO_FLUSH
    Z_PARTIAL_FLUSH
    Z_SYNC_FLUSH
    Z_FULL_FLUSH
    Z_FINISH
    Z_BLOCK

=item :level

These symbolic constants are used by the C<Level> option in the constructor.

    Z_NO_COMPRESSION
    Z_BEST_SPEED
    Z_BEST_COMPRESSION
    Z_DEFAULT_COMPRESSION

=item :strategy

These symbolic constants are used by the C<Strategy> option in the constructor.

    Z_FILTERED
    Z_HUFFMAN_ONLY
    Z_RLE
    Z_FIXED
    Z_DEFAULT_STRATEGY

=back

=head1 EXAMPLES

=head2 Apache::GZip Revisited

See L<IO::Compress::FAQ|IO::Compress::FAQ/"Apache::GZip Revisited">

=head2 Working with Net::FTP

See L<IO::Compress::FAQ|IO::Compress::FAQ/"Compressed files and Net::FTP">

=head1 SUPPORT

General feedback/questions/bug reports should be sent to
L<https://github.com/pmqs/IO-Compress/issues> (preferred) or
L<https://rt.cpan.org/Public/Dist/Display.html?Name=IO-Compress>.

=head1 SEE ALSO

L<Compress::Zlib>, L<IO::Compress::Gzip>, L<IO::Uncompress::Gunzip>, L<IO::Uncompress::Inflate>, L<IO::Compress::RawDeflate>, L<IO::Uncompress::RawInflate>, L<IO::Compress::Bzip2>, L<IO::Uncompress::Bunzip2>, L<IO::Compress::Lzma>, L<IO::Uncompress::UnLzma>, L<IO::Compress::Xz>, L<IO::Uncompress::UnXz>, L<IO::Compress::Lzip>, L<IO::Uncompress::UnLzip>, L<IO::Compress::Lzop>, L<IO::Uncompress::UnLzop>, L<IO::Compress::Lzf>, L<IO::Uncompress::UnLzf>, L<IO::Compress::Zstd>, L<IO::Uncompress::UnZstd>, L<IO::Uncompress::AnyInflate>, L<IO::Uncompress::AnyUncompress>

L<IO::Compress::FAQ|IO::Compress::FAQ>

L<File::GlobMapper|File::GlobMapper>, L<Archive::Zip|Archive::Zip>,
L<Archive::Tar|Archive::Tar>,
L<IO::Zlib|IO::Zlib>

For RFC 1950, 1951 and 1952 see
L<https://datatracker.ietf.org/doc/html/rfc1950>,
L<https://datatracker.ietf.org/doc/html/rfc1951> and
L<https://datatracker.ietf.org/doc/html/rfc1952>

The I<zlib> compression library was written by Jean-loup Gailly
C<gzip@prep.ai.mit.edu> and Mark Adler C<madler@alumni.caltech.edu>.

The primary site for the I<zlib> compression library is
L<http://www.zlib.org>.

The primary site for the I<zlib-ng> compression library is
L<https://github.com/zlib-ng/zlib-ng>.

The primary site for gzip is L<http://www.gzip.org>.

=head1 AUTHOR

This module was written by Paul Marquess, C<pmqs@cpan.org>.

=head1 MODIFICATION HISTORY

See the Changes file.

=head1 COPYRIGHT AND LICENSE

Copyright (c) 2005-2024 Paul Marquess. All rights reserved.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.
