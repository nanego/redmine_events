require File.expand_path(File.dirname(__FILE__) + '/../../../../lib/plugins/acts_as_customizable/lib/acts_as_customizable')

module Redmine
  module Acts
    module Customizable
      module InstanceMethods

        # Sets the values of the object's custom fields
        # values is a hash like {'1' => 'foo', 2 => 'bar'}
        def custom_field_values=(values)
          values = values.stringify_keys
          custom_field_values.each do |custom_field_value|
            key = custom_field_value.custom_field_id.to_s
            if values.has_key?(key)
              value = values[key]
              if value.is_a?(Array)
                value = value.reject(&:blank?).map(&:to_s).uniq
                if value.empty?
                  value << ''
                end
              else
                value = value.to_s
              end
              custom_field_value.value = value
              # PATCH START
              custom_field_value.comment = values[key+'-comment']
              # PATCH END
            end
          end
          @custom_field_values_changed = true
        end

        def custom_field_values
          @custom_field_values ||= available_custom_fields.collect do |field|
            x = CustomFieldValue.new
            x.custom_field = field
            x.customized = self
            if field.multiple?
              values = custom_values.select { |v| v.custom_field == field }
              if values.empty?
                values << custom_values.build(:customized => self, :custom_field => field, :value => nil)
              end
              x.value = values.map(&:value)
              # PATCH START
              x.comment = values.map(&:comment)
              # PATCH END
            else
              cv = custom_values.detect { |v| v.custom_field == field }
              cv ||= custom_values.build(:customized => self, :custom_field => field, :value => nil)
              x.value = cv.value
              # PATCH START
              x.comment = cv.comment
              # PATCH END
            end
            x.value_was = x.value.dup if x.value
            x
          end
        end

        def save_custom_field_values
          target_custom_values = []
          custom_field_values.each do |custom_field_value|
            if custom_field_value.value.is_a?(Array)
              custom_field_value.value.each do |v|
                target = custom_values.detect {|cv| cv.custom_field == custom_field_value.custom_field && cv.value == v}
                target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field, :value => v)
                target_custom_values << target
              end
            else
              target = custom_values.detect {|cv| cv.custom_field == custom_field_value.custom_field}
              target ||= custom_values.build(:customized => self, :custom_field => custom_field_value.custom_field)
              target.value = custom_field_value.value
              # PATCH START
              target.comment = custom_field_value.comment
              # PATCH END
              target_custom_values << target
            end
          end
          self.custom_values = target_custom_values
          custom_values.each(&:save)
          @custom_field_values_changed = false
          true
        end

      end
    end
  end
end
