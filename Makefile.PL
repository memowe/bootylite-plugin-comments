#!/usr/bin/env perl

use 5.010000;

use strict;
use warnings;

use ExtUtils::MakeMaker;

WriteMakefile(
    NAME            => 'Bootylite::Plugin::Comments',
    VERSION_FROM    => 'lib/Bootylite/Plugin/Comments.pm',
    AUTHOR          => 'Mirko Westermeier <mail@memowe.de>',
    PREREQ_PM       => {Bootylite => 0},
    test            => {TESTS => 't/*.t t/*/*.t t/*/*/*.t'}
);
