module Charges
  module ChargeModels
    class FlexibleService < Charges::ChargeModels::BaseService
      protected

      def ranges
        properties['graduated_ranges']&.map(&:with_indifferent_access)
      end

      def compute_per_txn_aggregation
        ranges.reduce(0) do |result_amount, range|
          flat_amount = BigDecimal(range[:flat_amount])
          per_unit_amount = BigDecimal(range[:per_unit_amount])
          percentage_rate = BigDecimal(range[:percentage_rate] || 0)
          min_amount = range[:min_amount]
          max_amount = range[:max_amount]
          fixed_fee_deductions = BigDecimal(range[:per_txn_fixed_fee_deductions] || 0)

          # NOTE: Add flat amount to the total
          result_amount += flat_amount unless units.zero?

          range_units = compute_range_units(range[:from_value], range[:to_value])
          result_amount += range_units * per_unit_amount

          percentage_units = compute_percentage_units(percentage_rate, range[:from_value], range[:to_value], min_amount, max_amount, fixed_fee_deductions)
          result_amount += percentage_units

          # NOTE: aggregation_result.aggregation is between the bounds of the current range,
          #       we must stop the loop
          break result_amount if range[:to_value].nil? || range[:to_value] >= units

          result_amount
        end
      end

      def compute_amount
        total = 0.0
        total += compute_per_txn_aggregation
        total_take_away_percentage = BigDecimal(properties['total_take_away_percentage'] || 100)
        minimum_commitment = BigDecimal(properties['minimum_commitment'] || 0)
        total = total * total_take_away_percentage / 100
        max(minimum_commitment, total)
      end

      def max (a, b)
        a > b ? a : b
      end

      def min (a, b)
        a < b ? a : b
      end

      def compute_percentage_units(percentage_rate, from_value, to_value, min_amount, max_amount, fixed_fee_deductions)
        total = 0.0
        percent = percentage_rate / 100
        if min_amount and max_amount
          aggregation_result.events[from_value..to_value].map { |x| total += min(max_amount, max(x, min_amount)) * percent - fixed_fee_deductions }
        elsif min_amount
          aggregation_result.events[from_value..to_value].map { |x| total += max(x, min_amount) * percent - fixed_fee_deductions }
        elsif max_amount
          aggregation_result.events[from_value..to_value].map { |x| total += min(max_amount, x) * percent - fixed_fee_deductions }
        else
          aggregation_result.events[from_value..to_value].map { |x| total += x * percent - fixed_fee_deductions }
        end
        total
      end

      # NOTE: compute how many units to bill in the range
      def compute_range_units(from_value, to_value)
        # NOTE: units is higher than the to_value of the range
        if to_value && units >= to_value
          return to_value - (from_value.zero? ? 1 : from_value) + 1
        end

        return to_value - from_value if to_value && units >= to_value
        return units if from_value.zero?

        # NOTE: units is in the range
        units - from_value + 1
      end
    end
  end
end