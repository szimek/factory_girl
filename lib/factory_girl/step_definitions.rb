module FactoryGirlStepHelpers
  def convert_association_string_to_instance(factory_name, assignment)
    attribute, value = assignment.split(':', 2)
    attributes = convert_human_hash_to_attribute_hash(attribute => value.strip)
    factory = FactoryGirl::Factory.factory_by_name(factory_name)
    model_class = factory.build_class
    model_class.find(:first, :conditions => attributes) or
      Factory(factory_name, attributes)
  end

  def convert_human_hash_to_attribute_hash(human_hash, associations = [])
    human_hash.inject({}) do |attribute_hash, (human_key, value)|
      key = human_key.downcase.gsub(' ', '_').to_sym
      if association = associations.detect {|association| association.name == key }
        value = convert_association_string_to_instance(association.factory, value)
      end
      attribute_hash.merge(key => value)
    end
  end
end

World(FactoryGirlStepHelpers)

FactoryGirl::Factory.factories.each do |name, factory|
  human_name = name.to_s.humanize.downcase
  Given /^the following (?:#{human_name}|#{human_name.pluralize}) exists?:$/ do |table|
    table.hashes.each do |human_hash|
      attributes = convert_human_hash_to_attribute_hash(human_hash, factory.associations)
      Factory.create(name, attributes)
    end
  end

  Given /^an? #{human_name} exists$/ do
    Factory(name)
  end

  Given /^(\d+) #{human_name.pluralize} exist$/ do |count|
    count.to_i.times { Factory(name) }
  end

  if factory.build_class.respond_to?(:columns)
    factory.build_class.columns.each do |column|
      human_column_name = column.name.downcase.gsub('_', ' ')
      Given /^an? #{human_name} exists with an? #{human_column_name} of "([^"]*)"$/i do |value|
        Factory(name, column.name => value)
      end

      Given /^(\d+) #{human_name.pluralize} exist with an? #{human_column_name} of "([^"]*)"$/i do |count, value|
        count.to_i.times { Factory(name, column.name => value) }
      end
    end
  end
end

