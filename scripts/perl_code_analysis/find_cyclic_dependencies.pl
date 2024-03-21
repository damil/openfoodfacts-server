# Check for cyclic dependencies in ProductOpener modules
use 5.24.0;
use utf8;
use strict;
use warnings;
use Path::Tiny;

# files to inspect
my @po_modules = glob "../../lib/ProductOpener/*.pm";

# structure for storing direct dependencies ($package => [list of used packages])
my %uses;

# inspect ProductOpener modules, filling the direct dependency structure
foreach my $file (@po_modules) {
	my $source_code = path($file)->slurp;
	my ($package)   = $source_code =~ /^package\h+ProductOpener::([\w:]+)/m;
	my @used        = $source_code =~ /^use\h+ProductOpener::([\w:]+)/mg;
	$uses{$package} = \@used ;
}

# loop over modules to check for cycles
check_cycles($_, {}) foreach sort keys %uses;

# recursive function
sub check_cycles {
	my ($package, $seen, @path) = @_;

	# update the path of traversed modules
	push @path, $package;

	# check for cycles at this level
	if (my @circular_deps = grep {$seen->{$_}} $uses{$package}->@*) {
		warn sprintf "CYCLES IN %s ON %s\n", join(" => ", @path), join(" & ", @circular_deps);
		return 1; # has a cycle
	}

	# otherwise check one level deeper
	else {
		foreach my $used ($uses{$package}->@*) {
			my $has_cycle = check_cycles($used, {$package => 1, %$seen}, @path);
			return 1 if $has_cycle;
		}
		return 0; # does not have a cycle
	}
}



__END__
Script results as of 20.03.2024
===============================
CYCLES IN API => Display ON API
CYCLES IN APIProductRead => Display => Users ON Display
CYCLES IN APIProductRevert => Display => Users ON Display
CYCLES IN APIProductServices => Display => Users ON Display
CYCLES IN APIProductWrite => Display => Users ON Display
CYCLES IN APITagRead => Display => Users ON Display
CYCLES IN APITaxonomySuggestions => Display => Users ON Display
CYCLES IN APITest => Producers => Products => Users ON Products
CYCLES IN Attributes => Products => Users ON Products
CYCLES IN Brevo => Display => Users ON Display & Brevo
CYCLES IN DataQuality => DataQualityFood => Food => Images => Products ON Food & DataQuality
CYCLES IN DataQualityFood => Food => Images => Products ON Food
CYCLES IN Display => Users ON Display
CYCLES IN Ecoscore => Packaging => Images => Products ON Ecoscore & Packaging
CYCLES IN Events => Display => Users ON Display
CYCLES IN Export => Display ON Export
CYCLES IN Food => Images => Products ON Food
CYCLES IN FoodGroups => Food ON FoodGroups
CYCLES IN GS1 => Display => Users ON Display
CYCLES IN Images => Products => Users ON Products
CYCLES IN Import => Display => Users ON Display
CYCLES IN ImportConvert => Products => Users ON Products
CYCLES IN ImportConvertCarrefourFrance => ImportConvert => Products => Users ON Products
CYCLES IN Ingredients => Users => Display ON Users & Ingredients
CYCLES IN KnowledgePanels => Products => Users ON Products
CYCLES IN KnowledgePanelsContribution => KnowledgePanels ON KnowledgePanelsContribution
CYCLES IN KnowledgePanelsTags => KnowledgePanels => Products => Users ON Products
CYCLES IN LoadData => Packaging => Images => Products ON Packaging
CYCLES IN MainCountries => Products ON MainCountries
CYCLES IN Missions => Users => Display ON Users & Missions
CYCLES IN MissionsConfig => Users => Display ON Users & MissionsConfig
CYCLES IN Orgs => Display ON Orgs
CYCLES IN Packaging => Images => Products ON Packaging
CYCLES IN PackagingStats => Products => Users ON Products
CYCLES IN Producers => Products => Users ON Products
CYCLES IN ProducersFood => Food => Images => Products ON Food
CYCLES IN Products => Users ON Products
CYCLES IN Recipes => Products => Users ON Products
CYCLES IN Routing => Display => Users ON Display
CYCLES IN TaxonomySuggestions => Display => Users ON Display
CYCLES IN Users => Display ON Users
CYCLES IN Web => Display ON Web
