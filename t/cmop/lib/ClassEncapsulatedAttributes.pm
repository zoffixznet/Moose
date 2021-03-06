
package # hide the package from PAUSE
    ClassEncapsulatedAttributes;

use strict;
use warnings;

our $VERSION = '0.06';

use parent 'Class::MOP::Class';

sub initialize {
    (shift)->SUPER::initialize(@_,
        # use the custom attribute metaclass here
        'attribute_metaclass' => 'ClassEncapsulatedAttributes::Attribute',
    );
}

sub construct_instance {
    my ($class, %params) = @_;

    my $meta_instance = $class->get_meta_instance;
    my $instance = $meta_instance->create_instance();

    # initialize *ALL* attributes, including masked ones (as opposed to applicable)
    foreach my $current_class ($class->class_precedence_list()) {
        my $meta = $current_class->meta;
        foreach my $attr_name ($meta->get_attribute_list()) {
            my $attr = $meta->get_attribute($attr_name);
            $attr->initialize_instance_slot($meta_instance, $instance, \%params);
        }
    }

    return $instance;
}

package # hide the package from PAUSE
    ClassEncapsulatedAttributes::Attribute;

use strict;
use warnings;

our $VERSION = '0.04';

use parent 'Class::MOP::Attribute';

# alter the way parameters are specified
sub initialize_instance_slot {
    my ($self, $meta_instance, $instance, $params) = @_;
    # if the attr has an init_arg, use that, otherwise,
    # use the attributes name itself as the init_arg
    my $init_arg = $self->init_arg();
    # try to fetch the init arg from the %params ...
    my $class = $self->associated_class;
    my $val;
    $val = $params->{$class->name}->{$init_arg}
        if exists $params->{$class->name} &&
           exists ${$params->{$class->name}}{$init_arg};
    # if nothing was in the %params, we can use the
    # attribute's default value (if it has one)
    if (!defined $val && $self->has_default) {
        $val = $self->default($instance);
    }

    # now add this to the instance structure
    $meta_instance->set_slot_value($instance, $self->name, $val);
}

sub name {
    my $self = shift;
    return ($self->associated_class->name . '::' . $self->SUPER::name)
}

1;

__END__

=pod

=head1 NAME

ClassEncapsulatedAttributes - A set of example metaclasses with class encapsulated attributes

=head1 SYNOPSIS

  package Foo;

  use metaclass 'ClassEncapsulatedAttributes';

  Foo->meta->add_attribute('foo' => (
      accessor  => 'Foo_foo',
      default   => 'init in FOO'
  ));

  sub new  {
      my $class = shift;
      $class->meta->new_object(@_);
  }

  package Bar;
  our @ISA = ('Foo');

  # duplicate the attribute name here
  Bar->meta->add_attribute('foo' => (
      accessor  => 'Bar_foo',
      default   => 'init in BAR'
  ));

  # ... later in other code ...

  my $bar = Bar->new();
  prints $bar->Bar_foo(); # init in BAR
  prints $bar->Foo_foo(); # init in FOO

  # and ...

  my $bar = Bar->new(
      'Foo' => { 'foo' => 'Foo::foo' },
      'Bar' => { 'foo' => 'Bar::foo' }
  );

  prints $bar->Bar_foo(); # Foo::foo
  prints $bar->Foo_foo(); # Bar::foo

=head1 DESCRIPTION

This is an example metaclass which encapsulates a class's
attributes on a per-class basis. This means that there is no
possibility of name clashes with inherited attributes. This
is similar to how C++ handles its data members.

=head1 ACKNOWLEDGEMENTS

Thanks to Yuval "nothingmuch" Kogman for the idea for this example.

=head1 AUTHORS

Stevan Little E<lt>stevan@iinteractive.comE<gt>

Yuval Kogman E<lt>nothingmuch@woobling.comE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright 2006-2008 by Infinity Interactive, Inc.

L<http://www.iinteractive.com>

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut
