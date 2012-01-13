#!/usr/bin/env perl

use strict;
use warnings;
use utf8;

use Test::More tests => 31;
use Test::Mojo;

use FindBin '$Bin';
use lib "$Bin/../lib";

# prepare
$ENV{MOJO_HOME} = "$Bin";
require 'bootylite.pl';
my $t = Test::Mojo->new;

# comment count on home page
$t->get_ok('/')->status_is(200);
my $cc = $t->tx->res->dom->find('.comment-count a');
is($cc->[0]->text, 'Comments: 0', 'right comment count');
is($cc->[1]->text, 'Comments: 1', 'right comment count');

# comments on article page
$t->get_ok('/articles/test6')->status_is(200);
$t->element_exists('.comment-count')->element_exists('#comments');
my $comment = $t->tx->res->dom->at('.comment');
is($comment->at('.name')->text, 'Mirko Westermeier', 'right author name');
is(
    $comment->all_text,
    'Mirko Westermeier H€llo world Second <b>para&graph</b> '
        . 'second line of second paragraph',
    'right comment'
);
$t->element_exists('form[action=../comment]');

# submit: wrong article
$t->post_form_ok('/comment', {article_url => 'foo'})->status_is(404);

# submit: no comment
$t->post_form_ok('/comment', {article_url => 'test7', name => 'foo'});
$t->status_is(401)->content_is('Please provide a name and a comment.');

# submit: everything is fine, first comment for that article
ok(! -e "$Bin/comments/test7", 'will be the first comment');
$t->ua->max_redirects(0);
$t->post_form_ok('/comment',
    {article_url => 'test7', name => 'foo', comment => 'bar'}
)->status_is(302)->header_like('Location', qr|/articles/test7|);
$t->get_ok('/articles/test7')->status_is(200)->element_exists('#message');
$comment = $t->tx->res->dom->at('.comment');
is($comment->at('.name')->text, 'foo', 'right author name');
is($comment->all_text, 'foo bar', 'right comment');

# delete the last comment
unlink($t->app->booty->get_article('test7')->comments->[-1]->filename) or die $!;
rmdir("$Bin/comments/test7") or die $!;
$t->get_ok('/refresh')->status_is(200)->content_is('Done');
$t->get_ok('/')->status_is(200);
$t->text_is('.comment-count a', 'Comments: 0', 'right comment count');

__END__
