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
    body = <<-EOS
  scheme #{lb[:scheme].inspect}
  vpc_id #{lb[:vpc_id].inspect}
  security_groups #{lb[:security_groups].inspect}
  subnets #{lb[:subnets].inspect}
    EOS

    body += "\n" + <<-EOS
  attributes do
    #{lb[:attributes].pretty_inspect.gsub(/^/m, "\s" * 4).strip}
  end
    EOS

    body += "\n" + <<-EOS
  #{output_listeners(lb[:listeners]).strip}
    EOS

    <<-EOS
load_balancer #{name.inspect} do
  #{body.strip}
end
    EOS
  end

  def output_listeners(lstnr_by_port)
    listeners = []

    lstnr_by_port.sort_by(&:first).each do |port, lstnr|
      listeners << output_listener(port, lstnr)
    end

    listeners.join("\n")
  end

  def output_listener(port, lstnr)
    body = <<-EOS
    protocol #{lstnr[:protocol].inspect}
    EOS

    unless lstnr[:certificates].empty?
      body += <<-EOS
    certificates #{lstnr[:certificates].inspect}
      EOS
    end

    if lstnr[:ssl_policy]
      body += <<-EOS
    ssl_policy #{lstnr[:ssl_policy].inspect}
      EOS
    end

    body += "\n" + <<-EOS
    #{output_actions(lstnr[:default_actions], default: true).strip}
    EOS

    body += "\n" + <<-EOS
    #{output_rules(lstnr[:rules]).strip}
    EOS

#        {:listener_arn=>
#          "arn:aws:elasticloadbalancing:ap-northeast-1:822997939312:listener/app/test/c67c874afd293edd/456dd428ede55d55",
#         :protocol=>"HTTP",
#         :certificates=>[],
#         :ssl_policy=>nil,
#         :default_actions=>[{:type=>"forward", :target_group=>"tesdafdafa"}],

    <<-EOS
  listener #{port.inspect} do
    #{body.strip}
  end
    EOS
  end

  def output_actions(action_list, options = {})
    actions = []

    action_list.each do |a|
      actions << output_action(a, options)
    end

    actions.join("\n")
  end

  def output_action(action, options = {})
    method_name = options[:default] ? 'default_action' : 'action'

    out = <<-EOS
    #{method_name} do
      type #{action[:type].inspect}
      target_group #{action[:target_group].inspect}
    end
    EOS

    if options[:additional_indent]
      out.gsub(/^/m, options[:additional_indent])
    else
      out
    end
  end

  def output_rules(rule_list)
    rules = []

    rule_list.each do |r|
      rules << output_rule(r)
    end

    rules.join("\n")
  end

  def output_rule(rule)
    body = <<-EOS
      priority #{rule[:priority].inspect}
    EOS

    body += "\n" + <<-EOS
      #{output_conditions(rule[:conditions]).strip}
    EOS

    body += "\n" + <<-EOS
      #{output_actions(rule[:actions], additional_indent: "\s" * 2).strip}
    EOS

    <<-EOS
    rule do
      #{body.strip}
    end
    EOS
  end

  def output_conditions(condition_list)
    conditions = []

    condition_list.each do |c|
      conditions << output_condition(c)
    end

    conditions.join("\n")
  end

  def output_condition(condition)
    <<-EOS
      condition do
        field #{condition[:field].inspect}
        values #{condition[:values].inspect}
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
    body = <<-EOS
  protocol #{tg[:protocol].inspect}
  port #{tg[:port].inspect}
  vpc_id #{tg[:vpc_id].inspect}
  health_check_protocol #{tg[:health_check_protocol].inspect}
  health_check_port #{tg[:health_check_port].inspect}
  health_check_interval_seconds #{tg[:health_check_interval_seconds].inspect}
  health_check_timeout_seconds #{tg[:health_check_timeout_seconds].inspect}
  healthy_threshold_count #{tg[:healthy_threshold_count].inspect}
  unhealthy_threshold_count #{tg[:unhealthy_threshold_count].inspect}
  health_check_path #{tg[:health_check_path].inspect}
    EOS

    body += "\n" + <<-EOS
  #{output_matcher(tg[:matcher]).strip}
    EOS

    body += "\n" + <<-EOS
  attributes do
    #{tg[:attributes].pretty_inspect.gsub(/^/m, "\s" * 4).strip}
  end
    EOS

    <<-EOS
target_group #{name.inspect} do
  #{body.strip}
end
    EOS
  end

  def output_matcher(matcher)
    <<-EOS
  matcher do
    http_code #{matcher[:http_code].inspect}
  end
    EOS
  end
end

__END__
