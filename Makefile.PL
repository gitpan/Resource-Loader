use ExtUtils::MakeMaker;

WriteMakefile(
    'NAME'		=> 'Resource::Loader',
    'VERSION_FROM'	=> 'Loader.pm',
    'PREREQ_PM'		=> {},
    ($] >= 5.005 ?
      (ABSTRACT_FROM => 'Loader.pm',
       AUTHOR     => 'Joshua Keroes <joshua@cpan.org>') : ()),
);
