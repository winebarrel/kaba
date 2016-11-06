class Kaba::Exporter
  CONCURRENCY = 8

  def initialize(client, options = {})
    @client = client
    @options = options
  end

  def export
    {
      load_balancers: export_load_balancers.sort_array!,
      target_groups: export_target_groups.sort_array!
    }
  end

  private

  def export_load_balancers
    lb_by_name = {}
    resp = @client.describe_load_balancers
    load_balancers = Parallel.map(resp, in_threads: CONCURRENCY, &:load_balancers).flatten

    Parallel.each(load_balancers, in_threads: CONCURRENCY) do |lb|
      arn = lb.load_balancer_arn

      lb_h = {
        load_balancer_arn: arn,
        scheme: lb.scheme,
        vpc_id: lb.vpc_id,
        security_groups: lb.security_groups,
        subnets: lb.availability_zones.map(&:subnet_id),
        attributes: export_load_balancer_attributes(arn),
        listeners: export_listeners(arn)
      }

      lb_by_name[lb.load_balancer_name] = lb_h
    end

    lb_by_name
  end

  def export_load_balancer_attributes(lb_arn)
    resp = @client.describe_load_balancer_attributes(load_balancer_arn: lb_arn)
    resp.attributes.map(&:to_a).to_h
  end

  def export_listeners(lb_arn)
    lstnr_by_port = {}

    resp = @client.describe_listeners(load_balancer_arn: lb_arn)
    listeners = Parallel.map(resp, in_threads: CONCURRENCY, &:listeners).flatten

    Parallel.each(listeners, in_threads: CONCURRENCY) do |lstnr|
      arn = lstnr.listener_arn

      lstnr_h = {
        listener_arn: arn,
        protocol: lstnr.protocol,
        certificates: lstnr.certificates.map(&:certificate_arn),
        ssl_policy: lstnr.ssl_policy,
        default_actions: actions_to_hash_list(lstnr.default_actions),
        rules: export_rules(arn),
      }

      lstnr_by_port[lstnr.port] = lstnr_h
    end

    lstnr_by_port
  end

  def export_rules(lstnr_arn)
    resp = @client.describe_rules(listener_arn: lstnr_arn)

    resp.rules.reject(&:is_default).map do |r|
      {
        rule_arn: r.rule_arn,
        priority: r.priority,
        conditions: r.conditions.map(&:to_h),
        actions: actions_to_hash_list(r.actions),
      }
    end
  end

  def export_target_groups
    tg_by_name = {}
    resp = @client.describe_target_groups
    target_groups = Parallel.map(resp, in_threads: CONCURRENCY, &:target_groups).flatten

    Parallel.each(target_groups, in_threads: CONCURRENCY) do |tg|
      arn = tg.target_group_arn

      tg_h = {
        target_group_arn: arn,
        protocol: tg.protocol,
        port: tg.port,
        vpc_id: tg.vpc_id,
        health_check_protocol: tg.health_check_protocol,
        health_check_port: tg.health_check_port,
        health_check_interval_seconds: tg.health_check_interval_seconds,
        health_check_timeout_seconds: tg.health_check_timeout_seconds,
        healthy_threshold_count: tg.healthy_threshold_count,
        unhealthy_threshold_count: tg.unhealthy_threshold_count,
        health_check_path: tg.health_check_path,
        matcher: tg.matcher.to_h,
        attributes: export_target_group_attributes(arn),
        targets: export_targets(arn),
      }

      tg_by_name[tg.target_group_name] = tg_h
    end

    tg_by_name
  end

  def export_target_group_attributes(tg_arn)
    resp = @client.describe_target_group_attributes(target_group_arn: tg_arn)
    resp.attributes.map(&:to_a).to_h
  end

  def export_targets(tg_arn)
    port_by_instance = {}
    resp = @client.describe_target_health(target_group_arn: tg_arn)

    resp.target_health_descriptions.each do |thd|
      port_by_instance[thd.target.id] = thd.target.port
    end

    port_by_instance
  end

  def actions_to_hash_list(actions)
    actions.map do |a|
      {
        type: a.type,
        target_group: target_group_arn_to_name(a.target_group_arn),
      }
    end
  end

  def target_group_arn_to_name(tg_arn)
    tg_arn.split('/').fetch(1)
  end
end
