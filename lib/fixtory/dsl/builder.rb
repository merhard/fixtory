require 'fixtory/dsl/table'

class Fixtory::DSL::Builder < BasicObject
  attr_accessor :_tables

  def initialize
    @_tables = []
  end

  def _table(name, &block)
    _tables << ::Fixtory::DSL::Table.new(name, self, &block)
  end

  def _eval_from_fixtory_file(path)
    contents = ::File.read(path)
    instance_eval(contents, path, 1)
    _tables.each do |table|
      if table._block
        table.instance_eval(&table._block)
        table._block = nil
      end
    end
  end

  def _insert
    _tables.each do |table|
      table._rows.each do |row|
        _connection.insert_fixture(row.instance_eval('@attributes'), table._name)
        row.instance_eval("@inserted = true")
      end
    end
  end

  def method_missing(method, *args, &block)
    if block && block.respond_to?(:call)
      _table(method, &block)
    else
      table = _tables.find do |table|
        table._name == method.to_s
      end

      table || super
    end
  end

  private

  def _connection
    ::ActiveRecord::Base.connection
  end
end
