# frozen_string_literal: true

module Subscriptions
  module Dates
    # TODO: Handle pay in advance and terminated_pay_in_arrear
    class QuarterlyService < Subscriptions::DatesService
      def compute_base_date
        # This is the time date_time when the api was called.
        total_months_difference = compute_months_difference(subscription_at, billing_date)
        modulus_months = total_months_difference % 3
        billing_date << modulus_months
      end

      def compute_months_difference(subscription_date, current_date)
        (current_date.year * 12 + current_date.month) - (subscription_date.year * 12 + subscription_date.month)
      end

      def compute_base_end_date
        plus_3_months_date = compute_base_date >> 3
        end_date = plus_3_months_date - 1
        end_date
      end

      def compute_end_date_calendar
        plus_3_months_date = compute_base_date >> 3
        plus_3_month_day_1 = Date.new(plus_3_months_date.year, plus_3_months_date.month, 1)
        plus_3_month_day_1 - 1
      end

      def compute_from_date
        subscription.anniversary? ? compute_base_date : Date.new(compute_base_date.year, compute_base_date.month, 1)
      end

      def compute_to_date
        subscription.anniversary? ? compute_base_end_date : compute_end_date_calendar
      end

      def compute_charges_from_date
        subscription.anniversary? ? compute_base_date : Date.new(compute_base_date.year, compute_base_date.month, 1)
      end

      def compute_charges_to_date
        subscription.anniversary? ? compute_base_end_date : compute_end_date_calendar
      end

      def compute_next_end_of_period
        compute_to_date
      end

      def first_month_in_yearly_period?
        false
      end

      def compute_previous_beginning_of_period(date)
        compute_from_date << 3
      end

      def compute_duration(from_date:)
        (compute_to_date - compute_from_date + 1.day).to_i
      end
    end
  end
end
