#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 13;
use Test::Mojo;

use FindBin '$Bin';
use lib "$Bin/../lib";

# prepare
$ENV{MOJO_HOME} = "$Bin";
require 'bootylite.pl';
my $t = Test::Mojo->new;

# request
$t->get_ok('/comment_feed.xml')->status_is(200);

# elements
my $feed = $t->tx->res->dom;
like($feed->at('id')->text, qr|comment_feed.xml$|, 'right id');
is($feed->at('title')->text, 'Bootylite comment feed', 'right title');

# entries
my $entries = $feed->find('entry');
is (scalar(@$entries), 2, 'two comments');
my ($c1, $c2) = @$entries;
my $link1 = $c1->at('link[rel=alternate]');
like($link1->attrs('href'), qr|/articles/test6#comments$|, 'right link');
my $link2 = $c2->at('link[rel=alternate]');
like($link2->attrs('href'), qr|/articles/test6#comments$|, 'right link');
my $title1 = $c1->at('title');
like($title1->text, qr|^Comment from Mirko Westermeier,|, 'right title');
my $title2 = $c2->at('title');
like($title2->text, qr|^Comment from Foo Bar,|, 'right title');
my $name1 = $c1->at('author name');
is($name1->text, 'Mirko Westermeier', 'right author');
my $name2 = $c2->at('author name');
is($name2->text, 'Foo Bar', 'right author');
my $content1 = $c1->at('content');
like($content1->text, qr|H&euro;llo world|, 'right content');
my $content2 = $c2->at('content');
is($content2->text, '<p>quux</p>', 'right content');

__END__
