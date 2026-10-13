# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RouteConstraints::IdConstraint do
  subject(:constraint) { described_class.new }

  def request_with_id(id)
    instance_double(ActionDispatch::Request, path_parameters: { id: id })
  end

  describe '#matches?' do
    context 'with a valid DOI' do
      it 'matches a standard DOI' do
        expect(constraint.matches?(request_with_id('10.1234/abcd.5678'))).to be true
      end

      it 'matches a DOI with a multi-segment registrant code' do
        expect(constraint.matches?(request_with_id('10.1234.5678/suffix'))).to be true
      end

      it 'matches a DOI whose suffix contains additional slashes' do
        expect(constraint.matches?(request_with_id('10.1234/abcd/efgh/5678'))).to be true
      end

      it 'matches a DOI with a 9-digit registrant code' do
        expect(constraint.matches?(request_with_id('10.123456789/suffix'))).to be true
      end
    end

    context 'with a valid ac: identifier' do
      it 'matches a lowercase alphanumeric ac: id' do
        expect(constraint.matches?(request_with_id('ac:12345'))).to be true
      end

      it 'matches an ac: id with mixed-case letters' do
        expect(constraint.matches?(request_with_id('ac:AbC123'))).to be true
      end

      it 'does not match an upper-case "AC:" prefix' do
        expect(constraint.matches?(request_with_id('AC:12345'))).to be false
      end
    end

    context 'with an invalid id' do
      it 'does not match a plain numeric id' do
        expect(constraint.matches?(request_with_id('12345'))).to be false
      end

      it 'does not match a DOI missing the registrant/suffix separator' do
        expect(constraint.matches?(request_with_id('10.1234'))).to be false
      end

      it 'does not match a DOI with a too-short registrant code' do
        expect(constraint.matches?(request_with_id('10.123/suffix'))).to be false
      end

      it 'does not match an ac: id containing a colon in the suffix' do
        expect(constraint.matches?(request_with_id('ac:123:456'))).to be false
      end

      it 'does not match an ac: id containing non-alphanumeric characters' do
        expect(constraint.matches?(request_with_id('ac:123-456'))).to be false
      end

      it 'does not match an ac: id with nothing after the colon' do
        expect(constraint.matches?(request_with_id('ac:'))).to be false
      end

      it 'does not match an arbitrary string' do
        expect(constraint.matches?(request_with_id('not-a-valid-id'))).to be false
      end
    end

    context 'with a blank or missing id' do
      it 'does not match a nil id' do
        expect(constraint.matches?(request_with_id(nil))).to be false
      end

      it 'does not match an empty string id' do
        expect(constraint.matches?(request_with_id(''))).to be false
      end
    end
  end
end
