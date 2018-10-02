# frozen_string_literal: true

require 'rspec'
require 'simplecov'

SimpleCov.start
require 'mealy'

class Example
  include RSpec::Mocks::ExampleMethods

  def initialize
    @receiver = spy('receiver')
  end

  attr_reader :receiver
end

RSpec.describe Mealy do
  let(:fsm_instance) { Example.new }

  describe '.run' do
    context 'without a block' do
      it 'returns an Enumerator' do
        Example.class_eval { include Mealy }

        expect(fsm_instance.run([])).to be_an Enumerator
      end
    end
  end

  describe '.execute' do
    it 'returns the result of the finish block' do
      Example.class_eval do
        include Mealy

        finish { :something }
      end

      expect(fsm_instance.execute([])).to eql :something
    end
  end

  describe 'running' do
    context 'with .initial_state user block' do
      it 'fires user block once' do
        Example.class_eval do
          include Mealy

          initial_state(:start) { @receiver.call! }
        end

        fsm_instance.execute([])

        expect(fsm_instance.receiver).to have_received(:call!)
      end
    end

    context 'when transitioning away from initial state' do
      context 'with matching input' do
        context 'with user block' do
          it 'fires user block' do
            Example.class_eval do
              include Mealy

              initial_state(:start)
              transition(from: :start, to: :end, on: 1) { @receiver.call! }
            end

            fsm_instance.execute([1])

            expect(fsm_instance.receiver).to have_received(:call!)
          end
        end
      end

      context 'with non matching input' do
        it 'raises Mealy::UnexpectedTokenError' do
          Example.class_eval do
            include Mealy

            initial_state :start
            transition from: :start, to: :end, on: 1
          end

          expect do
            fsm_instance.execute([2])
          end.to raise_error(Mealy::UnexpectedTokenError)
        end
      end
    end

    context 'when in normal state transitions' do
      context 'with ANY label' do
        context 'with user block' do
          it 'fires user block' do
            Example.class_eval do
              include Mealy

              initial_state :start
              transition from: :start, to: :mid
              transition(from: :mid, to: :end) { @receiver.call! }
            end

            fsm_instance.execute([1, 2])
            expect(fsm_instance.receiver).to have_received(:call!)
          end
        end
      end

      context 'with matching input' do
        context 'with user block' do
          it 'fires user block' do
            Example.class_eval do
              include Mealy

              initial_state(:start)
              transition from: :start, to: :mid, on: 1
              transition(from: :mid, to: :end, on: 2) { @receiver.call! }
            end

            fsm_instance.execute([1, 2])

            expect(fsm_instance.receiver).to have_received(:call!)
          end

          it 'runs user blocks in instance context' do
            Example.class_eval do
              include Mealy

              initial_state(:start) { @something = :defined }
            end

            fsm_instance.execute([])
            something = fsm_instance.instance_variable_get(:@something)
            expect(something).to be :defined
          end

          it 'passes the token, the to and from states to user block' do
            Example.class_eval do
              include Mealy

              initial_state(:start)

              transition from: :start, to: :end, on: 1 do |token, from, to|
                @token = token
                @from = from
                @to = to
              end

              attr_reader :token, :to, :from
            end

            fsm_instance.execute([1])

            expect(fsm_instance.token).to eql(1)
            expect(fsm_instance.from).to eql(:start)
            expect(fsm_instance.to).to eql(:end)
          end

          it 'emits from the user block' do
            Example.class_eval do
              include Mealy

              initial_state(:start)

              transition from: :start, to: :end, on: 1 do
                emit(1)
                emit(2)
                emit(3)
              end
            end

            ix = 1
            fsm_instance.run([1]) do |emit|
              expect(emit).to eql(ix)
              ix += 1
            end
          end
        end
      end

      context 'with non matching input' do
        it 'raises Mealy::UnexpectedTokenError' do
          Example.class_eval do
            include Mealy

            initial_state :start
            transition from: :start, to: :mid, on: 1
            transition from: :mid, to: :end, on: 2
          end

          expect do
            fsm_instance.execute([1, 1])
          end.to raise_error(Mealy::UnexpectedTokenError)
        end
      end
    end

    context 'when input ends prematurely' do
      it 'runs without error' do
        Example.class_eval do
          include Mealy

          initial_state :start
          transition from: :start, to: :mid, on: 1
          transition from: :mid, to: :end, on: 2
        end

        expect do
          fsm_instance.execute([1])
        end.not_to raise_error
      end
    end

    context 'when in a state loop' do
      it 'fires the user action on each loop' do
        Example.class_eval do
          include Mealy

          initial_state :start
          read(state: :start, on: 1) { @receiver.call! }
        end

        fsm_instance.execute([1] * 10)

        expect(fsm_instance.receiver).to have_received(:call!).exactly(10).times
      end
    end

    context 'when at the end' do
      context 'if finish is set with user block' do
        it 'calls the user block' do
          Example.class_eval do
            include Mealy

            finish { @receiver.call! }
          end

          fsm_instance.execute([])

          expect(fsm_instance.receiver).to have_received(:call!)
        end
      end
    end
  end
end
