require File.dirname(__FILE__) + '/../spec_helper'

context "The PersonController" do
  controller_name :person

  specify "should be a PersonController" do
    controller.should_be_instance_of PersonController
  end

  specify "should create an unsaved person record on GET to create" do
    person = mock("person")
    Person.should_receive(:new).and_return(person)
    get 'create'
    response.should_be_success
    response.should_not_be_redirect
    assigns('person').should_be person
  end

  specify "should persist a new person and redirect to index on POST to create" do
    Person.should_receive(:create).with({"name" => 'Aslak'})
    post 'create', {:person => {:name => 'Aslak'}}
    response.should_be_redirect
    response.redirect_url.should_equal 'http://test.host/person'
  end
end

context "When requesting /person" do
  fixtures :people
  controller_name :person

  setup do
    get 'index'
  end

  specify "the response should render 'list'" do
    response.should_render :list
  end

  specify "the response should not render 'index'" do
    lambda {
      response.should_render :index
    }.should_raise
  end

  specify "should find all people on GET to index" do
    get 'index'
    response.should_be_success
    assigns('people').should_equal [people(:lachie)]
  end

end

context "/person/show/3" do
  fixtures :people
  controller_name :person
  
  setup do
    @person = mock("person")
  end
  
  specify "should get person with id => 3 from model (using stub)" do
    Person.stub!(:find).and_return(@person)
    get 'show', :id => 3
  
    assigns(:person).should_be @person
  end
  
  specify "should get person with id => 3 from model (using partial mock)" do
    Person.should_receive(:find).and_return(@person)
    get 'show', :id => 3
  
    assigns(:person).should_be @person
  end
end
