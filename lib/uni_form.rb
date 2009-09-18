module UniForm #:nodoc:
  module UniFormHelper
    [:form_for, :fields_for, :form_remote_for, :remote_form_for].each do |meth|
      src = <<-end_src
        def uni_#{meth}(object_name, *args, &proc)
          options = args.extract_options!
          html_options = options.has_key?(:html) ? options[:html] : {}
          if html_options.has_key?(:class)
            html_options[:class] << ' uniForm'
          else
            html_options[:class] = 'uniForm'
          end
          options.update(:html => html_options)
          options.update(:builder => UniFormBuilder)
          #{meth}(object_name, *(args << options), &proc)
        end
      end_src
      module_eval src, __FILE__, __LINE__
    end

    # Returns a label tag that points to a specified attribute (identified by +method+) on an object assigned to a template
    # (identified by +object+).  Additional options on the input tag can be passed as a hash with +options+.  An alternate
    # text label can be passed as a 'text' key to +options+.
    # Example (call, result).
    #   label_for('post', 'category')
    #     <label for="post_category">Category</label>
    #
    #   label_for('post', 'category', 'text' => 'This Category')
    #     <label for="post_category">This Category</label>
    def label_for(object_name, method, options = {})
      # puts "----text: " + options[:text] if options[:text]
      # puts "----del: " + options.delete(:text) if options[:text]
      # puts "---or:" + ((options.delete('text') || method.to_s.humanize)
      label = options[:text] ? options[:text] : method.to_s.humanize
      options.delete(:text)
      ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object)).to_label_tag2(label, options)
      # ActionView::Helpers::InstanceTag.new(object_name, method, self, nil,
      # options.delete(:object)).to_label_tag2(options[:text] ? options.delete('text') : method.to_s.humanize, options) 
    end

    # Creates a label tag.
    #   label_tag('post_title', 'Title')
    #     <label for="post_title">Title</label>
    # def label_tag(name, text, options = {})
    #   content_tag('label', text, { 'for' => name }.merge(options.stringify_keys))
    # end
  end

  module LabeledInstanceTag #:nodoc:
    # def to_label_tag(options = {})
    def to_label_tag2(text = nil, options = {})
      options = options.stringify_keys
      add_default_name_and_id(options)
      options.delete('name')
      options['for'] = options.delete('id')
      # content_tag 'label', (options.delete('required') ? "<em>*</em> " : "") + ((options.delete('text') || @method_name.humanize)), options
      content_tag 'label', (options.delete('required') ? "<em>*</em> " : "") + text, options
    end
  end

  module FormBuilderMethods #:nodoc:
    def label_for(method, options = {})
      @template.label_for(@object_name, method, options.merge(:object => @object))
    end
  end

  class UniFormBuilder < ActionView::Helpers::FormBuilder #:nodoc:
    (['date_select'] + self.field_helpers - %w(label_for hidden_field form_for fields_for)).each do |selector|

        field_classname =
          case selector
            when "text_field": "textInput"
            when "password_field": "textInput"
            when "file_upload": "fileUpload"
            else ""
          end

        label_classname =
          case selector
            when "check_box", "radio_button": "inlineLabel"
            else ""
          end

        src = <<-end_src
          def #{selector}(method, options = {})
            label_options = {}
            label_classname = "#{label_classname}"
            label_options.update(:class => label_classname) unless label_classname.blank?
            if options.has_key?(:class)
              field_classnames = [ '#{field_classname}', options[:class] ].join(" ")
            else
              field_classnames = '#{field_classname}'
            end
            render_field(method, options, super(method, clean_options(options.merge(:class => field_classnames))), label_options)
          end
        end_src
        class_eval src, __FILE__, __LINE__
    end

    def submit(value = "Save changes", options = {})
      options.stringify_keys!
      if disable_with = options.delete("disable_with")
        options["onclick"] = "this.disabled=true;this.value='#{disable_with}';this.form.submit();#{options["onclick"]}"
      end
      
      button = @template.content_tag(:button, value, { "type" => "submit", "name" => "commit", :class => "submitButton"}.update(options.stringify_keys))
      @template.content_tag :div, button, :class => "buttonHolder"
    end

    def radio_button(method, tag_value, options = {})
      label = (options.delete(:label) if options.has_key?(:label)) || tag_value
      super_options = options.dup
      render_field(method, options.merge!(:label => label), super(method, tag_value, super_options))
    end

    def collection_select(method, collection, value_method, text_method, options = {}, html_options = {})
      render_field(method, options, super(method, collection, value_method, text_method, options, html_options.merge(:class => "selectInput")))
    end

    def select(method, choices, options = {}, html_options = {})
      render_field(method, options, super(method, choices, options, html_options))
    end

    def country_select(method, priority_countries = nil, options = {}, html_options = {})
      render_field(method, options, super(method, priority_countries, options, html_options))
    end

    def time_zone_select(method, priority_zones = nil, options = {}, html_options = {})
      render_field(method, options, super(method, priority_zones, options, html_options))
    end

    def hidden_field(method, options={})
      super
    end

    def fieldset(*args, &proc)
      raise ArgumentError, "Missing block" unless block_given?
      options = args.last.is_a?(Hash) ? args.pop : {}

      content = @template.capture(&proc)
      content = @template.content_tag(:legend, options.delete(:legend)) + (content || '')  if options.has_key?(:legend) 

      classname = options[:class] || ''
      classname << " " << (options.delete(:type) == ("inline" || :inline) ? "inlineLabels" : "blockLabels")

      @template.concat(@template.content_tag(:fieldset, content, options.merge({ :class => classname.strip })))
    end

    def ctrl_group(args, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      @ctrl_group = true
      block_content = @template.capture(&proc)
      content = ""
      content << @template.content_tag(:p, args[:label], :class => 'label') if args[:label]
      content << @template.content_tag(:div, block_content, :class => 'multiField')
      content << @template.content_tag(:p, args[:hint], :class => 'formHint')        if args[:hint]
      @template.concat(@template.content_tag(:div, content, :class => "ctrlHolder"))
      @ctrl_group = nil
    end

    def error_messages(options={})
      obj = @object || @template.instance_variable_get("@#{@object_name}")
      count = obj.errors.count
      unless count.zero?
        html = {}
        [:id, :class].each do |key|
          if options.include?(key)
            value = options[key]
            html[key] = value unless value.blank?
          else
            html[key] = 'errorMsg'
          end
        end
        header_message = "Ooops!"
        error_messages = obj.errors.full_messages.map {|msg| @template.content_tag(:li, msg) }
        @template.content_tag(:div,
          @template.content_tag(options[:header_tag] || :h3, header_message) <<
            @template.content_tag(:ol, error_messages),
          html
        )
      else
        ''
      end
    end

    def info_message(options={})
      sym = options[:sym] || :uni_message
      @template.flash[sym] ? @template.content_tag(:h3, @template.flash[sym], :id => "OKMsg") : ''
    end

    def messages
       error_messages + info_message
    end


#    # This is a minorly modified version from actionview
#    # actionpack/lib/action_view/helpers/active_record_helper.rb
#    def uni_error_messages_for(*params)
#      options = params.last.is_a?(Hash) ? params.pop.symbolize_keys : {}
#      objects = params.collect {|object_name| instance_variable_get("@#{object_name}") }.compact
#      count   = objects.inject(0) {|sum, object| sum + object.errors.count }
#      unless count.zero?
#        html = {}
#        [:id, :class].each do |key|
#          if options.include?(key)
#            value = options[key]
#            html[key] = value unless value.blank?
#          else
#            html[key] = 'errorMsg'
#          end
#        end
#        header_message = "Ooops!"
#        error_messages = objects.map {|object| object.errors.full_messages.map {|msg| content_tag(:li, msg) } }
#        content_tag(:div,
#          content_tag(options[:header_tag] || :h3, header_message) <<
#            content_tag(:p, 'There were problems with the following fields:') <<
#            content_tag(:ul, error_messages),
#          html
#        )
#      else
#        ''
#      end
#    end
#

    private

    def render_field(method, options, field_tag, base_label_options = {})
      label_options = { :required => options.delete(:required)}
      label_options.update(base_label_options)
      label_options.update(:text => options.delete(:label)) if options.has_key? :label

      hint = options.delete :hint

      obj = @object || @template.instance_variable_get("@#{@object_name}")
      errors = obj.errors.on(method)

      div_content = errors.nil? ? "" : @template.content_tag('p', errors.class == Array ? errors.first : errors, :class => "errorField")

      wrapper_class = 'ctrlHolder'
      wrapper_class << ' col' if options.delete(:column)
      wrapper_class << options.delete(:ctrl_class) if options.has_key? :ctrl_class
      wrapper_class << ' error' if not errors.nil?
      
      if @ctrl_group.nil? # <label for="cool" ...>descr</label><input id="cool" ..>
        div_content << label_for(method, label_options) + field_tag
      else 
        # Using block labels for grouped fields: 
        # <label for="cool" class="blockLabel"><input id="cool" ..>descr</label>
        label_options.merge!(:class => 'blockLabel')
        # FIXME: someday...
        # Correct labels for radiobuttons 
        # Html id's of radiobuttons created from "object_field" + "_value" 
        # So we need find value of radiobutton here or just grep our field
        # tag for acutal id:
        label_options[:for] = field_tag.match(/id=\"(\S*?)\"/)[1] 
        div_content << @template.content_tag(:label, field_tag << (label_options.delete(:text) || ''), label_options)
      end

      div_content << @template.content_tag('p', hint, :class => 'formHint') if not hint.blank?

      if @ctrl_group.nil?
        @template.content_tag('div', div_content, :class => wrapper_class)
      else
        div_content
      end
    end

    def clean_options(options)
      options.reject { |key, value| key == :required or key == :label or key == :hint or key == :column or key == :ctrl_class}
    end
  end
end
