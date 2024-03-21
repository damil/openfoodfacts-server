# Compute recursive runtime dependencies from initial modules listed in cpanfile.
# Requires an internet connection to contact MetaCPAN fastapi.
use 5.24.0;
use utf8;
use strict;
use warnings;
use Module::CPANfile;
use MetaCPAN::Client;
use Try::Tiny;

# read cpanfile and compute initial module list
my $cpanfile     = shift // "../../cpanfile";
my $initial_deps = try   {Module::CPANfile->load($cpanfile)->prereqs->as_string_hash}
                   catch {die "could not load cpanfile from $cpanfile: $_"};
my @modules      = keys $initial_deps->{runtime}{requires}->%*;

# client for MetaCPAN API
my $metacpan = MetaCPAN::Client->new;

# structure for collecting modules
my %seen_module; # ($module_name => $dependency_level)

# starting from the initial @modules list, iterate over dependencies until we have seen all modules
for (my $level = 1; @modules; $level += 1) {
	warn "loop at level $level\n";

	# only keep modules that were not seen before
	@modules = grep {!$seen_module{$_}} @modules;

	# mark those as seen
	$seen_module{$_} = $level foreach @modules;

	# replace the list by the dependencies of the current list
	@modules = gather_dependencies(@modules);
}

# print results
say "$_ at level $seen_module{$_}" foreach sort keys %seen_module;

sub gather_dependencies {
	my @modules_at_previous_level = @_;

	my %depends_on;

	# iterate on modules and gather their dependencies in a collective hash
	foreach my $mod_name (@modules_at_previous_level) {
		warn "handling $mod_name\n";

		my $dist = $metacpan->module($mod_name)->distribution;
		try {
			my $release 		 = $metacpan->release($dist);
			my @subdeps 		 = $release->dependency->@*;
			my @runtime_deps = grep {$_->{phase} eq 'runtime' && $_->{relationship} eq 'requires'} @subdeps;
			$depends_on{$_}++ for map {$_->{module}} @runtime_deps;
		}
		catch {
			warn "$mod_name: can't find release ($_)\n";
		};
	}

	return keys %depends_on;
}


__END__
Script results as of 20.03.2024
===============================
Action::CircuitBreaker at level 1
Action::Retry at level 1
Algorithm::CheckDigits at level 1
Algorithm::Diff at level 2
Alien::Base at level 3
Alien::libgs1encoders at level 2
AnyDBM_File at level 3
AnyEvent at level 1
AnyEvent::Inotify::Simple at level 1
Apache2::Connection::XForwardedFor at level 1
Apache2::Request at level 1
Apache::Bootstrap at level 1
Archive::Zip at level 2
Array::Diff at level 1
Authen::SASL::SASLprep at level 2
Authen::SCRAM::Client at level 2
B at level 2
B::Hooks::EndOfScope at level 3
BSON at level 2
BSON::Bytes at level 2
BSON::Code at level 2
BSON::DBRef at level 2
BSON::OID at level 2
BSON::Raw at level 2
BSON::Regex at level 2
BSON::Time at level 2
BSON::Timestamp at level 2
BSON::Types at level 2
Barcode::ZBar at level 1
CGI at level 1
CLDR::Number at level 1
CLDR::Number::Format::Decimal at level 1
CLDR::Number::Format::Percent at level 1
CPAN::Meta at level 3
CPAN::Meta::Requirements at level 4
CPAN::Meta::YAML at level 4
Cache::Memcached::Fast at level 1
Capture::Tiny at level 2
Carp at level 2
Carp::Clan at level 3
Carp::Heavy at level 3
Class::Accessor::Fast at level 2
Class::Data::Inheritable at level 3
Class::Inspector at level 3
Class::Load at level 3
Class::Load::XS at level 3
Class::Method::Modifiers at level 2
Class::Singleton at level 3
Clone at level 1
Clone::Choose at level 5
Color::Library at level 2
Compress::Raw::Bzip2 at level 3
Compress::Raw::Zlib at level 3
Compress::Zlib at level 2
Config at level 2
Cpanel::JSON::XS at level 1
Crypt::PasswdMD5 at level 1
Crypt::RC4 at level 3
Crypt::Random::Source at level 2
Crypt::ScryptKDF at level 1
Crypt::URandom at level 3
Cwd at level 2
DBD::Pg at level 2
DBI at level 3
Data::Compare at level 1
Data::DeepAccess at level 1
Data::Difference at level 1
Data::Dumper at level 2
Data::Dumper::AutoEncode at level 1
Data::Dumper::Concise at level 4
Data::IEEE754 at level 3
Data::OptList at level 3
Data::Printer at level 3
Data::Section::Simple at level 2
Data::Validate::IP at level 2
Data::Visitor at level 3
Data::Visitor::Callback at level 3
Date::Format at level 3
Date::Parse at level 3
DateTime at level 1
DateTime::Format::Builder at level 2
DateTime::Format::ISO8601 at level 1
DateTime::Format::Strptime at level 3
DateTime::Locale at level 1
DateTime::Locale::Base at level 4
DateTime::Locale::FromData at level 4
DateTime::TimeZone at level 2
Devel::GlobalDestruction at level 3
Devel::OverloadInfo at level 3
Devel::Size at level 1
Devel::StackTrace at level 3
Digest at level 2
Digest::HMAC at level 3
Digest::MD5 at level 1
Digest::Perl::MD5 at level 3
Digest::SHA at level 2
Digest::SHA1 at level 1
Digest::base at level 2
Dist::CheckConflicts at level 2
DynaLoader at level 3
Email::Abstract at level 3
Email::Address::XS at level 3
Email::Date::Format at level 2
Email::MIME at level 2
Email::MIME::ContentType at level 3
Email::MIME::Creator at level 2
Email::MIME::Encodings at level 3
Email::MessageID at level 3
Email::Sender::Simple at level 2
Email::Simple at level 3
Email::Simple::Creator at level 3
Email::Simple::Header at level 3
Email::Stuffer at level 1
Email::Valid at level 1
Encode at level 2
Encode::Alias at level 3
Encode::Detect at level 1
Encode::Locale at level 2
Encode::Punycode at level 1
English at level 2
Errno at level 3
Eval::Closure at level 3
Excel::Writer::XLSX at level 1
Exception::Class at level 3
Exporter at level 2
Exporter::Tiny at level 2
ExtUtils::CBuilder at level 2
ExtUtils::Install at level 3
ExtUtils::MakeMaker at level 3
ExtUtils::Manifest at level 3
ExtUtils::Mkbootstrap at level 3
ExtUtils::ParseXS at level 3
ExtUtils::testlib at level 4
FFI::CheckLib at level 3
FFI::Platypus at level 2
Fcntl at level 2
File::Basename at level 2
File::Compare at level 2
File::Copy at level 2
File::Copy::Recursive at level 1
File::Find at level 2
File::Find::Rule at level 2
File::Glob at level 2
File::Listing at level 2
File::Next at level 2
File::Path at level 2
File::ShareDir at level 2
File::Spec at level 2
File::Spec::Functions at level 3
File::Temp at level 2
File::Which at level 2
File::chdir at level 4
File::chmod at level 2
File::chmod::Recursive at level 1
File::stat at level 2
FileHandle at level 3
GS1::SyntaxEngine::FFI at level 1
GeoIP2 at level 1
Getopt::Long at level 2
Getopt::Std at level 3
Graph at level 2
GraphViz2 at level 1
Graphics::Color::HSL at level 1
Graphics::Color::RGB at level 1
HTML::Entities at level 2
HTML::HeadParser at level 2
HTML::Tagset at level 3
HTTP::Cookies at level 2
HTTP::Date at level 2
HTTP::Headers at level 2
HTTP::Headers::Util at level 3
HTTP::Negotiate at level 2
HTTP::Request at level 2
HTTP::Request::Common at level 2
HTTP::Response at level 2
HTTP::Status at level 2
Hash::Merge at level 4
Hash::Util at level 5
Hash::Util::FieldHash::Compat at level 3
Heap at level 3
I18N::LangTags at level 4
I18N::LangTags::Detect at level 4
IO::Compress::Bzip2 at level 3
IO::Compress::Deflate at level 3
IO::Compress::Gzip at level 3
IO::Dir at level 5
IO::File at level 2
IO::HTML at level 3
IO::Handle at level 2
IO::Interactive::Tiny at level 2
IO::Scalar at level 3
IO::Seekable at level 3
IO::Select at level 2
IO::Socket at level 2
IO::Socket::INET at level 3
IO::Socket::IP at level 2
IO::Socket::SSL at level 3
IO::Socket::Timeout at level 2
IO::Uncompress::Gunzip at level 3
IO::Uncompress::Inflate at level 3
IO::Uncompress::RawInflate at level 3
IPC::Cmd at level 3
IPC::Open3 at level 3
IPC::Run3 at level 2
Image::Magick at level 1
Image::OCR::Tesseract at level 1
Imager at level 2
Imager::File::AVIF at level 1
Imager::File::HEIF at level 1
Imager::File::JPEG at level 1
Imager::File::PNG at level 1
Imager::File::WEBP at level 1
Imager::zxing at level 1
JSON at level 1
JSON::Create at level 1
JSON::MaybeXS at level 1
JSON::PP at level 1
JSON::Parse at level 1
LEOCHARRE::CLI at level 2
LEOCHARRE::DEBUG at level 3
LWP at level 3
LWP::Authen::Digest at level 1
LWP::MediaTypes at level 2
LWP::Protocol::http at level 3
LWP::Protocol::https at level 2
LWP::Simple at level 1
LWP::UserAgent at level 1
Linux::Inotify2 at level 2
Linux::usermod at level 3
List::AllUtils at level 3
List::MoreUtils at level 1
List::MoreUtils::XS at level 2
List::SomeUtils at level 2
List::Util at level 2
List::UtilsBy at level 4
Locale::Maketext at level 3
Locale::Maketext::Lexicon at level 2
Locale::Maketext::Lexicon::Getcontext at level 1
Locale::Maketext::Lexicon::Gettext at level 2
Locale::Maketext::Simple at level 4
Log::Any at level 1
Log::Any::Adapter::Base at level 2
Log::Any::Adapter::Log4perl at level 1
Log::Any::Adapter::Util at level 2
Log::Log4perl at level 1
MIME::Base32 at level 1
MIME::Base64 at level 2
MIME::Lite at level 1
MIME::QuotedPrint at level 2
MIME::Types at level 2
MRO::Compat at level 3
Mail::Address at level 2
Math::BigFloat at level 2
Math::BigInt at level 2
Math::Complex at level 3
Math::Fibonacci at level 2
Math::Random::ISAAC at level 2
Math::Random::Secure at level 1
Math::Round at level 2
MaxMind::DB::Common at level 3
MaxMind::DB::Metadata at level 3
MaxMind::DB::Reader at level 2
MaxMind::DB::Role::Debugs at level 3
MaxMind::DB::Types at level 3
Minion at level 1
Modern::Perl at level 1
Module::Build at level 2
Module::CoreList at level 5
Module::Find at level 3
Module::Implementation at level 3
Module::Load at level 1
Module::Load::Conditional at level 4
Module::Metadata at level 3
Module::Pluggable at level 3
Module::Runtime at level 2
Module::Runtime::Conflicts at level 3
Mojo::Pg at level 1
Mojolicious at level 2
Mojolicious::Lite at level 1
MongoDB at level 1
Moo at level 2
Moo::Role at level 2
MooX::StrictConstructor at level 3
MooX::Types::MooseLike at level 3
MooX::Types::MooseLike::Base at level 3
Moose at level 2
Moose::Exporter at level 3
Moose::Meta::Attribute at level 3
Moose::Meta::TypeConstraint::Union at level 3
Moose::Role at level 2
Moose::Util::TypeConstraints at level 2
MooseX::Aliases at level 2
MooseX::Clone at level 2
MooseX::FileAttribute at level 2
MooseX::Storage::Deferred at level 2
MooseX::Types at level 2
MooseX::Types::Moose at level 2
MooseX::Types::Path::Class at level 3
Mozilla::CA at level 4
Net::DNS at level 2
Net::Domain at level 3
Net::Domain::TLD at level 2
Net::FTP at level 2
Net::HTTP at level 2
Net::HTTPS at level 3
Net::IDN::Punycode at level 2
Net::SMTP at level 3
Net::SSLeay at level 4
NetAddr::IP at level 3
Number::Compare at level 3
OLE::Storage_Lite at level 3
PBKDF2::Tiny at level 3
POSIX at level 2
Package::DeprecationManager at level 3
Package::Stash at level 3
Package::Stash::XS at level 3
Params::Check at level 4
Params::Util at level 2
Params::Validate at level 2
Params::ValidationCompiler at level 2
Path::Class at level 4
Path::Tiny at level 1
Perl::OSType at level 3
PerlIO at level 3
PerlIO::via at level 4
PerlIO::via::Timeout at level 3
Pod::Escapes at level 2
Pod::Man at level 4
Pod::Perldoc at level 4
Pod::Simple at level 3
Pod::Simple::HTMLBatch at level 1
Pod::Simple::RTF at level 5
Pod::Simple::XMLOutStream at level 5
Pod::Text at level 2
Pod::Usage at level 3
Redis at level 1
Role::Tiny at level 3
Role::Tiny::With at level 3
SQL::Abstract at level 3
SQL::Abstract::Pg at level 2
Safe at level 3
Safe::Isa at level 2
Scalar::Util at level 2
SelectSaver at level 4
Sentinel at level 2
Set::Object at level 3
Socket at level 2
Specio at level 2
Specio::Declare at level 2
Specio::Exporter at level 2
Specio::Library::Builtins at level 2
Specio::Library::Numeric at level 2
Specio::Library::String at level 2
Specio::Subs at level 2
Spreadsheet::CSV at level 1
Spreadsheet::ParseExcel at level 2
Storable at level 2
String::RewritePrefix at level 3
String::ShellQuote at level 2
Sub::Defer at level 2
Sub::Exporter at level 3
Sub::Exporter::ForMethods at level 3
Sub::Exporter::Progressive at level 4
Sub::Exporter::Util at level 3
Sub::Identify at level 3
Sub::Install at level 3
Sub::Name at level 3
Sub::Quote at level 2
Sub::Util at level 2
Symbol at level 2
Sys::Hostname at level 3
TAP::Harness at level 3
Template at level 1
Term::ANSIColor at level 4
Test2::API at level 4
Test::Builder at level 4
Test::Builder::Module at level 4
Test::Deep at level 4
Test::Differences at level 2
Test::Fatal at level 3
Test::Harness at level 2
Test::More at level 2
Test::Simple at level 2
Test::use::ok at level 5
Text::Abbrev at level 3
Text::Balanced at level 4
Text::CSV at level 1
Text::CSV_XS at level 1
Text::Diff at level 3
Text::Fuzzy at level 1
Text::Glob at level 3
Text::ParseWords at level 3
Text::Unidecode at level 4
Text::Wrap at level 2
Throwable at level 2
Throwable::Error at level 2
Tie::Hash at level 3
Tie::IxHash at level 1
Tie::RefHash at level 4
Tie::ToObject at level 4
Time::HiRes at level 2
Time::Local at level 1
Time::Zone at level 3
Try::Tiny at level 2
Type::Library at level 2
Type::Tiny::XS at level 1
Type::Utils at level 2
Types::Standard at level 2
URI at level 2
URI::Escape at level 2
URI::Escape::XS at level 1
URI::Find at level 1
URI::URL at level 3
UUID::URandom at level 2
Unicode::Normalize at level 3
Unicode::Stringprep at level 3
Unicode::UTF8 at level 2
WWW::RobotRules at level 2
XML::Encoding at level 1
XML::FeedPP at level 1
XML::LibXML at level 2
XML::NamespaceSupport at level 2
XML::Parser at level 2
XML::Parser::Expat at level 2
XML::Rules at level 1
XML::SAX at level 2
XML::SAX::Base at level 3
XML::SAX::DocumentLocator at level 3
XML::SAX::Exception at level 3
XML::SAX::Expat at level 2
XML::Simple at level 1
XML::TreePP at level 2
XML::XML2JSON at level 1
XSLoader at level 2
YAML at level 3
YAML::XS at level 2
autodie at level 3
base at level 2
boolean at level 2
bytes at level 2
charnames at level 2
common::sense at level 3
constant at level 2
experimental at level 1
feature at level 2
fields at level 2
if at level 2
integer at level 2
lib at level 2
locale at level 3
mod_perl2 at level 2
mro at level 2
namespace::autoclean at level 2
namespace::clean at level 2
overload at level 2
parent at level 2
perl at level 2
re at level 2
strict at level 2
strictures at level 2
threads at level 4
threads::shared at level 3
utf8 at level 2
vars at level 3
version at level 2
warnings at level 2
warnings::register at level 2
