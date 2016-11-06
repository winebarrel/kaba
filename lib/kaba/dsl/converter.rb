class Kaba::DSL::Converter
  def self.convert(exported, options = {})
    self.new(exported, options).convert
  end

  def initialize(exported, options = {})
    @exported = exported
    @options = options
  end

  def convert
    [
      output_load_balancers(@exported.fetch(:load_balancers, [])),
      output_target_groups(@exported.fetch(:target_groups, [])),
    ].join("\n").strip
  end

  private

  def output_load_balancers(lb_by_name)
    load_balancers = []

    lb_by_name.sort_by(&:first).each do |name, lb|
      load_balancers << output_load_balancer(name, lb)
    end

    load_balancers.join("\n")
  end

  def output_load_balancer(name, lb)
    <<-EOS
load_balancer #{name.inspect} do
end
    EOS
  end

  def output_target_groups(tg_by_name)
    target_groups = []

    tg_by_name.sort_by(&:first).each do |name, tg|
      target_groups << output_target_group(name, tg)
    end

    target_groups.join("\n")
  end

  def output_target_group(name, tg)
    <<-EOS
target_group #{name.inspect} do
end
    EOS
  end
end
