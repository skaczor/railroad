# RailRoad - RoR diagrams generator
# http://railroad.rubyforge.org
#
# Copyright 2007-2008 - Javier Smaldone (http://www.smaldone.com.ar)
# See COPYING for more details

# AASM code provided by Ana Nelson (http://ananelson.com/)

require 'railroad/app_diagram'

# Diagram for Acts As State Machine
class AasmDiagram < AppDiagram

  def initialize(options)
    #options.exclude.map! {|e| e = "app/models/" + e}
    super options 
    @graph.diagram_type = 'Models'
    # Processed habtm associations
    @habtm = []
  end

  # Process model files
  def generate
    STDERR.print "Generating AASM diagram\n" if @options.verbose
    files.each do |f| 
      process_class extract_class_name(f).constantize
    end
  end
  
  private
  def files
    if @options.include.any?
      @options.include.map{ |file| File.join("app/models", file) }
    else
      f = Dir.glob("app/models/**/*.rb") 
      f += Dir.glob("vendor/plugins/**/app/models/*.rb") if @options.plugins_models
      f -= @options.exclude
    end
  end  
  # Load model classes
  def load_classes
    begin
      disable_stdout
      files.each {|m| require m }
      enable_stdout
    rescue LoadError
      enable_stdout
      print_error "model classes"
      raise
    end
  end  # load_classes

  # Process a model class
  def process_class(current_class)
    
    STDERR.print "\tProcessing #{current_class}\n" if @options.verbose
    
    # Only interested in acts_as_state_machine models.
    return unless current_class.respond_to?'aasm_states'
    
    node_attribs = []
    node_type = 'aasm'
    
    current_class.aasm_states.each do |state|
      node_shape = (current_class.aasm_initial_state === state.name) ? ", peripheries = 2" : ""
      node_attribs << "#{current_class.name.downcase}_#{state.name} [label=#{state.name} #{node_shape}];"
    end
    @graph.add_node [node_type, current_class.name, node_attribs]
    
    current_class.aasm_events.values.each do |event|
      event.all_transitions.each do |transition|
        @graph.add_edge [
          'event', 
          current_class.name.downcase + "_" + transition.from.to_s, 
          current_class.name.downcase + "_" + transition.to.to_s, 
          event.name.to_s
        ]
      end
    end
  end # process_class

end # class AasmDiagram
