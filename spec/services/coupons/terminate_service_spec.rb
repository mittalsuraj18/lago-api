# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Coupons::TerminateService, type: :service do
  subject(:terminate_service) { described_class.new(membership.user) }

  let(:membership) { create(:membership) }
  let(:organization) { membership.organization }

  let(:coupon) { create(:coupon, organization: organization) }

  describe 'terminate' do
    it 'terminates the coupon' do
      result = terminate_service.terminate(coupon.id)

      expect(result).to be_success
      expect(result.coupon).to be_terminated
    end

    context 'when coupon is already terminated' do
      before { coupon.mark_as_terminated! }

      it 'does not impact the coupon' do
        terminated_at = coupon.terminated_at
        result = terminate_service.terminate(coupon.id)

        expect(result).to be_success
        expect(result.coupon).to be_terminated
        expect(result.coupon.terminated_at).to eq(terminated_at)
      end
    end
  end
end