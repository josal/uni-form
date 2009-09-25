require 'uni_form'

ActionView::Base.send(:include, UniForm::UniFormHelper)
ActionView::Helpers::InstanceTag.send(:include, UniForm::UniInstanceTag)
ActionView::Helpers::FormBuilder.send(:include, UniForm::FormBuilderMethods)
