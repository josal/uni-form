require File.dirname(__FILE__) + '/../../../../config/environment'
require File.dirname(__FILE__) + '/../lib/uni_form'

require 'test/unit'
require 'rubygems'
require 'date'
if Rails.version >= '3.0'
  require 'action_dispatch/testing/assertions'
  # XXX keep this until bug in 3.0 will be fixed
  # https://rails.lighthouseapp.com/projects/8994/tickets/3132-simple-rack-test-fails
  gem "rack", "~> 1.0.0"
  gem "rack-test", "~> 0.4.2"
else
  require 'action_controller/assertions/dom_assertions'
end
require 'action_view/test_case'


class UniFormTest < ActionView::TestCase
  tests UniForm::UniFormHelper

  include ActionView::Helpers::UrlHelper
  include ActionView::Helpers::TextHelper
  include ActionView::Helpers::FormHelper
  include ActionView::Helpers::FormTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::CaptureHelper

  alias_method :original_assert_dom_equal, :assert_dom_equal

  User = Struct.new("User", :id, :first_name, :last_name, :email, :likes_dogs, :likes_cats, :sex, :dob, :was_born_at, :messages)
  Message = Struct.new("Message", :id, :user_id, :title, :text, :created_at)

  # had to add this to get the tests to run with rails 2.0, maybe a better way?
  def protect_against_forgery?
  end

  def setup

    @user = User.new
    @user.id = 45
    @user.first_name = "Marcus"
    @user.last_name = "Irven"
    @user.email = "marcus@example.com"
    @user.likes_dogs = true
    @user.likes_cats = false
    @user.sex = "M"
    @user.dob = Date.new(1982,9,11)
    @user.was_born_at = Time.at(123456789)

    def @user.errors()
      Class.new do
        def on(field)
          nil
        end
      end.new
    end

    @user.messages = (1..5).to_a.collect do |n|
      m = Message.new
      m.id = n
      m.title = "Title #{n}"
      m.text  = "Text #{n}"
    end

    @controller = Class.new do
      def url_for(options, *parameters_for_method_reference)
        "http://www.example.com"
      end
    end.new

    self.output_buffer = ''
  end

  def test_pass
    assert_equal 1, 1
  end

  def test_empty_form

    uni_form_for(:user, @user) do |f|
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm"></form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_default_fieldset

    uni_form_for(:user, @user) do |f|
      f.fieldset do
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_inline_fieldset

    uni_form_for(:user, @user) do |f|
      f.fieldset :type => "inline" do
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="inlineLabels">
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer

    self.output_buffer = ''

    uni_form_for(:user, @user) do |f|
      f.fieldset :type => :inline do
      end
    end

    assert_dom_equal expected, output_buffer
  end

  def test_fieldset_with_legend

    uni_form_for(:user, @user) do |f|
      f.fieldset :legend => "User" do
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <legend>User</legend>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_block_fieldset

    uni_form_for(:user, @user) do |f|
      f.fieldset :type => "block" do
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_submit

    uni_form_for(:user, @user) do |f|
      output_buffer.concat f.submit("save")
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <div class="buttonHolder">
          <button type="submit" name="commit" class="submitButton">save</button>
        </div>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_label_for

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.label_for(:first_name, :text => 'Your First Name')
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class='blockLabels'>
          <label for="user_first_name">Your First Name</label>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_text_field

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.text_field(:first_name)
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name">First name</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_text_field_with_label
    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.text_field(:first_name, :label => "First")
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name">First</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_required_text_field

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.text_field(:first_name, :required => true)
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name"><em>*</em> First name</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_non_required_text_field

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.text_field(:first_name, :required => false)
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name">First name</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_text_field_with_hint

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        f.text_field(:first_name, :hint => "Your given name")
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name">First name</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
            <p class="formHint">Your given name</p>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_hidden_field
    uni_form_for(:user, @user) do |f|
      output_buffer.concat f.hidden_field(:id)
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <input type="hidden" id="user_id" name="user[id]" value="45"/>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  # TODO Whats up with input class=""
  def test_check_box

    uni_form_for(:user, @user) do |f|
      output_buffer.concat f.check_box(:likes_dogs)
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <div class="ctrlHolder">
          <label class="inlineLabel" for="user_likes_dogs">Likes dogs</label>
          <input name="user[likes_dogs]" value="0" type="hidden" />
          <input name="user[likes_dogs]" checked="checked" class="" id="user_likes_dogs" value="1" type="checkbox" />
        </div>
      </form>
    html

    assert_dom_equal expected, output_buffer

    self.output_buffer = ''

    uni_form_for(:user, @user) do |f|
      output_buffer.concat f.check_box(:likes_dogs, :label => 'Likez dogzzz')
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <div class="ctrlHolder">
          <label class="inlineLabel" for="user_likes_dogs">Likez dogzzz</label>
          <input name="user[likes_dogs]" value="0" type="hidden" />
          <input name="user[likes_dogs]" checked="checked" class="" id="user_likes_dogs" value="1" type="checkbox" />
        </div>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  # TODO Whats up with input class=""
  def test_multifield_check_boxes

    uni_form_for(:user, @user) do |f|
      f.multi_field :label => 'Some Questions', :hint => 'Lala', :required => true  do
        output_buffer.concat f.check_box(:likes_dogs, :label => 'Likes dogs?')
        output_buffer.concat f.check_box(:likes_cats, :label => 'Likes cats?')
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <div class="ctrlHolder">
          <p class="label"><em> * </em>Some Questions</p>
          <div class="multiField">
            <label class="blockLabel">
              <input name="user[likes_dogs]" value="0" type="hidden" />
              <input name="user[likes_dogs]" class="" id="user_likes_dogs" value="1" type="checkbox" checked="checked" />Likes dogs?</label>
            <label class="blockLabel">
              <input name="user[likes_cats]" value="0" type="hidden" />
              <input name="user[likes_cats]" class="" id="user_likes_cats" value="1" type="checkbox" />Likes cats?</label>
          </div>
          <p class="formHint">Lala</p>
        </div>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_radio_buttons

    uni_form_for(:user, @user) do |f|
      f.multi_field :label => 'Sex', :hint => 'Pex!', :required => true  do
        output_buffer.concat f.radio_button(:sex, "Male",   :label => 'Maaan', :checked => 'checked')
        output_buffer.concat f.radio_button(:sex, "Female", :label => 'Wooman')
      end
    end

    expected = <<-html
     <form action="http://www.example.com" method="post" class="uniForm">
         <div class="ctrlHolder">
           <p class="label"><em> * </em>Sex</p>
           <div class="multiField">
             <label class="blockLabel"><input name="user[sex]" type="radio" id="user_sex_male" value="Male" checked="checked"/>Maaan</label>
             <label class="blockLabel"><input name="user[sex]" type="radio" id="user_sex_female" value="Female" />Wooman</label>
           </div>
           <p class="formHint">Pex!</p>
         </div>
     </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_date_select

    I18n.locale = :en # explicitly set to :en to avoid errors with month
                      # names (russian gem and similar extensions)

    uni_form_for(:user, @user) do |f|
      f.multi_field :label => 'Date of birth', :hint => 'Be honest!', :required => true do
        f.date_select(:dob)
      end
    end

    expected = <<-html
      <form class="uniForm" method="post" action="http://www.example.com">
        <div class="ctrlHolder">
          <p class="label"><em> * </em>Date of birth</p>
          <div class="multiField">
            <label class="blockLabel year">
              <select name="user[dob(1i)]" id="user_dob_1i">
                <option value="1977">1977</option>
                <option value="1978">1978</option>
                <option value="1979">1979</option>
                <option value="1980">1980</option>
                <option value="1981">1981</option>
                <option selected="selected" value="1982">1982</option>
                <option value="1983">1983</option>
                <option value="1984">1984</option>
                <option value="1985">1985</option>
                <option value="1986">1986</option>
                <option value="1987">1987</option>
              </select>
            </label>
            <label class="blockLabel month">
              <select name="user[dob(2i)]" id="user_dob_2i">
                <option value="1">January</option>
                <option value="2">February</option>
                <option value="3">March</option>
                <option value="4">April</option>
                <option value="5">May</option>
                <option value="6">June</option>
                <option value="7">July</option>
                <option value="8">August</option>
                <option selected="selected" value="9">September</option>
                <option value="10">October</option>
                <option value="11">November</option>
                <option value="12">December</option>
              </select>
            </label>
            <label class="blockLabel day">
              <select name="user[dob(3i)]" id="user_dob_3i">
                <option value="1">1</option>
                <option value="2">2</option>
                <option value="3">3</option>
                <option value="4">4</option>
                <option value="5">5</option>
                <option value="6">6</option>
                <option value="7">7</option>
                <option value="8">8</option>
                <option value="9">9</option>
                <option value="10">10</option>
                <option selected="selected" value="11">11</option>
                <option value="12">12</option>
                <option value="13">13</option>
                <option value="14">14</option>
                <option value="15">15</option>
                <option value="16">16</option>
                <option value="17">17</option>
                <option value="18">18</option>
                <option value="19">19</option>
                <option value="20">20</option>
                <option value="21">21</option>
                <option value="22">22</option>
                <option value="23">23</option>
                <option value="24">24</option>
                <option value="25">25</option>
                <option value="26">26</option>
                <option value="27">27</option>
                <option value="28">28</option>
                <option value="29">29</option>
                <option value="30">30</option>
                <option value="31">31</option>
              </select>
            </label>
          </div>
          <p class="formHint">Be honest!</p>
        </div>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_time_select
    I18n.locale = :en # explicitly set to :en to avoid errors with month
                      # names (russian gem and similar extensions)

    uni_form_for(:user, @user) do |f|
      f.multi_field :label => 'Time of birth', :hint => 'Be honest!', :required => true do
        f.time_select(:was_born_at)
      end
    end

    expected = <<-html
      <form action="http://www.example.com" class="uniForm" method="post">
        <div class="ctrlHolder">
          <p class="label"><em> * </em>Time of birth</p>
          <div class="multiField">
          <input id="user_was_born_at_1i" name="user[was_born_at(1i)]" type="hidden" value="1973" />
          <input id="user_was_born_at_2i" name="user[was_born_at(2i)]" type="hidden" value="11" />
          <input id="user_was_born_at_3i" name="user[was_born_at(3i)]" type="hidden" value="30" />
          <label class="blockLabel hour">
            <select id="user_was_born_at_4i" name="user[was_born_at(4i)]">
              <option selected="selected" value="00">00</option>
              <option value="01">01</option>
              <option value="02">02</option>
              <option value="03">03</option>
              <option value="04">04</option>
              <option value="05">05</option>
              <option value="06">06</option>
              <option value="07">07</option>
              <option value="08">08</option>
              <option value="09">09</option>
              <option value="10">10</option>
              <option value="11">11</option>
              <option value="12">12</option>
              <option value="13">13</option>
              <option value="14">14</option>
              <option value="15">15</option>
              <option value="16">16</option>
              <option value="17">17</option>
              <option value="18">18</option>
              <option value="19">19</option>
              <option value="20">20</option>
              <option value="21">21</option>
              <option value="22">22</option>
              <option value="23">23</option>
            </select>
            </label> : <label class="blockLabel minute">
              <select id="user_was_born_at_5i" name="user[was_born_at(5i)]">
                <option value="00">00</option>
                <option value="01">01</option>
                <option value="02">02</option>
                <option value="03">03</option>
                <option value="04">04</option>
                <option value="05">05</option>
                <option value="06">06</option>
                <option value="07">07</option>
                <option value="08">08</option>
                <option value="09">09</option>
                <option value="10">10</option>
                <option value="11">11</option>
                <option value="12">12</option>
                <option value="13">13</option>
                <option value="14">14</option>
                <option value="15">15</option>
                <option value="16">16</option>
                <option value="17">17</option>
                <option value="18">18</option>
                <option value="19">19</option>
                <option value="20">20</option>
                <option value="21">21</option>
                <option value="22">22</option>
                <option value="23">23</option>
                <option value="24">24</option>
                <option value="25">25</option>
                <option value="26">26</option>
                <option value="27">27</option>
                <option value="28">28</option>
                <option value="29">29</option>
                <option value="30">30</option>
                <option value="31">31</option>
                <option value="32">32</option>
                <option selected="selected" value="33">33</option>
                <option value="34">34</option>
                <option value="35">35</option>
                <option value="36">36</option>
                <option value="37">37</option>
                <option value="38">38</option>
                <option value="39">39</option>
                <option value="40">40</option>
                <option value="41">41</option>
                <option value="42">42</option>
                <option value="43">43</option>
                <option value="44">44</option>
                <option value="45">45</option>
                <option value="46">46</option>
                <option value="47">47</option>
                <option value="48">48</option>
                <option value="49">49</option>
                <option value="50">50</option>
                <option value="51">51</option>
                <option value="52">52</option>
                <option value="53">53</option>
                <option value="54">54</option>
                <option value="55">55</option>
                <option value="56">56</option>
                <option value="57">57</option>
                <option value="58">58</option>
                <option value="59">59</option>
              </select>
            </label>
          </div>
          <p class="formHint">Be honest!</p>
      </div>
    </form>
    html
    assert_dom_equal expected, output_buffer
  end

  def test_fields_for

    flunk('Just do it!')

    uni_form_for(:user, @user) do |f|
      f.fieldset do
        output_buffer.concat f.text_field(:first_name, :hint => "Your given name")
        f.fields_for :messages do |mf|
          output_buffer.concat mf.text_field :title
          output_buffer.concat mf.text_area :text
        end
      end
    end

    expected = <<-html
      <form action="http://www.example.com" method="post" class="uniForm">
        <fieldset class="blockLabels">
          <div class="ctrlHolder">
            <label for="user_first_name">First name</label>
            <input name="user[first_name]" size="30" type="text" class="textInput" id="user_first_name" value="Marcus"/>
            <p class="formHint">Your given name</p>
          </div>
        </fieldset>
      </form>
    html

    assert_dom_equal expected, output_buffer
  end

  def test_datetime_select
    flunk 'not implemented'
    expected = <<-html
    html
    assert_dom_equal expected, output_buffer
  end


  private

  def assert_dom_equal(expected, actual, message="", debug = false)
    if debug
      puts
      puts "-" * 100
      puts expected
      puts "-" * 100
      puts output_buffer
      puts
    end
    # We remove whitespace between elements and at the begining and end of expected
    original_assert_dom_equal expected.gsub(/>\s+?</, "><").strip, actual.gsub(/>\s+?</, "><").strip, message
  end
end
