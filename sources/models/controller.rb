require "yaml"
require "fileutils"
require "pp"

require File.expand_path("../plantuml_adaptor.rb", __FILE__)
require File.expand_path("../asciidoc_adaptor.rb", __FILE__)

ADOC_LEVEL = 2
PLANTUML_PATH = "../models/plantuml"

TYPE_MAP = {
  "class" => "classes",
  "enum" => "enums",
}

def for_each_model
  models_path = File.expand_path("../models", __FILE__)
  yml_files = Dir.glob(File.expand_path("**/*.yml", models_path))

  yml_files.each do |yml_file|
    file_match = yml_file.match(/\A#{Regexp.quote(models_path)}\/(?<model_name>.+)\.yml\Z/)
    model_name = file_match[:model_name]
    model_yml = YAML.load_file(yml_file)
    model_type = TYPE_MAP[model_yml["modelType"]]

    model_hash = model_yml.merge({
      "classes" => {},
      "enums" => {},
      "relations" => [],
    })

    model_hash = model_hash.merge({
      model_type => model_hash[model_type].merge({
        model_yml["name"] => model_yml
      })
    })

    yield(model_name, model_hash)
  end
end

def for_each_view
  yml_files = Dir.glob(File.expand_path("../views/*.yml", __FILE__))

  yml_files.each do |yml_file|
    yml = YAML.load_file(yml_file)

    view_hash = {
      "classes" => {},
      "enums" => {},
      "relations" => [],
    }.merge(yml)

    if view_hash["title"] == "Top-down"
      puts "view_hash???"
      pp view_hash
    end

    view_hash = yml["imports"].reduce(view_hash) do |acc, (model_name, model_hash)|
      model_yml = YAML.load_file(File.expand_path("../models/#{model_name}.yml", __FILE__))
      model_type = TYPE_MAP[model_yml["modelType"]]

      acc.merge({
        model_type => acc[model_type].merge({
          model_yml["name"] => model_yml
        })
      })
    end

    file_match = yml_file.match(/(?<view_name>[^\/]+)\.yml\Z/)
    view_name = file_match[:view_name]

    yield(view_name, view_hash)
  end
end

def model_to_plantuml(model_path, yml)
  (*model_dirs, model_name) = model_path.split("/")

  model_dir = model_dirs.join("/")
  dir_name = File.expand_path("../plantuml/models/#{model_dir}", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{model_name}.wsd", "w") do |file|
    file.write(PlantumlAdaptor.yml_to_plantuml(
      yml,
      PLANTUML_PATH
    ))
  end
end

def view_to_plantuml(view_name, yml)
  view_hash = yml.merge({
    "classes" => {},
    "enums" => {},
    "relations" => [],
  }).merge({
    "fidelity" => (yml["fidelity"] || {}).merge({
      "classes" => yml["classes"]
    })
  }).merge({
    "relations" => yml["relations"]
  })

  dir_name = File.expand_path("../plantuml/views", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{view_name}.wsd", "w") do |file|
    file.write(PlantumlAdaptor.yml_to_plantuml(
      view_hash,
      PLANTUML_PATH
    ))
  end
end

def view_to_adocs(view_name, yml)
  dir_name = File.expand_path("../adoc", __FILE__)
  FileUtils.mkdir_p(dir_name)

  File.open("#{dir_name}/#{view_name}.adoc", "w") do |file|
    adoc = AsciidocAdaptor.yml_to_asciidoc(
      yml,
      view_name,
      "../plantuml/views",
      ADOC_LEVEL
    )
    file.write(adoc)
  end
end

for_each_model do |model_name, model_hash|
  model_to_plantuml(model_name, model_hash)
end

for_each_view do |view_name, view_hash|
  view_to_plantuml(view_name, view_hash)
  view_to_adocs(view_name, view_hash)
end
