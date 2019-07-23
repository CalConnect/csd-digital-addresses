module PlantumlAdaptor
  def self.yml_to_plantuml(yml)
    <<-plantuml
@startuml

!include ../models/style.uml.inc

'******* CLASS DEFINITION *********************************************
#{classes_to_classes_plantuml(yml["classes"])}
#{enums_to_enums_plantuml(yml["enums"])}

'******* CLASS RELATIONS **********************************************
#{classes_to_relations_plantuml(yml["classes"])}
#{relations_to_plantuml(nil, yml["relations"])}

@enduml
    plantuml
  end

  def self.classes_to_classes_plantuml(classes)
    classes ||= {}

    classes.map do |(class_name, class_hash)|
      class_to_plantuml(class_name, class_hash)
    end.join("\n")
  end

  def self.class_to_plantuml(class_name, class_hash)
    class_hash ||= {}

    <<-plantuml
class #{class_name} {
#{attributes_to_plantuml(class_hash["attributes"])}
}
    plantuml
  end

  def self.attributes_to_plantuml(attributes)
    return "" unless attributes

    attributes.map do |(attr_name, attr_hash)|
      attribute_to_plantuml(attr_name, attr_hash)
    end.join("\n")
  end

  def self.attribute_to_plantuml(attr_name, attr_hash)
    "  +#{attr_name}: #{attr_hash["type"]}#{attribute_cardinality_plantuml(attr_hash["cardinality"])}"
  end

  def self.attribute_cardinality_plantuml(cardinality, withBracket = true)
    return "" unless cardinality

    min_card = cardinality["min"] || 1
    max_card = cardinality["max"] || 1

    return "" if min_card == 1 && max_card == 1

    card = "#{min_card}..#{max_card}"

    return card unless withBracket

    "[#{card}]"
  end

  def self.classes_to_relations_plantuml(classes)
    classes.map do |(class_name, class_hash)|
      class_hash ||= {}
      relations_to_plantuml(class_name, class_hash["relations"])
    end.join("\n").strip
  end

  def self.relations_to_plantuml(class_name, relations)
    return "" unless relations

    relations.map do |relation|
      source = class_name || relation["source"]
      relation_to_plantuml(source, relation)
    end.join("\n").strip
  end

  def self.relation_to_plantuml(source, relation)
    target = relation["target"]
    relationship = relation["relationship"] || {}

    source_relationship = relationship["source"] || {}
    target_relationship = relationship["target"] || {}

    source_arrow = case source_relationship["type"]
    when "direct"
      "<"
    when "inheritance"
      "<|"
    when "composition"
      "*"
    when "aggregation"
      "o"
    else
      ""
    end

    target_arrow = case target_relationship["type"]
    when "direct"
      ">"
    when "inheritance"
      "|>"
    when "composition"
      "*"
    when "aggregation"
      "o"
    else
      ""
    end

    direction = relation["direction"] || ""

    arrow = "#{source_arrow}-#{direction}-#{target_arrow}"

    action = relation["action"]
    label = ""

    if action
      label = case action["direction"]
      when "source"
        " : < #{action["verb"]}"
      when "target"
        " : #{action["verb"]} >"
      else
        ""
      end
    end

    source_attribute = relationship_cardinality_to_plantuml(
      source_relationship["attribute"]
    )
    source_attribute = " #{source_attribute}"

    target_attribute = relationship_cardinality_to_plantuml(
      target_relationship["attribute"]
    )
    target_attribute = "#{target_attribute} "

    "#{source}#{source_attribute} #{arrow} #{target_attribute}#{target}#{label}"
  end

  def self.relationship_cardinality_to_plantuml(attribute)

    attribute_name = (attribute || {}).keys.first

    return "" unless attribute_name

    attribute_hash = attribute[attribute_name]
    attribute_cardinality = attribute_hash["cardinality"]
    cardinality = ""

    if attribute_cardinality
      cardinality = attribute_cardinality_plantuml(
        attribute_cardinality,
        false
      )

      cardinality = " #{cardinality}"
    end

    "\"+#{attribute_name}#{cardinality}\""
  end

  def self.enums_to_enums_plantuml(enums)
    enums ||= {}

    enums.map do |(enum_name, enum_hash)|
      enum_to_plantuml(enum_name, enum_hash)
    end.join("\n\n")
  end

  def self.enum_to_plantuml(enum_name, enum_hash)
    enum_hash ||= {}

    <<-plantuml
enum #{enum_name}#{enum_type_to_plantuml(enum_hash["type"])} {
#{enum_values_to_plantuml(enum_hash["values"])}
}
    plantuml
  end

  def self.enum_type_to_plantuml(enum_type)
    return "" unless enum_type

    " <<#{enum_type}>>"
  end

  def self.enum_values_to_plantuml(enum_values)
    enum_values.map do |(enum_value, enum_value_hash)|
      "  #{enum_value}"
    end.join("\n")
  end
end