#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 21;

use FindBin '$Bin';
use lib "$Bin/../lib";

use Bootylite;
use_ok('Bootylite::Plugin::Comments');

my $cp = Bootylite::Plugin::Comments->new(comments_dir => "$Bin/comments");
isa_ok($cp, 'Bootylite::Plugin::Comments', 'generated comments plugin object');

# init with dummy app
use Mojolicious;
$cp->startup(Mojolicious->new);

# built right
is(ref $cp->comments, 'HASH', 'comments isa hash ref');
is_deeply([keys %{$cp->comments}], ['test6'], 'right comment urls');
is(ref $cp->comments->{test6}, 'ARRAY', 'comments come in array refs');
is(scalar @{$cp->comments->{test6}}, 1, 'right comment count');

# comment data
my $comment = $cp->comments->{test6}->[0];
isa_ok($comment, 'Bootylite::Plugin::Comments::Comment', 'comment');
like($comment->filename, qr|^$Bin/comments/test6/|, 'right comment filename');
is($comment->encoding, 'utf-8', 'right comment encoding');
is($comment->time, 1304299362, 'right comment time');
is($comment->raw_content, <<'EOF', 'right comment raw_content');
Name: Mirko Westermeier
Mail: mirko@westermeier.de

H€llo world

Second <b>para&graph</b>
second line of second paragraph
EOF

# parsed comment data
my $meta = {name => 'Mirko Westermeier', mail => 'mirko@westermeier.de'};
is_deeply($comment->meta, $meta, 'right comment meta data');
is($comment->html, <<'EOF', 'right rendered comment content');
<p>H&euro;llo world</p>

<p>Second &lt;b&gt;para&amp;graph&lt;/b&gt;<br>
second line of second paragraph</p>

EOF

# access from article object
my $booty   = Bootylite->new(articles_dir => "$Bin/articles");
my $article = $booty->get_article('test6');
is($article->all_comment_count, 2, 'right all comment count');
is(ref $article->all_comments, 'ARRAY', 'all_comments isa array ref');
$comment = $article->all_comments->[1];
isa_ok($comment, 'Bootylite::Plugin::Comments::Comment', 'comment');
like($comment->filename, qr|^$Bin/comments/test6/|, 'right comment filename');
is($article->comment_count, 1, 'right comment count');
is(ref $article->comments, 'ARRAY', 'comments isa array ref');
$comment = $article->comments->[0];
isa_ok($comment, 'Bootylite::Plugin::Comments::Comment', 'comment');
like($comment->filename, qr|^$Bin/comments/test6/|, 'right comment filename');

__END__
