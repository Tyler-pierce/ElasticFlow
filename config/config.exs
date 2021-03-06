# This file is responsible for configuring your application
# and its dependencies with the aid of the Mix.Config module.
use Mix.Config

# This configuration is loaded before any dependency and is restricted
# to this project. If another project depends on this project, this
# file won't be loaded nor affect the parent project. For this reason,
# if you want to provide default values for your application for
# 3rd-party users, it should be done in your "mix.exs" file.

# You can configure your application as:
#
#     config :elastic_flow, key: :value
#
# and access this configuration in your application as:
#
#     Application.get_env(:elastic_flow, :key)
#
# You can also configure a 3rd-party app:
#
#     config :logger, level: :info
#

config :elastic_flow, 
  servers: %{
	:"yam1@baggy-the-cat" => :master, 
	:"yam2@baggy-the-cat" => :slave, 
	:"yam3@baggy-the-cat" => :slave
  },
  task: {ElasticFlow.Example, :count_words},
  aggregator: {ElasticFlow.Example, :aggregate}, # Optional
  intercept: ElasticFlow.ExampleInterceptor, # Optional
  distribute_window: {ElasticFlow.Example, :get_window}, # Optional, used in example to force more distribution
  compress: false # Optional, can't work for example since tuples are used


# It is also possible to import configuration files, relative to this
# directory. For example, you can emulate configuration per environment
# by uncommenting the line below and defining dev.exs, test.exs and such.
# Configuration from the imported file will override the ones defined
# here (which is why it is important to import them last).
#
#     import_config "#{Mix.env}.exs"
