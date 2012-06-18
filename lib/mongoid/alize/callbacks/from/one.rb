module Mongoid
  module Alize
    module Callbacks
      module From
        class One < FromCallback

          protected

          def define_callback
            field_sets = ""
            fields.each do |name|
              field_sets << "self.set(:#{prefixed_field_name(name)}, relation && relation.read_attribute(:#{name}))\n"
            end

            klass.class_eval <<-CALLBACK, __FILE__, __LINE__ + 1
              def #{callback_name}
                relation = self.#{relation}
                #{field_sets}
                true
              end
            CALLBACK
          end

          def define_fields
            fields.each do |name|
              prefixed_name = prefixed_field_name(name)
              if klass.fields[prefixed_name]
                raise Mongoid::Alize::Errors::AlreadyDefinedField.new(prefixed_name, klass.name)
              else
                klass.class_eval <<-CALLBACK, __FILE__, __LINE__ + 1
                  field :#{prefixed_name}, :type => #{inverse_field_type(name)}
                CALLBACK
              end
            end
          end

          def prefixed_field_name(name)
            "#{relation}_#{name}"
          end

          def inverse_field_type(name)
            name = name.to_s

            name = "_id" if name == "id"
            name = "_type" if name == "type"

            field = inverse_klass.fields[name]
            if field
              field.options[:type] ? field.type : String
            else
              raise Mongoid::Alize::Errors::InvalidField.new(name, inverse_klass.name)
            end
          end
        end
      end
    end
  end
end