require 'spec_helper'

describe Braspag::ProtectedCreditCard do
  let(:braspag_homologation_protected_card_url) { "https://cartaoprotegido.braspag.com.br" }
  let(:braspag_production_protected_card_url) { "https://www.cartaoprotegido.com.br" }
  let(:merchant_id) { "um id qualquer" }

  before do
    @connection = mock(:merchant_id => merchant_id, :protected_card_url => 'https://www.cartaoprotegido.com.br/Services/TestEnvironment', :homologation? => false)
    Braspag::Connection.stub(:instance => @connection)
  end

  describe ".save" do
    let(:params) do
      {
        :customer_name => "W" * 21,
        :holder =>  "Joao Maria Souza",
        :card_number => "9" * 10,
        :expiration => "10/12",
        :order_id => "um order id",
        :request_id => "00000000-0000-0000-0000-000000000044"
      }
    end

    let(:params_with_merchant_id) do
      params.merge!(:merchant_id => merchant_id)
    end

    let(:save_protected_card_url) { "http://braspag.com/bla" }

    let(:savon_double) { double('Savon') }

    before do
      @connection.should_receive(:merchant_id)
    end

    context "with valid params" do
      let(:valid_hash) do
        {
          :save_credit_card_response => {
            :save_credit_card_result => {
              :just_click_key => 'SAVE-PROTECTED-CARD-TOKEN',
              :success => true
            }
          }
        }
      end

      let(:response) do
        double('Response', :to_hash => valid_hash)
      end

      before do
        Braspag::ProtectedCreditCard.should_receive(:save_protected_card_url)
        Braspag::ProtectedCreditCard.should_receive(:check_protected_card_params)
                           .and_return(true)
        Savon::Client.should_receive(:new).and_return(savon_double)
        savon_double.should_receive(:request).and_return(response)

        @response = Braspag::ProtectedCreditCard.save(params)
      end

      it "should return a Hash" do
        @response.should be_kind_of Hash
        @response.should == {
          :just_click_key => "SAVE-PROTECTED-CARD-TOKEN",
          :success => true
        }
      end
    end

    context "with invalid params" do
      let(:invalid_hash) do
        {
          :save_credit_card_response => {
            :save_credit_card_result => {
              :just_click_key => nil,
              :success => false
            }
          }
        }
      end

      let(:response) do
        double('Response', :to_hash => invalid_hash)
      end

      before do
        Braspag::ProtectedCreditCard.should_receive(:check_protected_card_params)
                            .and_return(true)
        Braspag::ProtectedCreditCard.should_receive(:save_protected_card_url)
                            .and_return(save_protected_card_url)
        Savon::Client.should_receive(:new).and_return(savon_double)
        savon_double.should_receive(:request).and_return(response)

        @response = Braspag::ProtectedCreditCard.save(params)
      end

      it "should return a Hash" do
        @response.should be_kind_of Hash
        @response.should == {
          :just_click_key => nil,
          :success => false
        }
      end
    end
  end

  describe ".get" do
    let(:get_protected_card_url) { "http://braspag/bla" }

    let(:invalid_xml) do
      <<-EOXML
      <CartaoProtegidoReturn xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                   xmlns="http://www.pagador.com.br/">
        <CardHolder>Joao Maria Souza</CardHolder>
        <CardNumber></CardNumber>
        <CardExpiration>10/12</CardExpiration>
        <MaskedCardNumber>******9999</MaskedCardNumber>
      </CartaoProtegidoReturn>
      EOXML
    end

    let(:valid_xml) do
      <<-EOXML
      <CartaoProtegidoReturn xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance"
                   xmlns:xsd="http://www.w3.org/2001/XMLSchema"
                   xmlns="http://www.pagador.com.br/">
        <CardHolder>Joao Maria Souza</CardHolder>
        <CardNumber>9999999999</CardNumber>
        <CardExpiration>10/12</CardExpiration>
        <MaskedCardNumber>******9999</MaskedCardNumber>
      </CartaoProtegidoReturn>
      EOXML
    end

    it "should raise an error when just click key is not valid" do
      Braspag::ProtectedCreditCard.should_receive(:valid_just_click_key?)
                         .with("bla")
                         .and_return(false)

      expect {
        Braspag::ProtectedCreditCard.get "bla"
      }.to raise_error(Braspag::InvalidJustClickKey)
    end

    it "should raise an error when Braspag returned an invalid xml as response" do
      FakeWeb.register_uri(:post, get_protected_card_url, :body => invalid_xml)

      Braspag::ProtectedCreditCard.should_receive(:get_protected_card_url)
                         .and_return(get_protected_card_url)

      expect {
        Braspag::ProtectedCreditCard.get("b0b0b0b0-bbbb-4d4d-bd27-f1f1f1ededed")
      }.to raise_error(Braspag::UnknownError)
    end

    it "should return a Hash when Braspag returned a valid xml as response" do
      FakeWeb.register_uri(:post, get_protected_card_url, :body => valid_xml)

      Braspag::ProtectedCreditCard.should_receive(:get_protected_card_url)
                         .and_return(get_protected_card_url)

      response = Braspag::ProtectedCreditCard.get("b0b0b0b0-bbbb-4d4d-bd27-f1f1f1ededed")
      response.should be_kind_of Hash

      response.should == {
        :holder => "Joao Maria Souza",
        :expiration => "10/12",
        :card_number => "9" * 10,
        :masked_card_number => "*" * 6 + "9" * 4
      }
    end

  end

  describe ".just_click_shop" do
    context "body" do
      let(:params) { {
        :request_id => "123",
        :customer_name => "Joao Silva",
        :order_id => "999",
        :amount => 10.50,
        :payment_method => :redecard,
        :number_installments => 3,
        :payment_type => "test",
        :just_click_key => "key",
        :security_code => "123"
      } }

      class SavonClientTest
        attr_accessor :response
        attr_reader :method

        def request(web, method, &block)
          @method = method
          instance_eval &block

          @response
        end

        def soap
          @soap ||= OpenStruct.new
        end
      end

      before :each do
        @savon_client_test = SavonClientTest.new
        @savon_client_test.response = {:just_click_shop_response => {}}
        Savon::Client.stub(:new).with('https://www.cartaoprotegido.com.br/Services/TestEnvironment/CartaoProtegido.asmx?wsdl').and_return(@savon_client_test)
      end

      after :each do
        Savon::Client.unstub(:new)
      end

      it "should have RequestId" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['RequestId'].should eq '123'
      end

      it "should have MerchantKey" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['MerchantKey'].should eq 'um id qualquer'
      end

      it "should have CustomerName" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['CustomerName'].should eq 'Joao Silva'
      end

      it "should have OrderId" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['OrderId'].should eq '999'
      end

      it "should have Amount" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['Amount'].should eq 10.50
      end

      it "should have PaymentMethod" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['PaymentMethod'].should eq 20
      end

      it "should have PaymentType" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['PaymentType'].should eq 'test'
      end

      it "should have NumberInstallments" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['NumberInstallments'].should eq 3
      end

      it "should have JustClickKey" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['JustClickKey'].should eq 'key'
      end

      it "should have SecurityCode" do
        described_class.just_click_shop(params)
        @savon_client_test.soap.body['justClickShopRequestWS']['SecurityCode'].should eq '123'
      end
    end

    it ".save_protected_card_url .get_protected_card_url" do
      @connection.stub(:protected_card_url => braspag_homologation_protected_card_url)

      Braspag::ProtectedCreditCard.save_protected_card_url.should == "#{braspag_homologation_protected_card_url}/CartaoProtegido.asmx?wsdl"
      Braspag::ProtectedCreditCard.get_protected_card_url.should == "#{braspag_homologation_protected_card_url}/CartaoProtegido.asmx/GetCreditCard"
    end

  end
end
