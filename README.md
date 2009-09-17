UniForm
=======

A plugin for generating forms using http://sprawsm.com/uni-form

Installation
============

      ./script/plugin install git://github.com/antono/uni-form.git

Usage
=====

1. Include the Javascript file (probably in your layout).
   If You prefer Prototype.js:
        <%= javascript_include_tag 'uni-form.prototype.js' %>
   If using jQuery framework:
        <%= javascript_include_tag 'jquery.uni-form.js' %>

2. Include the stylesheet (again, probably in your layout):
        <%= stylesheet_link_tag 'uni-form', :media => "all" %>

3. Then, to create your form you can do the following:

      <% uni_form_for :user do |form| %>
        <% form.fieldset :type => "block", :legend => "cool stuff" do %>

          <%= form.text_field :first_name, :required => true, :label => "Your first name" %>
          <%= form.text_field :last_name %>

          <!-- grouped inputs -->
          <% form.ctrl_group :label => 'Sex', :hint => 'Pex!' do %>
            <%= form.radio_button(:sex, "Male", :label => 'Maaan', :checked => 'checked') %>
            <%= form.radio_button(:sex, "Female", :label => 'Wooman') %>
          <% end %>
          <!-- /grouped inputs -->

        <% end %>
        <%= form.submit "save" %>
      <% end %>

Credits
=======

Based on the original uni-form plugin by Marcus Irvin
http://github.com/mirven/uni-form/tree and
http://github.com/thewebfellas/uni-form/tree/master
