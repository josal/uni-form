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
      label = options[:text] ? options[:text] : method.to_s.humanize
      options.delete(:text)
      ActionView::Helpers::InstanceTag.new(object_name, method, self, options.delete(:object)).to_uni_label_tag(label, options)
    end
  end

  module UniInstanceTag #:nodoc:
    def to_uni_label_tag(text = nil, options = {})
      options = options.stringify_keys
      add_default_name_and_id(options)
      options.delete('name')
      options['for'] = options.delete('id')
      content_tag 'label', ((options.delete('required') ? "<em>*</em> " : "") + text).html_safe, options
    end
  end

  module FormBuilderMethods #:nodoc:
    def label_for(method, options = {})
      @template.label_for(@object_name, method, options.merge(:object => @object))
    end
  end

  class UniFormBuilder < ActionView::Helpers::FormBuilder #:nodoc:
    (self.field_helpers - %w(label_for hidden_field form_for fields_for)).each do |selector|

      field_classname =
        case selector
        when "text_field" then "textInput"
        when "password_field" then "textInput"
        when "file_upload" then "fileUpload"
        else ""
        end

      label_classname =
        case selector
        when "check_box", "radio_button" then "inlineLabel"
        else ""
        end

      src = <<-end_src
        def #{selector}(method, options = {})
          label_options = {}
          label_classname = "#{label_classname}"
          label_options.update(:class => label_classname) unless label_classname.blank?
          field_classnames = options.has_key?(:class) ?  ['#{field_classname}', options[:class]].join(" ") : '#{field_classname}'
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
      label = (options.delete(:label) if options.has_key?(:label)) || tag_value.capitalize
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

    def date_select(method, options = {})
      render_field(method, options.merge(:multi_tag => true), super(method, options))
    end

    # Creates scope for rendering fieldset
    #
    # Options:
    #     :legend => string
    #     :type   => :inline | :block
    #
    def fieldset(*args, &proc)
      raise ArgumentError, "Missing block" unless block_given?
      options = args.last.is_a?(Hash) ? args.pop : {}

      content = @template.capture(&proc)
      content = @template.content_tag(:legend, options.delete(:legend)) + (content || '')  if options.has_key?(:legend)

      classname = options[:class] || ''
      classname << " " << (options.delete(:type).to_s == "inline" ? "inlineLabels" : "blockLabels")

      @template.concat(@template.content_tag(:fieldset, content, options.merge({ :class => classname.strip })))
    end

    # Creates scope for rendering multifield inputs
    #
    # Options:
    #     :label => string
    #     :hint  => string
    #     :required => boolean
    #
    def multi_field(args, &proc)
      raise ArgumentError, "Missing block" unless block_given?

      label = ''
      label << '<em> * </em>' if args[:required]
      label << args[:label]   if args[:label]


      @multi_field = true
      block_content = @template.capture(&proc)
      @multi_field = false

      content = ""
      content << @template.content_tag(:p, label, :class => 'label') unless label.blank?
      content << @template.content_tag(:div, block_content, :class => 'multiField')
      content << @template.content_tag(:p, args[:hint], :class => 'formHint') if args[:hint]
      @template.concat(@template.content_tag(:div, content, :class => "ctrlHolder"))
    end

    def error_messages(options={})
      obj = @object || @template.instance_variable_get("@#{@object_name}")
      unless obj.errors.count.zero?
        html = {}
        [:id, :class].each do |key|
          if options.include?(key)
            value = options[key]
            html[key] = value unless value.blank?
          else
            html[key] = 'errorMsg'
          end
        end
        error_messages = obj.errors.full_messages.map { |msg| @template.content_tag(:li, msg) }
        @template.content_tag(:div,
          @template.content_tag(options[:header_tag] || :h3, options[:header_message] || "Ooops!") <<
            @template.content_tag(:ol, error_messages), html)
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

    private

    # Generic renderer for uni-form div with inputs (ctrlHolder)
    def render_field(method, options, field_tag, base_label_options = {})
      label_options = { :required => options.delete(:required) }
      label_options.update(base_label_options)
      label_options.update(:text => options.delete(:label)) if options.has_key? :label

      multi_tag = options.delete :multi_tag # this should be true for multitag selects like datetimes
      hint = options.delete :hint

      obj = @object || @template.instance_variable_get("@#{@object_name}")
      errors = obj.errors[method]

      div_content = errors.nil? ? "" : @template.content_tag('p', errors.class == Array ? errors.first : errors, :class => "errorField")

      wrapper_class = ['ctrlHolder']
      wrapper_class << 'col' if options.delete(:column)
      wrapper_class << options.delete(:ctrl_class) if options.has_key? :ctrl_class
      wrapper_class << 'error' if not errors.nil?

      if @multi_field # rendering select inside label
        if multi_tag
          # if rendering multi_tag select (as date, datetime etc...)
          # just passing tag to wrapper. Labels already was added by monkey
          # patched ActionView::Helpers::DateTimeSelector#build_select (see below)
          div_content << field_tag
        else
          # FIXME use inlineLabels for checkboxes
          # FIXME inliners = %w(checkbox radio)
          # FIXME
          label_options.merge!(:class => 'blockLabel')
          div_content << @template.content_tag(:label, field_tag << (label_options.delete(:text) || ''), label_options)
        end
      else # rendering select after label
        div_content << label_for(method, label_options) + field_tag
      end

      div_content << @template.content_tag('p', hint, :class => 'formHint') if not hint.blank?

      if @multi_field
        div_content
      else
        @template.content_tag('div', div_content, :class => wrapper_class.join(' '))
      end
    end

    def clean_options(options)
      options.reject { |key, value| [:required, :label, :hint, :column, :ctrl_class].include? key }
    end
  end
end

# XXX Monkey patch for build_select
# We need selects wrapped by <label class="blockLabel">
module ActionView
  module Helpers
    class DateTimeSelector
      # Builds select tag from date type and html select options
      #  build_select(:month, "<option value="1">January</option>...")
      #  => "<select id="post_written_on_2i" name="post[written_on(2i)]">
      #        <option value="1">January</option>...
      #      </select>"
      def build_select(type, select_options_as_html)
        select_options = {
          :id => input_id_from_type(type),
          :name => input_name_from_type(type)
        }.merge(@html_options)
        select_options.merge!(:disabled => 'disabled') if @options[:disabled]

        select_html = "\n"
        select_html << content_tag(:option, '', :value => '') + "\n" if @options[:include_blank]
        select_html << prompt_option_tag(type, @options[:prompt]) + "\n" if @options[:prompt]
        select_html << select_options_as_html.to_s
        content_tag(:label, content_tag(:select, select_html, select_options) + "\n", :class => "blockLabel #{type}")
      end
    end
  end
end
