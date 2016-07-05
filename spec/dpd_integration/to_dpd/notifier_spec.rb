require "rails_helper"

RSpec.describe ToDPD::Notifier do
  include ActiveRecordChangers::TransactionSkipper
  subject { ToDPD::Notifier }

  describe 'user' do
    describe 'notifier' do
      let(:user) { create(:patient) }
      let(:routing_key) { 'dpd.user.update' }

      context 'parameter given' do
        it 'sends message to dpd' do
          response = double(:response)
          allow_any_instance_of(subject).to receive(:open_connection)
          allow_any_instance_of(subject).to receive(:send_message_to_dpd)
          instance = subject.new(routing_key)
          expect(instance).to receive(:send_message_to_dpd).with(user, nil)
          instance.notify(user)
        end
      end

      context 'block given' do
        it '2 phase commit used' do
          uuid = rand(1..5)
          allow_any_instance_of(subject).to receive(:open_connection)
          allow_any_instance_of(subject).to receive(:uuid).and_return(uuid)
          allow_any_instance_of(subject).to receive(:send_message_to_dpd)
          allow_any_instance_of(subject).to receive(:complete_prepared)
          allow_any_instance_of(subject).to receive(:return_active_record_transaction_wrapper)

          subject.new(routing_key).notify{user}
          gid_prepared = ActiveRecord::Base.connection.execute("select gid from pg_prepared_xacts")
            .column_values(0).first

          expect(gid_prepared).to eq(uuid.to_s)
          ActiveRecord::Base.connection.execute("ROLLBACK PREPARED '#{uuid}'")
          return_active_record_transaction_wrapper
        end

        it 'sends message to dpd' do
          uuid = rand(1..5)
          allow_any_instance_of(subject).to receive(:open_connection)
          allow_any_instance_of(subject).to receive(:uuid).and_return(uuid)
          allow_any_instance_of(subject).to receive(:remove_active_record_transaction_wrapper)
          allow_any_instance_of(subject).to receive(:get_first_message).and_return(false)
          allow_any_instance_of(subject).to receive(:send_message_to_dpd)
          allow_any_instance_of(subject).to receive(:return_active_record_transaction_wrapper)

          instance = subject.new(routing_key)
          expect(instance).to receive(:send_message_to_dpd).with(user, "transaction.#{uuid}")
          instance.notify{user}
        end

        context 'gets response message from dpd' do
          before(:each) do
            @uuid = rand(1..5)
            allow_any_instance_of(subject).to receive(:open_connection)
            allow_any_instance_of(subject).to receive(:uuid).and_return(@uuid)
            allow_any_instance_of(subject).to receive(:send_message_to_dpd)
          end

          it 'SUCCESS' do
            allow_any_instance_of(subject).to receive(:get_first_message).and_return('message' => 'SUCCESS')
            instance = subject.new(routing_key)
            expect{
              instance.notify{ user = FactoryGirl.create(:patient); user }
            }.to change(User, :count).by(1)

          end
          it 'FAILURE' do
            allow_any_instance_of(subject).to receive(:get_first_message).and_return('message' => 'FAILURE')

            instance = subject.new(routing_key)
            expect{
              instance.notify{ user2 = FactoryGirl.create(:patient); user2 }
            }.not_to change(User, :count)
          end
        end
      end
    end
  end
end
