require 'wit'
# Quickstart example
# See https://wit.ai/l5t/Quickstart

class WitAi
  attr_accessor :session_id, :context, :access_token, :client, :output

  def initialize
    @session_id = 'my-user-id-42'
    @context = {}
    @access_token = ENV["WITAI_ACCESS_TOKEN"]
    @client = Wit.new @access_token, self.actions
  end

  def first_entity_value(entities, entity)
    return nil unless entities.has_key? entity
    val = entities[entity][0]['value']
    return nil if val.nil?
    return val.is_a?(Hash) ? val['value'] : val
  end

  def actions
    actions = {
     :say => -> (session_id, msg) {
       @output = msg
       return @output
     },
     :merge => -> (ctx, entities) {
       new_context = ctx.clone
       loc = first_entity_value entities, 'location'
       new_context['loc'] = loc unless loc.nil?
       return new_context
     },
     :error => -> (session_id, msg) {
       return 'Oops I don\'t know what to do.'
     },
     :'fetch-weather' => -> (ctx) {
       new_context = ctx.clone
       new_context['forecast'] = "sunny"
       return new_context
     },
   }
  end

  def send_converse(message)
    rst = client.converse session_id, message, context
    handle_actions(rst, context)
  end

  def handle_actions(converse, ctx)
    type = converse['type']
    context = ctx

    return context if type == 'stop'
    if type == 'msg'
      msg = converse['msg']
      actions[:say].call session_id, msg
    elsif type == 'merge'
      ctx = actions[:merge].call context, converse['entities']
      context = ctx
      if context.nil?
        p 'WARN missing context - did you forget to return it?'
        context = {}
      end
    elsif type == 'action'
      action = converse['action'].to_sym
      ctx = actions[action].call context
      context = ctx
      if context.nil?
        p 'WARN missing context - did you forget to return it?'
        context = {}
      end
    elsif type == 'error'
        actions[:error].call session_id, 'unknown action: error'
    else
      exit
    end
    # Retrieving action sequence
    rst = client.converse session_id, nil, context
    handle_actions(rst, context)
  end
end
